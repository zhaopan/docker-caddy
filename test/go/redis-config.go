package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

// RedisSentinelConfig Redis 哨兵配置结构体
type RedisSentinelConfig struct {
	// 哨兵节点列表
	Sentinels []string
	// 主节点名称
	MasterName string
	// Redis 密码
	Password string
	// 哨兵客户端
	SentinelClient *redis.SentinelClient
	// 主节点客户端
	MasterClient *redis.Client
	// 从节点客户端
	SlaveClient *redis.Client
}

// NewRedisSentinelConfig 创建新的 Redis 哨兵配置
func NewRedisSentinelConfig() *RedisSentinelConfig {
	config := &RedisSentinelConfig{
		Sentinels: []string{
			"localhost:26379",
			"localhost:26380",
			"localhost:26381",
		},
		MasterName: "redis-master",
		Password:   "CG1rMeyRryFgvElf8n",
	}

	// 初始化哨兵客户端
	config.initSentinel()
	
	// 初始化主从客户端
	config.initClients()

	return config
}

// initSentinel 初始化哨兵客户端
func (r *RedisSentinelConfig) initSentinel() {
	r.SentinelClient = redis.NewSentinelClient(&redis.SentinelOptions{
		Addrs:      r.Sentinels,
		Password:   r.Password,
		MaxRetries: 3,
		PoolSize:   10,
	})

	// 测试哨兵连接
	ctx := context.Background()
	_, err := r.SentinelClient.Ping(ctx).Result()
	if err != nil {
		log.Printf("哨兵连接失败: %v", err)
	} else {
		log.Println("哨兵连接成功")
	}
}

// initClients 初始化主从客户端
func (r *RedisSentinelConfig) initClients() {
	ctx := context.Background()

	// 获取主节点地址
	masterAddr, err := r.SentinelClient.GetMasterAddrByName(ctx, r.MasterName).Result()
	if err != nil {
		log.Printf("获取主节点地址失败: %v", err)
		return
	}

	// 获取从节点地址
	slaveAddrs, err := r.SentinelClient.Slaves(ctx, r.MasterName).Result()
	if err != nil {
		log.Printf("获取从节点地址失败: %v", err)
		return
	}

	// 创建主节点客户端
	r.MasterClient = redis.NewClient(&redis.Options{
		Addr:         fmt.Sprintf("%s:%s", masterAddr[0], masterAddr[1]),
		Password:     r.Password,
		DB:           0,
		MaxRetries:   3,
		PoolSize:     20,
		MinIdleConns: 5,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
	})

	// 创建从节点客户端（使用第一个从节点）
	if len(slaveAddrs) > 0 {
		slaveAddr := slaveAddrs[0]
		r.SlaveClient = redis.NewClient(&redis.Options{
			Addr:         fmt.Sprintf("%s:%s", slaveAddr["ip"], slaveAddr["port"]),
			Password:     r.Password,
			DB:           0,
			MaxRetries:   3,
			PoolSize:     20,
			MinIdleConns: 5,
			DialTimeout:  5 * time.Second,
			ReadTimeout:  3 * time.Second,
			WriteTimeout: 3 * time.Second,
		})
	}

	// 测试连接
	r.testConnections(ctx)
}

// testConnections 测试连接
func (r *RedisSentinelConfig) testConnections(ctx context.Context) {
	// 测试主节点
	if r.MasterClient != nil {
		_, err := r.MasterClient.Ping(ctx).Result()
		if err != nil {
			log.Printf("主节点连接测试失败: %v", err)
		} else {
			log.Println("主节点连接测试成功")
		}
	}

	// 测试从节点
	if r.SlaveClient != nil {
		_, err := r.SlaveClient.Ping(ctx).Result()
		if err != nil {
			log.Printf("从节点连接测试失败: %v", err)
		} else {
			log.Println("从节点连接测试成功")
		}
	}
}

// Set 写操作（使用主节点）
func (r *RedisSentinelConfig) Set(ctx context.Context, key, value string, expiration time.Duration) error {
	if r.MasterClient == nil {
		return fmt.Errorf("主节点客户端未初始化")
	}

	if expiration > 0 {
		return r.MasterClient.SetEX(ctx, key, value, expiration).Err()
	}
	return r.MasterClient.Set(ctx, key, value, 0).Err()
}

// Get 读操作（使用从节点）
func (r *RedisSentinelConfig) Get(ctx context.Context, key string) (string, error) {
	if r.SlaveClient == nil {
		return "", fmt.Errorf("从节点客户端未初始化")
	}

	return r.SlaveClient.Get(ctx, key).Result()
}

// Del 删除操作（使用主节点）
func (r *RedisSentinelConfig) Del(ctx context.Context, keys ...string) (int64, error) {
	if r.MasterClient == nil {
		return 0, fmt.Errorf("主节点客户端未初始化")
	}

	return r.MasterClient.Del(ctx, keys...).Result()
}

// Exists 检查键是否存在（使用从节点）
func (r *RedisSentinelConfig) Exists(ctx context.Context, keys ...string) (int64, error) {
	if r.SlaveClient == nil {
		return 0, fmt.Errorf("从节点客户端未初始化")
	}

	return r.SlaveClient.Exists(ctx, keys...).Result()
}

// HSet 哈希设置（使用主节点）
func (r *RedisSentinelConfig) HSet(ctx context.Context, key string, values ...interface{}) (int64, error) {
	if r.MasterClient == nil {
		return 0, fmt.Errorf("主节点客户端未初始化")
	}

	return r.MasterClient.HSet(ctx, key, values...).Result()
}

