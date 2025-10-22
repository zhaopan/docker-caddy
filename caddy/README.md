# Caddy 配置文档

本项目使用 Caddy 2.10 作为反向代理服务器，提供自动 HTTPS、负载均衡、安全头等功能。

## 文档导航

- **[Worker 代理配置详解](./WORKER-PROXY-GUIDE.md)** - 详细的 Worker 代理配置和工作机制说明
- **[Caddy 配置文档](./README.md)** - 本文档，Caddy 基础配置说明

## 架构说明

### 服务组件

| 服务 | 端口 | 说明 |
|------|------|------|
| caddy | 80, 443 | HTTP/HTTPS 服务器 |
| caddy-cluster1 | 80, 443 | 集群节点 1 |
| caddy-cluster2 | 80, 443 | 集群节点 2 |
| caddy-cluster3 | 80, 443 | 集群节点 3 |

### 站点配置

| 站点 | 域名 | 后端服务 | 端口 | 说明 |
|------|------|----------|------|------|
| www | www.example.com | home-service | 3000 | 主站点 |
| api | api.example.com | api-service | 3001 | API 接口 |
| admin | admin.example.com | admin-service | 3002 | 管理后台 |

## 配置文件说明

### Caddyfile

主配置文件，包含全局配置和站点导入：

```caddyfile
# Caddy 配置
{
    # 日志配置
    log {
        output file /data/logs/caddy.log
        format console
        level INFO
    }
}

# 导入站点配置
import conf.d/*.caddy
```

### 站点配置文件

#### 02-www.caddy - 主站点配置

```caddyfile
# Home Site Configuration
www {
    # 反向代理到 home 服务
    reverse_proxy home-service:3000 {
        # 健康检查
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }

    # 安全头
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # Gzip 压缩
    encode gzip

    # 日志记录
    log {
        output file /data/logs/home.log
        format json
        level INFO
    }
}
```

#### 03-api.caddy - API 接口配置

```caddyfile
# API Site Configuration
api {
    # 反向代理到 API 服务
    reverse_proxy api-service:3001 {
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }

    # 安全头
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # Gzip 压缩
    encode gzip

    # 日志记录
    log {
        output file /data/logs/api.log
        format json
        level INFO
    }
}
```

#### 04-admin.caddy - 管理后台配置

```caddyfile
# Admin Site Configuration
admin {
    # 反向代理到管理服务
    reverse_proxy admin-service:3002 {
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }

    # 安全头
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # Gzip 压缩
    encode gzip

    # 日志记录
    log {
        output file /data/logs/admin.log
        format json
        level INFO
    }
}
```

## 管理命令

### 集群模式管理

```bash
# 启动 Caddy 集群
make caddy-start

# 停止 Caddy 集群
make caddy-stop

# 重启 Caddy 集群
make caddy-restart

# 查看 Caddy 状态
make caddy-status

# 查看 Caddy 日志
make caddy-logs
```

### 单机模式管理

```bash
# 启动单机模式 Caddy
make -f Makefile.single caddy

# 查看单机模式 Caddy 日志
make -f Makefile.single logs-caddy

# 查看单机模式状态
make -f Makefile.single status
```

## 功能特性

### 1. 自动 HTTPS

- 自动获取 Let's Encrypt SSL 证书
- 支持 HTTP 到 HTTPS 自动重定向
- 证书自动续期

### 2. 集群功能（Caddy 2.10 增强）

- **环境变量配置**：通过环境变量配置集群存储后端
- **Redis 存储支持**：支持 Redis 作为集群配置存储
- **配置同步**：集群节点间自动同步配置
- **负载均衡**：改进的负载均衡算法
- **故障转移**：自动检测和故障转移
- **一致性保证**：确保集群配置一致性

### 3. 反向代理

- 支持多个后端服务
- 健康检查机制
- 负载均衡（轮询算法）

### 4. 安全头

所有站点都包含以下安全头：

```caddyfile
header {
    X-Content-Type-Options "nosniff"
    X-Frame-Options "SAMEORIGIN"
    X-XSS-Protection "1; mode=block"
    Referrer-Policy "strict-origin-when-cross-origin"
}
```

### 5. 压缩

- Gzip 压缩支持
- 自动压缩文本文件

### 6. 速率限制

- **主站点**：100 请求/分钟/IP
- **API 接口**：50 请求/分钟/IP（更严格）
- **管理后台**：20 请求/分钟/IP（最严格）
- 基于 IP 地址的速率限制
- 可配置的限制策略

### 7. 日志记录

- 结构化 JSON 日志
- 分离的访问日志文件
- 可配置日志级别

## 配置注意事项

### 1. 版本兼容性

**重要**：本项目使用 Caddy 2.10，具有增强的集群支持：

- √ 环境变量集群配置（通过环境变量配置存储后端）
- √ Redis 存储后端支持
- √ 集群配置同步和一致性
- √ 改进的负载均衡算法
- √ `tls internal`（开发环境自签名证书）
- √ `rate_limit` 指令（已添加插件支持）

