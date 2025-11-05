#!/bin/bash

# 单机版 Redis 启动配置检查脚本

echo "=========================================="
echo "单机版 Redis 启动配置检查"
echo "=========================================="
echo ""

# 1. 检查 Docker Compose 配置文件
echo "[1] 检查 Docker Compose 配置..."
if [ -f "docker-compose.single.yml" ]; then
    echo "✓ docker-compose.single.yml 存在"
else
    echo "✗ docker-compose.single.yml 不存在"
    exit 1
fi

# 2. 检查 Redis 配置文件
echo ""
echo "[2] 检查 Redis 配置文件..."
if [ -f "redis/redis5.conf" ]; then
    echo "✓ redis5.conf 存在"

    # 检查配置文件中的关键设置
    if grep -q "requirepass" redis/redis5.conf; then
        echo "✓ 配置文件包含密码设置"
    else
        echo "⚠ 配置文件未找到 requirepass 设置（可能通过命令行参数设置）"
    fi

    if grep -q "^bind" redis/redis5.conf; then
        bind_config=$(grep "^bind" redis/redis5.conf | head -1)
        echo "✓ 绑定地址配置: $bind_config"
    fi

    if grep -q "^port" redis/redis5.conf; then
        port_config=$(grep "^port" redis/redis5.conf | head -1)
        echo "✓ 端口配置: $port_config"
    fi
else
    echo "✗ redis5.conf 不存在"
    exit 1
fi

# 3. 检查 Docker 镜像
echo ""
echo "[3] 检查 Docker 镜像..."
if docker images | grep -q "zhaopan/redis:5"; then
    echo "✓ Redis 镜像 zhaopan/redis:5 已存在"
else
    echo "⚠ Redis 镜像 zhaopan/redis:5 不存在，需要构建"
    echo "  运行: docker-compose -f docker-compose.single.yml build redis"
fi

# 4. 检查 Docker 网络
echo ""
echo "[4] 检查 Docker 网络..."
if docker network ls | grep -q "backend"; then
    echo "✓ backend 网络已存在"

    # 检查网络配置
    network_info=$(docker network inspect backend --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null)
    if [ -n "$network_info" ]; then
        echo "  网络子网: $network_info"
    fi
else
    echo "✗ backend 网络不存在"
    echo "  运行: ./init.sh 初始化网络"
    exit 1
fi

# 5. 检查数据目录
echo ""
echo "[5] 检查数据目录..."
if [ -d "data/redis" ]; then
    echo "✓ 数据目录 data/redis 存在"
    ls -la data/redis 2>/dev/null | head -5
else
    echo "⚠ 数据目录 data/redis 不存在，将在启动时自动创建"
fi

# 6. 检查环境变量配置
echo ""
echo "[6] 检查环境变量配置..."
if [ -f ".env" ]; then
    echo "✓ .env 文件存在"

    # 检查关键环境变量
    if grep -q "^REDIS_PASSWORD=" .env; then
        redis_pwd=$(grep "^REDIS_PASSWORD=" .env | cut -d'=' -f2 | head -1)
        echo "  REDIS_PASSWORD: ${redis_pwd:0:5}***"
    else
        echo "⚠ REDIS_PASSWORD 未在 .env 中设置（使用默认值）"
    fi

    if grep -q "^REDIS_PORT=" .env; then
        redis_port=$(grep "^REDIS_PORT=" .env | cut -d'=' -f2 | head -1)
        echo "  REDIS_PORT: $redis_port"
    else
        echo "⚠ REDIS_PORT 未在 .env 中设置（使用默认值 6379）"
    fi

    if grep -q "^REDIS_IP=" .env; then
        redis_ip=$(grep "^REDIS_IP=" .env | cut -d'=' -f2 | head -1)
        echo "  REDIS_IP: $redis_ip"
    else
        echo "⚠ REDIS_IP 未在 .env 中设置（使用默认值）"
    fi

    if grep -q "^REDIS_DATA_PATH=" .env; then
        redis_data=$(grep "^REDIS_DATA_PATH=" .env | cut -d'=' -f2 | head -1)
        echo "  REDIS_DATA_PATH: $redis_data"
    else
        echo "⚠ REDIS_DATA_PATH 未在 .env 中设置（使用默认值）"
    fi

    if grep -q "^REDIS_CONF_PATH=" .env; then
        redis_conf=$(grep "^REDIS_CONF_PATH=" .env | cut -d'=' -f2 | head -1)
        echo "  REDIS_CONF_PATH: $redis_conf"
    else
        echo "⚠ REDIS_CONF_PATH 未在 .env 中设置（使用默认值）"
    fi
else
    echo "⚠ .env 文件不存在，将使用默认配置"
fi

# 7. 验证 Docker Compose 配置
echo ""
echo "[7] 验证 Docker Compose 配置..."
if docker-compose -f docker-compose.single.yml config --services | grep -q "redis"; then
    echo "✓ Redis 服务在配置文件中已定义"

    # 获取 Redis 服务配置
    echo ""
    echo "Redis 服务配置详情:"
    docker-compose -f docker-compose.single.yml config 2>/dev/null | grep -A 30 "^  redis:" | head -25
else
    echo "✗ Redis 服务未在配置文件中定义"
    exit 1
fi

# 8. 检查容器状态
echo ""
echo "[8] 检查容器状态..."
if docker ps -a --filter "name=^redis$" --format "{{.Names}}" | grep -q "^redis$"; then
    container_status=$(docker ps -a --filter "name=^redis$" --format "{{.Status}}")
    echo "✓ Redis 容器已存在"
    echo "  状态: $container_status"

    if docker ps --filter "name=^redis$" --format "{{.Names}}" | grep -q "^redis$"; then
        echo "✓ Redis 容器正在运行"

        # 测试连接
        echo ""
        echo "[9] 测试 Redis 连接..."
        redis_pwd=$(grep "^REDIS_PASSWORD=" .env 2>/dev/null | cut -d'=' -f2 | head -1 || echo "CG1rMeyRryFgvElf8n")
        if docker exec redis redis-cli --no-auth-warning -a "$redis_pwd" ping 2>/dev/null | grep -q "PONG"; then
            echo "✓ Redis 连接测试成功"
        else
            echo "✗ Redis 连接测试失败"
        fi
    else
        echo "⚠ Redis 容器已停止"
        echo "  启动命令: docker-compose -f docker-compose.single.yml up -d redis"
        echo "  或使用: make -f Makefile.single redis"
    fi
else
    echo "⚠ Redis 容器不存在"
    echo "  启动命令: docker-compose -f docker-compose.single.yml up -d redis"
    echo "  或使用: make -f Makefile.single redis"
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="
echo ""
echo "启动 Redis 的命令:"
echo "  make -f Makefile.single redis"
echo "  或"
echo "  docker-compose -f docker-compose.single.yml up -d redis"
echo ""
echo "查看 Redis 日志:"
echo "  docker-compose -f docker-compose.single.yml logs -f redis"
echo "  或"
echo "  make -f Makefile.single logs-redis"
echo ""
echo "测试 Redis 连接:"
echo "  docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n ping"
