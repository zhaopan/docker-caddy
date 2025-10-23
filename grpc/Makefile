# gRPC Go 服务 Makefile

# 变量定义
BINARY_NAME=grpc-service
BINARY_NAME_WORKER1=grpc-worker1
BINARY_NAME_WORKER2=grpc-worker2
BINARY_NAME_WORKER3=grpc-worker3
GO_VERSION=1.24
PORT=8000
WORKER1_PORT=8001
WORKER2_PORT=8002
WORKER3_PORT=8003

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
	@echo "构建 gRPC 主服务..."
	go build -o $(BINARY_NAME) main.go
	@echo "构建 gRPC Worker1..."
	go build -o $(BINARY_NAME_WORKER1) -ldflags "-X main.PORT=$(WORKER1_PORT)" main.go
	@echo "构建 gRPC Worker2..."
	go build -o $(BINARY_NAME_WORKER2) -ldflags "-X main.PORT=$(WORKER2_PORT)" main.go
	@echo "构建 gRPC Worker3..."
	go build -o $(BINARY_NAME_WORKER3) -ldflags "-X main.PORT=$(WORKER3_PORT)" main.go

# 构建主服务
.PHONY: build-main
build-main: deps
	@echo "构建 gRPC 主服务..."
	go build -o $(BINARY_NAME) main.go

# 构建 Worker 服务
.PHONY: build-workers
build-workers: deps
	@echo "构建 gRPC Worker 服务..."
	go build -o $(BINARY_NAME_WORKER1) -ldflags "-X main.PORT=$(WORKER1_PORT)" main.go
	go build -o $(BINARY_NAME_WORKER2) -ldflags "-X main.PORT=$(WORKER2_PORT)" main.go
	go build -o $(BINARY_NAME_WORKER3) -ldflags "-X main.PORT=$(WORKER3_PORT)" main.go

# 运行主服务
.PHONY: run
run: build-main
	@echo "启动 gRPC 主服务 (端口 $(PORT))..."
	./$(BINARY_NAME)

# 运行 Worker1
.PHONY: run-worker1
run-worker1: build-workers
	@echo "启动 gRPC Worker1 (端口 $(WORKER1_PORT))..."
	./$(BINARY_NAME_WORKER1)

# 运行 Worker2
.PHONY: run-worker2
run-worker2: build-workers
	@echo "启动 gRPC Worker2 (端口 $(WORKER2_PORT))..."
	./$(BINARY_NAME_WORKER2)

# 运行 Worker3
.PHONY: run-worker3
run-worker3: build-workers
	@echo "启动 gRPC Worker3 (端口 $(WORKER3_PORT))..."
	./$(BINARY_NAME_WORKER3)

# 运行所有服务
.PHONY: run-all
run-all: build
	@echo "启动所有 gRPC 服务..."
	@echo "主服务: http://localhost:$(PORT)/process"
	@echo "Worker1: http://localhost:$(WORKER1_PORT)/process"
	@echo "Worker2: http://localhost:$(WORKER2_PORT)/process"
	@echo "Worker3: http://localhost:$(WORKER3_PORT)/process"
	@echo ""
	@echo "按 Ctrl+C 停止所有服务"
	@echo ""
	./$(BINARY_NAME) &
	./$(BINARY_NAME_WORKER1) &
	./$(BINARY_NAME_WORKER2) &
	./$(BINARY_NAME_WORKER3) &
	wait

# 测试服务
.PHONY: test
test: build-main
	@echo "测试 gRPC 主服务..."
	@echo "发送测试请求到 http://localhost:$(PORT)/process"
	@echo ""
	@echo "测试数据: {\"input\": \"Hello gRPC\"}"
	@echo ""
	curl -X POST http://localhost:$(PORT)/process \
		-H "Content-Type: application/json" \
		-d '{"input": "Hello gRPC"}' || echo "请确保服务正在运行"

# 测试所有服务
.PHONY: test-all
test-all: build
	@echo "测试所有 gRPC 服务..."
	@echo ""
	@echo "测试主服务..."
	curl -X POST http://localhost:$(PORT)/process \
		-H "Content-Type: application/json" \
		-d '{"input": "Main Service Test"}' || echo "主服务未运行"
	@echo ""
	@echo "测试 Worker1..."
	curl -X POST http://localhost:$(WORKER1_PORT)/process \
		-H "Content-Type: application/json" \
		-d '{"input": "Worker1 Test"}' || echo "Worker1 未运行"
	@echo ""
	@echo "测试 Worker2..."
	curl -X POST http://localhost:$(WORKER2_PORT)/process \
		-H "Content-Type: application/json" \
		-d '{"input": "Worker2 Test"}' || echo "Worker2 未运行"
	@echo ""
	@echo "测试 Worker3..."
	curl -X POST http://localhost:$(WORKER3_PORT)/process \
		-H "Content-Type: application/json" \
		-d '{"input": "Worker3 Test"}' || echo "Worker3 未运行"

