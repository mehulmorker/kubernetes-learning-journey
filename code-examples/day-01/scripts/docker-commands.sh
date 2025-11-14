#!/bin/bash
# Common Docker commands for practice

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List images
docker images

# Get shell inside container
docker exec -it my-app sh

# Detailed container info
docker inspect my-app

# View container logs
docker logs my-app

# Follow container logs
docker logs -f my-app

