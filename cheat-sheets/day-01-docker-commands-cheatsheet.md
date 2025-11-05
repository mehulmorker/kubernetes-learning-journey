# Docker Command Cheat Sheet

## Verify Installation
```bash
docker --version
docker info
```

## Run Test Container
```bash
docker run hello-world
```

## Build and Manage Images
```bash
docker build -t <image-name>:<tag> .
docker images
docker rmi <image-id>
```

## Run Containers
```bash
docker run -d -p 3000:3000 --name my-app <image-name>:<tag>
docker ps
docker stop <container-name>
docker rm <container-name>
```

## Debugging and Inspection
```bash
docker logs <container-name>
docker exec -it <container-name> sh
docker inspect <container-name>
```

## Cleanup
```bash
docker system prune
```
