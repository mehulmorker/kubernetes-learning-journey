#!/bin/bash
# Get Pods in different formats
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json

# Watch Pods (useful for seeing changes)
kubectl get pods -w

# Delete a Pod
kubectl delete pod node-app-v3

# Delete multiple Pods
kubectl delete pod node-app-v1 node-app-v2

# Delete using label selector
kubectl delete pods -l app=node-demo