// HGet 哈希获取（使用从节点）
func (r *RedisSentinelConfig) HGet(ctx context.Context, key, field string) (string, error) {
	if r.SlaveClient == nil {
		return "", fmt.Errorf("从节点客户端未初始化")
	}

	return r.SlaveClient.HGet(ctx, key, field).Result()
}

// HGetAll 获取所有哈希字段（使用从节点）
func (r *RedisSentinelConfig) HGetAll(ctx context.Context, key string) (map[string]string, error) {
	if r.SlaveClient == nil {
		return nil, fmt.Errorf("从节点客户端未初始化")
	}

	return r.SlaveClient.HGetAll(ctx, key).Result()
}

// LPush 列表左推（使用主节点）
func (r *RedisSentinelConfig) LPush(ctx context.Context, key string, values ...interface{}) (int64, error) {
	if r.MasterClient == nil {
		return 0, fmt.Errorf("主节点客户端未初始化")
	}

	return r.MasterClient.LPush(ctx, key, values...).Result()
}

// RPop 列表右弹（使用主节点）
func (r *RedisSentinelConfig) RPop(ctx context.Context, key string) (string, error) {
	if r.MasterClient == nil {
		return "", fmt.Errorf("主节点客户端未初始化")
	}

	return r.MasterClient.RPop(ctx, key).Result()
}

// LRange 获取列表范围（使用从节点）
func (r *RedisSentinelConfig) LRange(ctx context.Context, key string, start, stop int64) ([]string, error) {
	if r.SlaveClient == nil {
		return nil, fmt.Errorf("从节点客户端未初始化")
	}

	return r.SlaveClient.LRange(ctx, key, start, stop).Result()
}

// SAdd 集合添加（使用主节点）
func (r *RedisSentinelConfig) SAdd(ctx context.Context, key string, members ...interface{}) (int64, error) {
	if r.MasterClient == nil {
		return 0, fmt.Errorf("主节点客户端未初始化")
	}

	return r.MasterClient.SAdd(ctx, key, members...).Result()
}

// SMembers 获取集合所有成员（使用从节点）
func (r *RedisSentinelConfig) SMembers(ctx context.Context, key string) ([]string, error) {
	if r.SlaveClient == nil {
		return nil, fmt.Errorf("从节点客户端未初始化")
	}

	return r.SlaveClient.SMembers(ctx, key).Result()
}

// ZAdd 有序集合添加（使用主节点）
func (r *RedisSentinelConfig) ZAdd(ctx context.Context, key string, members ...*redis.Z) (int64, error) {
	if r.MasterClient == nil {
		return 0, fmt.Errorf("主节点客户端未初始化")
	}

	return r.MasterClient.ZAdd(ctx, key, members...).Result()
}

// ZRange 有序集合范围查询（使用从节点）
func (r *RedisSentinelConfig) ZRange(ctx context.Context, key string, start, stop int64) ([]string, error) {
	if r.SlaveClient == nil {
		return nil, fmt.Errorf("从节点客户端未初始化")
	}

	return r.SlaveClient.ZRange(ctx, key, start, stop).Result()
}

// GetMasterAddr 获取主节点地址
func (r *RedisSentinelConfig) GetMasterAddr(ctx context.Context) ([]string, error) {
	return r.SentinelClient.GetMasterAddrByName(ctx, r.MasterName).Result()
}

// GetSlaveAddrs 获取从节点地址列表
func (r *RedisSentinelConfig) GetSlaveAddrs(ctx context.Context) ([]map[string]string, error) {
	return r.SentinelClient.Slaves(ctx, r.MasterName).Result()
}

// GetSentinelInfo 获取哨兵信息
func (r *RedisSentinelConfig) GetSentinelInfo(ctx context.Context) (map[string]interface{}, error) {
	info := make(map[string]interface{})
	
	// 获取主节点信息
	masterInfo, err := r.SentinelClient.Masters(ctx).Result()
	if err != nil {
		return nil, err
	}
	info["masters"] = masterInfo

	// 获取哨兵信息
	sentinels, err := r.SentinelClient.Sentinels(ctx, r.MasterName).Result()
	if err != nil {
		return nil, err
	}
	info["sentinels"] = sentinels

	return info, nil
}

// Close 关闭所有连接
func (r *RedisSentinelConfig) Close() error {
	var err error

	if r.SentinelClient != nil {
		if e := r.SentinelClient.Close(); e != nil {
			err = e
		}
	}

	if r.MasterClient != nil {
		if e := r.MasterClient.Close(); e != nil {
			err = e
		}
	}

	if r.SlaveClient != nil {
		if e := r.SlaveClient.Close(); e != nil {
			err = e
		}
	}

	return err
}

// 全局配置实例
var RedisConfig *RedisSentinelConfig

// 初始化函数
func init() {
	RedisConfig = NewRedisSentinelConfig()
}

// 便捷函数
func Set(ctx context.Context, key, value string, expiration time.Duration) error {
	return RedisConfig.Set(ctx, key, value, expiration)
}

func Get(ctx context.Context, key string) (string, error) {
	return RedisConfig.Get(ctx, key)
}

func Del(ctx context.Context, keys ...string) (int64, error) {
	return RedisConfig.Del(ctx, keys...)
}

func Exists(ctx context.Context, keys ...string) (int64, error) {
	return RedisConfig.Exists(ctx, keys...)
}
