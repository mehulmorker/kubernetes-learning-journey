# Exercise 5: Debugging Deployments

## Objective
Learn how to debug deployment issues by creating a broken deployment and fixing it.

## Steps

1. Create a broken deployment:
   ```bash
   kubectl apply -f broken-deployment.yaml
   ```

2. Debug the deployment using various commands:
   ```bash
   # Check deployment status
   kubectl get deployments
   
   # Check ReplicaSets
   kubectl get replicasets
   
   # Check Pods
   kubectl get pods
   
   # Describe deployment for details
   kubectl describe deployment broken-app
   
   # Describe a specific Pod
   kubectl describe pod <pod-name>
   
   # Check Pod logs
   kubectl logs <pod-name>
   ```

3. Identify the issue:
   - The deployment uses a non-existent image tag
   - Pods will be in `ImagePullBackOff` or `ErrImagePull` state

4. Fix the deployment:
   - Edit `broken-deployment.yaml`
   - Change `image: node-k8s-demo:nonexistent-tag` to `image: node-k8s-demo:v1`
   - Re-apply: `kubectl apply -f broken-deployment.yaml`

## Files
- `broken-deployment.yaml` - Intentionally broken deployment for debugging practice

## Common Issues to Look For

| Issue | Symptom | Solution |
|-------|---------|----------|
| Image not found | `ImagePullBackOff` | Check image name/tag, verify image exists |
| Wrong image pull policy | `ErrImagePull` | Set `imagePullPolicy: Never` for local images |
| Resource limits too low | `OOMKilled` | Increase memory limits |
| Port conflicts | Pods not starting | Check port configuration |
| Label mismatch | Deployment not managing Pods | Ensure selector matches template labels |

## Debugging Commands Reference

```bash
# Get overview
kubectl get all

# Detailed information
kubectl describe deployment <name>
kubectl describe pod <name>
kubectl describe replicaset <name>

# Logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous container instance

# Events
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage
kubectl top pods
kubectl top nodes
```

## Expected Outcome
- Learn to identify common deployment issues
- Practice using debugging commands
- Understand how to fix deployment problems
- Gain confidence in troubleshooting Kubernetes resources

