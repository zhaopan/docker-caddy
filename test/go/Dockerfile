# 使用 Go 官方镜像
FROM golang:1.24-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN go build -o web-app web-app.go redis-config.go
RUN go build -o test-redis test-redis.go redis-config.go

# 运行阶段
FROM alpine:latest

# 安装 ca-certificates
RUN apk --no-cache add ca-certificates

# 设置工作目录
WORKDIR /root/

# 从构建阶段复制二进制文件
COPY --from=builder /app/web-app .
COPY --from=builder /app/test-redis .

# 暴露端口
EXPOSE 8080

# 默认运行 web-app
CMD ["./web-app"]
