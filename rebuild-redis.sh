#!/bin/bash

echo "=== 重建 Redis 容器 ==="

echo "1. 停止所有 Redis 容器..."
docker-compose stop redis-master redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3

echo "2. 删除 Redis 容器..."
docker-compose rm -f redis-master redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3

echo "3. 删除 Redis 镜像..."
docker rmi zhaopan/redis:5 2>/dev/null || echo "镜像不存在，跳过删除"

echo "4. 重新构建 Redis 镜像..."
docker-compose build --no-cache redis-master

echo "5. 启动 Redis 主节点..."
docker-compose up -d redis-master

echo "6. 等待 10 秒..."
sleep 10

echo "7. 检查容器状态..."
docker ps | grep redis-master

echo "8. 检查容器日志..."
docker logs redis-master --tail 10

echo "9. 测试连接..."
docker exec redis-master redis-cli -a CG1rMeyRryFgvElf8n ping

echo "=== 重建完成 ==="
