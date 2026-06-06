#!/usr/bin/env bash
# 公共工具函数库，供 bin/ 下其他脚本 source 使用

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
