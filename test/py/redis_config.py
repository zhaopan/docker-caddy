#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Redis 哨兵模式连接配置
适用于 Web 应用程序
"""

import redis
from redis.sentinel import Sentinel
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RedisSentinelConfig:
    """Redis 哨兵配置类"""
    
    def __init__(self):
        # 哨兵节点配置
        self.SENTINELS = [
            ('localhost', 26379),
            ('localhost', 26380),
            ('localhost', 26381)
        ]
        
        # Redis 密码
        self.PASSWORD = 'CG1rMeyRryFgvElf8n'
        
        # 主节点名称
        self.MASTER_NAME = 'redis-master'
        
        # 连接超时设置
        self.SOCKET_TIMEOUT = 5
        self.SOCKET_CONNECT_TIMEOUT = 5
        
        # 重试设置
        self.MAX_RETRIES = 3
        self.RETRY_DELAY = 0.1
        
        # 初始化哨兵连接
        self._init_sentinel()
    
    def _init_sentinel(self):
        """初始化哨兵连接"""
        try:
            self.sentinel = Sentinel(
                self.SENTINELS,
                password=self.PASSWORD,
                socket_timeout=self.SOCKET_TIMEOUT,
                socket_connect_timeout=self.SOCKET_CONNECT_TIMEOUT
            )
            logger.info("哨兵连接初始化成功")
        except Exception as e:
            logger.error(f"哨兵连接初始化失败: {e}")
            raise
    
    def get_master_connection(self):
        """获取主节点连接（用于写操作）"""
        try:
            master = self.sentinel.master_for(
                self.MASTER_NAME,
                password=self.PASSWORD,
                socket_timeout=self.SOCKET_TIMEOUT,
                socket_connect_timeout=self.SOCKET_CONNECT_TIMEOUT,
                retry_on_timeout=True,
                max_connections=20
            )
            logger.info("主节点连接获取成功")
            return master
        except Exception as e:
            logger.error(f"主节点连接获取失败: {e}")
            raise
    
    def get_slave_connection(self):
        """获取从节点连接（用于读操作）"""
        try:
            slave = self.sentinel.slave_for(
                self.MASTER_NAME,
                password=self.PASSWORD,
                socket_timeout=self.SOCKET_TIMEOUT,
                socket_connect_timeout=self.SOCKET_CONNECT_TIMEOUT,
                retry_on_timeout=True,
                max_connections=20
            )
            logger.info("从节点连接获取成功")
            return slave
        except Exception as e:
            logger.error(f"从节点连接获取失败: {e}")
            raise
    
    def get_connection_info(self):
        """获取连接信息"""
        try:
            master_info = self.sentinel.discover_master(self.MASTER_NAME)
            slaves_info = self.sentinel.discover_slaves(self.MASTER_NAME)
            
            return {
                'master': master_info,
                'slaves': slaves_info,
                'sentinels': self.SENTINELS
            }
        except Exception as e:
            logger.error(f"获取连接信息失败: {e}")
            return None

# 全局配置实例
redis_config = RedisSentinelConfig()

# 便捷函数
def get_redis_master():
    """获取 Redis 主节点连接"""
    return redis_config.get_master_connection()

def get_redis_slave():
    """获取 Redis 从节点连接"""
    return redis_config.get_slave_connection()

def get_redis_info():
    """获取 Redis 连接信息"""
    return redis_config.get_connection_info()

# 使用示例
if __name__ == "__main__":
    try:
        # 获取连接
        master = get_redis_master()
        slave = get_redis_slave()
        
        # 测试写操作
        master.set('test_key', 'Hello Redis Sentinel!')
        print("写操作成功")
        
        # 测试读操作
        value = slave.get('test_key')
        print(f"读操作成功: {value}")
        
        # 显示连接信息
        info = get_redis_info()
        print(f"连接信息: {info}")
        
    except Exception as e:
        print(f"Redis 连接测试失败: {e}")
