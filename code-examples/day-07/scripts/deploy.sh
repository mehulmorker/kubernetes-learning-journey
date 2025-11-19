#!/bin/bash
# Deploy the e-commerce application to Kubernetes

cd k8s-manifests

# Create namespace
echo "Creating namespace..."
kubectl apply -f namespace.yaml

# Deploy database (wait for it to be ready)
echo "Deploying database..."
kubectl apply -f database.yaml

# Wait for database to be ready
echo "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n ecommerce --timeout=120s

# Deploy backend
echo "Deploying backend..."
kubectl apply -f backend.yaml

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n ecommerce --timeout=120s

# Deploy frontend
echo "Deploying frontend..."
kubectl apply -f frontend.yaml

# Check all resources
echo "Checking all resources..."
kubectl get all -n ecommerce

echo "Deployment complete!"
echo "Frontend URL: http://$(minikube ip):30080"

