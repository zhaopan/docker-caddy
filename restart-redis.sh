#!/bin/bash

echo "=== 重启 Redis 容器 ==="

echo "1. 停止 Redis 主节点..."
docker-compose stop redis-master

echo "2. 删除 Redis 主节点容器..."
docker-compose rm -f redis-master

echo "3. 重新启动 Redis 主节点..."
docker-compose up -d redis-master

echo "4. 等待 10 秒..."
sleep 10

echo "5. 检查容器状态..."
docker ps | grep redis-master

echo "6. 检查配置文件..."
docker exec redis-master cat /etc/redis/redis.conf | grep -E "(bind|requirepass)" | head -5

echo "7. 测试连接..."
docker exec redis-master redis-cli -a CG1rMeyRryFgvElf8n ping

echo "8. 检查端口监听..."
docker exec redis-master netstat -tlnp | grep 6379

echo "=== 重启完成 ==="
