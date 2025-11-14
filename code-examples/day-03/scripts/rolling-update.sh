#!/bin/bash
# Rolling Update Commands

# Build new version
eval $(minikube docker-env)
docker build -t node-k8s-demo:v2 .
docker images | grep node-k8s-demo

# Method 1: Direct kubectl command
kubectl set image deployment/node-app-deployment node-app=node-k8s-demo:v2
kubectl rollout status deployment/node-app-deployment

# Method 2: Edit YAML and apply
# Change image: node-k8s-demo:v1 to image: node-k8s-demo:v2
# Then: kubectl apply -f deployment.yaml

# Watch the rollout
kubectl get pods -w
kubectl rollout status deployment/node-app-deployment

# Verify the update
kubectl describe deployment node-app-deployment
kubectl port-forward deployment/node-app-deployment 3000:3000
curl http://localhost:3000