# 健康检查
.PHONY: health
health:
	@echo "检查 gRPC 服务健康状态..."
	@echo ""
	@echo "主服务 (端口 $(PORT)):"
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:$(PORT)/process || echo "主服务不可用"
	@echo ""
	@echo "Worker1 (端口 $(WORKER1_PORT)):"
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:$(WORKER1_PORT)/process || echo "Worker1 不可用"
	@echo ""
	@echo "Worker2 (端口 $(WORKER2_PORT)):"
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:$(WORKER2_PORT)/process || echo "Worker2 不可用"
	@echo ""
	@echo "Worker3 (端口 $(WORKER3_PORT)):"
	@curl -s -o /dev/null -w "状态码: %{http_code}, 响应时间: %{time_total}s\n" http://localhost:$(WORKER3_PORT)/process || echo "Worker3 不可用"

# 清理构建文件
.PHONY: clean
clean:
	@echo "清理构建文件..."
	rm -f $(BINARY_NAME) $(BINARY_NAME_WORKER1) $(BINARY_NAME_WORKER2) $(BINARY_NAME_WORKER3)
	rm -f main.exe

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

# 构建 Docker 镜像
.PHONY: docker-build
docker-build:
	@echo "构建 Docker 镜像..."
	docker build -t grpc-service:latest .

# 运行 Docker 容器
.PHONY: docker-run
docker-run: docker-build
	@echo "运行 Docker 容器..."
	docker run -p $(PORT):8000 grpc-service:latest

# 停止所有服务
.PHONY: stop
stop:
	@echo "停止所有 gRPC 服务..."
	@pkill -f $(BINARY_NAME) || true
	@pkill -f $(BINARY_NAME_WORKER1) || true
	@pkill -f $(BINARY_NAME_WORKER2) || true
	@pkill -f $(BINARY_NAME_WORKER3) || true
	@echo "所有服务已停止"

# 查看服务状态
.PHONY: status
status:
	@echo "gRPC 服务状态:"
	@echo ""
	@ps aux | grep -E "$(BINARY_NAME)|$(BINARY_NAME_WORKER1)|$(BINARY_NAME_WORKER2)|$(BINARY_NAME_WORKER3)" | grep -v grep || echo "没有运行的服务"

# 查看端口使用情况
.PHONY: ports
ports:
	@echo "端口使用情况:"
	@echo ""
	@netstat -tlnp | grep -E ":$(PORT)|:$(WORKER1_PORT)|:$(WORKER2_PORT)|:$(WORKER3_PORT)" || echo "没有服务在监听这些端口"

# 帮助信息
.PHONY: help
help:
	@echo "gRPC Go 服务管理工具"
	@echo ""
	@echo "构建命令:"
	@echo "  build         构建所有程序"
	@echo "  build-main    构建主服务"
	@echo "  build-workers 构建 Worker 服务"
	@echo "  deps          安装 Go 依赖"
	@echo ""
	@echo "运行命令:"
	@echo "  run           运行主服务"
	@echo "  run-worker1   运行 Worker1"
	@echo "  run-worker2   运行 Worker2"
	@echo "  run-worker3   运行 Worker3"
	@echo "  run-all       运行所有服务"
	@echo ""
	@echo "测试命令:"
	@echo "  test          测试主服务"
	@echo "  test-all      测试所有服务"
	@echo "  health        健康检查"
	@echo ""
	@echo "管理命令:"
	@echo "  stop          停止所有服务"
	@echo "  status        查看服务状态"
	@echo "  ports         查看端口使用情况"
	@echo "  clean         清理构建文件"
	@echo ""
	@echo "开发命令:"
	@echo "  fmt           格式化代码"
	@echo "  vet           代码检查"
	@echo "  test-go       运行 Go 测试"
	@echo ""
	@echo "Docker 命令:"
	@echo "  docker-build  构建 Docker 镜像"
	@echo "  docker-run    运行 Docker 容器"
	@echo ""
	@echo "其他命令:"
	@echo "  help          显示此帮助信息"
