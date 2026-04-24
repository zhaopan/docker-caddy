# FRP 服务组件

本项目集成了 FRP (Fast Reverse Proxy) 服务，用于实现内网穿透和反向代理。已适配最新的 TOML 配置格式。

## 快速开始

### 1. 初始化安装
在项目根目录下，进入 `frp` 目录并执行安装脚本：
```bash
cd frp
chmod +x install.sh
sh install.sh
```
该脚本会自动从 `.example` 模板创建配置文件。

### 2. 重置密码与 Token
如果您需要更新身份验证 Token 或管理面板密码，可以运行：
```bash
sh resetpwd.sh
```
**注意**：该脚本会自动生成高强度随机字符串，并同步更新到根目录的 `.env` 文件中。

### 3. 启动服务
在项目根目录下运行：
```bash
# 启动服务端
docker compose up -d frps

# 启动客户端
docker compose up -d frpc
```

## Docker Compose 配置

FRP 服务已集成在根目录的 `docker-compose.yml` 中。主要配置项如下：

### FRPS (服务端)
- **监听端口**: `6500` (对应容器内 `7000` TCP/UDP)
- **打洞端口**: `6502` (对应容器内 `7001` UDP)
- **管理面板**: `6501` (对应容器内 `7500` TCP)
- **HTTP/HTTPS**: `6503/6504` (对应容器内 `80/443`)

### FRPC (客户端)
- 默认连接到本项目部署的 FRPS。
- 配置文件路径通过 `.env` 中的 `FRPC_CONFIG_PATH` 指定。

## 配置文件说明

所有配置文件均采用 **TOML** 格式，并带有详细的中文注释。

- **[frps.toml.example](frps/frps.toml.example)**: 服务端完整参考配置。
- **[frpc.toml.example](frpc/frpc.toml.example)**: 客户端参考配置。

### 关键字段
- `auth.token`: 客户端与服务端连接的身份凭证。
- `webServer.password`: FRPS 仪表板的登录密码。

## 外部客户端连接示例 (TOML)

如果您想在其他设备（如 Windows/Linux 宿主机）上运行 frpc 连接到此服务器，请参考以下配置：

```toml
# frpc.toml
serverAddr = "您的服务器公网IP"
serverPort = 6500
auth.token = "从 .env 文件中获取的 FRP_TOKEN"

[[proxies]]
name = "web-test"
type = "http"
localIP = "127.0.0.1"
localPort = 8080
customDomains = ["test.yourdomain.com"]
```

## 常用管理命令

```bash
# 查看日志
docker compose logs -f frps
docker compose logs -f frpc

# 重启服务
docker compose restart frps frpc
```

## Caddy 反向代理配置

如果您希望通过 80/443 端口访问 FRP 穿透的服务或管理面板，建议使用 Caddy 作为前置代理。

### 1. 配置说明
项目在 `caddy/conf.d/` 目录下提供了配置文件：
- **[frp.dev.com.caddy](../caddy/conf.d/frp.dev.com.caddy)**: 包含 Dashboard 面板代理及泛域名转发配置。

### 2. 使用方法
1. 修改 `caddy/conf.d/frp.dev.com.caddy` 中的域名为您的实际域名。
2. 运行 `docker compose restart proxy` 重新加载配置。

**注意**：泛域名（如 `*.frp.dev.com`）的自动 SSL 申请通常需要配置 DNS Challenge 插件。如果没有配置，建议仅在 HTTP 模式下使用或为特定子域名单独配置。

## Windows 客户端 (frpc) 设置

在 Windows 上运行 frpc，您需要下载 [FRP 官方发布包](https://github.com/fatedier/frp/releases)。

### 1. 配置文件 (frpc.toml)

创建一个 `frpc.toml` 文件，内容示例：

```toml
serverAddr = "您的服务器公网IP"
serverPort = 6500
auth.token = "从服务器 .env 获取的 FRP_TOKEN"

[[proxies]]
name = "win-rdp"
type = "tcp"
localIP = "127.0.0.1"
localPort = 3389
remotePort = 3505
```

### 2. 设置为系统服务 (推荐)
为了让 frpc 在开机时自动后台运行，建议使用 **nssm**。

- 下载并解压 [nssm](https://nssm.cc/download)。
- 以管理员权限打开命令行，执行：
  ```cmd
  nssm install frpc
  ```
- 在弹出的窗口中：
  - **Path**: 选择 `frpc.exe` 的路径。
  - **Startup directory**: 选择 `frpc.exe` 所在目录。
  - **Arguments**: 输入 `-c frpc.toml`。
- 点击 "Install service"。

### 3. 手动启动脚本

如果您不想安装服务，可以创建一个 `start_frpc.bat`：

```batch
@echo off
:loop
frpc.exe -c frpc.toml
echo frpc 意外退出，10秒后重启...
timeout /t 10
goto loop
```
