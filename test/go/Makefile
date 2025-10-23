# Redis 哨兵模式 Go 测试 Makefile

# 变量定义
BINARY_NAME=redis-sentinel-test
WEB_BINARY_NAME=web-app
TEST_BINARY_NAME=test-redis
GO_VERSION=1.24

# 默认目标
.PHONY: all
all: build

# 安装依赖
.PHONY: deps
deps:
	@echo "安装 Go 依赖..."
	go mod tidy
	go mod download

# 构建所有程序
.PHONY: build
build: deps
	@echo "构建 Web 应用..."
	go build -o $(WEB_BINARY_NAME) web-app.go redis-config.go
	@echo "构建测试程序..."
	go build -o $(TEST_BINARY_NAME) test-redis.go redis-config.go

# 运行 Redis 配置测试
.PHONY: test
test: build
	@echo "运行 Redis 配置测试..."
	./$(TEST_BINARY_NAME)

# 运行 Web 应用
.PHONY: web
web: build
	@echo "启动 Web 应用..."
	./$(WEB_BINARY_NAME)

# 运行 Redis 配置程序
.PHONY: run
run: build
	@echo "运行 Redis 配置程序..."
	./$(BINARY_NAME)

# 清理构建文件
.PHONY: clean
clean:
	@echo "清理构建文件..."
	rm -f $(BINARY_NAME) $(WEB_BINARY_NAME) $(TEST_BINARY_NAME)

# 格式化代码
.PHONY: fmt
fmt:
	@echo "格式化 Go 代码..."
	go fmt ./...

# 运行代码检查
.PHONY: vet
vet:
	@echo "运行 Go 代码检查..."
	go vet ./...

# 运行测试
.PHONY: test-go
test-go:
	@echo "运行 Go 测试..."
	go test -v ./...

# 帮助信息
.PHONY: help
help:
	@echo "可用的 Make 目标:"
	@echo "  deps      - 安装 Go 依赖"
	@echo "  build     - 构建所有程序"
	@echo "  test      - 运行 Redis 配置测试"
	@echo "  web       - 启动 Web 应用"
	@echo "  run       - 运行 Redis 配置程序"
	@echo "  clean     - 清理构建文件"
	@echo "  fmt       - 格式化代码"
	@echo "  vet       - 运行代码检查"
	@echo "  test-go   - 运行 Go 测试"
	@echo "  help      - 显示此帮助信息"
