#!/bin/bash

echo "=== 修复 Redis 配置 ==="

echo "1. 停止所有 Redis 相关容器..."
docker-compose down redis-master redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3

echo "2. 删除 Redis 镜像..."
docker rmi zhaopan/redis:5 2>/dev/null || echo "镜像不存在"

echo "3. 清理构建缓存..."
docker builder prune -f

echo "4. 重新构建 Redis 镜像..."
docker-compose build --no-cache redis-master

echo "5. 启动 Redis 主节点..."
docker-compose up -d redis-master

echo "6. 等待 10 秒..."
sleep 10

echo "7. 检查配置文件..."
docker exec redis-master cat /etc/redis/redis.conf | grep -E "(bind|requirepass)" | head -5

echo "8. 测试连接..."
docker exec redis-master redis-cli -a CG1rMeyRryFgvElf8n ping

echo "9. 检查端口监听..."
docker exec redis-master netstat -tlnp | grep 6379

echo "=== 修复完成 ==="
