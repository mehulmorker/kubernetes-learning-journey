#!/bin/bash
# Scaling Commands

# Manual Scaling
kubectl scale deployment node-app-deployment --replicas=5
kubectl get pods -w

kubectl scale deployment node-app-deployment --replicas=2
kubectl get pods -w

# Declarative Scaling (edit deployment.yaml first)
kubectl apply -f deployment.yaml
kubectl get pods

# Check Resource Usage
minikube addons enable metrics-server
kubectl top nodes
kubectl top pods

