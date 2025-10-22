#!/bin/bash -e

# Redis 哨兵模式智能动态管理脚本
# Redis主节点使用静态IP，worker节点使用动态IP

# 加载环境变量
if [ -f .env ]; then
    # 跳过BOM字符并加载环境变量
    while IFS='=' read -r key value; do
        # 移除注释部分
        value=$(echo "$value" | sed 's/#.*$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [[ ! "$key" =~ ^[[:space:]]*# ]] && [[ -n "$key" ]] && [[ -n "$value" ]]; then
            export "$key=$value"
        fi
    done < <(sed '1s/^\xEF\xBB\xBF//' .env)
fi

# 设置默认值
REDIS_PASSWORD=${REDIS_PASSWORD:-"CG1rMeyRryFgvElf8n"}
REDIS_SENTINEL_QUORUM=${REDIS_SENTINEL_QUORUM:-2}
REDIS_SENTINEL_DOWN_AFTER_MS=${REDIS_SENTINEL_DOWN_AFTER_MS:-5000}
REDIS_SENTINEL_FAILOVER_TIMEOUT=${REDIS_SENTINEL_FAILOVER_TIMEOUT:-10000}

echo "=== Redis 哨兵模式智能动态管理脚本 ==="

# 等待服务启动的函数
wait_for_service() {
    local service_name=$1
    local max_attempts=30
    local attempt=1

    echo "等待 $service_name 服务启动..."
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T $service_name redis-cli --no-auth-warning -a $REDIS_PASSWORD ping 2>/dev/null | grep -q PONG; then
            echo "$service_name 服务已就绪"
            return 0
        fi
        echo "尝试 $attempt/$max_attempts: 等待 $service_name 启动..."
        sleep 2
        ((attempt++))
    done

    echo "错误: $service_name 服务启动超时"
    return 1
}

# 获取服务的实际IP地址
get_service_ip() {
    local service_name=$1
    docker inspect $service_name --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null
}

# 生成智能动态的哨兵配置
generate_smart_sentinel_config() {
    local config_file="/tmp/sentinel-smart-dynamic.conf"
    local template_file="redis/sentinel.conf.template"

    # 主节点使用静态IP（从环境变量获取）
    local master_ip=${REDIS_IP:-"172.18.0.4"}

    echo "主节点IP: $master_ip (静态配置)" >&2

    # 检查模板文件是否存在
    if [ ! -f "$template_file" ]; then
        echo "错误: 模板文件 $template_file 不存在"
        return 1
    fi

    # 使用envsubst处理模板文件
    envsubst < "$template_file" > "$config_file"

    echo "$config_file"
}

case "$1" in
    "start")
        echo "启动 Redis 哨兵模式（智能动态配置）..."
        echo "Redis主节点使用静态IP，worker节点使用动态IP"

        # 1. 启动Redis主节点（静态IP）
        echo "1. 启动Redis主节点（静态IP）..."
        docker-compose up -d redis-master
        wait_for_service redis-master 6379 || exit 1

        # 2. 启动worker节点（动态IP）
        echo "2. 启动worker节点（动态IP）..."
        docker-compose up -d redis-slave1 redis-slave2
        wait_for_service redis-slave1 6379 || exit 1
        wait_for_service redis-slave2 6379 || exit 1

        # 3. 配置主从复制
        echo "3. 配置主从复制..."
        docker-compose exec -T redis-master redis-cli --no-auth-warning -a $REDIS_PASSWORD SLAVEOF NO ONE
        docker-compose exec -T redis-slave1 redis-cli --no-auth-warning -a $REDIS_PASSWORD SLAVEOF redis-master 6379
        docker-compose exec -T redis-slave2 redis-cli --no-auth-warning -a $REDIS_PASSWORD SLAVEOF redis-master 6379
        sleep 5

        # 4. 生成智能动态配置
        echo "4. 生成智能动态哨兵配置..."
        config_file=$(generate_smart_sentinel_config)
        if [ $? -ne 0 ]; then
            echo "错误: 无法生成哨兵配置"
            exit 1
        fi

        # 5. 启动哨兵节点（worker节点，动态IP）
        echo "5. 启动哨兵节点（动态IP）..."
        # 先停止现有的哨兵节点
        docker-compose stop redis-sentinel1 redis-sentinel2 redis-sentinel3 2>/dev/null || true

        # 将配置复制到宿主机，然后通过卷挂载
        cp "$config_file" redis/sentinel.conf

        # 启动哨兵节点
        docker-compose up -d redis-sentinel1 redis-sentinel2 redis-sentinel3

        # 等待哨兵节点启动
        echo "6. 等待哨兵节点启动..."
        sleep 10

        # 清理临时文件
        rm -f "$config_file"

        echo "哨兵模式启动完成！"
        echo "Redis主节点（静态IP）:"
        echo "  - redis-master: ${REDIS_IP:-172.18.0.4}:6379"
        echo "Worker节点（动态IP）:"
        echo "  - redis-slave1: $(get_service_ip redis-slave1):6379"
        echo "  - redis-slave2: $(get_service_ip redis-slave2):6379"
        echo "  - redis-sentinel1: $(get_service_ip redis-sentinel1):26379"
        echo "  - redis-sentinel2: $(get_service_ip redis-sentinel2):26379"
        echo "  - redis-sentinel3: $(get_service_ip redis-sentinel3):26379"
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
        echo "=== 网络信息 ==="
        echo "Redis主节点（静态IP）:"
        echo "  redis-master: ${REDIS_IP:-172.18.0.4}"
        echo "Worker节点（动态IP）:"
        echo "  redis-slave1: $(get_service_ip redis-slave1)"
        echo "  redis-slave2: $(get_service_ip redis-slave2)"
        echo "  redis-sentinel1: $(get_service_ip redis-sentinel1)"
        echo "  redis-sentinel2: $(get_service_ip redis-sentinel2)"
        echo "  redis-sentinel3: $(get_service_ip redis-sentinel3)"
        echo ""
        echo "=== 主节点信息 ==="
        docker-compose exec -T redis-master redis-cli --no-auth-warning -a $REDIS_PASSWORD INFO replication | grep -E "(role|connected_slaves|master_host|master_port)"
        echo ""
        echo "=== 从节点信息 ==="
        docker-compose exec -T redis-slave1 redis-cli --no-auth-warning -a $REDIS_PASSWORD INFO replication | grep -E "(role|master_host|master_port|master_link_status)"
        docker-compose exec -T redis-slave2 redis-cli --no-auth-warning -a $REDIS_PASSWORD INFO replication | grep -E "(role|master_host|master_port|master_link_status)"
        echo ""
        echo "=== 哨兵信息 ==="
        docker-compose exec -T redis-sentinel1 redis-cli -p 26379 SENTINEL masters
        echo ""
        echo "=== 哨兵监控状态 ==="
        docker-compose exec -T redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels redis-master
        ;;
    "logs")
        echo "查看哨兵模式日志..."
        docker-compose logs -f redis-master redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3
        ;;
    "test")
        echo "测试哨兵模式..."
        echo "1. 写入测试数据到主节点..."
        docker-compose exec -T redis-master redis-cli --no-auth-warning -a $REDIS_PASSWORD SET test_key "Hello Smart Dynamic Sentinel Mode"
        echo "2. 从从节点读取数据..."
        docker-compose exec -T redis-slave1 redis-cli --no-auth-warning -a $REDIS_PASSWORD GET test_key
        docker-compose exec -T redis-slave2 redis-cli --no-auth-warning -a $REDIS_PASSWORD GET test_key
        echo "3. 通过哨兵查询主节点地址..."
        docker-compose exec -T redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name redis-master
        echo "4. 测试故障转移（模拟）..."
        echo "   停止主节点..."
        docker-compose stop redis-master
        sleep 5
        echo "   通过哨兵查询新的主节点..."
        docker-compose exec -T redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name redis-master
        echo "   重启主节点..."
        docker-compose up -d redis-master
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs|test}"
        echo ""
        echo "命令说明:"
        echo "  start        - 启动 Redis 哨兵模式（智能动态配置）"
        echo "  stop         - 停止 Redis 哨兵模式"
        echo "  restart      - 重启 Redis 哨兵模式"
        echo "  status       - 检查哨兵模式状态（显示静态/动态IP）"
        echo "  logs         - 查看哨兵模式日志"
        echo "  test         - 测试哨兵模式功能（包括故障转移）"
        echo ""
        echo "架构说明:"
        echo "  - Redis主节点使用静态IP（redis-master）"
        echo "  - Worker节点使用动态IP（redis-slave, redis-sentinel）"
        exit 1
        ;;
esac
