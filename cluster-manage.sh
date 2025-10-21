#!/bin/bash -e

# Caddy 集群管理脚本

echo "=== Caddy 集群管理脚本 ==="

case "$1" in
    "start")
        echo "启动 Caddy 集群..."
        docker-compose up -d proxy proxy-worker1 proxy-worker2 proxy-worker3
        echo "集群启动完成！"
        echo "主入口: http://localhost:80"
        echo "Worker1: http://localhost:8001"
        echo "Worker2: http://localhost:8002" 
        echo "Worker3: http://localhost:8003"
        ;;
    "stop")
        echo "停止 Caddy 集群..."
        docker-compose stop proxy proxy-worker1 proxy-worker2 proxy-worker3
        echo "集群已停止！"
        ;;
    "restart")
        echo "重启 Caddy 集群..."
        docker-compose restart proxy proxy-worker1 proxy-worker2 proxy-worker3
        echo "集群重启完成！"
        ;;
    "status")
        echo "检查集群状态..."
        docker-compose ps proxy proxy-worker1 proxy-worker2 proxy-worker3
        echo ""
        echo "检查健康状态..."
        curl -s http://localhost/health || echo "主入口健康检查失败"
        curl -s http://localhost:8001/health || echo "Worker1健康检查失败"
        curl -s http://localhost:8002/health || echo "Worker2健康检查失败"
        curl -s http://localhost:8003/health || echo "Worker3健康检查失败"
        ;;
    "logs")
        echo "查看集群日志..."
        docker-compose logs -f proxy proxy-worker1 proxy-worker2 proxy-worker3
        ;;
    "rebuild")
        echo "重新构建并启动集群..."
        docker-compose up -d --build proxy proxy-worker1 proxy-worker2 proxy-worker3
        echo "集群重建完成！"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs|rebuild}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动 Caddy 集群"
        echo "  stop    - 停止 Caddy 集群"
        echo "  restart - 重启 Caddy 集群"
        echo "  status  - 检查集群状态"
        echo "  logs    - 查看集群日志"
        echo "  rebuild - 重新构建并启动集群"
        exit 1
        ;;
esac
