# Day 3: Deployments - Production-Ready Applications

Today we explore Deployments — the controller that makes Pods production-ready through automation, scaling, and self-healing.

## Part 1: Why Not Just Pods?
Pods don’t auto-restart or recover if deleted. Deployments solve this by managing Pods via ReplicaSets.

## Key Benefits:
- Self-healing
- Scaling
- Rolling updates and rollbacks
- Desired state management

## Part 2: Creating Deployments
### Imperative:
```bash
kubectl create deployment node-app --image=node-k8s-demo:v1 --replicas=3
kubectl get deployments
kubectl get replicasets
kubectl get pods
```

### Declarative (YAML)
See `deployment.yaml` in `/code-examples/day-03/`.

## Part 3: Scaling and Healing
```bash
kubectl scale deployment node-app-deployment --replicas=5
kubectl delete pod <pod-name>
kubectl get pods  # new Pod appears
```

## Part 4: Rolling Updates
```bash
kubectl set image deployment/node-app-deployment node-app=node-k8s-demo:v2
kubectl rollout status deployment/node-app-deployment
```

## Part 5: Rollback
```bash
kubectl rollout undo deployment/node-app-deployment
kubectl rollout undo deployment/node-app-deployment --to-revision=1
```

## Part 6: Pause & Resume
```bash
kubectl rollout pause deployment/node-app-deployment
kubectl rollout resume deployment/node-app-deployment
```

## Homework
- Create Deployments with labels
- Test different rollout strategies
- Practice scaling and rollback

✅ Checklist:
- Create and manage Deployments
- Perform rolling updates
- Use rollback safely
- Configure update strategies
