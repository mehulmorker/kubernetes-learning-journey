#!/bin/bash

# Method 1: Edit directly
kubectl edit configmap node-app-config

# Method 2: Update YAML and re-apply
# Edit configmap.yaml (change LOG_LEVEL to "debug")
kubectl apply -f configmap.yaml

# Check the change
kubectl get configmap node-app-config -o yaml

# Force pods to restart and pick up new config
kubectl rollout restart deployment/node-app-with-config

# Watch the rollout
kubectl rollout status deployment/node-app-with-config

