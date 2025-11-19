#!/bin/bash
# Build Docker images for the e-commerce application

# Set Docker environment to minikube
eval $(minikube docker-env)

# Build backend
echo "Building backend image..."
cd backend
docker build -t ecommerce-backend:1.0 .
cd ..

# Build frontend
echo "Building frontend image..."
cd frontend
docker build -t ecommerce-frontend:1.0 .
cd ..

echo "Images built successfully!"

