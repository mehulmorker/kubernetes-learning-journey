#!/bin/bash
# Create a Pod imperatively
kubectl run my-node-pod --image=node-k8s-demo:v1 --port=3000 --image-pull-policy=Never

# Check Pod status
kubectl get pods

# Wait until STATUS shows "Running" (might take 10-30 seconds)
kubectl get pods -w  # -w watches for changes (Ctrl+C to exit)

