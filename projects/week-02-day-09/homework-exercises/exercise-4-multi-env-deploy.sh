#!/bin/bash
# Exercise 4: Complete Multi-Environment Project
# Deploy your Week 1 e-commerce project to multiple namespaces

# Create namespaces
kubectl create ns ecommerce-dev
kubectl create ns ecommerce-staging
kubectl create ns ecommerce-prod

# Add labels
kubectl label ns ecommerce-dev environment=dev
kubectl label ns ecommerce-staging environment=staging
kubectl label ns ecommerce-prod environment=prod

# Deploy to each (adjust replicas and resources per environment)
# Note: Assumes k8s-manifests/ directory exists with your e-commerce manifests
if [ -d "k8s-manifests" ]; then
  kubectl apply -f k8s-manifests/ -n ecommerce-dev
  kubectl apply -f k8s-manifests/ -n ecommerce-staging
  kubectl apply -f k8s-manifests/ -n ecommerce-prod
else
  echo "Warning: k8s-manifests/ directory not found. Creating sample deployment..."
  
  # Create sample deployments for each environment
  kubectl create deployment frontend --image=nginx --replicas=1 -n ecommerce-dev
  kubectl create deployment frontend --image=nginx --replicas=2 -n ecommerce-staging
  kubectl create deployment frontend --image=nginx --replicas=3 -n ecommerce-prod
  
  kubectl expose deployment frontend --port=80 --type=ClusterIP -n ecommerce-dev --name=frontend-service
  kubectl expose deployment frontend --port=80 --type=ClusterIP -n ecommerce-staging --name=frontend-service
  kubectl expose deployment frontend --port=80 --type=ClusterIP -n ecommerce-prod --name=frontend-service
fi

# Access each environment (if using minikube)
if command -v minikube &> /dev/null; then
  echo "Accessing services via minikube..."
  minikube service frontend-service -n ecommerce-dev
  minikube service frontend-service -n ecommerce-staging
  minikube service frontend-service -n ecommerce-prod
else
  echo "Minikube not found. Use port-forward to access services:"
  echo "  kubectl port-forward -n ecommerce-dev svc/frontend-service 8080:80"
fi

# List all deployments across environments
echo ""
echo "=== All e-commerce deployments ==="
kubectl get deployments --all-namespaces | grep ecommerce