### 2. 域名配置

生产环境需要修改域名：

```caddyfile
# 开发环境
www {
    # 使用自签名证书
    tls internal
}

# 生产环境
www.example.com {
    # 自动获取 Let's Encrypt 证书
    # tls 配置会自动处理
}
```

### 3. 集群配置

Caddy 2.10 通过环境变量配置集群：

```bash
# 环境变量配置
CADDY_CLUSTER_NAME=caddy-cluster
CADDY_CLUSTER_STORAGE=redis
CADDY_CLUSTER_STORAGE_REDIS_ADDRESS=redis-master:6379
CADDY_CLUSTER_STORAGE_REDIS_PASSWORD=CG1rMeyRryFgvElf8n
CADDY_CLUSTER_STORAGE_REDIS_DB=1
```

### 4. 后端服务

确保后端服务正常运行：

```bash
# 检查后端服务状态
docker ps | grep -E "(home-service|api-service|admin-service)"

# 检查服务健康状态
curl http://localhost:3000/health
curl http://localhost:3001/health
curl http://localhost:3002/health
```

## 日志管理

### 日志文件位置

```
/data/logs/
├── caddy.log      # Caddy 主日志
├── home.log       # 主站点访问日志
├── api.log        # API 接口访问日志
└── admin.log      # 管理后台访问日志
```

### 日志格式

**Caddy 主日志**（控制台格式）：
```
2024/01/01 12:00:00 [INFO] serving initial configuration
```

**站点访问日志**（JSON 格式）：
```json
{
  "level": "info",
  "ts": 1704067200,
  "logger": "http.log.access",
  "msg": "handled request",
  "request": {
    "method": "GET",
    "uri": "/",
    "proto": "HTTP/2.0",
    "remote_addr": "192.168.1.100:12345"
  },
  "duration": 0.001,
  "status": 200,
  "size": 1024
}
```

### 日志查看

```bash
# 查看 Caddy 主日志
docker logs caddy

# 查看站点访问日志
docker exec caddy tail -f /data/logs/home.log

# 查看所有日志
make caddy-logs
```

## 故障排除

### 常见问题

1. **Caddy 启动失败**
   ```bash
   # 检查配置文件语法
   docker exec caddy caddy validate --config /etc/caddy/Caddyfile

   # 查看详细错误信息
   docker logs caddy
   ```

2. **HTTPS 证书问题**
   ```bash
   # 检查证书状态
   docker exec caddy caddy list-certificates

   # 强制更新证书
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

3. **后端服务连接失败**
   ```bash
   # 检查后端服务状态
   docker ps | grep service

   # 测试后端服务连接
   docker exec caddy curl -I http://home-service:3000/health
   ```

4. **配置不生效**
   ```bash
   # 重新加载配置
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile

   # 重启 Caddy 服务
   make caddy-restart
   ```

### 调试模式

启用调试日志：

```caddyfile
{
    log {
        output file /data/logs/caddy.log
        format console
        level DEBUG
    }
}
```

## 性能优化

### 1. 缓存配置

```caddyfile
# 静态资源缓存
@static {
    path *.css *.js *.png *.jpg *.jpeg *.gif *.ico *.svg
}

header @static Cache-Control "public, max-age=31536000"
```

### 2. 压缩优化

```caddyfile
# 启用压缩
encode gzip {
    minimum_length 1024
    level 6
}
```

### 3. 连接优化

```caddyfile
# 反向代理优化
reverse_proxy home-service:3000 {
    health_uri /health
    health_interval 10s
    health_timeout 3s
    header_up Host {host}
    header_up X-Real-IP {remote}
    header_up X-Forwarded-For {remote}
    header_up X-Forwarded-Proto {scheme}
}
```

## 安全建议

1. **定期更新**：保持 Caddy 版本更新
2. **访问控制**：使用 IP 白名单限制管理后台访问
3. **监控告警**：设置 Caddy 服务监控
4. **日志审计**：定期检查访问日志
5. **证书管理**：监控证书过期时间

## 扩展功能

### 1. 添加新站点

创建新的配置文件 `conf.d/05-new-site.caddy`：

```caddyfile
# New Site Configuration
new-site {
    reverse_proxy new-service:3003 {
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }

    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }

    encode gzip

    log {
        output file /data/logs/new-site.log
        format json
        level INFO
    }
}
```

### 2. 自定义中间件

```caddyfile
# 自定义中间件示例
{
    # 全局中间件
    log {
        output file /data/logs/caddy.log
        format console
        level INFO
    }
}
```

## 版本信息

- **Caddy 版本**: 2.10
- **Docker 镜像**: caddy:2.10
- **配置文件**: Caddyfile
- **日志格式**: JSON + Console

---

更多详细信息请参考 [Caddy 官方文档](https://caddyserver.com/docs/) 和 [Caddyfile 语法](https://caddyserver.com/docs/caddyfile)。
