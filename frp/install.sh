#!/bin/bash -e

if [ -f frpd.lock ]
then
    echo 'frpd is installed, please config !!!'
else
    mkdir -p ../data/frp/logs/
    touch ../data/frp/logs/frps.log ../data/frp/logs/frpc.log

    cp -rf frps/frps.toml.example frps/frps.toml
    cp -rf frpc/frpc.toml.example frpc/frpc.toml

    touch frpd.lock

    echo 'Waiting for password reset...'

    chmod +x resetpwd.sh

    bash resetpwd.sh
fi
