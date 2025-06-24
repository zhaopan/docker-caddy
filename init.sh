#!/bin/bash -e

# 初始化数据文件

mkdir data
chmod -R +w data

# 初始化网络

docker network rm backend

# 核心：subnet 将网络的总子网范围设置为 172.18.0.0/16
# 这个范围包含 172.18.0.0 到 172.18.255.255

# 网络的网关，gateway 通常是子网的第一个可用IP 172.18.0.1

# 核心：ip_range 进一步限制自动分配的 IP 地址池。
# 设置为 172.18.1.0/24 意味着 Docker 将从 172.18.1.0 开始分配 IP，直到 172.18.255.255。
# 这样，整个 172.18.0.* 子网（包括 172.18.0.1 到 172.18.0.255）都将不会被 Docker 自动分配给容器。
docker network create --subnet=172.18.0.0/16 --gateway=172.18.0.1 --ip-range 172.18.1.0/24 backend
