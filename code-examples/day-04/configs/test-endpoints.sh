#!/bin/bash
# Services create Endpoints automatically
kubectl get endpoints node-app-service

# Describe them
kubectl describe endpoints node-app-service

# Endpoints = list of Pod IPs that match the selector

# In one terminal, watch endpoints
kubectl get endpoints node-app-service -w

# In another, scale the deployment
kubectl scale deployment node-app --replicas=5

# Watch endpoints update in real-time!

