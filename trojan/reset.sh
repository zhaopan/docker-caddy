#!/bin/bash
# Trojan 密码与域名重置工具

set -e

CADDYFILE="caddy/Caddyfile"
PROXY_CONFIG_DIR="../caddy/conf.d"
ENV_FILE="../.env"

# 1. 加载 .env 变量 (如果存在)
if [ -f "$ENV_FILE" ]; then
    # 使用 grep 和 sed 提取变量，避免直接 source 可能带来的兼容性问题
    ENV_DOMAIN=$(grep "^TROJAN_SERVICE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    ENV_PASS=$(grep "^TROJAN_PASS=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
fi

# 2. 确定域名 (优先级: 命令行参数 > .env > 当前配置 > 默认值)
CURRENT_DOMAIN=$(grep "service_name" "$CADDYFILE" | awk -F'"' '{print $2}' || echo "")
DOMAIN=${1:-$ENV_DOMAIN}
DOMAIN=${DOMAIN:-$CURRENT_DOMAIN}
DOMAIN=${DOMAIN:-"trojan.dev.com"}

# 3. 确定密码 (优先级: .env > 随机生成)
NEW_PASS=${ENV_PASS:-$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)}

echo "===> 重置 Trojan 配置 <==="
echo "域名: $DOMAIN"
echo "密码: $NEW_PASS"

# 4. 修改 trojan/caddy/Caddyfile
if [ -f "$CADDYFILE" ]; then
    sed -i "s|users .*|users $NEW_PASS|g" "$CADDYFILE"
    sed -i "s|service_name \".*\"|service_name \"$DOMAIN\"|g" "$CADDYFILE"
    echo "[OK] 已更新 $CADDYFILE"
else
    echo "[ERR] 未找到 $CADDYFILE"
    exit 1
fi

# 5. 修改主 Proxy 配置
# 查找现有的 trojan 配置文件（匹配包含 trojan 的 .caddy 文件）
OLD_PROXY_CONFIG=$(ls $PROXY_CONFIG_DIR/trojan*.caddy 2>/dev/null | head -n 1 || echo "")
NEW_PROXY_CONFIG="$PROXY_CONFIG_DIR/trojan.${DOMAIN}.caddy"

if [ -n "$OLD_PROXY_CONFIG" ]; then
    # 修改文件内的域名
    sed -i "1s|.*{|${DOMAIN} {|" "$OLD_PROXY_CONFIG"
    
    # 如果域名发生变化，重命名配置文件
    if [ "$OLD_PROXY_CONFIG" != "$NEW_PROXY_CONFIG" ]; then
        mv "$OLD_PROXY_CONFIG" "$NEW_PROXY_CONFIG"
        echo "[OK] 已重命名 Proxy 配置为: $(basename $NEW_PROXY_CONFIG)"
    else
        echo "[OK] 已更新 Proxy 站点配置内容"
    fi
else
    echo "[WARN] 未在 $PROXY_CONFIG_DIR 中找到 trojan 相关的站点配置"
fi

# 6. 回写 .env (保持同步)
if [ -f "$ENV_FILE" ]; then
    sed -i "s|^TROJAN_SERVICE=.*|TROJAN_SERVICE=\"$DOMAIN\"|" "$ENV_FILE"
    sed -i "s|^TROJAN_PASS=.*|TROJAN_PASS=\"$NEW_PASS\"|" "$ENV_FILE"
    echo "[OK] 已同步更新 .env 文件"
fi

echo "========================"
echo "重置完成！请运行 'make reload' 或 'make restart trojan' 使其生效。"
