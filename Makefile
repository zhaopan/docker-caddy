# Docker Caddy 项目主 Makefile
# 支持集群模式和单机模式

# 项目信息
PROJECT_NAME = docker-caddy
VERSION = $(shell git describe --always --tags 2>/dev/null || echo "dev")
DOCKER_COMPOSE ?= docker-compose

# 帮助信息
.PHONY: help
help:
	@echo "Docker Caddy 项目管理工具"
	@echo ""
	@echo "集群模式命令:"
	@echo "  build         构建 Docker 镜像"
	@echo "  up            启动 Docker 服务"
	@echo "  down          停止 Docker 服务"
	@echo "  dev           启动开发环境"
	@echo "  status        查看服务状态"
	@echo ""
	@echo "Redis 集群管理:"
	@echo "  redis-start         启动 Redis 哨兵集群"
	@echo "  redis-stop          停止 Redis 哨兵集群"
	@echo "  redis-restart       重启 Redis 哨兵集群"
	@echo "  redis-status        检查 Redis 集群状态"
	@echo "  redis-logs          查看 Redis 集群日志"
	@echo ""
	@echo "Caddy 集群管理:"
	@echo "  caddy-start   启动 Caddy 集群"
	@echo "  caddy-stop    停止 Caddy 集群"
	@echo "  caddy-restart 重启 Caddy 集群"
	@echo "  caddy-status  检查 Caddy 集群状态"
	@echo "  caddy-logs    查看 Caddy 集群日志"
	@echo "  caddy-test    测试 Caddy 集群功能"
	@echo ""
	@echo "gRPC 集群管理:"
	@echo "  grpc-start    启动 gRPC 集群"
	@echo "  grpc-stop     停止 gRPC 集群"
	@echo "  grpc-restart  重启 gRPC 集群"
	@echo "  grpc-status   查看 gRPC 集群状态"
	@echo "  grpc-logs     查看 gRPC 集群日志"
	@echo "  grpc-rebuild  重新构建并启动 gRPC 集群"
	@echo ""
	@echo "测试和开发:"
	@echo "  test-go       运行 Go 语言测试"
	@echo "  test-py       运行 Python 语言测试"
	@echo "  test-all      运行所有测试"
	@echo "  web-go        启动 Go Web 应用"
	@echo "  web-py        启动 Python Web 应用"
	@echo "  web-all       启动所有 Web 应用"
	@echo ""
	@echo "单机模式:"
	@echo "  使用 'make -f Makefile.single help' 查看单机模式命令"
	@echo ""
	@echo "其他命令:"
	@echo "  clean         清理 Docker 资源"
	@echo "  stop-all      停止所有服务（包含 Docker 与本地进程）"
	@echo "  full-test     完整测试流程"
	@echo ""

# Docker 操作
.PHONY: build
build:
	$(DOCKER_COMPOSE) build

.PHONY: up
up:
	$(DOCKER_COMPOSE) up -d

.PHONY: down
down:
	$(DOCKER_COMPOSE) down

.PHONY: clean
clean:
	@echo "清理 Docker 资源..."
	-$(DOCKER_COMPOSE) down --rmi local --volumes --remove-orphans
	-docker rmi -f $(shell docker images -f "dangling=true" -q) 2> /dev/null
	-docker rmi -f $(PROJECT_NAME):latest $(PROJECT_NAME):$(VERSION) 2> /dev/null

# Redis 哨兵集群管理
.PHONY: redis-start
redis-start:
	./redis-sentinel-manage.sh start

.PHONY: redis-stop
redis-stop:
	./redis-sentinel-manage.sh stop

.PHONY: redis-status
redis-status:
	./redis-sentinel-manage.sh status

.PHONY: redis-restart
redis-restart:
	./redis-sentinel-manage.sh restart

.PHONY: redis-logs
redis-logs:
	./redis-sentinel-manage.sh logs

# Caddy 集群管理
.PHONY: caddy-start
caddy-start:
	./cluster-manage.sh start

.PHONY: caddy-stop
caddy-stop:
	./cluster-manage.sh stop

