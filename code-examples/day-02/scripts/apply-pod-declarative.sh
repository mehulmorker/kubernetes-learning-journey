#!/bin/bash
# Delete the previous Pod first
kubectl delete pod my-node-pod

# Create Pod from YAML
kubectl apply -f pod.yaml

# Check it
kubectl get pods
kubectl describe pod node-app-pod

# Test it
kubectl port-forward node-app-pod 3000:3000
# In another terminal: curl http://localhost:3000

