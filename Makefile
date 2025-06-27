build:
	docker-compose down
	docker-compose up -d --build
up:
	docker-compose up -d
down:
	docker-compose down
stop:
	docker-compose stop
