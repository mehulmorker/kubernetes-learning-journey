# Day 1: Container Fundamentals - Cheat Sheet

## Docker Core Concepts

| Concept       | Description                                | Analogy                    |
| ------------- | ------------------------------------------ | -------------------------- |
| **Image**     | Blueprint for containers                   | Like a class in JavaScript |
| **Container** | Running instance of an image               | Like an object instance    |
| **Layers**    | Images built in layers (immutable, cached) | Stacked building blocks    |

## Essential Docker Commands

### Verification & Setup

```bash
docker --version          # Check Docker version
docker info               # Detailed Docker system information
docker run hello-world    # Test Docker installation
```

### Image Management

```bash
docker images             # List all images
docker build -t <name>:<tag> .    # Build image with tag
docker rmi <image>        # Remove image
```

### Container Management

```bash
docker ps                 # List running containers
docker ps -a              # List all containers (including stopped)
docker run -d -p <host>:<container> <image>    # Run container in detached mode
docker stop <container>   # Stop container
docker rm <container>     # Remove container
docker logs <container>   # View container logs
docker logs -f <container>    # Follow logs (real-time)
docker exec -it <container> sh    # Get shell inside container
docker inspect <container>    # Detailed container information
```

### Environment Variables

```bash
docker run -e KEY=value <image>    # Set environment variable
docker run -e PORT=3000 -e NODE_ENV=production <image>
```

## Dockerfile Basics

```dockerfile
FROM node:18-alpine      # Base image
WORKDIR /app             # Set working directory
COPY package*.json ./    # Copy package files
RUN npm install          # Install dependencies
COPY . .                 # Copy application code
EXPOSE 3000              # Expose port
CMD ["node", "app.js"]   # Default command
```

## .dockerignore

Common entries:

```
node_modules
npm-debug.log
.git
.gitignore
README.md
```

## Why Kubernetes?

### Problems Docker Alone Can't Solve

- ❌ Running multiple instances (load balancing)
- ❌ Auto-restart on failure
- ❌ Zero-downtime updates
- ❌ Auto-scaling based on traffic
- ❌ Managing across multiple servers
- ❌ Configuration and secrets management
- ❌ Storage orchestration

### Kubernetes Solutions

- ✅ **Orchestration** - Manages containers across machines
- ✅ **Self-healing** - Auto-restarts failed containers
- ✅ **Scaling** - Horizontal scaling (add/remove instances)
- ✅ **Load Balancing** - Automatic traffic distribution
- ✅ **Rolling Updates** - Zero-downtime deployments
- ✅ **Service Discovery** - Containers find each other
- ✅ **Storage Orchestration** - Manages persistent data
- ✅ **Configuration Management** - Centralized config/secrets

## Quick Reference: Docker Workflow

1. **Create application** → Write code
2. **Create Dockerfile** → Define container image
3. **Build image** → `docker build -t <name>:<tag> .`
4. **Run container** → `docker run -d -p <port> <image>`
5. **Test** → `curl http://localhost:<port>`
6. **View logs** → `docker logs <container>`
7. **Stop/Remove** → `docker stop <container>` && `docker rm <container>`

## Common Patterns

### Node.js Express App

```javascript
const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});
```

### Multi-stage Build (Advanced)

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm install --production
CMD ["node", "dist/index.js"]
```

## Tips & Best Practices

1. **Use .dockerignore** - Reduces build context size
2. **Layer caching** - Order Dockerfile commands from least to most frequently changing
3. **Use specific tags** - Avoid `latest` in production
4. **Multi-stage builds** - Reduce final image size
5. **Health checks** - Always include `/health` endpoint
6. **Environment variables** - Use for configuration
7. **Alpine images** - Smaller base images when possible
