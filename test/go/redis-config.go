package main

import (
	"context"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

// RedisSentinelConfig Redis 哨兵配置结构体
type RedisSentinelConfig struct {
	MasterClient *redis.Client
	SlaveClient  *redis.Client
	SentinelClient *redis.Client
}

// RedisConfig 全局 Redis 配置实例
var RedisConfig *RedisSentinelConfig

// 初始化 Redis 哨兵配置
func init() {
	// Redis 哨兵配置 - 使用 localhost 端口映射用于本地测试
	sentinelAddrs := []string{
		"localhost:26379", // sentinel1
		"localhost:26380", // sentinel2
		"localhost:26381", // sentinel3
	}

	masterName := "redis-master"
	password := "CG1rMeyRryFgvElf8n"

	// 创建哨兵客户端
	sentinelClient := redis.NewFailoverClient(&redis.FailoverOptions{
		MasterName:    masterName,
		SentinelAddrs: sentinelAddrs,
		Password:      password,
		DB:            0,
		DialTimeout:   5 * time.Second,
		ReadTimeout:   3 * time.Second,
		WriteTimeout:  3 * time.Second,
		PoolTimeout:   4 * time.Second,
		IdleTimeout:   5 * time.Minute,
		MaxRetries:    3,
		MinRetryBackoff: 8 * time.Millisecond,
		MaxRetryBackoff: 512 * time.Millisecond,
	})

	// 创建主节点客户端
	masterClient := redis.NewClient(&redis.Options{
		Addr:         "localhost:6379", // 主节点地址
		Password:     password,
		DB:           0,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolTimeout:  4 * time.Second,
		IdleTimeout:  5 * time.Minute,
		MaxRetries:   3,
		MinRetryBackoff: 8 * time.Millisecond,
		MaxRetryBackoff: 512 * time.Millisecond,
	})

	// 创建从节点客户端
	slaveClient := redis.NewClient(&redis.Options{
		Addr:         "localhost:6380", // 从节点地址
		Password:     password,
		DB:           0,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolTimeout:  4 * time.Second,
		IdleTimeout:  5 * time.Minute,
		MaxRetries:   3,
		MinRetryBackoff: 8 * time.Millisecond,
		MaxRetryBackoff: 512 * time.Millisecond,
	})

	RedisConfig = &RedisSentinelConfig{
		MasterClient:   masterClient,
		SlaveClient:    slaveClient,
		SentinelClient: sentinelClient,
	}

	// 测试连接
	ctx := context.Background()
	if err := RedisConfig.MasterClient.Ping(ctx).Err(); err != nil {
		log.Printf("主节点连接失败: %v", err)
	}

	if err := RedisConfig.SlaveClient.Ping(ctx).Err(); err != nil {
		log.Printf("从节点连接失败: %v", err)
	}

	if err := RedisConfig.SentinelClient.Ping(ctx).Err(); err != nil {
		log.Printf("哨兵连接失败: %v", err)
	}
}

// Set 设置键值对
func (r *RedisSentinelConfig) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return r.MasterClient.Set(ctx, key, value, expiration).Err()
}

// Get 获取键值
func (r *RedisSentinelConfig) Get(ctx context.Context, key string) (string, error) {
	return r.SlaveClient.Get(ctx, key).Result()
}

// Del 删除键
func (r *RedisSentinelConfig) Del(ctx context.Context, keys ...string) (int64, error) {
	return r.MasterClient.Del(ctx, keys...).Result()
}

// Exists 检查键是否存在
func (r *RedisSentinelConfig) Exists(ctx context.Context, keys ...string) (int64, error) {
	return r.SlaveClient.Exists(ctx, keys...).Result()
}

// HSet 设置哈希字段
func (r *RedisSentinelConfig) HSet(ctx context.Context, key string, values ...interface{}) (int64, error) {
	return r.MasterClient.HSet(ctx, key, values...).Result()
}

// HGetAll 获取所有哈希字段
func (r *RedisSentinelConfig) HGetAll(ctx context.Context, key string) (map[string]string, error) {
	return r.SlaveClient.HGetAll(ctx, key).Result()
}

// LPush 向列表左侧推入元素
func (r *RedisSentinelConfig) LPush(ctx context.Context, key string, values ...interface{}) (int64, error) {
	return r.MasterClient.LPush(ctx, key, values...).Result()
}

// LRange 获取列表范围内的元素
func (r *RedisSentinelConfig) LRange(ctx context.Context, key string, start, stop int64) ([]string, error) {
	return r.SlaveClient.LRange(ctx, key, start, stop).Result()
}

// RPop 从列表右侧弹出元素
func (r *RedisSentinelConfig) RPop(ctx context.Context, key string) (string, error) {
	return r.MasterClient.RPop(ctx, key).Result()
}

// SAdd 向集合添加成员
func (r *RedisSentinelConfig) SAdd(ctx context.Context, key string, members ...interface{}) (int64, error) {
	return r.MasterClient.SAdd(ctx, key, members...).Result()
}

// SMembers 获取集合所有成员
func (r *RedisSentinelConfig) SMembers(ctx context.Context, key string) ([]string, error) {
	return r.SlaveClient.SMembers(ctx, key).Result()
}

// GetMasterAddr 获取主节点地址
func (r *RedisSentinelConfig) GetMasterAddr(ctx context.Context) (string, error) {
	// 简化实现，直接返回配置的主节点地址
	return "localhost:6379", nil
}

// GetSlaveAddrs 获取从节点地址列表
func (r *RedisSentinelConfig) GetSlaveAddrs(ctx context.Context) ([]string, error) {
	// 简化实现，直接返回配置的从节点地址
	return []string{"localhost:6380", "localhost:6381"}, nil
}

// GetSentinelInfo 获取哨兵信息
func (r *RedisSentinelConfig) GetSentinelInfo(ctx context.Context) (map[string]interface{}, error) {
	// 简化实现，返回模拟的哨兵信息
	return map[string]interface{}{
		"masters": []map[string]interface{}{
			{
				"name": "mymaster",
				"ip":   "localhost",
				"port": "6379",
			},
		},
		"slaves": []map[string]interface{}{
			{
				"ip":   "localhost",
				"port": "6380",
			},
			{
				"ip":   "localhost",
				"port": "6381",
			},
		},
		"sentinels": []map[string]interface{}{
			{
				"ip":   "localhost",
				"port": "26379",
			},
			{
				"ip":   "localhost",
				"port": "26380",
			},
			{
				"ip":   "localhost",
				"port": "26381",
			},
		},
	}, nil
}

// Close 关闭所有连接
func (r *RedisSentinelConfig) Close() error {
	var err error
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
	if r.SentinelClient != nil {
		if e := r.SentinelClient.Close(); e != nil {
			err = e
		}
	}
	return err
}
