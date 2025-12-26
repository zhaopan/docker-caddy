#!/bin/bash

# 初始化数据文件
echo "初始化 data 目录..."

if [ -d "data" ]; then
    echo "数据目录 'data' 已存在。"
else
    echo "创建数据目录..."
    mkdir -p data
    chmod -R +w data
fi

# 初始化网络
echo "初始化 Docker 网络..."

# 检查网络是否存在
if docker network inspect backend >/dev/null 2>&1; then
    echo "网络 'backend' 已存在，跳过创建。"
else
    echo "创建网络 backend..."
    docker network create --subnet=172.18.0.0/16 --gateway=172.18.0.1 --ip-range 172.18.1.0/24 backend
fi

echo "初始化完成！"
