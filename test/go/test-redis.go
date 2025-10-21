package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

func main() {
	ctx := context.Background()

	fmt.Println("=== Redis 哨兵模式测试 ===")

	// 测试基本操作
	fmt.Println("\n1. 测试基本键值操作")
	
	// 设置键值对
	err := Set(ctx, "test_key", "Hello Redis Sentinel!", 0)
	if err != nil {
		log.Printf("设置键值对失败: %v", err)
	} else {
		fmt.Println("✓ 设置键值对成功")
	}

	// 获取键值对
	value, err := Get(ctx, "test_key")
	if err != nil {
		log.Printf("获取键值对失败: %v", err)
	} else {
		fmt.Printf("✓ 获取键值对成功: %s\n", value)
	}

	// 测试过期时间
	fmt.Println("\n2. 测试过期时间")
	err = Set(ctx, "temp_key", "This will expire", 5*time.Second)
	if err != nil {
		log.Printf("设置带过期时间的键失败: %v", err)
	} else {
		fmt.Println("✓ 设置带过期时间的键成功")
	}

	// 立即检查
	value, err = Get(ctx, "temp_key")
	if err != nil {
		log.Printf("获取临时键失败: %v", err)
	} else {
		fmt.Printf("✓ 获取临时键成功: %s\n", value)
	}

	// 等待过期
	fmt.Println("等待 6 秒后检查过期...")
	time.Sleep(6 * time.Second)
	value, err = Get(ctx, "temp_key")
	if err != nil {
		fmt.Println("✓ 键已过期（预期结果）")
	} else {
		fmt.Printf("✗ 键未过期: %s\n", value)
	}

	// 测试哈希操作
	fmt.Println("\n3. 测试哈希操作")
	
	// 设置用户信息
	err = RedisConfig.HSet(ctx, "user:1", "name", "张三", "age", "25", "email", "zhangsan@example.com")
	if err != nil {
		log.Printf("设置用户信息失败: %v", err)
	} else {
		fmt.Println("✓ 设置用户信息成功")
	}

	// 获取用户姓名
	name, err := RedisConfig.HGet(ctx, "user:1", "name")
	if err != nil {
		log.Printf("获取用户姓名失败: %v", err)
	} else {
		fmt.Printf("✓ 获取用户姓名成功: %s\n", name)
	}

	// 获取所有用户信息
	userData, err := RedisConfig.HGetAll(ctx, "user:1")
	if err != nil {
		log.Printf("获取所有用户信息失败: %v", err)
	} else {
		fmt.Printf("✓ 获取所有用户信息成功: %v\n", userData)
	}

	// 测试列表操作
	fmt.Println("\n4. 测试列表操作")
	
	// 添加列表项
	err = RedisConfig.LPush(ctx, "tasks", "任务1", "任务2", "任务3")
	if err != nil {
		log.Printf("添加列表项失败: %v", err)
	} else {
		fmt.Println("✓ 添加列表项成功")
	}

	// 获取列表
	tasks, err := RedisConfig.LRange(ctx, "tasks", 0, -1)
	if err != nil {
		log.Printf("获取列表失败: %v", err)
	} else {
		fmt.Printf("✓ 获取列表成功: %v\n", tasks)
	}

	// 弹出列表项
	task, err := RedisConfig.RPop(ctx, "tasks")
	if err != nil {
		log.Printf("弹出列表项失败: %v", err)
	} else {
		fmt.Printf("✓ 弹出列表项成功: %s\n", task)
	}

	// 测试集合操作
	fmt.Println("\n5. 测试集合操作")
	
	// 添加集合成员
	err = RedisConfig.SAdd(ctx, "tags", "golang", "redis", "sentinel", "docker")
	if err != nil {
		log.Printf("添加集合成员失败: %v", err)
	} else {
		fmt.Println("✓ 添加集合成员成功")
	}

	// 获取集合成员
	tags, err := RedisConfig.SMembers(ctx, "tags")
	if err != nil {
		log.Printf("获取集合成员失败: %v", err)
	} else {
		fmt.Printf("✓ 获取集合成员成功: %v\n", tags)
	}

	// 测试有序集合操作
	fmt.Println("\n6. 测试有序集合操作")
	
	// 添加有序集合成员
	err = RedisConfig.ZAdd(ctx, "scores", 
		&redis.Z{Score: 95, Member: "Alice"},
		&redis.Z{Score: 87, Member: "Bob"},
		&redis.Z{Score: 92, Member: "Charlie"},
	)
	if err != nil {
		log.Printf("添加有序集合成员失败: %v", err)
	} else {
		fmt.Println("✓ 添加有序集合成员成功")
	}

	// 获取有序集合成员
	scores, err := RedisConfig.ZRange(ctx, "scores", 0, -1)
	if err != nil {
		log.Printf("获取有序集合成员失败: %v", err)
	} else {
		fmt.Printf("✓ 获取有序集合成员成功: %v\n", scores)
	}

	// 测试连接信息
	fmt.Println("\n7. 测试连接信息")
	
	// 获取主节点地址
	masterAddr, err := RedisConfig.GetMasterAddr(ctx)
	if err != nil {
		log.Printf("获取主节点地址失败: %v", err)
	} else {
		fmt.Printf("✓ 主节点地址: %v\n", masterAddr)
	}

	// 获取从节点地址
	slaveAddrs, err := RedisConfig.GetSlaveAddrs(ctx)
	if err != nil {
		log.Printf("获取从节点地址失败: %v", err)
	} else {
		fmt.Printf("✓ 从节点地址: %v\n", slaveAddrs)
	}

	// 获取哨兵信息
	sentinelInfo, err := RedisConfig.GetSentinelInfo(ctx)
	if err != nil {
		log.Printf("获取哨兵信息失败: %v", err)
	} else {
		fmt.Printf("✓ 哨兵信息: %v\n", sentinelInfo)
	}

	// 测试键存在性
	fmt.Println("\n8. 测试键存在性")
	
	// 检查存在的键
	exists, err := Exists(ctx, "test_key")
	if err != nil {
		log.Printf("检查键存在性失败: %v", err)
	} else {
		fmt.Printf("✓ 键 'test_key' 存在: %d\n", exists)
	}

	// 检查不存在的键
	exists, err = Exists(ctx, "non_existent_key")
	if err != nil {
		log.Printf("检查键存在性失败: %v", err)
	} else {
		fmt.Printf("✓ 键 'non_existent_key' 存在: %d\n", exists)
	}

	// 清理测试数据
	fmt.Println("\n9. 清理测试数据")
	
	keys := []string{"test_key", "user:1", "tasks", "tags", "scores"}
	count, err := Del(ctx, keys...)
	if err != nil {
		log.Printf("清理测试数据失败: %v", err)
	} else {
		fmt.Printf("✓ 清理测试数据成功，删除了 %d 个键\n", count)
	}

	fmt.Println("\n=== 测试完成 ===")
}
