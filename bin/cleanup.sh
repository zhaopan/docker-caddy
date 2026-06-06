#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_utils.sh"

log_header "Cleaning up Project Environment"

# 1. Stop and remove containers and volumes
if [ -f "docker-compose.yml" ]; then
    log_info "Stopping and removing containers and volumes..."
    docker compose down --remove-orphans -v 2>/dev/null || true
    log_success "Containers and volumes removed."
fi

# 2. Remove Network
if docker network inspect backend >/dev/null 2>&1; then
    log_info "Removing network 'backend'..."
    docker network rm backend
    log_success "Network 'backend' removed."
fi

# 3. Cleanup temporary files
log_info "Cleaning up temporary files..."
rm -rf redis/generated
log_success "Temporary files removed."

# 4. 清理日志
find ./data/caddy/logs -type f -name "*.log" -exec sh -c '> "{}"' \;

printf "\n${GREEN}===> Cleanup Complete! <===${NC}\n"
