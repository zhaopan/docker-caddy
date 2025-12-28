#!/bin/bash

set -euo pipefail
SECRET_LEN=16

# Color
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

# 1. Initialize data directory
log_header "Initialize Data Directory"
if [ -d "data" ]; then
    log_info "Data directory 'data' already exists, skipping creation."
else
    log_info "Creating data directory 'data'..."
    mkdir -p data
    chmod -R +w data
    log_success "Data directory created successfully."
fi

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

    SED_CMD_FILE=$(mktemp)
    for var in $targets; do
        # Generate random password
        new_secret=$(set +o pipefail; LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c "$SECRET_LEN")
        echo "s|^\([[:space:]]*\(export[[:space:]]*\)\?$var[[:space:]]*=[[:space:]]*\)[^#]*|\1\"$new_secret\"|g" >> "$SED_CMD_FILE"
        log_info "Updated variable: $var"
    done

    # Execute replacement
    sed -i -f "$SED_CMD_FILE" .env
    rm -f "$SED_CMD_FILE"
    log_success "All default passwords updated to random secure passwords."
else
    log_success "No default passwords found, security check passed."
fi

printf "\n${GREEN}===> Initialization Complete! <===${NC}\n"

