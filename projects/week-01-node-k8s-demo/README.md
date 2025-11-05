# Node.js Kubernetes Demo

## Overview
A simple Express.js application containerized with Docker.  
This project demonstrates how to:
- Build Docker images for Node.js apps
- Run and test containers locally
- Prepare apps for Kubernetes deployment

## Setup
```bash
docker build -t node-k8s-demo:v1 .
docker run -d -p 3000:3000 --name my-node-app node-k8s-demo:v1
```

## Endpoints
| Route | Description |
|--------|-------------|
| `/` | Main app response |
| `/health` | Health check endpoint |
| `/version` | Version info |

## Homework Extension
Modify the app, rebuild as `v2`, and practice using Docker CLI commands.
