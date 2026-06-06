#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_utils.sh"

log_header "Preparing Redis Sentinel Configurations"

# Start redis master and get its IP
docker compose -f docker-compose.yml up -d redis

MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis 2>/dev/null || echo "")

if [ -z "$MASTER_IP" ]; then
    log_error "Failed to detect Redis master IP"
    exit 1
fi
log_info "Detected Master IP: $MASTER_IP"

# Extract REDIS_PASSWORD from .env (handles quoted and unquoted values)
REDIS_PASS=$(grep '^REDIS_PASSWORD=' .env 2>/dev/null | sed -E 's/^REDIS_PASSWORD=["'\''\"]?([^"'\''\"]+)["'\''\"]?.*/\1/' || echo "")

if [ -z "$REDIS_PASS" ]; then
    log_error "Failed to extract REDIS_PASSWORD from .env"
    exit 1
fi

mkdir -p redis/generated

# Generate sentinel configs
for i in 1 2 3; do
    sed -e "s/REDIS_MASTER_IP/$MASTER_IP/g" \
        -e "s/REDIS_PASSWORD/$REDIS_PASS/g" \
        redis/sentinel.conf.template > "redis/generated/sentinel${i}.conf"
    log_info "Generated sentinel${i}.conf"
done

# Generate slave config
sed -e "s/REDIS_MASTER_IP/$MASTER_IP/g" \
    -e "s/REDIS_PASSWORD/$REDIS_PASS/g" \
    redis/redis-slave.conf.template > redis/generated/redis-slave.conf
log_info "Generated redis-slave.conf"

log_success "Sentinel configurations prepared"
