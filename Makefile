# Docker Caddy Management Tool (Robust Version)
# Usage: make <cmd> [service] [MODE=standard|redis-ha|cluster]

MODE ?= standard
DOCKER_COMPOSE = docker-compose

# Compose File Combinations based on MODE
ifeq ($(MODE),standard)
    COMPOSE_FILES = -f docker-compose.yml

else ifeq ($(MODE),redis-ha)
    COMPOSE_FILES = -f docker-compose.yml -f docker-compose.redis-ha.yml
    export DATA_SUBDIR = redis-ha
else ifeq ($(MODE),cluster)
    COMPOSE_FILES = -f docker-compose.yml -f docker-compose.redis-ha.yml -f docker-compose.cluster.yml
    export DATA_SUBDIR = cluster
endif

# --- Service & Command Definition ---
CMD_LIST := up stop restart status st logs down help init prepare-sentinel clean reload rebuild
# Define valid services for validation (including aliases)
VALID_SERVICES := proxy caddy redis mysql mongo grpc n8n postgres redis-slave1 redis-slave2 redis-sentinel1 redis-sentinel2 redis-sentinel3

# Extract words that are not commands or mode assignments
RAW_GOALS := $(filter-out $(CMD_LIST) MODE=%,$(MAKECMDGOALS))

# Validate services and define aliases
ifeq ($(RAW_GOALS),caddy)
    SERVICE := proxy
else ifneq ($(filter $(RAW_GOALS),$(VALID_SERVICES)),)
    SERVICE := $(RAW_GOALS)
else ifneq ($(RAW_GOALS),)
    # If it's not a known service and not empty, it might be a typo'd command (like 'dwon')
    # We DON'T define a phony target here, so Make will naturally error out
endif

# If the goal is a recognized service, we define a dummy target to suppress "nothing to be done"
ifneq ($(SERVICE),)
.PHONY: $(RAW_GOALS)
$(RAW_GOALS):
	@:
endif

.PHONY: $(CMD_LIST)

help:
	@echo "Docker Caddy Management CLI"
	@echo ""
	@echo "Current Mode: $(MODE)"
	@echo "Available Modes: standard, redis-ha, cluster"
	@echo ""
	@echo "Usage:"
	@echo "  make up [service]      Start services"
	@echo "  make stop [service]    Stop services"
	@echo "  make restart [service] Restart services"
	@echo "  make rebuild [service] Rebuild and restart service"
	@echo "  make status [service]  Show status (alias: st)"
	@echo "  make logs [service]    Tail logs"
	@echo "  make reload            Reload proxy config"
	@echo "  make down              Remove project"
	@echo "  make clean             Cleanup project (remove all data/containers)"

	@echo ""

init:
	@sh bin/init.sh

prepare-sentinel:
	@if [ "$(MODE)" != "standard" ] && [ -z "$(SERVICE)" ]; then \
		echo "Preparing Redis Sentinel configurations..."; \
		$(DOCKER_COMPOSE) $(COMPOSE_FILES) up -d redis; \
		MASTER_IP=$$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master); \
		echo "Detected Master IP: $$MASTER_IP"; \
		REDIS_PASS=$$(grep REDIS_PASSWORD .env | cut -d '=' -f2); \
		mkdir -p redis/generated; \
		for i in 1 2 3; do \
			sed -e "s/REDIS_MASTER_IP/$$MASTER_IP/g" -e "s/REDIS_PASSWORD/$$REDIS_PASS/g" redis/sentinel.conf.template > redis/generated/sentinel$$i.conf; \
		done; \
		sed -e "s/REDIS_MASTER_IP/$$MASTER_IP/g" -e "s/REDIS_PASSWORD/$$REDIS_PASS/g" redis/redis-slave.conf.template > redis/generated/redis-slave.conf; \
	fi

up: init
	@$(MAKE) prepare-sentinel --no-print-directory
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) up -d $(SERVICE)

stop:
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) stop $(SERVICE)

restart:
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) restart $(SERVICE)

status:
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) ps $(SERVICE)

st: status

logs:
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) logs -f --tail 100 $(SERVICE)

down:
	@if [ -z "$(SERVICE)" ]; then \
		$(DOCKER_COMPOSE) $(COMPOSE_FILES) down; \
	else \
		$(DOCKER_COMPOSE) $(COMPOSE_FILES) stop $(SERVICE) && $(DOCKER_COMPOSE) $(COMPOSE_FILES) rm -f $(SERVICE); \
	fi

clean:
	@sh bin/cleanup.sh

reload:
ifeq ($(MODE),cluster)
	@echo "Reloading Cluster (Proxy + Workers)..."
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) exec -w /etc/caddy proxy caddy reload
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) exec -w /etc/caddy proxy-worker1 caddy reload
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) exec -w /etc/caddy proxy-worker2 caddy reload
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) exec -w /etc/caddy proxy-worker3 caddy reload
else
	@echo "Reloading Proxy..."
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) exec -w /etc/caddy proxy caddy reload
endif

rebuild:
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) build --no-cache $(SERVICE)
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) up -d --force-recreate $(SERVICE)
