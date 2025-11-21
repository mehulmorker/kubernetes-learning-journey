# Complete App with ConfigMap and Secret

This project demonstrates a realistic application setup using both ConfigMaps and Secrets together.

## Exercise Overview

Create a complete application deployment that uses:

- ConfigMap for non-sensitive configuration
- Secret for sensitive data (passwords, API keys)
- Both environment variables and volume mounts

## Files

- `complete-app.yaml` - Complete application manifest with ConfigMap, Secret, and Deployment

## Instructions

1. Apply the complete application:

   ```bash
   kubectl apply -f complete-app.yaml
   ```

2. Verify all resources are created:

   ```bash
   kubectl get configmap myapp-config
   kubectl get secret myapp-secrets
   kubectl get deployment myapp
   kubectl get pods
   ```

3. Check environment variables:

   ```bash
   kubectl exec -it deployment/myapp -- env | grep -E 'PORT|LOG_LEVEL|DB_|JWT'
   ```

4. Verify mounted secret files:

   ```bash
   kubectl exec -it deployment/myapp -- ls -la /etc/secrets
   kubectl exec -it deployment/myapp -- cat /etc/secrets/jwt.key
   ```

5. View application logs:
   ```bash
   kubectl logs deployment/myapp
   ```

## Expected Results

- ConfigMap provides: PORT, LOG_LEVEL, DATABASE_HOST, DATABASE_PORT, REDIS_HOST
- Secret provides: database-username, database-password, redis-password, jwt-secret
- Environment variables are set from ConfigMap and Secret
- Secret files are mounted at /etc/secrets
