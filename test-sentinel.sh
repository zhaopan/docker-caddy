#!/bin/bash

echo "=== 测试 Redis 哨兵节点 ==="

echo "1. 停止所有哨兵节点..."
docker-compose stop redis-sentinel1 redis-sentinel2 redis-sentinel3

echo "2. 删除哨兵节点容器..."
docker-compose rm -f redis-sentinel1 redis-sentinel2 redis-sentinel3

echo "3. 启动哨兵节点1..."
docker-compose up -d redis-sentinel1

echo "4. 等待 5 秒..."
sleep 5

echo "5. 检查哨兵节点1状态..."
docker ps | grep sentinel1

echo "6. 检查哨兵节点1日志..."
docker logs redis-sentinel1 --tail 10

echo "7. 测试哨兵连接..."
docker exec redis-sentinel1 redis-cli -p 26379 ping

echo "8. 检查哨兵监控状态..."
docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL masters

echo "9. 启动其他哨兵节点..."
docker-compose up -d redis-sentinel2 redis-sentinel3

echo "10. 等待 5 秒..."
sleep 5

echo "11. 检查所有哨兵节点状态..."
docker ps | grep sentinel

echo "12. 检查哨兵集群状态..."
docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels redis-master

echo "=== 哨兵节点测试完成 ==="
