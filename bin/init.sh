#!/usr/bin/env bash

set -euo pipefail
SECRET_LEN=16

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_utils.sh"

# 1. Initialize Data Directories
log_header "Initialize Data Directories"
DIRS=(
    "./data"
    "./data/redis"
    "./data/mysql"
    "./data/ollama"
    "./data/postgres"
    "./data/openclaw"
    "./data/www"
    "./data/webdav"
    "./data/frp/logs"
    "${CADDY_ROOT:-./data/caddy}/data"
    "${CADDY_ROOT:-./data/caddy}/config"
    "${CADDY_ROOT:-./data/caddy}/logs"
    "${N8N_PATH:-./data/n8n}"
    "${N8N_PATH:-./data/n8n}/userfiles"
    "${TROJAN_PATH:-./data/trojan}"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        log_info "Creating directory: $dir"
        mkdir -p "$dir"

        # Special handling for base data directory
        if [[ "$dir" == "data" || "$dir" == "./data" ]]; then
            chmod -R +w "$dir"
        fi

        # n8n specific permissions
        if [[ "$dir" == *"/n8n"* ]]; then
            # Set ownership for n8n's node user (UID 1000)
            if command -v chown >/dev/null 2>&1; then
                chown -R 1000:1000 "$dir" 2>/dev/null || true
            fi

            # Specific permissions for userfiles
            if [[ "$dir" == *"userfiles"* ]]; then
                chmod -R 775 "$dir"
            else
                chmod -R 777 "$dir"
            fi
        fi
    fi
done
log_success "All required data directories initialized."

# 2. Initialize Network
log_header "Initialize Docker Network"
if docker network inspect backend >/dev/null 2>&1; then
    log_info "Docker network 'backend' already exists, skipping creation."
else
    log_info "Creating Docker network 'backend'..."
    if docker network create --subnet=172.18.0.0/16 --gateway=172.18.0.1 --ip-range 172.18.1.0/24 backend >/dev/null; then
        log_success "Docker network created successfully."
    else
        log_error "Failed to create Docker network."
        exit 1
    fi
fi

# 3. Initialize Configuration
log_header "Initialize Configuration"
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        log_success "Created .env from .env.example."
    else
        log_error ".env.example file not found, cannot create configuration."
        exit 1
    fi
else
    log_info ".env file already exists, skipping creation."
fi

# 4. Security Configuration (Update Default Passwords)
log_header "Security Check"
KEYWORDS="PASS|PWD|SECRET|TOKEN|KEY|JWT"

# Find variables that need updating (contain keywords and have default or empty values)
targets=$(grep -iE "$KEYWORDS" .env | grep -E "123456|=\"\"|=''|=$" | cut -d= -f1 | sed 's/export //;s/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u || true)

if [ -n "$targets" ]; then
    log_info "Default password configuration found, updating..."

    # Backup .env
    BACKUP=".env.bak.$(date +%s)"
    cp .env "$BACKUP"
    log_success "Backed up current configuration to $BACKUP"

    for var in $targets; do
        # Generate random password
        new_secret=$(set +o pipefail; LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c "$SECRET_LEN")
        # Use a more robust sed regex to preserve the prefix (including export and spaces)
        sed -i "s/^\([[:space:]]*\(export[[:space:]]*\)\?$var[[:space:]]*=[[:space:]]*\)[^#]*/\1\"$new_secret\"/" .env
        log_info "Updated variable: $var"
    done
    log_success "All default passwords updated to random secure passwords."
else
    log_success "No default passwords found, security check passed."
fi

printf "\n${GREEN}===> Initialization Complete! <===${NC}\n"
