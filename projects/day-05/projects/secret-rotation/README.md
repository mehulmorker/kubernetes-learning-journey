# Secret Rotation Practice

This project demonstrates how to rotate secrets in a running application without downtime.

## Exercise Overview

Practice the complete secret rotation workflow:

1. Create initial secret
2. Deploy application using the secret
3. Update the secret
4. Restart the deployment to pick up new secret
5. Verify the new secret is being used

## Files

- `secret-app.yaml` - Application deployment using secrets
- `rotating-secret.yaml` - Secret manifest

## Instructions

1. Create initial secret:

   ```bash
   kubectl create secret generic rotating-secret \
     --from-literal=api-key=initial-key-123
   ```

2. Deploy application:

   ```bash
   kubectl apply -f secret-app.yaml
   ```

3. Verify initial secret is being used:

   ```bash
   kubectl exec -it deployment/secret-app -- env | grep api-key
   ```

4. Update the secret:

   ```bash
   kubectl create secret generic rotating-secret \
     --from-literal=api-key=new-key-456 \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

5. Restart deployment to pick up new secret:

   ```bash
   kubectl rollout restart deployment/secret-app
   ```

6. Watch the rollout:

   ```bash
   kubectl rollout status deployment/secret-app
   ```

7. Verify new secret is being used:
   ```bash
   kubectl exec -it deployment/secret-app -- env | grep api-key
   ```

## Expected Results

- Initial secret value: `api-key=initial-key-123`
- After rotation: `api-key=new-key-456`
- Application continues running during rotation
- New pods use the updated secret

## Best Practices

- Always use `kubectl rollout restart` after updating secrets
- Monitor the rollout status
- Verify the new secret is being used
- Consider using external secret management systems for production
