# Docker Caddy 项目主 Makefile
# 支持集群模式和单机模式

# 项目信息
PROJECT_NAME = docker-caddy
VERSION = $(shell git describe --always --tags 2>/dev/null || echo "dev")

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
	@echo "  logs          查看服务日志"
	@echo ""
	@echo "单机模式:"
	@echo "  使用 'make -f Makefile.single help' 查看单机模式命令"
	@echo ""
	@echo "Redis 集群管理:"
	@echo "  redis-start   启动 Redis 哨兵集群"
	@echo "  redis-stop    停止 Redis 哨兵集群"
	@echo "  redis-status  检查 Redis 集群状态"
	@echo "  redis-logs    查看 Redis 集群日志"
	@echo ""
	@echo "Caddy 集群管理:"
	@echo "  caddy-start   启动 Caddy 集群"
	@echo "  caddy-stop    停止 Caddy 集群"
	@echo "  caddy-status  检查 Caddy 集群状态"
	@echo "  caddy-logs    查看 Caddy 集群日志"
	@echo ""
	@echo "测试和开发:"
	@echo "  test-go       运行 Go 语言测试"
	@echo "  test-py       运行 Python 语言测试"
	@echo "  test-all      运行所有测试"
	@echo "  web-go        启动 Go Web 应用"
	@echo "  web-py        启动 Python Web 应用"
	@echo "  web-all       启动所有 Web 应用"
	@echo ""
	@echo "其他命令:"
	@echo "  clean         清理 Docker 镜像"
	@echo "  stop-all      停止所有服务"
	@echo "  full-test     完整测试流程"

# Docker 操作
.PHONY: build
build:
	docker-compose build

.PHONY: up
up:
	docker-compose up -d

.PHONY: down
down:
	docker-compose down


.PHONY: clean
clean:
	rm -rf $(PROJECT_NAME)
	docker rmi -f $(shell docker images -f "dangling=true" -q) 2> /dev/null; true
	docker rmi -f $(PROJECT_NAME):latest $(PROJECT_NAME):$(VERSION) 2> /dev/null; true

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

# 测试管理
.PHONY: test-go
test-go:
	cd test/go && make test

.PHONY: test-py
test-py:
	cd test/py && make test

.PHONY: test-all
test-all:
	cd test && make test-all

# Web 应用管理
.PHONY: web-go
web-go:
	cd test/go && make web

.PHONY: web-py
web-py:
	cd test/py && make web

.PHONY: web-all
web-all:
	cd test && make web-all

# 开发环境
.PHONY: dev
dev:
	cd test && make dev

# 停止所有服务
.PHONY: stop-all
stop-all:
	cd test && make stop-all

# 查看状态
.PHONY: status
status:
	cd test && make status-all

# 完整测试流程
.PHONY: full-test
full-test:
	cd test && make full-test

# 帮助信息
.PHONY: help
help:
	@echo "Docker 操作:"
	@echo "  build         - 构建 Docker 镜像"
	@echo "  up            - 启动 Docker 服务"
	@echo "  down          - 停止 Docker 服务"
	@echo "  clean         - 清理 Docker 镜像"
	@echo ""
	@echo "Redis 哨兵集群:"
	@echo "  redis-start   - 启动 Redis 哨兵集群"
	@echo "  redis-stop    - 停止 Redis 哨兵集群"
	@echo "  redis-status  - 检查 Redis 哨兵集群状态"
	@echo "  redis-restart - 重启 Redis 哨兵集群"
	@echo "  redis-logs    - 查看 Redis 日志"
	@echo ""
	@echo "Caddy 集群:"
	@echo "  caddy-start   - 启动 Caddy 集群"
	@echo "  caddy-stop    - 停止 Caddy 集群"
	@echo "  caddy-status  - 检查 Caddy 集群状态"
	@echo "  caddy-restart - 重启 Caddy 集群"
	@echo "  caddy-logs    - 查看 Caddy 日志"
	@echo ""
	@echo "单机模式:"
	@echo "  使用 'make -f Makefile.single help' 查看单机模式命令"
	@echo ""
	@echo "测试管理:"
	@echo "  test-go       - 运行 Go 语言测试"
	@echo "  test-py       - 运行 Python 语言测试"
	@echo "  test-all      - 运行所有测试"
	@echo ""
	@echo "Web 应用:"
	@echo "  web-go        - 启动 Go Web 应用"
	@echo "  web-py        - 启动 Python Web 应用"
	@echo "  web-all       - 启动所有 Web 应用"
	@echo ""
	@echo "开发环境:"
	@echo "  dev           - 启动开发环境"
	@echo "  stop-all      - 停止所有服务"
	@echo "  status        - 查看所有服务状态"
	@echo "  full-test     - 完整测试流程"
	@echo "  help          - 显示此帮助信息"

# 默认目标
.PHONY: all
all: help