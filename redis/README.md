# Redis 哨兵模式配置

本项目使用 Redis 哨兵模式提供高可用的 Redis 服务，支持自动故障转移和主从复制。

## 架构说明

### 服务组件

| 服务 | 端口 | 角色 | 说明 |
|------|------|------|------|
| redis-master | 6379 | 主节点 | 处理写操作，数据同步到从节点 |
| redis-slave1 | 6380 | 从节点 | 复制主节点数据，处理读操作 |
| redis-slave2 | 6381 | 从节点 | 复制主节点数据，处理读操作 |
| redis-sentinel1 | 26379 | 哨兵 | 监控主从节点，执行故障转移 |
| redis-sentinel2 | 26380 | 哨兵 | 监控主从节点，执行故障转移 |
| redis-sentinel3 | 26381 | 哨兵 | 监控主从节点，执行故障转移 |

### 网络配置

- **主节点 IP**: 172.18.0.4
- **从节点 IP**: 172.18.1.1, 172.18.1.2
- **哨兵节点**: 自动发现和通信

## 配置文件说明

### sentinel.conf

哨兵配置文件，包含以下关键配置：

```conf
# 监控的主节点
sentinel monitor redis-master redis-master 6379 2

# 主节点认证密码
sentinel auth-pass redis-master CG1rMeyRryFgvElf8n

# 故障检测时间（毫秒）
sentinel down-after-milliseconds redis-master 5000

# 故障转移超时时间
sentinel failover-timeout redis-master 10000

# 并行同步从节点数量
sentinel parallel-syncs redis-master 1
```

### redis.conf

主节点 Redis 配置文件，包含：

- 端口配置：6379
- 认证密码：CG1rMeyRryFgvElf8n
- 持久化配置
- 内存优化配置

### redis-slave.conf

从节点 Redis 配置文件，包含：

- 主从复制配置
- 只读模式
- 数据同步配置

## 管理命令

### 基础管理

```bash
# 启动哨兵模式
make redis-start

# 停止哨兵模式
make redis-stop

# 重启哨兵模式
make redis-restart

# 查看状态
make redis-status

# 查看日志
make redis-logs
```

### 测试命令

```bash
# 测试哨兵功能
./redis-sentinel-manage.sh test

# 模拟故障转移
./redis-sentinel-manage.sh failover

# 重新构建
./redis-sentinel-manage.sh rebuild
```

## 使用注意事项

### 1. 密码安全

**重要**：所有 Redis 连接都使用密码 `CG1rMeyRryFgvElf8n`，请在生产环境中修改此密码。

### 2. 命令行警告

为了避免 Redis CLI 的密码警告，所有脚本都使用了 `--no-auth-warning` 参数：

```bash
# 正确的方式（无警告）
redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n ping

# 错误的方式（会显示警告）
redis-cli -a CG1rMeyRryFgvElf8n ping
```

### 3. 故障转移

- 需要至少 2 个哨兵节点同意才能执行故障转移
- 故障检测时间为 5 秒
- 故障转移超时时间为 10 秒

### 4. 数据持久化

- 主节点使用 RDB + AOF 持久化
- 从节点自动同步主节点数据
- 数据目录：`/data`

## 连接示例

### 通过哨兵连接

```bash
# 获取主节点地址
docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name redis-master

# 连接主节点
docker exec redis-master redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n ping
```

### 直接连接

```bash
# 连接主节点
docker exec redis-master redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n

# 连接从节点
docker exec redis-slave1 redis-cli --no-auth-warning -a CG1rMeyRryFgvElf8n

# 连接哨兵
docker exec redis-sentinel1 redis-cli -p 26379
```

## 监控命令

### 查看主节点信息

```bash
docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL masters
```

### 查看从节点信息

```bash
docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL slaves redis-master
```

### 查看哨兵信息

```bash
docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels redis-master
```

## 故障排除

### 常见问题

1. **哨兵节点间通信问题**
   - 检查网络配置
   - 确认容器间网络连通性

2. **主从同步失败**
   - 检查密码配置
   - 查看从节点日志

3. **故障转移失败**
   - 确认哨兵节点数量（至少 2 个）
   - 检查法定人数配置

### 日志查看

```bash
# 查看主节点日志
docker logs redis-master

# 查看从节点日志
docker logs redis-slave1

# 查看哨兵日志
docker logs redis-sentinel1
```

## 性能优化

### 内存配置

- 根据实际需求调整 `maxmemory` 配置
- 使用适当的内存淘汰策略

### 网络优化

- 调整 `tcp-keepalive` 配置
- 优化网络缓冲区设置

### 持久化优化

- 根据数据重要性调整持久化策略
- 监控 AOF 文件大小

## 安全建议

1. **修改默认密码**：生产环境必须修改默认密码
2. **网络隔离**：使用 Docker 网络隔离 Redis 服务
3. **访问控制**：限制 Redis 服务的访问权限
4. **监控告警**：设置 Redis 服务监控和告警

## 版本信息

- **Redis 版本**: 5.0.14
- **哨兵版本**: 5.0.14
- **Docker 镜像**: zhaopan/redis:5

---

更多详细信息请参考 [Redis 官方文档](https://redis.io/documentation) 和 [Redis Sentinel 文档](https://redis.io/topics/sentinel)。
