#!/bin/bash

# Edit secret (values are base64 encoded)
kubectl edit secret app-secrets

# Or delete and recreate
kubectl delete secret app-secrets
kubectl create secret generic app-secrets \
  --from-literal=database-password=NewPassword456 \
  --from-literal=api-key=newkey9876543210

# Restart pods to pick up changes
kubectl rollout restart deployment/node-app-with-secrets

