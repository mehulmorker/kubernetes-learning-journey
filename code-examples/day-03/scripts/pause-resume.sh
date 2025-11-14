#!/bin/bash
# Pause & Resume Commands

# Pause rollout
kubectl rollout pause deployment/node-app-deployment

# Make multiple changes (they won't apply yet)
kubectl set image deployment/node-app-deployment node-app=node-k8s-demo:v2
kubectl set resources deployment/node-app-deployment -c node-app --limits=cpu=300m,memory=256Mi

# Resume (all changes applied at once)
kubectl rollout resume deployment/node-app-deployment

# Watch the combined rollout
kubectl rollout status deployment/node-app-deployment

