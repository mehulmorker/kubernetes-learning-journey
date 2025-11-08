# kubectl Deployment Commands Cheat Sheet

## Create and Inspect
```bash
kubectl create deployment node-app --image=node-k8s-demo:v1 --replicas=3
kubectl get deployments
kubectl describe deployment node-app
```

## Manage via YAML
```bash
kubectl apply -f deployment.yaml
kubectl delete -f deployment.yaml
kubectl rollout status deployment/node-app-deployment
```

## Scaling
```bash
kubectl scale deployment node-app-deployment --replicas=5
kubectl get pods
```

## Rolling Updates
```bash
kubectl set image deployment/node-app-deployment node-app=node-k8s-demo:v2
kubectl rollout status deployment/node-app-deployment
```

## Rollback
```bash
kubectl rollout undo deployment/node-app-deployment
kubectl rollout undo deployment/node-app-deployment --to-revision=1
```

## Pause & Resume
```bash
kubectl rollout pause deployment/node-app-deployment
kubectl rollout resume deployment/node-app-deployment
```

## Label Queries
```bash
kubectl get deployments --show-labels
kubectl get pods -l app=demo
kubectl get all -l tier=backend
```
