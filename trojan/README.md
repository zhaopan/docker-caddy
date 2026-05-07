# Trojan 服务模块

基于 Caddy v2.11+ 和 `caddy-trojan` 插件的高性能代理方案，采用 gRPC 传输协议并由主网关统一进行 TLS 卸载。

## 🚀 快速开始

### 1. 初始化与启动
确保你已经完成了项目的全局初始化（`make init`），然后运行：
```bash
make up trojan
```

### 2. 自动化配置（推荐）
你可以使用内置的重置工具一键配置密码和域名：
```bash
# 自动生成随机密码，并设置域名
make trojan-reset DOMAIN=your.domain.com
```
*该操作会自动同步修改 Trojan 核心配置与主 Proxy 的路由配置。*

### 3. 使配置生效
修改配置后，请运行：
```bash
make reload
```

## 🛠️ 管理指令

| 命令 | 说明 |
| :--- | :--- |
| `make up trojan` | 启动/更新 Trojan 服务 |
| `make trojan-reset` | 一键重置密码与域名 (支持 `DOMAIN=...` 参数) |
| `make logs trojan` | 查看实时访问日志 |
| `make status trojan` | 查看容器运行状态 |
| `make fmt` | 格式化 Caddy 配置文件 |

## 📁 目录结构

- `caddy/`：Trojan 专用的 Caddy 配置与环境。
- `reset.sh`：自动化配置脚本。
- `Dockerfile`：集成 `caddy-trojan` 插件的自构建镜像。

## 📱 客户端连接指引 (gRPC)

推荐使用支持 gRPC 的客户端（如 v2rayN, Clash Meta, Shadowrocket 等）：

- **服务器地址**: `your.domain.com`
- **端口**: `443`
- **UUID/密码**: `make trojan-reset 输出生成的密码`
- **传输协议**: `grpc`
- **gRPC 服务名**: `your.domain.com`
- **TLS**: `开启 (True)`
- **SNI**: `your.domain.com`

---
*注意：本模块依赖 `backend` 外部网络，请确保已运行过全局 `make up`。*
