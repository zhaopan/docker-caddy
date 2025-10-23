package main

import (
	"context"
	"log"
)

func main() {
	ctx := context.Background()

	log.Println("=== Redis 哨兵模式测试 ===")

	// 测试基本连接
	log.Println("1. 测试基本连接...")
	if err := RedisConfig.MasterClient.Ping(ctx).Err(); err != nil {
		log.Printf("主节点连接失败: %v", err)
	} else {
		log.Println("✓ 主节点连接成功")
	}

	if err := RedisConfig.SlaveClient.Ping(ctx).Err(); err != nil {
		log.Printf("从节点连接失败: %v", err)
	} else {
		log.Println("✓ 从节点连接成功")
	}

	if err := RedisConfig.SentinelClient.Ping(ctx).Err(); err != nil {
		log.Printf("哨兵连接失败: %v", err)
	} else {
		log.Println("✓ 哨兵连接成功")
	}

	// 测试基本键值操作
	log.Println("\n2. 测试基本键值操作...")
	testKey := "test:key"
	testValue := "Hello Redis Sentinel!"

	// 设置键值
	err := RedisConfig.Set(ctx, testKey, testValue, 0)
	if err != nil {
		log.Printf("设置键值失败: %v", err)
	} else {
		log.Println("✓ 设置键值成功")
	}

	// 获取键值
	value, err := RedisConfig.Get(ctx, testKey)
	if err != nil {
		log.Printf("获取键值失败: %v", err)
	} else {
		log.Printf("✓ 获取键值成功: %s", value)
	}

	// 检查键是否存在
	count, err := RedisConfig.Exists(ctx, testKey)
	if err != nil {
		log.Printf("检查键存在失败: %v", err)
	} else {
		log.Printf("✓ 键存在检查成功: %d", count)
	}

	// 测试哈希操作
	log.Println("\n3. 测试哈希操作...")
	userKey := "user:1"
	_, err = RedisConfig.HSet(ctx, userKey, "id", 1, "name", "张三", "age", 25)
	if err != nil {
		log.Printf("设置哈希失败: %v", err)
	} else {
		log.Println("✓ 设置哈希成功")
	}

	userData, err := RedisConfig.HGetAll(ctx, userKey)
	if err != nil {
		log.Printf("获取哈希失败: %v", err)
	} else {
		log.Printf("✓ 获取哈希成功: %v", userData)
	}

	// 测试列表操作
	log.Println("\n4. 测试列表操作...")
	listKey := "test:list"
	items := []string{"item1", "item2", "item3"}

	for _, item := range items {
		_, err := RedisConfig.LPush(ctx, listKey, item)
		if err != nil {
			log.Printf("添加列表项失败: %v", err)
		}
	}
	log.Println("✓ 添加列表项成功")

	listItems, err := RedisConfig.LRange(ctx, listKey, 0, -1)
	if err != nil {
		log.Printf("获取列表失败: %v", err)
	} else {
		log.Printf("✓ 获取列表成功: %v", listItems)
	}

	// 测试集合操作
	log.Println("\n5. 测试集合操作...")
	setKey := "test:set"
	members := []string{"member1", "member2", "member3"}

	for _, member := range members {
		_, err := RedisConfig.SAdd(ctx, setKey, member)
		if err != nil {
			log.Printf("添加集合成员失败: %v", err)
		}
	}
	log.Println("✓ 添加集合成员成功")

	setMembers, err := RedisConfig.SMembers(ctx, setKey)
	if err != nil {
		log.Printf("获取集合成员失败: %v", err)
	} else {
		log.Printf("✓ 获取集合成员成功: %v", setMembers)
	}

	// 测试哨兵信息
	log.Println("\n6. 测试哨兵信息...")
	masterAddr, err := RedisConfig.GetMasterAddr(ctx)
	if err != nil {
		log.Printf("获取主节点地址失败: %v", err)
	} else {
		log.Printf("✓ 主节点地址: %s", masterAddr)
	}

	slaveAddrs, err := RedisConfig.GetSlaveAddrs(ctx)
	if err != nil {
		log.Printf("获取从节点地址失败: %v", err)
	} else {
		log.Printf("✓ 从节点地址: %v", slaveAddrs)
	}

	sentinelInfo, err := RedisConfig.GetSentinelInfo(ctx)
	if err != nil {
		log.Printf("获取哨兵信息失败: %v", err)
	} else {
		log.Printf("✓ 哨兵信息获取成功")
		log.Printf("  主节点数量: %d", len(sentinelInfo["masters"].([]map[string]interface{})))
		log.Printf("  从节点数量: %d", len(sentinelInfo["slaves"].([]map[string]interface{})))
		log.Printf("  哨兵数量: %d", len(sentinelInfo["sentinels"].([]map[string]interface{})))
	}

	// 清理测试数据
	log.Println("\n7. 清理测试数据...")
	keys := []string{testKey, userKey, listKey, setKey}
	deletedCount, err := RedisConfig.Del(ctx, keys...)
	if err != nil {
		log.Printf("清理数据失败: %v", err)
	} else {
		log.Printf("✓ 清理数据成功，删除了 %d 个键", deletedCount)
	}

	log.Println("\n=== 测试完成 ===")
}
