#!/usr/bin/env bash
set -euo pipefail

# 颜色定义
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

printf "${BLUE}===> Cleaning up Project Environment <===${NC}\n"

# 1. 停止并移除容器和卷
if [ -f "docker-compose.yml" ]; then
    printf "${YELLOW}Stopping and removing containers and volumes...${NC}\n"
    # 使用 -v 参数删除项目关联的 Volumes
    if docker compose version >/dev/null 2>&1; then
        docker compose down --remove-orphans -v
    else
        docker-compose down --remove-orphans -v
    fi
fi

# # 2. 移除网络
# if docker network inspect backend >/dev/null 2>&1; then
#     printf "${YELLOW}Removing network 'backend'...${NC}\n"
#     docker network rm backend
# fi

# # 3. 清理临时文件和数据
# printf "${YELLOW}Cleaning up temporary files and data...${NC}\n"
# rm -rf redis/generated

# # 4. 清理 Docker 资源 (镜像与卷)
# printf "${YELLOW}Cleaning unused Docker resources...${NC}\n"
# docker system prune -f
# docker volume prune -f

# 询问是否删除持久化数据
# if [ -d "data" ]; then
#     printf "${RED}Warning: Found 'data' directory. Do you want to delete it? [y/N] ${NC}"
#     read -r response
#     if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
#         printf "${YELLOW}Removing data directory...${NC}\n"
#         rm -rf data
#     else
#         printf "${BLUE}Skipping data removal.${NC}\n"
#     fi
# fi

printf "${GREEN}[DONE] Cleanup Complete!${NC}\n"
