#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Redis 哨兵模式测试脚本
"""

import time
import json
from redis_config import get_redis_master, get_redis_slave, get_redis_info

def test_basic_operations():
    """测试基本操作"""
    print("=== 1. 测试基本键值操作 ===")
    
    try:
        master = get_redis_master()
        slave = get_redis_slave()
        
        # 设置键值对
        master.set('test_key', 'Hello Redis Sentinel!')
        print("✓ 设置键值对成功")
        
        # 获取键值对
        value = slave.get('test_key')
        print(f"✓ 获取键值对成功: {value}")
        
        # 测试过期时间
        master.setex('temp_key', 5, 'This will expire')
        print("✓ 设置带过期时间的键成功")
        
        # 立即检查
        value = slave.get('temp_key')
        print(f"✓ 获取临时键成功: {value}")
        
        # 等待过期
        print("等待 6 秒后检查过期...")
        time.sleep(6)
        value = slave.get('temp_key')
        if value is None:
            print("✓ 键已过期（预期结果）")
        else:
            print(f"✗ 键未过期: {value}")
            
    except Exception as e:
        print(f"✗ 基本操作测试失败: {e}")

def test_hash_operations():
    """测试哈希操作"""
    print("\n=== 2. 测试哈希操作 ===")
    
    try:
        master = get_redis_master()
        slave = get_redis_slave()
        
        # 设置用户信息
        user_data = {
            'name': '张三',
            'age': '25',
            'email': 'zhangsan@example.com'
        }
        master.hset('user:1', mapping=user_data)
        print("✓ 设置用户信息成功")
        
        # 获取用户姓名
        name = slave.hget('user:1', 'name')
        print(f"✓ 获取用户姓名成功: {name}")
        
        # 获取所有用户信息
        user_info = slave.hgetall('user:1')
        print(f"✓ 获取所有用户信息成功: {user_info}")
        
    except Exception as e:
        print(f"✗ 哈希操作测试失败: {e}")

def test_list_operations():
    """测试列表操作"""
    print("\n=== 3. 测试列表操作 ===")
    
    try:
        master = get_redis_master()
        slave = get_redis_slave()
        
        # 添加列表项
        master.lpush('tasks', '任务1', '任务2', '任务3')
        print("✓ 添加列表项成功")
        
        # 获取列表
        tasks = slave.lrange('tasks', 0, -1)
        print(f"✓ 获取列表成功: {tasks}")
        
        # 弹出列表项
        task = master.rpop('tasks')
        print(f"✓ 弹出列表项成功: {task}")
        
    except Exception as e:
        print(f"✗ 列表操作测试失败: {e}")

def test_set_operations():
    """测试集合操作"""
    print("\n=== 4. 测试集合操作 ===")
    
    try:
        master = get_redis_master()
        slave = get_redis_slave()
        
        # 添加集合成员
        master.sadd('tags', 'golang', 'redis', 'sentinel', 'docker')
        print("✓ 添加集合成员成功")
        
        # 获取集合成员
        tags = slave.smembers('tags')
        print(f"✓ 获取集合成员成功: {tags}")
        
    except Exception as e:
        print(f"✗ 集合操作测试失败: {e}")

def test_sorted_set_operations():
    """测试有序集合操作"""
    print("\n=== 5. 测试有序集合操作 ===")
    
    try:
        master = get_redis_master()
        slave = get_redis_slave()
        
        # 添加有序集合成员
        scores = {
            'Alice': 95,
            'Bob': 87,
            'Charlie': 92
        }
        master.zadd('scores', scores)
        print("✓ 添加有序集合成员成功")
        
        # 获取有序集合成员
        members = slave.zrange('scores', 0, -1)
        print(f"✓ 获取有序集合成员成功: {members}")
        
    except Exception as e:
        print(f"✗ 有序集合操作测试失败: {e}")

def test_connection_info():
    """测试连接信息"""
    print("\n=== 6. 测试连接信息 ===")
    
    try:
        info = get_redis_info()
        if info:
            print(f"✓ 主节点信息: {info['master']}")
            print(f"✓ 从节点信息: {info['slaves']}")
            print(f"✓ 哨兵信息: {info['sentinels']}")
        else:
            print("✗ 获取连接信息失败")
            
    except Exception as e:
        print(f"✗ 连接信息测试失败: {e}")

def test_key_existence():
    """测试键存在性"""
    print("\n=== 7. 测试键存在性 ===")
    
    try:
        slave = get_redis_slave()
        
        # 检查存在的键
        exists = slave.exists('test_key')
        print(f"✓ 键 'test_key' 存在: {bool(exists)}")
        
        # 检查不存在的键
        exists = slave.exists('non_existent_key')
        print(f"✓ 键 'non_existent_key' 存在: {bool(exists)}")
        
    except Exception as e:
        print(f"✗ 键存在性测试失败: {e}")

def cleanup_test_data():
    """清理测试数据"""
    print("\n=== 8. 清理测试数据 ===")
    
    try:
        master = get_redis_master()
        
        # 删除测试键
        keys = ['test_key', 'user:1', 'tasks', 'tags', 'scores']
        count = master.delete(*keys)
        print(f"✓ 清理测试数据成功，删除了 {count} 个键")
        
    except Exception as e:
        print(f"✗ 清理测试数据失败: {e}")

def main():
    """主测试函数"""
    print("=== Redis 哨兵模式测试 ===")
    
    try:
        # 运行所有测试
        test_basic_operations()
        test_hash_operations()
        test_list_operations()
        test_set_operations()
        test_sorted_set_operations()
        test_connection_info()
        test_key_existence()
        cleanup_test_data()
        
        print("\n=== 测试完成 ===")
        
    except Exception as e:
        print(f"测试过程中发生错误: {e}")

if __name__ == "__main__":
    main()
