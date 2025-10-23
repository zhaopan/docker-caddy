package main

import (
	"context"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// WebApp Web 应用结构体
type WebApp struct {
	redis *RedisSentinelConfig
}

// NewWebApp 创建新的 Web 应用
func NewWebApp() *WebApp {
	return &WebApp{
		redis: RedisConfig,
	}
}

// Response 统一响应结构
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// User 用户结构体
type User struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
	Age  int    `json:"age"`
}

// 成功响应
func success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    200,
		Message: "success",
		Data:    data,
	})
}

// 错误响应
func errorResponse(c *gin.Context, code int, message string) {
	c.JSON(code, Response{
		Code:    code,
		Message: message,
	})
}

// 设置键值对
func (app *WebApp) setKeyValue(c *gin.Context) {
	var req struct {
		Key   string `json:"key" binding:"required"`
		Value string `json:"value" binding:"required"`
		TTL   int    `json:"ttl"` // 过期时间（秒）
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		errorResponse(c, http.StatusBadRequest, "参数错误: "+err.Error())
		return
	}

	ctx := context.Background()
	var expiration time.Duration
	if req.TTL > 0 {
		expiration = time.Duration(req.TTL) * time.Second
	}

	err := app.redis.Set(ctx, req.Key, req.Value, expiration)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "设置失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"key":   req.Key,
		"value": req.Value,
		"ttl":   req.TTL,
	})
}

// 获取键值对
func (app *WebApp) getKeyValue(c *gin.Context) {
	key := c.Param("key")
	if key == "" {
		errorResponse(c, http.StatusBadRequest, "键名不能为空")
		return
	}

	ctx := context.Background()
	value, err := app.redis.Get(ctx, key)
	if err != nil {
		errorResponse(c, http.StatusNotFound, "键不存在或获取失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"key":   key,
		"value": value,
	})
}

// 删除键
func (app *WebApp) deleteKey(c *gin.Context) {
	key := c.Param("key")
	if key == "" {
		errorResponse(c, http.StatusBadRequest, "键名不能为空")
		return
	}

	ctx := context.Background()
	count, err := app.redis.Del(ctx, key)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "删除失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"key":   key,
		"count": count,
	})
}

// 检查键是否存在
func (app *WebApp) existsKey(c *gin.Context) {
	key := c.Param("key")
	if key == "" {
		errorResponse(c, http.StatusBadRequest, "键名不能为空")
		return
	}

	ctx := context.Background()
	count, err := app.redis.Exists(ctx, key)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "检查失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"key":    key,
		"exists": count > 0,
	})
}

// 设置用户信息
func (app *WebApp) setUser(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		errorResponse(c, http.StatusBadRequest, "参数错误: "+err.Error())
		return
	}

	ctx := context.Background()
	userKey := "user:" + strconv.Itoa(user.ID)

	// 使用哈希存储用户信息
	_, err := app.redis.HSet(ctx, userKey, "id", user.ID, "name", user.Name, "age", user.Age)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "设置用户失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"user": user,
	})
}

// 获取用户信息
func (app *WebApp) getUser(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := strconv.Atoi(userIDStr)
	if err != nil {
		errorResponse(c, http.StatusBadRequest, "用户ID格式错误")
		return
	}

	ctx := context.Background()
	userKey := "user:" + strconv.Itoa(userID)

	// 获取用户信息
	userData, err := app.redis.HGetAll(ctx, userKey)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "获取用户失败: "+err.Error())
		return
	}

	if len(userData) == 0 {
		errorResponse(c, http.StatusNotFound, "用户不存在")
		return
	}

	// 解析用户数据
	age, _ := strconv.Atoi(userData["age"])
	user := User{
		ID:   userID,
		Name: userData["name"],
		Age:  age,
	}

	success(c, gin.H{
		"user": user,
	})
}

// 添加列表项
func (app *WebApp) addListItem(c *gin.Context) {
	var req struct {
		ListKey string   `json:"list_key" binding:"required"`
		Items   []string `json:"items" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		errorResponse(c, http.StatusBadRequest, "参数错误: "+err.Error())
		return
	}

	ctx := context.Background()

	// 转换为 interface{} 切片
	items := make([]interface{}, len(req.Items))
	for i, item := range req.Items {
		items[i] = item
	}

	count, err := app.redis.LPush(ctx, req.ListKey, items...)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "添加列表项失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"list_key": req.ListKey,
		"count":    count,
		"items":    req.Items,
	})
}

// 获取列表
func (app *WebApp) getList(c *gin.Context) {
	listKey := c.Param("list_key")
	if listKey == "" {
		errorResponse(c, http.StatusBadRequest, "列表键名不能为空")
		return
	}

	ctx := context.Background()
	items, err := app.redis.LRange(ctx, listKey, 0, -1)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "获取列表失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"list_key": listKey,
		"items":    items,
		"count":    len(items),
	})
}

// 弹出列表项
func (app *WebApp) popListItem(c *gin.Context) {
	listKey := c.Param("list_key")
	if listKey == "" {
		errorResponse(c, http.StatusBadRequest, "列表键名不能为空")
		return
	}

	ctx := context.Background()
	item, err := app.redis.RPop(ctx, listKey)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "弹出列表项失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"list_key": listKey,
		"item":     item,
	})
}

// 添加集合成员
func (app *WebApp) addSetMember(c *gin.Context) {
	var req struct {
		SetKey  string   `json:"set_key" binding:"required"`
		Members []string `json:"members" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		errorResponse(c, http.StatusBadRequest, "参数错误: "+err.Error())
		return
	}

	ctx := context.Background()

	// 转换为 interface{} 切片
	members := make([]interface{}, len(req.Members))
	for i, member := range req.Members {
		members[i] = member
	}

	count, err := app.redis.SAdd(ctx, req.SetKey, members...)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "添加集合成员失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"set_key": req.SetKey,
		"count":   count,
		"members": req.Members,
	})
}

