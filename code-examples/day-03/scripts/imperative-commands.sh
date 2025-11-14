#!/bin/bash
# Imperative Deployment Commands

# Set Docker environment
eval $(minikube docker-env)

# Rebuild image if needed
cd ~/node-k8s-demo
docker build -t node-k8s-demo:v1 .

# Create a Deployment with 3 replicas
kubectl create deployment node-app --image=node-k8s-demo:v1 --replicas=3

# Watch it create Pods
kubectl get deployments
kubectl get replicasets
kubectl get pods

# Detailed view
kubectl describe deployment node-app

# See all resources
kubectl get all

