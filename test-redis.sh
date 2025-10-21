#!/bin/bash

echo "=== Redis 诊断脚本 ==="

echo "1. 检查 Docker 是否运行..."
docker --version || echo "❌ Docker 未安装或未运行"

echo ""
echo "2. 检查 Docker Compose..."
docker-compose --version || echo "❌ Docker Compose 未安装"

echo ""
echo "3. 检查网络..."
docker network ls | grep backend || echo "❌ backend 网络不存在"

echo ""
echo "4. 启动 Redis 主节点..."
docker-compose up -d redis-master

echo ""
echo "5. 等待 5 秒..."
sleep 5

echo ""
echo "6. 检查容器状态..."
docker ps | grep redis-master

echo ""
echo "7. 检查容器日志..."
docker logs redis-master --tail 20

echo ""
echo "8. 测试 Redis 连接..."
docker exec redis-master redis-cli ping 2>&1 || echo "❌ 无密码连接失败"
docker exec redis-master redis-cli -a CG1rMeyRryFgvElf8n ping 2>&1 || echo "❌ 有密码连接失败"

echo ""
echo "9. 检查 Redis 配置..."
docker exec redis-master cat /etc/redis/redis.conf | grep -E "(bind|port|requirepass)" | head -5

echo ""
echo "10. 检查端口监听..."
docker exec redis-master netstat -tlnp | grep 6379 || echo "❌ Redis 未监听 6379 端口"

echo ""
echo "=== 诊断完成 ==="