// 获取集合成员
func (app *WebApp) getSetMembers(c *gin.Context) {
	setKey := c.Param("set_key")
	if setKey == "" {
		errorResponse(c, http.StatusBadRequest, "集合键名不能为空")
		return
	}

	ctx := context.Background()
	members, err := app.redis.SMembers(ctx, setKey)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "获取集合成员失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"set_key": setKey,
		"members": members,
		"count":   len(members),
	})
}

// 获取 Redis 状态
func (app *WebApp) getRedisStatus(c *gin.Context) {
	ctx := context.Background()

	// 获取主节点地址
	masterAddr, err := app.redis.GetMasterAddr(ctx)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "获取主节点地址失败: "+err.Error())
		return
	}

	// 获取从节点地址
	slaveAddrs, err := app.redis.GetSlaveAddrs(ctx)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "获取从节点地址失败: "+err.Error())
		return
	}

	// 获取哨兵信息
	sentinelInfo, err := app.redis.GetSentinelInfo(ctx)
	if err != nil {
		errorResponse(c, http.StatusInternalServerError, "获取哨兵信息失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"master_addr":  masterAddr,
		"slave_addrs":  slaveAddrs,
		"sentinel_info": sentinelInfo,
	})
}

// 健康检查
func (app *WebApp) healthCheck(c *gin.Context) {
	ctx := context.Background()

	// 测试主节点连接
	_, err := app.redis.MasterClient.Ping(ctx).Result()
	if err != nil {
		errorResponse(c, http.StatusServiceUnavailable, "主节点连接失败: "+err.Error())
		return
	}

	// 测试从节点连接
	_, err = app.redis.SlaveClient.Ping(ctx).Result()
	if err != nil {
		errorResponse(c, http.StatusServiceUnavailable, "从节点连接失败: "+err.Error())
		return
	}

	success(c, gin.H{
		"status": "healthy",
		"timestamp": time.Now().Unix(),
	})
}

// 设置路由
func (app *WebApp) setupRoutes() *gin.Engine {
	r := gin.Default()

	// 中间件
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	// CORS 中间件
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// API 路由组
	api := r.Group("/api/v1")
	{
		// 基本键值操作
		api.POST("/kv", app.setKeyValue)           // 设置键值对
		api.GET("/kv/:key", app.getKeyValue)       // 获取键值对
		api.DELETE("/kv/:key", app.deleteKey)      // 删除键
		api.GET("/kv/:key/exists", app.existsKey)  // 检查键是否存在

		// 用户操作
		api.POST("/users", app.setUser)     // 设置用户
		api.GET("/users/:id", app.getUser)  // 获取用户

		// 列表操作
		api.POST("/lists", app.addListItem)        // 添加列表项
		api.GET("/lists/:list_key", app.getList)   // 获取列表
		api.DELETE("/lists/:list_key/pop", app.popListItem) // 弹出列表项

		// 集合操作
		api.POST("/sets", app.addSetMember)        // 添加集合成员
		api.GET("/sets/:set_key", app.getSetMembers) // 获取集合成员

		// 系统操作
		api.GET("/redis/status", app.getRedisStatus) // 获取 Redis 状态
		api.GET("/health", app.healthCheck)         // 健康检查
	}

	return r
}

// 启动 Web 应用
func (app *WebApp) Run(port string) {
	r := app.setupRoutes()

	log.Printf("Web 应用启动在端口 %s", port)
	log.Printf("API 文档:")
	log.Printf("  POST   /api/v1/kv              - 设置键值对")
	log.Printf("  GET    /api/v1/kv/:key         - 获取键值对")
	log.Printf("  DELETE /api/v1/kv/:key         - 删除键")
	log.Printf("  GET    /api/v1/kv/:key/exists  - 检查键是否存在")
	log.Printf("  POST   /api/v1/users           - 设置用户")
	log.Printf("  GET    /api/v1/users/:id       - 获取用户")
	log.Printf("  POST   /api/v1/lists           - 添加列表项")
	log.Printf("  GET    /api/v1/lists/:list_key - 获取列表")
	log.Printf("  DELETE /api/v1/lists/:list_key/pop - 弹出列表项")
	log.Printf("  POST   /api/v1/sets            - 添加集合成员")
	log.Printf("  GET    /api/v1/sets/:set_key   - 获取集合成员")
	log.Printf("  GET    /api/v1/redis/status    - 获取 Redis 状态")
	log.Printf("  GET    /api/v1/health          - 健康检查")

	if err := r.Run(":" + port); err != nil {
		log.Fatal("启动 Web 应用失败:", err)
	}
}

func main() {
	// 创建 Web 应用
	app := NewWebApp()

	// 启动应用
	app.Run("8080")
}
