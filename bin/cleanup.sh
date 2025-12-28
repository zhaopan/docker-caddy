#!/usr/bin/env bash
set -euo pipefail

# Color Definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging helper functions
log_header() {
    printf "\n${BLUE}===> $1 <===${NC}\n"
}

log_info() {
    printf "${NC}   [INFO] $1${NC}\n"
}

log_success() {
    printf "${GREEN}   [OK]   $1${NC}\n"
}

log_warn() {
    printf "${YELLOW}   [WARN] $1${NC}\n"
}

log_error() {
    printf "${RED}   [ERR]  $1${NC}\n"
}

log_header "Cleaning up Project Environment"

# 1. Stop and remove containers and volumes
if [ -f "docker-compose.yml" ]; then
    log_info "Stopping and removing containers and volumes..."
    # Use -v to remove volumes associated with the project
    if docker compose version >/dev/null 2>&1; then
        docker compose down --remove-orphans -v
    else
        docker-compose down --remove-orphans -v
    fi
    log_success "Containers and volumes removed."
fi

# 2. Remove Network
# if docker network inspect backend >/dev/null 2>&1; then
#     log_info "Removing network 'backend'..."
#     docker network rm backend
#     log_success "Network 'backend' removed."
# fi

# 3. Cleanup temporary files
# log_info "Cleaning up temporary files and data..."
# rm -rf redis/generated
# log_success "Temporary files removed."

# 4. Prune Docker Resources
# log_info "Cleaning unused Docker resources..."
# docker system prune -f
# docker volume prune -f

# 5. Delete persistent data
# if [ -d "data" ]; then
#     printf "${RED}   [WARN] Found 'data' directory. Do you want to delete it? [y/N] ${NC}"
#     read -r response
#     if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
#         log_info "Removing data directory..."
#         rm -rf data
#         log_success "Data directory removed."
#     else
#         log_info "Skipping data removal."
#     fi
# fi

printf "\n${GREEN}===> Cleanup Complete! <===${NC}\n"

