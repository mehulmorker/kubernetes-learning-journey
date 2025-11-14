# Multi-Environment Configuration Exercise

This project demonstrates how to create and use different ConfigMaps for different environments (dev, staging, production).

## Exercise Overview

Create ConfigMaps for different environments and deploy applications using environment-specific configurations.

## Files

- `configmap-dev.yaml` - Development environment ConfigMap
- `configmap-staging.yaml` - Staging environment ConfigMap
- `configmap-prod.yaml` - Production environment ConfigMap
- `deployment-dev.yaml` - Development deployment
- `deployment-staging.yaml` - Staging deployment
- `deployment-prod.yaml` - Production deployment

## Instructions

1. Create ConfigMaps for each environment:

   ```bash
   kubectl apply -f configmap-dev.yaml
   kubectl apply -f configmap-staging.yaml
   kubectl apply -f configmap-prod.yaml
   ```

2. Deploy applications using environment-specific configs:

   ```bash
   kubectl apply -f deployment-dev.yaml
   kubectl apply -f deployment-staging.yaml
   kubectl apply -f deployment-prod.yaml
   ```

3. Verify configurations:
   ```bash
   kubectl exec -it deployment/myapp-dev -- env | grep NODE_ENV
   kubectl exec -it deployment/myapp-staging -- env | grep NODE_ENV
   kubectl exec -it deployment/myapp-prod -- env | grep NODE_ENV
   ```

## Expected Results

- Each environment should have different configuration values
- Development: `NODE_ENV=development`, `LOG_LEVEL=debug`
- Staging: `NODE_ENV=staging`, `LOG_LEVEL=info`
- Production: `NODE_ENV=production`, `LOG_LEVEL=error`
