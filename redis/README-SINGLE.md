# Redis 单机模式配置文档

Redis 单机模式适用于开发环境和小规模部署，提供简单、快速的 Redis 服务。

## 目录

- [快速开始](#快速开始)
- [架构说明](#架构说明)
- [环境配置](#环境配置)
- [启动和管理](#启动和管理)
- [连接方式](#连接方式)
- [数据持久化](#数据持久化)
- [配置说明](#配置说明)
- [常用操作](#常用操作)
- [故障排除](#故障排除)
- [注意事项](#注意事项)

## 快速开始

### 前置要求

1. **Docker 和 Docker Compose**：确保已安装并运行
2. **Docker 网络**：需要创建 `backend` 网络（运行 `./init.sh`）
3. **环境变量**：确保 `.env` 文件配置正确

### 一键启动

```bash
# 使用 Makefile（推荐）
make -f Makefile.single redis

# 或使用 Docker Compose
docker-compose -f docker-compose.single.yml up -d redis
```

### 验证启动

```bash
# 测试连接
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n ping
# 应该返回: PONG

# 检查状态
docker ps --filter "name=redis"
```

## 架构说明

### 服务组件

| 组件 | 说明 |
|------|------|
| **容器名称** | `redis` |
| **镜像** | `zhaopan/redis:5` (基于 Redis 5.0.14) |
| **端口** | `6379` (映射到主机 `6379`) |
| **网络 IP** | `172.18.0.4` (静态 IP) |
| **数据目录** | `./data/redis` |
| **配置文件** | `./redis/redis5.conf` |

### 架构特点

- **轻量级部署**：单容器，无需集群依赖
- **快速启动**：几秒内即可使用
- **开发友好**：适合本地开发和测试
- **数据持久化**：支持 RDB 快照
- **静态 IP**：固定 IP 地址，便于服务发现

### 适用场景

- 本地开发环境
- 小规模应用部署
- 功能测试和集成测试
- 学习和实验环境

> **注意**：生产环境建议使用 [Redis 哨兵模式](README.md) 以获得高可用性。

## 环境配置

### 必需的环境变量

在项目根目录的 `.env` 文件中配置以下变量：

```bash
# Redis 配置
REDIS_VERSION=5                    # Redis 版本
REDIS_NAME=redis                  # 容器名称
REDIS_PORT=6379                   # 端口映射
REDIS_PASSWORD=CG1rMeyRryFgvElf8n # Redis 密码
REDIS_IP=172.18.0.4              # 静态 IP 地址
REDIS_DATA_PATH=./data/redis      # 数据目录路径
REDIS_CONF_PATH=./redis/redis5.conf # 配置文件路径

# 镜像配置
AUTHOR=zhaopan                    # 镜像作者前缀
```

### 配置文件位置

- **配置文件**：`redis/redis5.conf`
- **数据目录**：`data/redis/`
- **日志目录**：`data/logs/redis/`

### 初始化环境

```bash
# 1. 创建 Docker 网络（如果不存在）
./init.sh

# 2. 确保数据目录存在
mkdir -p data/redis

# 3. 检查配置文件
ls -la redis/redis5.conf
```

## 启动和管理

### 启动命令

```bash
# 方法 1：使用 Makefile（推荐）
make -f Makefile.single redis

# 方法 2：使用 Docker Compose
docker-compose -f docker-compose.single.yml up -d redis

# 方法 3：手动构建并启动
docker-compose -f docker-compose.single.yml build redis
docker-compose -f docker-compose.single.yml up -d redis
```

### 管理命令

#### 查看状态

```bash
# 使用 Makefile
make -f Makefile.single status

# 直接查看容器
docker ps --filter "name=redis"
docker ps -a --filter "name=redis"  # 包括已停止的容器
```

#### 查看日志

```bash
# 实时日志
make -f Makefile.single logs-redis

# 或使用 docker-compose
docker-compose -f docker-compose.single.yml logs -f redis

# 查看最近 50 行日志
docker-compose -f docker-compose.single.yml logs --tail 50 redis
```

#### 停止服务

```bash
# 使用 Makefile
make -f Makefile.single stop

# 或使用 docker-compose
docker-compose -f docker-compose.single.yml stop redis
```

#### 重启服务

```bash
# 使用 Makefile
make -f Makefile.single restart

# 或使用 docker-compose
docker-compose -f docker-compose.single.yml restart redis
```

#### 删除容器

```bash
# 停止并删除容器（保留数据）
docker-compose -f docker-compose.single.yml down redis

# 删除容器和数据卷
docker-compose -f docker-compose.single.yml down -v redis
```

## 连接方式

### 连接信息

| 项目 | 值 |
|------|-----|
| **主机** | `localhost` 或 `172.18.0.4` |
| **端口** | `6379` |
| **密码** | `CG1rMeyRryFgvElf8n` |
| **数据库** | `0` (默认) |

### 命令行连接

```bash
# 方法 1：使用 docker exec（推荐）
docker exec -it redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n

# 方法 2：从主机连接（需要本地安装 redis-cli）
redis-cli -h localhost -p 6379 -a CG1rMeyRryFgvElf8n --no-auth-warning
```

### 测试连接

```bash
# Ping 测试
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n ping
# 返回: PONG

# 获取服务器信息
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n INFO server

# 查看配置
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n CONFIG GET "*"
```

### 应用程序连接

#### Go 语言示例

```go
package main

import (
    "github.com/go-redis/redis/v8"
    "context"
)

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr:     "localhost:6379",
        Password: "CG1rMeyRryFgvElf8n",
        DB:       0,
    })

    ctx := context.Background()
    err := rdb.Ping(ctx).Err()
    if err != nil {
        panic(err)
    }
}
```

#### Python 示例

```python
import redis

r = redis.Redis(
    host='localhost',
    port=6379,
    password='CG1rMeyRryFgvElf8n',
    db=0,
    decode_responses=True
)

# 测试连接
print(r.ping())  # 输出: True
```

#### Node.js 示例

```javascript
const redis = require('redis');

const client = redis.createClient({
    host: 'localhost',
    port: 6379,
    password: 'CG1rMeyRryFgvElf8n',
    db: 0
});

client.on('connect', () => {
    console.log('Connected to Redis');
});

client.ping((err, reply) => {
    console.log(reply); // 输出: PONG
});
```

## 数据持久化

### RDB 快照

Redis 默认启用 RDB 持久化，数据保存在容器内的 `/data/dump.rdb`，映射到主机的 `data/redis/dump.rdb`。

#### 持久化配置

在 `redis/redis5.conf` 中配置了以下保存策略：

```conf
save 900 1      # 900 秒内至少 1 个 key 变化
save 300 10     # 300 秒内至少 10 个 key 变化
save 60 10000   # 60 秒内至少 10000 个 key 变化
```

#### 手动保存

```bash
# 在 Redis CLI 中执行
SAVE          # 同步保存（会阻塞）
BGSAVE        # 后台异步保存（推荐）
```

### 数据备份

```bash
# 备份数据文件
cp data/redis/dump.rdb data/redis/dump.rdb.backup

# 查看数据文件大小
ls -lh data/redis/dump.rdb
```

### 数据恢复

```bash
# 1. 停止 Redis
docker-compose -f docker-compose.single.yml stop redis

# 2. 恢复备份文件
cp data/redis/dump.rdb.backup data/redis/dump.rdb

# 3. 启动 Redis
docker-compose -f docker-compose.single.yml start redis
```

## 配置说明

### 主要配置项

配置文件：`redis/redis5.conf`

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `bind` | `0.0.0.0` | 监听所有网络接口 |
| `port` | `6379` | Redis 端口 |
| `requirepass` | `CG1rMeyRryFgvElf8n` | 访问密码 |
| `dir` | `./` | 数据目录（容器内为 `/data`） |
| `dbfilename` | `dump.rdb` | RDB 文件名 |
| `save` | 见上文 | RDB 保存策略 |
| `appendonly` | `no` | AOF 持久化（默认关闭） |

### 修改配置

```bash
# 1. 编辑配置文件
vim redis/redis5.conf

# 2. 重启 Redis 使配置生效
docker-compose -f docker-compose.single.yml restart redis

# 或使用 Redis CLI 动态修改（临时生效）
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n CONFIG SET maxmemory 256mb
```

> **注意**：通过 `CONFIG SET` 修改的配置在重启后会丢失，永久修改需要编辑配置文件。

## 常用操作

### 基础操作

```bash
# 进入 Redis CLI
docker exec -it redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n

# 在 Redis CLI 中执行命令
SET key value
GET key
DEL key
KEYS *
FLUSHDB    # 清空当前数据库
FLUSHALL   # 清空所有数据库
INFO       # 查看服务器信息
CONFIG GET *  # 查看所有配置
```

### 监控命令

```bash
# 查看服务器信息
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n INFO

# 查看内存使用
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n INFO memory

# 查看客户端连接
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n CLIENT LIST

# 查看慢查询
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n SLOWLOG GET 10
```

### 性能测试

```bash
# 使用 redis-benchmark 进行性能测试
docker exec redis redis-benchmark -a CG1rMeyRryFgvElf8n -n 10000 -c 100
```

## 故障排除

### 检查脚本

项目提供了自动检查脚本：

```bash
bash check-redis-single.sh
```

### 常见问题

#### 1. 容器无法启动

**症状**：容器启动后立即退出

**排查步骤**：

```bash
# 查看容器日志
docker-compose -f docker-compose.single.yml logs redis

# 检查配置文件语法
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n CONFIG GET "*"

# 检查端口占用
netstat -an | grep 6379
```

**解决方案**：

- 检查端口是否被占用
- 检查配置文件语法
- 检查数据目录权限

#### 2. 无法连接 Redis

**症状**：连接时提示 "Connection refused" 或 "Authentication failed"

**排查步骤**：

```bash
# 检查容器是否运行
docker ps --filter "name=redis"

# 检查端口映射
docker port redis

# 测试容器内连接
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n ping
```

**解决方案**：

- 确认容器正在运行
- 检查密码是否正确
- 检查防火墙设置

#### 3. 数据丢失

**症状**：重启后数据消失

**排查步骤**：

```bash
# 检查数据文件
ls -lh data/redis/dump.rdb

# 检查持久化配置
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n CONFIG GET save
```

**解决方案**：

- 确认 RDB 持久化已启用
- 检查数据目录权限
- 确认数据文件存在

#### 4. 内存不足

**症状**：Redis 报错 "OOM command not allowed"

**排查步骤**：

```bash
# 查看内存使用
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n INFO memory

# 查看最大内存配置
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n CONFIG GET maxmemory
```

**解决方案**：

- 设置最大内存限制
- 配置内存淘汰策略
- 清理过期 key

### 日志查看

```bash
# 实时日志
docker-compose -f docker-compose.single.yml logs -f redis

# 查看最近 100 行
docker-compose -f docker-compose.single.yml logs --tail 100 redis

# 查看特定时间段的日志
docker-compose -f docker-compose.single.yml logs --since 30m redis
```

### 重置 Redis

```bash
# 1. 停止并删除容器
docker-compose -f docker-compose.single.yml down redis

# 2. 删除数据文件（谨慎操作！）
rm -rf data/redis/*

# 3. 重新启动
docker-compose -f docker-compose.single.yml up -d redis
```

## 注意事项

### 安全建议

1. **修改默认密码**：生产环境必须修改默认密码 `CG1rMeyRryFgvElf8n`
2. **限制访问**：使用防火墙限制 Redis 端口访问
3. **网络隔离**：使用 Docker 网络隔离 Redis 服务
4. **定期备份**：定期备份 RDB 文件

### 性能优化

1. **内存限制**：根据实际需求设置 `maxmemory`
2. **持久化策略**：根据数据重要性调整 RDB 保存频率
3. **连接池**：应用程序使用连接池管理连接
4. **监控**：定期检查 Redis 性能指标

### 开发建议

1. **使用连接池**：避免频繁创建/关闭连接
2. **合理使用过期时间**：为 key 设置合理的 TTL
3. **批量操作**：使用 Pipeline 或批量命令提高性能
4. **错误处理**：正确处理连接失败和超时情况

### 数据目录

- **数据文件**：`data/redis/dump.rdb`
- **日志文件**：`data/logs/redis/`
- **备份文件**：建议定期备份到安全位置

### 版本信息

- **Redis 版本**：5.0.14
- **Docker 镜像**：`zhaopan/redis:5`
- **配置文件**：`redis/redis5.conf`

## 相关文档

- [Redis 哨兵模式配置](README.md) - 生产环境高可用方案
- [项目主文档](../README.md) - 完整项目文档
- [Redis 官方文档](https://redis.io/documentation) - Redis 官方文档

## 快速参考

```bash
# 启动
make -f Makefile.single redis

# 停止
docker-compose -f docker-compose.single.yml stop redis

# 重启
docker-compose -f docker-compose.single.yml restart redis

# 查看日志
make -f Makefile.single logs-redis

# 测试连接
docker exec redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n ping

# 进入 CLI
docker exec -it redis redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n

# 检查配置
bash check-redis-single.sh
```
