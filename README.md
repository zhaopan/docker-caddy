# Docker Caddy 现代化开发脚手架

基于 Docker Compose 的高度模块化开发与生产环境，集成了 Caddy v2.10+、Redis 高可用、gRPC 支持及 Trojan 代理协议。

## 核心架构

- **多模式适配**：支持 Standard (单机)、Redis-HA (高可用) 及 Full-Cluster (网关集群) 三种运行模式。
- **自动化管理**：通过统一的 Makefile 实现环境初始化、服务启停、配置热加载及密码重置。
- **隔离性设计**：各服务组件（MySQL, Redis, Trojan, n8n）均以独立容器运行，通过外部网桥隔离。
- **安全保障**：内置自动密码生成工具，所有敏感配置均通过环境变量管理。

## 运行模式说明

| 模式 | 启动命令 | 适用场景 |
| :--- | :--- | :--- |
| **Standard** | `make up` | 基础开发环境，单节点 Caddy + 单节点 Redis |
| **Redis-HA** | `make up MODE=redis-ha` | 数据库增强模式，1主2从3哨兵架构 |
| **Full-Cluster** | `make up MODE=cluster` | 全栈集群，多节点 Caddy 负载均衡 + Redis HA |

## 快速开始

### 1. 环境准备
```bash
git clone <repository-url>
cd docker-caddy
cp .env.example .env  # 基础环境变量配置
```

### 2. 初始化环境
运行初始化脚本以创建 Docker 网络并生成随机安全密码：
```bash
make init
```

### 3. 启动服务
```bash
make up
```

## 常用管理指令

### 全局操作
- `make status` : 查看所有服务运行状态与资源占用。
- `make reload` : 在不重启容器的情况下热加载 Caddy 配置文件。
- `make down` : 停止并移除所有容器及网络。
- `make clean` : 彻底清理所有持久化数据（慎用）。

### 服务专用初始化
- `make frp-install` : 初始化 FRP (frps/frpc) 配置文件。
- `make frp-reset` : 重新生成 FRP 安全令牌与管理密码。
- `make trojan-reset` : 一键重置 Trojan 代理密码与服务域名。

### 单项服务管理
- `make up [service]` : 仅启动特定服务 (如 `make up trojan`)。
- `make logs [service]` : 查看特定服务的实时日志 (如 `make logs caddy`)。
- `make fmt` : 自动格式化所有 Caddy 配置文件。

## 项目结构导航

- `caddy/` : 主网关配置，包含 `conf.d/` 站点目录。
- `trojan/` : Trojan-gRPC 代理模块。
- `frp/` : 内网穿透组件。
- `n8n/` : 自动化工作流引擎。
- `data/` : 持久化数据存储目录（MySQL, Redis, Mongo, Postgres）。

## 开发注意事项

1. **Hosts 映射**：本地访问需在 `C:\Windows\System32\drivers\etc\hosts` 中添加：
   ```text
   127.0.0.1 dev.com www.dev.com admin.dev.com api.dev.com trojan.dev.com
   ```
2. **网络依赖**：项目依赖名为 `backend` 的外部网桥（172.18.0.0/16），由 `make init` 自动创建。
3. **配置文件**：站点配置应放置在 `caddy/conf.d/` 下，且必须以 `.caddy` 为后缀。

## 开源协议

MIT License.
