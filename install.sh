#!/bin/bash -e

##
## install
##

echo "build ..."
docker-compose up -d --build
echo "build and run is okay"
