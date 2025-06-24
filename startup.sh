#!/bin/bash -e

##
## startup
##

echo "stop... "
docker-compose stop
echo "stop is okay"

echo "startup..."
docker-compose up -d
echo "startup is okay"
