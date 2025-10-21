# Redis 哨兵模式测试

这个目录包含了 Redis 哨兵模式的多语言测试代码。

## 目录结构

```
test/
├── go/                    # Go 语言测试
│   ├── redis-config.go   # Redis 哨兵配置
│   ├── test-redis.go     # 功能测试
│   ├── web-app.go        # Web 应用
│   ├── go.mod            # Go 模块文件
│   └── Makefile          # 构建脚本
├── py/                    # Python 语言测试
│   ├── redis_config.py   # Redis 哨兵配置
│   ├── test_redis.py     # 功能测试
│   ├── web_app.py        # Web 应用
│   ├── requirements.txt  # Python 依赖
│   └── Makefile          # 构建脚本
└── README.md             # 本文档
```

## 快速开始

### 1. 启动 Redis 哨兵集群

```bash
# 在项目根目录执行
./redis-sentinel-manage.sh start
```

### 2. 运行 Go 测试

```bash
cd test/go
make test
```

### 3. 运行 Python 测试

```bash
cd test/py
make test
```

## 详细使用

### Go 语言测试

```bash
cd test/go

# 安装依赖
make deps

# 构建程序
make build

# 运行测试
make test

# 启动 Web 应用
make web

# 查看帮助
make help
```

### Python 语言测试

```bash
cd test/py

# 安装依赖
make install

# 运行测试
make test

# 启动 Web 应用
make web

# 查看帮助
make help
```

## 测试内容

### 基本功能测试
- 键值对操作（设置、获取、删除）
- 过期时间测试
- 键存在性检查

### 数据结构测试
- 哈希操作（用户信息存储）
- 列表操作（任务列表管理）
- 集合操作（标签管理）
- 有序集合操作（分数排名）

### 连接测试
- 哨兵连接测试
- 主从节点连接测试
- 连接信息获取

### Web API 测试
- RESTful API 接口
- 错误处理测试
- 健康检查测试

## Web API 接口

两种语言都提供了相同的 Web API 接口：

### 基本键值操作
- POST /api/v1/kv - 设置键值对
- GET /api/v1/kv/:key - 获取键值对
- DELETE /api/v1/kv/:key - 删除键
- GET /api/v1/kv/:key/exists - 检查键是否存在

### 用户操作
- POST /api/v1/users - 设置用户信息
- GET /api/v1/users/:id - 获取用户信息

### 列表操作
- POST /api/v1/lists - 添加列表项
- GET /api/v1/lists/:list_key - 获取列表
- DELETE /api/v1/lists/:list_key/pop - 弹出列表项

### 集合操作
- POST /api/v1/sets - 添加集合成员
- GET /api/v1/sets/:set_key - 获取集合成员

### 系统操作
- GET /api/v1/redis/status - 获取 Redis 状态
- GET /api/v1/health - 健康检查

## 测试示例

### Go 语言示例

```go
// 设置键值对
Set(ctx, "key", "value", 0)

// 获取键值对
value, err := Get(ctx, "key")

// 删除键
count, err := Del(ctx, "key")
```

### Python 语言示例

```python
# 设置键值对
master.set('key', 'value')

# 获取键值对
value = slave.get('key')

# 删除键
count = master.delete('key')
```

## 注意事项

1. Redis 集群: 确保 Redis 哨兵集群已启动
2. 端口冲突: 检查端口是否被占用
3. 依赖安装: 确保已安装相应的语言环境
4. 网络连接: 确保能够连接到 Redis 集群

## 故障排除

### 常见问题

1. 连接失败
   - 检查 Redis 集群状态
   - 验证网络连接
   - 检查端口配置

2. 依赖问题
   - 检查 Go 版本（需要 1.21+）
   - 检查 Python 版本（需要 3.7+）
   - 重新安装依赖

3. 权限问题
   - 检查文件权限
   - 确保有执行权限

### 调试命令

```bash
# 检查 Redis 集群状态
./redis-sentinel-manage.sh status

# 检查 Go 环境
go version

# 检查 Python 环境
python3 --version

# 查看日志
./redis-sentinel-manage.sh logs
```

## 性能测试

可以通过以下方式进行性能测试：

1. 并发测试: 使用多线程/协程同时访问
2. 压力测试: 使用工具如 ab、wrk 等
3. 监控指标: 观察 Redis 和应用的性能指标

## 安全建议

1. 密码保护: 使用强密码
2. 网络隔离: 在生产环境中使用网络隔离
3. 访问控制: 限制 Redis 访问权限
4. 日志审计: 记录和监控所有操作
