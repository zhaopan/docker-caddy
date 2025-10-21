#!/bin/bash -e

# Redis 哨兵模式管理脚本

echo "=== Redis 哨兵模式管理脚本 ==="

case "$1" in
    "start")
        echo "启动 Redis 哨兵模式..."
        echo "1. 启动主节点..."
        docker-compose up -d redis-master
        sleep 5
        
        echo "2. 启动从节点..."
        docker-compose up -d redis-slave1 redis-slave2
        sleep 5
        
        echo "3. 配置主从复制..."
        docker exec redis-master redis-cli -a CG1rMeyRryFgvElf8n SLAVEOF NO ONE
        docker exec redis-slave1 redis-cli -a CG1rMeyRryFgvElf8n SLAVEOF redis-master 6379
        docker exec redis-slave2 redis-cli -a CG1rMeyRryFgvElf8n SLAVEOF redis-master 6379
        sleep 3
        
        echo "4. 启动哨兵节点..."
        docker-compose up -d redis-sentinel1 redis-sentinel2 redis-sentinel3
        sleep 5
        
        echo "哨兵模式启动完成！"
        echo "主节点: redis-master:6379"
        echo "从节点: redis-slave1:6380, redis-slave2:6381"
        echo "哨兵节点: redis-sentinel1:26379, redis-sentinel2:26380, redis-sentinel3:26381"
        ;;
    "stop")
        echo "停止 Redis 哨兵模式..."
        docker-compose stop redis-sentinel1 redis-sentinel2 redis-sentinel3
        docker-compose stop redis-slave1 redis-slave2
        docker-compose stop redis-master
        echo "哨兵模式已停止！"
        ;;
    "restart")
        echo "重启 Redis 哨兵模式..."
        $0 stop
        sleep 3
        $0 start
        ;;
    "status")
        echo "检查哨兵模式状态..."
        echo ""
        echo "=== 容器状态 ==="
        docker-compose ps redis-master redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3
        echo ""
        echo "=== 主节点信息 ==="
        docker exec redis-master redis-cli -a CG1rMeyRryFgvElf8n INFO replication | grep -E "(role|connected_slaves|master_host|master_port)"
        echo ""
        echo "=== 从节点信息 ==="
        docker exec redis-slave1 redis-cli -a CG1rMeyRryFgvElf8n INFO replication | grep -E "(role|master_host|master_port|master_link_status)"
        docker exec redis-slave2 redis-cli -a CG1rMeyRryFgvElf8n INFO replication | grep -E "(role|master_host|master_port|master_link_status)"
        echo ""
        echo "=== 哨兵信息 ==="
        docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL masters
        echo ""
        echo "=== 哨兵监控状态 ==="
        docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels redis-master
        ;;
    "logs")
        echo "查看哨兵模式日志..."
        docker-compose logs -f redis-master redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3
        ;;
    "test")
        echo "测试哨兵模式..."
        echo "1. 写入测试数据到主节点..."
        docker exec redis-master redis-cli -a CG1rMeyRryFgvElf8n SET test_key "Hello Sentinel Mode"
        echo "2. 从从节点读取数据..."
        docker exec redis-slave1 redis-cli -a CG1rMeyRryFgvElf8n GET test_key
        docker exec redis-slave2 redis-cli -a CG1rMeyRryFgvElf8n GET test_key
        echo "3. 通过哨兵查询主节点地址..."
        docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name redis-master
        ;;
    "failover")
        echo "模拟故障转移测试..."
        echo "1. 停止主节点..."
        docker-compose stop redis-master
        echo "2. 等待哨兵检测故障..."
        sleep 10
        echo "3. 检查新的主节点..."
        docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name redis-master
        echo "4. 检查从节点状态..."
        docker exec redis-slave1 redis-cli -a CG1rMeyRryFgvElf8n INFO replication | grep -E "(role|master_host|master_port)"
        docker exec redis-slave2 redis-cli -a CG1rMeyRryFgvElf8n INFO replication | grep -E "(role|master_host|master_port)"
        echo "故障转移测试完成！"
        ;;
    "rebuild")
        echo "重新构建并启动哨兵模式..."
        docker-compose up -d --build redis-master redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3
        echo "哨兵模式重建完成！"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs|test|failover|rebuild}"
        echo ""
        echo "命令说明:"
        echo "  start    - 启动 Redis 哨兵模式"
        echo "  stop     - 停止 Redis 哨兵模式"
        echo "  restart  - 重启 Redis 哨兵模式"
        echo "  status   - 检查哨兵模式状态"
        echo "  logs     - 查看哨兵模式日志"
        echo "  test     - 测试哨兵模式功能"
        echo "  failover - 模拟故障转移测试"
        echo "  rebuild  - 重新构建并启动哨兵模式"
        exit 1
        ;;
esac
