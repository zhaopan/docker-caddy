VERSION = $(shell git describe --always --tags)
IMAGE = docker-caddy
BINARY = docker-caddy

build:
	docker-compose build
up:
	docker-compose up -d
down:
	docker-compose down
clean:
	rm -rf $(BINARY)
	docker rmi -f $(shell docker images -f "dangling=true" -q) 2> /dev/null; true
	docker rmi -f $(IMAGE):latest $(IMAGE):$(VERSION) 2> /dev/null; true
