#!/bin/bash
# Build and run the container

# Build the image
docker build -t node-k8s-demo:v1 .

# Run the container
docker run -d -p 3000:3000 --name my-node-app node-k8s-demo:v1

# Test it
echo "Testing the application..."
curl http://localhost:3000
echo ""
curl http://localhost:3000/health

# Check logs
echo "Container logs:"
docker logs my-node-app

