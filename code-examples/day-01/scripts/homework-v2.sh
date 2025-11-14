#!/bin/bash
# Homework: Build and run v2 with environment variables

# Rebuild with v2 tag
docker build -t node-k8s-demo:v2 .

# Run with environment variables
docker run -d -p 3000:3000 -e PORT=3000 -e NODE_ENV=production --name my-app node-k8s-demo:v2

# Test the version endpoint
curl http://localhost:3000/version

