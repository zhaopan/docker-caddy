#!/bin/bash

echo "=== 测试单机模式 Redis ==="

echo "1. 停止单机模式 Redis..."
docker-compose -f docker-compose.single.yml stop redis

echo "2. 删除单机模式 Redis 容器..."
docker-compose -f docker-compose.single.yml rm -f redis

echo "3. 启动单机模式 Redis..."
docker-compose -f docker-compose.single.yml up -d redis

echo "4. 等待 10 秒..."
sleep 10

echo "5. 检查容器状态..."
docker ps | grep redis

echo "6. 检查配置文件..."
docker exec redis cat /etc/redis/redis.conf | grep -E "(bind|requirepass)" | head -5

echo "7. 测试连接..."
docker exec redis redis-cli -a CG1rMeyRryFgvElf8n ping

echo "8. 检查端口监听..."
docker exec redis netstat -tlnp | grep 6379

echo "=== 单机模式测试完成 ==="
