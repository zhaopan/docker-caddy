#!/bin/bash

echo "=== 简单 Redis 测试 ==="

echo "1. 停止现有容器..."
docker-compose down redis-master

echo "2. 直接运行 Redis 容器测试..."
docker run --rm -d \
  --name test-redis \
  -p 6379:6379 \
  -v $(pwd)/redis/redis5.conf:/etc/redis/redis.conf \
  redis:5 redis-server /etc/redis/redis.conf

echo "3. 等待 5 秒..."
sleep 5

echo "4. 检查容器状态..."
docker ps | grep test-redis

echo "5. 检查日志..."
docker logs test-redis --tail 5

echo "6. 测试连接..."
docker exec test-redis redis-cli ping
docker exec test-redis redis-cli -a CG1rMeyRryFgvElf8n ping

echo "7. 清理测试容器..."
docker stop test-redis

echo "=== 测试完成 ==="
