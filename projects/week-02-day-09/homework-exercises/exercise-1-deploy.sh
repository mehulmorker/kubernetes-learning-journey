#!/bin/bash
# Exercise 1: Deploy the same application to all three environments with different configurations

# Apply environments
kubectl apply -f exercise-1-environments.yaml

# Deploy to dev
kubectl create deployment myapp --image=nginx --replicas=1 -n development

# Deploy to staging
kubectl create deployment myapp --image=nginx --replicas=2 -n staging

# Deploy to production
kubectl create deployment myapp --image=nginx --replicas=5 -n production

# List all deployments across environments
kubectl get deployments --all-namespaces -l app=myapp


