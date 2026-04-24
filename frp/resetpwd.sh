#!/bin/bash -e

if [ -f frps/frps.toml ] && [ -f frpc/frpc.toml ]
then
    TOKEN=$(openssl rand -base64 18)
    DASHBOARD=$(openssl rand -base64 24)

    # 修改服务端TOKEN
    sed -i "s|^auth.token = .*|auth.token = \"${TOKEN}\"|" frps/frps.toml

    # 修改客户端TOKEN
    sed -i "s|^auth.token = .*|auth.token = \"${TOKEN}\"|" frpc/frpc.toml

    # 修改管理密码
    sed -i "s|^webServer.password = .*|webServer.password = \"${DASHBOARD}\"|" frps/frps.toml

    # 修改根目录 .env
    if [ -f ../.env ]; then
        sed -i "s|^FRP_TOKEN=.*|FRP_TOKEN=\"${TOKEN}\"|" ../.env
        sed -i "s|^FRP_DASHBOARD_PWD=.*|FRP_DASHBOARD_PWD=\"${DASHBOARD}\"|" ../.env
    fi

    echo "TOKEN: ${TOKEN}"
    echo "DASHBOARD: ${DASHBOARD}"
    echo 'reset password done !!!'

else
    echo 'FRP configuration files (frps.toml/frpc.toml) not found. Please run init.sh first.'
    exit 1
fi
