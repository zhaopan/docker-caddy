# Redis 哨兵模式测试总管理 Makefile

# 变量定义
GO_DIR = go
PY_DIR = py

# 默认目标
.PHONY: all
all: help

# 启动 Redis 哨兵集群
.PHONY: redis-start
redis-start:
	@echo "启动 Redis 哨兵集群..."
	cd .. && ./redis-sentinel-manage.sh start

# 停止 Redis 哨兵集群
.PHONY: redis-stop
redis-stop:
	@echo "停止 Redis 哨兵集群..."
	cd .. && ./redis-sentinel-manage.sh stop

# 检查 Redis 哨兵集群状态
.PHONY: redis-status
redis-status:
	@echo "检查 Redis 哨兵集群状态..."
	cd .. && ./redis-sentinel-manage.sh status

# 重启 Redis 哨兵集群
.PHONY: redis-restart
redis-restart:
	@echo "重启 Redis 哨兵集群..."
	cd .. && ./redis-sentinel-manage.sh restart

# 测试 Redis 哨兵集群
.PHONY: redis-test
redis-test:
	@echo "测试 Redis 哨兵集群..."
	cd .. && ./redis-sentinel-manage.sh test

# 模拟 Redis 故障转移
.PHONY: redis-failover
redis-failover:
	@echo "模拟 Redis 故障转移..."
	cd .. && ./redis-sentinel-manage.sh failover

# 查看 Redis 日志
.PHONY: redis-logs
redis-logs:
	@echo "查看 Redis 日志..."
	cd .. && ./redis-sentinel-manage.sh logs

# Go 语言测试
.PHONY: go-test
go-test:
	@echo "运行 Go 语言测试..."
	cd $(GO_DIR) && make test

# Go 语言 Web 应用
.PHONY: go-web
go-web:
	@echo "启动 Go 语言 Web 应用..."
	cd $(GO_DIR) && make web

# Go 语言构建
.PHONY: go-build
go-build:
	@echo "构建 Go 语言程序..."
	cd $(GO_DIR) && make build

# Go 语言清理
.PHONY: go-clean
go-clean:
	@echo "清理 Go 语言构建文件..."
	cd $(GO_DIR) && make clean

# Python 语言测试
.PHONY: py-test
py-test:
	@echo "运行 Python 语言测试..."
	cd $(PY_DIR) && make test

# Python 语言 Web 应用
.PHONY: py-web
py-web:
	@echo "启动 Python 语言 Web 应用..."
	cd $(PY_DIR) && make web

# Python 语言安装
.PHONY: py-install
py-install:
	@echo "安装 Python 语言依赖..."
	cd $(PY_DIR) && make install

# Python 语言清理
.PHONY: py-clean
py-clean:
	@echo "清理 Python 语言环境..."
	cd $(PY_DIR) && make clean

# 运行所有测试
.PHONY: test-all
test-all: redis-start
	@echo "等待 Redis 集群启动..."
	sleep 10
	@echo "运行 Go 语言测试..."
	$(MAKE) go-test
	@echo "运行 Python 语言测试..."
	$(MAKE) py-test
	@echo "所有测试完成"

# 启动所有 Web 应用
.PHONY: web-all
web-all: redis-start
	@echo "等待 Redis 集群启动..."
	sleep 10
	@echo "启动 Go Web 应用 (端口 8080)..."
	cd $(GO_DIR) && make web &
	@echo "启动 Python Web 应用 (端口 8081)..."
	cd $(PY_DIR) && make web &
	@echo "所有 Web 应用已启动"

# 构建所有程序
.PHONY: build-all
build-all:
	@echo "构建 Go 语言程序..."
	$(MAKE) go-build
	@echo "安装 Python 语言依赖..."
	$(MAKE) py-install
	@echo "所有程序构建完成"

# 清理所有构建文件
.PHONY: clean-all
clean-all:
	@echo "清理所有构建文件..."
	$(MAKE) go-clean
	$(MAKE) py-clean
	@echo "清理完成"

# 完整测试流程
.PHONY: full-test
full-test: redis-start
	@echo "等待 Redis 集群启动..."
	sleep 10
	@echo "运行完整测试流程..."
	$(MAKE) test-all
	@echo "完整测试流程完成"

# 开发环境启动
.PHONY: dev
dev: redis-start
	@echo "等待 Redis 集群启动..."
	sleep 10
	@echo "启动开发环境..."
	@echo "Go Web 应用: http://localhost:8080"
	@echo "Python Web 应用: http://localhost:8081"
	$(MAKE) web-all

# 停止所有服务
.PHONY: stop-all
stop-all:
	@echo "停止所有服务..."
	@echo "停止 Go Web 应用..."
	pkill -f "web-app" || true
	@echo "停止 Python Web 应用..."
	pkill -f "web_app.py" || true
	@echo "停止 Redis 集群..."
	$(MAKE) redis-stop
	@echo "所有服务已停止"

# 重启所有服务
.PHONY: restart-all
restart-all:
	@echo "重启所有服务..."
	$(MAKE) stop-all
	sleep 5
	$(MAKE) dev

# 查看所有服务状态
.PHONY: status-all
status-all:
	@echo "=== Redis 集群状态 ==="
	$(MAKE) redis-status
	@echo ""
	@echo "=== Go 程序状态 ==="
	ps aux | grep -E "(web-app|test-redis)" | grep -v grep || echo "Go 程序未运行"
	@echo ""
	@echo "=== Python 程序状态 ==="
	ps aux | grep -E "(web_app.py|test_redis.py)" | grep -v grep || echo "Python 程序未运行"

# 帮助信息
.PHONY: help
help:
	@echo "Redis 哨兵模式测试管理"
	@echo ""
	@echo "Redis 集群管理:"
	@echo "  redis-start    - 启动 Redis 哨兵集群"
	@echo "  redis-stop     - 停止 Redis 哨兵集群"
	@echo "  redis-status   - 检查 Redis 哨兵集群状态"
	@echo "  redis-restart  - 重启 Redis 哨兵集群"
	@echo "  redis-test     - 测试 Redis 哨兵集群"
	@echo "  redis-failover - 模拟 Redis 故障转移"
	@echo "  redis-logs     - 查看 Redis 日志"
	@echo ""
	@echo "Go 语言测试:"
	@echo "  go-test        - 运行 Go 语言测试"
	@echo "  go-web         - 启动 Go 语言 Web 应用"
	@echo "  go-build       - 构建 Go 语言程序"
	@echo "  go-clean       - 清理 Go 语言构建文件"
	@echo ""
	@echo "Python 语言测试:"
	@echo "  py-test        - 运行 Python 语言测试"
	@echo "  py-web         - 启动 Python 语言 Web 应用"
	@echo "  py-install     - 安装 Python 语言依赖"
	@echo "  py-clean       - 清理 Python 语言环境"
	@echo ""
	@echo "综合操作:"
	@echo "  test-all       - 运行所有测试"
	@echo "  web-all        - 启动所有 Web 应用"
	@echo "  build-all      - 构建所有程序"
	@echo "  clean-all      - 清理所有构建文件"
	@echo "  full-test      - 完整测试流程"
	@echo "  dev            - 开发环境启动"
	@echo "  stop-all       - 停止所有服务"
	@echo "  restart-all    - 重启所有服务"
	@echo "  status-all     - 查看所有服务状态"
	@echo "  help           - 显示此帮助信息"
