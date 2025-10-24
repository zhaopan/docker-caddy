#!/bin/bash -e

# gRPC 服务集群管理脚本

SERVICES=(grpc grpc-worker1 grpc-worker2 grpc-worker3)

# 加载 .env 中的变量（去除 BOM 并忽略注释）
if [ -f .env ]; then
    while IFS='=' read -r key value; do
        value=$(echo "$value" | sed 's/#.*$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [[ ! "$key" =~ ^[[:space:]]*# ]] && [[ -n "$key" ]] && [[ -n "$value" ]]; then
            export "$key=$value"
        fi
    done < <(sed '1s/^\xEF\xBB\xBF//' .env)
fi

GRPC_PORT=${GRPC_PORT:-8000}

echo "=== gRPC 集群管理脚本 ==="

join_services() {
    local IFS=' '
    echo "${SERVICES[*]}"
}

get_service_ip() {
    local service_name=$1
    docker inspect "$service_name" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null
}

case "$1" in
    "start")
        echo "启动 gRPC 集群..."
        docker-compose up -d $(join_services)
        echo "集群启动完成！"
        echo "提示：默认服务端口 ${GRPC_PORT}（容器内部映射）"
        ;;
    "stop")
        echo "停止 gRPC 集群..."
        docker-compose stop $(join_services)
        echo "集群已停止！"
        ;;
    "restart")
        echo "重启 gRPC 集群..."
        docker-compose restart $(join_services)
        echo "集群重启完成！"
        ;;
    "rebuild")
        echo "重新构建并启动 gRPC 集群..."
        docker-compose up -d --build $(join_services)
        echo "集群重建完成！"
        ;;
    "status")
        echo "检查 gRPC 集群状态..."
        docker-compose ps $(join_services)
        echo ""
        echo "网络信息："
        for svc in "${SERVICES[@]}"; do
            printf "  %-13s %s\n" "$svc" "$(get_service_ip "$svc")"
        done
        ;;
    "logs")
        echo "查看 gRPC 集群日志..."
        docker-compose logs -f $(join_services)
        ;;
    *)
        echo "用法: $0 {start|stop|restart|rebuild|status|logs}"
        echo ""
        echo "命令说明:"
        echo "  start    - 启动 gRPC 集群"
        echo "  stop     - 停止 gRPC 集群"
        echo "  restart  - 重启 gRPC 集群"
        echo "  rebuild  - 重新构建并启动 gRPC 集群"
        echo "  status   - 查看 gRPC 集群容器状态和网络信息"
        echo "  logs     - 追踪 gRPC 集群日志"
        exit 1
        ;;
esac

