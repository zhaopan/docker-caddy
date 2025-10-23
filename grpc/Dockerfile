# 使用 Golang 官方镜像作为基础镜像
FROM golang:1.24-alpine as builder

LABEL maintainer="syszhaopan@gmail.com"

# 设置工作目录
WORKDIR /app

ENV CGO_ENABLED=0
ENV GOPROXY=https://goproxy.cn,direct

# 复制 go.mod 和 go.sum 文件
COPY go.mod go.sum ./

# 下载 Go 模块依赖
RUN go mod tidy

# 复制项目源代码到容器内
COPY . .

# 编译 Go 应用
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# 第二阶段：运行阶段
FROM alpine:latest

# 安装依赖（如需要）
RUN apk --no-cache add ca-certificates

# 设置工作目录
WORKDIR /root/

# 从构建阶段复制二进制文件到运行镜像
COPY --from=builder /app/app .

# 暴露容器的端口
EXPOSE 80

# 启动应用
CMD ["./app"]
