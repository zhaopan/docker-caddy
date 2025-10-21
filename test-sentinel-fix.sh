#!/bin/bash

echo "=== 测试哨兵修复 ==="

echo "1. 停止哨兵节点..."
docker-compose stop redis-sentinel1

echo "2. 删除哨兵节点..."
docker-compose rm -f redis-sentinel1

echo "3. 启动哨兵节点..."
docker-compose up -d redis-sentinel1

echo "4. 等待 10 秒..."
sleep 10

echo "5. 检查状态..."
docker ps | grep sentinel1

echo "6. 检查日志..."
docker logs redis-sentinel1 --tail 10

echo "7. 测试连接..."
docker exec redis-sentinel1 redis-cli -p 26379 ping

echo "8. 检查哨兵监控..."
docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL masters

echo "=== 测试完成 ==="
