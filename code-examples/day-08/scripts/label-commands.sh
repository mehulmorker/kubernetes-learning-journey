#!/bin/bash
# Label Management Commands

# Create pod with labels
kubectl run nginx-pod \
  --image=nginx \
  --labels="app=nginx,env=dev,tier=frontend"

# Verify labels
kubectl get pods --show-labels

# Add label to existing pod
kubectl label pod nginx-pod version=1.0

# Update existing label (requires --overwrite)
kubectl label pod nginx-pod version=2.0 --overwrite

# Remove label (use minus sign)
kubectl label pod nginx-pod version-

# View specific label columns
kubectl get pods -L app,environment,version


