# Node.js Kubernetes Demo Application

A simple Express.js application containerized with Docker, designed as a foundation for learning Kubernetes.

## Project Structure

```
node-k8s-demo/
├── app.js              # Main application file
├── package.json        # Node.js dependencies
├── Dockerfile          # Container definition
└── .dockerignore       # Files to exclude from build
```

## Features

- Simple Express.js server
- Health check endpoint (`/health`)
- Version endpoint (`/version`) - added in homework
- Returns hostname and timestamp
- Configurable via environment variables

## Prerequisites

- Docker installed and running
- Node.js 18+ (for local development)

## Quick Start

### 1. Build the Docker Image

```bash
docker build -t node-k8s-demo:v1 .
```

### 2. Run the Container

```bash
docker run -d -p 3000:3000 --name my-node-app node-k8s-demo:v1
```

### 3. Test the Application

```bash
# Test main endpoint
curl http://localhost:3000

# Test health endpoint
curl http://localhost:3000/health

# Test version endpoint (v2)
curl http://localhost:3000/version
```

### 4. View Logs

```bash
docker logs my-node-app
```

### 5. Stop and Remove

```bash
docker stop my-node-app
docker rm my-node-app
```

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment mode (development/production)

Example:

```bash
docker run -d -p 3000:3000 \
  -e PORT=3000 \
  -e NODE_ENV=production \
  --name my-app \
  node-k8s-demo:v2
```

## Endpoints

- `GET /` - Returns welcome message with hostname and timestamp
- `GET /health` - Health check endpoint (returns `{ status: 'healthy' }`)
- `GET /version` - Version information (returns `{ version: '1.0.0' }`)

## Homework Tasks

1. ✅ Add `/version` endpoint to the application
2. ✅ Rebuild image with v2 tag
3. ✅ Run container with environment variables
4. ✅ Practice Docker commands (ps, images, exec, inspect)

## Next Steps

This containerized application will be used in upcoming days to learn:

- Kubernetes Pods
- Deployments
- Services
- ConfigMaps and Secrets
- Persistent Volumes
- And more!

## Troubleshooting

### Container won't start

- Check if port 3000 is already in use: `lsof -i :3000`
- View container logs: `docker logs my-node-app`

### Cannot connect to application

- Verify container is running: `docker ps`
- Check port mapping: `docker port my-node-app`
- Test from inside container: `docker exec -it my-node-app sh`

### Build fails

- Ensure Dockerfile is in the project root
- Check that package.json exists
- Verify Node.js base image is accessible
