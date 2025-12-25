# Docker Caddy 现代化开发脚手架

基于 Docker Compose 的模块化开发环境，支持 **Standard (单机)**, **Redis-HA (高可用)** 和 **Full-Cluster (全栈集群)** 三种模式。

## 核心特性

- **身份适配叠加架构**：一个基础配置，通过插件化叠加实现功能增强。
- **单命令统一管理**：通过 `Makefile` 极简控制（支持 `make up redis` 或 `make up MODE=cluster`）。
- **智能数据管理**：通用服务（MySQL, Mongo 等）跨模式共享数据，Redis HA 模式独立隔离。
- **全链路高可用**：支持 Caddy 多节点集群负载均衡及 Redis 哨兵集群。

## 快速开始

### 1. 环境准备

```bash
# 1. 克隆项目
git clone <repository-url>
cd docker-caddy

# 2. 准备环境变量
cp .env.example .env
# 编辑 .env 以配置密码和域名
```

### 2. 选择模式运行

本项目支持三种运行模式，默认为 `standard`。

| 模式 | 命令 | 说明 |
| :--- | :--- | :--- |
| **Standard (推荐开发)** | `make up` | 单节点 Caddy + 单节点 Redis，最省资源。 |
| **Redis-HA (数据库增强)** | `make up MODE=redis-ha` | 将 Redis 升级为 1主2从3哨兵。 |
| **Full-Cluster (全栈集群)** | `make up MODE=cluster` | 在 Redis-HA 基础上增加 3个 Caddy Worker 实现负载均衡。 |

## 键盘侠指南 (常用命令)

### 全局操作
- `make up` : 启动当前模式下的所有服务。
- `make logs` : 查看所有服务日志。
- `make status` : 查看当前模式下的容器状态。
- `make down` : **停止并摧毁** 当前模式下的所有资源。
- `make clean` : **深度清理** 移除容器、网络及持久化数据（需确认）。
- `make reload` : **热加载** 刷新 Caddy 配置（自动适配集群模式，无需重启）。
- `make rebuild [service]` : **强制重构** 不使用缓存重新构建并重启服务。

### 单个服务操作 (无需参数名)
- `make up redis` : 仅启动/更新 Redis。
- `make logs n8n` : 仅查看 n8n 日志。
- `make restart mysql` : 重启 MySQL。
- `make stop caddy` : 停止 Caddy。

## 项目结构

```txt
docker-caddy/
├── docker-compose.yml          # [核心] 基础包，所有模式的基座
├── docker-compose.redis-ha.yml # [插件] Redis 高可用增强包
├── docker-compose.cluster.yml  # [插件] Caddy 集群增强包
├── Makefile                    # [遥控] 统一管理入口
├── .env                        # [私密] 端口、版本、密码配置
│
├── bin/                        # [脚本] 初始化与清理脚本
├── caddy/                      # Caddy 自定义构建与站点配置
├── mysql/                      # MySQL 配置
├── redis/                      # Redis 配置定义
├── n8n/                        # n8n 工作流相关逻辑
│
└── data/                       # 宿主机持久化数据
    ├── mysql/                  # MySQL 数据 (共享)
    ├── mongo/                  # MongoDB 数据 (共享)
    ├── redis/                  # Redis 单机数据
    ├── redis-ha/               # Redis HA 集群数据 (隔离)
    └── cluster/                # Caddy 集群数据 (隔离)
```

## 注意事项

1. **网络自动创建**：第一次运行 `make up` 时，会自动创建一个名为 `backend` 的外部网桥（172.18.0.0/16）。
2. **模式切换**：如果您想从 `standard` 切换到 `cluster`，建议先执行 `make down` 清理旧容器，以防止容器名或端口冲突。
3. **数据策略**：MySQL/Mongo/Postgres 等服务在所有模式下共享数据 (`./data/service_name`)；Redis 在 Standard 模式下使用 `./data/redis`，在 HA/Cluster 模式下使用 `./data/redis-ha/` 以避免冲突。

## 开源协议

MIT License.