.PHONY: caddy-status
caddy-status:
	./cluster-manage.sh status

.PHONY: caddy-restart
caddy-restart:
	./cluster-manage.sh restart

.PHONY: caddy-logs
caddy-logs:
	./cluster-manage.sh logs

.PHONY: caddy-test
caddy-test:
	@echo "=== Caddy 集群功能测试 ==="
	@echo ""
	@echo "1. 检查集群状态..."
	@$(MAKE) caddy-status
	@echo ""
	@echo "2. 测试主入口 (http://localhost:80)..."
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:80 || echo "主入口测试失败"
	@echo ""
	@echo "3. 测试 Worker1 (http://localhost:8001)..."
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:8001 || echo "Worker1 测试失败"
	@echo ""
	@echo "4. 测试 Worker2 (http://localhost:8002)..."
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:8002 || echo "Worker2 测试失败"
	@echo ""
	@echo "5. 测试 Worker3 (http://localhost:8003)..."
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:8003 || echo "Worker3 测试失败"
	@echo ""
	@echo "6. 测试 HTTPS 端口..."
	@echo "HTTPS 端口监听检查:"
	@if netstat -tlnp | grep -q :443; then \
		echo "√ 端口 443 正在监听"; \
	else \
		echo "x 端口 443 未监听"; \
	fi
	@echo ""
	@echo "TLS 证书检查:"
	@if docker exec caddy ls /data/caddy/certificates/local/ 2>/dev/null | grep -q ".crt"; then \
		echo "√ TLS 证书已生成"; \
	else \
		echo "x TLS 证书未生成"; \
	fi
	@echo ""
	@echo "注意: HTTPS 测试需要正确的域名解析，当前使用 tls internal 模式"
	@echo ""
	@echo "7. 测试负载均衡..."
	@echo "连续请求 5 次主入口，观察负载均衡效果:"
	@for i in 1 2 3 4 5; do \
		echo -n "请求 $$i: "; \
		curl -s -o /dev/null -w "%{http_code} " http://localhost:80; \
		sleep 0.5; \
	done; \
	echo ""
	@echo ""
	@echo "8. 检查容器健康状态..."
	@docker ps --filter "name=caddy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "9. HTTPS 问题诊断..."
	@echo "检查端口监听状态:"
	@netstat -tlnp | grep :443 || echo "端口 443 未监听"
	@echo ""
	@echo "TLS 证书检查:"
	@docker exec caddy ls -la /data/caddy/certificates/ 2>/dev/null || echo "证书目录不存在"
	@echo ""
	@echo "=== 测试完成 ==="

# gRPC 集群管理
.PHONY: grpc-start
grpc-start:
	./grpc-manage.sh start

.PHONY: grpc-stop
grpc-stop:
	./grpc-manage.sh stop

.PHONY: grpc-status
grpc-status:
	./grpc-manage.sh status

.PHONY: grpc-restart
grpc-restart:
	./grpc-manage.sh restart

.PHONY: grpc-logs
grpc-logs:
	./grpc-manage.sh logs

.PHONY: grpc-rebuild
grpc-rebuild:
	./grpc-manage.sh rebuild

# 测试管理
.PHONY: test-go
test-go:
	$(MAKE) -C test/go test

.PHONY: test-py
test-py:
	$(MAKE) -C test/py test

.PHONY: test-all
test-all:
	$(MAKE) -C test test-all

# Web 应用管理
.PHONY: web-go
web-go:
	$(MAKE) -C test/go web

.PHONY: web-py
web-py:
	$(MAKE) -C test/py web

.PHONY: web-all
web-all:
	$(MAKE) -C test web-all

# 开发环境
.PHONY: dev
dev:
	$(MAKE) -C test dev

# 停止所有服务
.PHONY: stop-all
stop-all: down
	$(MAKE) -C test stop-all

# 查看状态
.PHONY: status
status:
	$(MAKE) -C test status-all

# 完整测试流程
.PHONY: full-test
full-test:
	$(MAKE) -C test full-test

# 默认目标
.PHONY: all
all: help
