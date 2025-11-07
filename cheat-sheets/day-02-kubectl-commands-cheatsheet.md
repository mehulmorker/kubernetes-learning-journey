# kubectl Command Cheat Sheet

## Cluster
```bash
minikube start --driver=docker
kubectl cluster-info
kubectl get nodes
```

## Pods
```bash
kubectl run my-node-pod --image=node-k8s-demo:v1
kubectl get pods
kubectl describe pod my-node-pod
kubectl logs my-node-pod
kubectl exec -it my-node-pod -- sh
```

## Declarative
```bash
kubectl apply -f pod.yaml
kubectl delete -f pod.yaml
```

## Debug
```bash
kubectl get events
kubectl get pods -o wide
kubectl describe pod <name>
kubectl logs <name>
```
