#!/bin/bash
# Rollback Commands

# Check Rollout History
kubectl rollout history deployment/node-app-deployment
kubectl rollout history deployment/node-app-deployment --revision=2

# Rollback to Previous Version
kubectl rollout undo deployment/node-app-deployment
kubectl rollout status deployment/node-app-deployment
kubectl get pods
curl http://localhost:3000

# Rollback to Specific Revision
kubectl rollout undo deployment/node-app-deployment --to-revision=1
kubectl rollout history deployment/node-app-deployment

