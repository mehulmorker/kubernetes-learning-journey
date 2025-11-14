# Day 3: Deployments Cheat Sheet

## Key Concepts

### Why Deployments?
- **Pods alone are not enough**: No auto-restart, no scaling, no updates
- **Deployments solve**: Self-healing, scaling, rolling updates, rollback

### Hierarchy
```
Deployment → ReplicaSet → Pods
```

## Essential Commands

### Create Deployment

**Imperative:**
```bash
kubectl create deployment <name> --image=<image> --replicas=<n>
```

**Declarative:**
```bash
kubectl apply -f deployment.yaml
```

### View Deployments
```bash
kubectl get deployments
kubectl get deployments -o wide
kubectl describe deployment <name>
kubectl get all
```

### Scaling
```bash
# Manual scaling
kubectl scale deployment <name> --replicas=<n>

# Declarative (edit YAML, then)
kubectl apply -f deployment.yaml
```

### Rolling Updates
```bash
# Update image
kubectl set image deployment/<name> <container>=<new-image>

# Watch rollout
kubectl rollout status deployment/<name>

# Watch Pods
kubectl get pods -w
```

### Rollback
```bash
# View history
kubectl rollout history deployment/<name>
kubectl rollout history deployment/<name> --revision=<n>

# Rollback
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=<n>
```

### Pause & Resume
```bash
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>
```

### Labels & Selectors
```bash
kubectl get pods --show-labels
kubectl get pods -l <key>=<value>
kubectl get all -l <key>=<value>
```

## YAML Structure

### Basic Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <name>
  labels:
    app: <app-name>
spec:
  replicas: <n>
  selector:
    matchLabels:
      app: <app-name>
  template:
    metadata:
      labels:
        app: <app-name>
    spec:
      containers:
      - name: <container-name>
        image: <image>
        ports:
        - containerPort: <port>
```

### Rolling Update Strategy
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max extra Pods during update
      maxUnavailable: 1  # Max Pods down during update
```

## Key Fields Explained

| Field | Purpose |
|-------|---------|
| `replicas` | Desired number of Pods |
| `selector.matchLabels` | How to find Pods to manage |
| `template.metadata.labels` | Labels applied to Pods (must match selector) |
| `template.spec` | Pod specification |
| `strategy.type` | Update strategy (RollingUpdate or Recreate) |
| `maxSurge` | Max extra Pods during update |
| `maxUnavailable` | Max Pods that can be unavailable |

## Common Patterns

### Resource Limits
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

### Environment Variables
```yaml
env:
- name: NODE_ENV
  value: "production"
```

### Image Pull Policy
```yaml
imagePullPolicy: Never  # For local images
imagePullPolicy: Always # Always pull
```

## Debugging

```bash
# Check deployment status
kubectl get deployments
kubectl describe deployment <name>

# Check ReplicaSets
kubectl get replicasets
kubectl describe replicaset <name>

# Check Pods
kubectl get pods
kubectl describe pod <name>
kubectl logs <pod-name>

# Check rollout history
kubectl rollout history deployment/<name>
```

## Best Practices

1. **Always use Deployments** - Never create Pods directly in production
2. **Use labels consistently** - Organize and query resources
3. **Set resource limits** - Prevent resource exhaustion
4. **Use RollingUpdate strategy** - Zero-downtime updates
5. **Test rollback procedures** - Know how to revert changes
6. **Monitor rollouts** - Watch `kubectl rollout status`
7. **Use declarative approach** - Version control your YAML

## Quick Reference

| Task | Command |
|------|---------|
| Create | `kubectl create deployment <name> --image=<img>` |
| Apply | `kubectl apply -f deployment.yaml` |
| Scale | `kubectl scale deployment <name> --replicas=<n>` |
| Update | `kubectl set image deployment/<name> <container>=<img>` |
| Status | `kubectl rollout status deployment/<name>` |
| History | `kubectl rollout history deployment/<name>` |
| Rollback | `kubectl rollout undo deployment/<name>` |
| Pause | `kubectl rollout pause deployment/<name>` |
| Resume | `kubectl rollout resume deployment/<name>` |
| Delete | `kubectl delete deployment <name>` |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Pods not starting | Check `kubectl describe pod` and `kubectl logs` |
| Image pull error | Verify image exists and `imagePullPolicy` |
| Update stuck | Check `kubectl rollout status` and Pod readiness |
| Wrong version | Use `kubectl rollout undo` to rollback |
| Too many Pods | Check `replicas` and scale down |

