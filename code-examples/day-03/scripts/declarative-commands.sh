#!/bin/bash
# Declarative Deployment Commands

# Delete previous deployment first
kubectl delete deployment node-app

# Create from YAML
kubectl apply -f deployment.yaml

# Watch the rollout
kubectl rollout status deployment/node-app-deployment

# Check everything
kubectl get deployments
kubectl get replicasets
kubectl get pods --show-labels

