#!/bin/bash

# Apply DaemonSet
kubectl apply -f simple-daemonset.yaml

# View DaemonSet
kubectl get daemonsets
kubectl get ds  # shorthand

# View pods created by DaemonSet
kubectl get pods -l app=node-logger -o wide

# Notice: One pod per node!

# Describe DaemonSet
kubectl describe ds node-logger

# View logs from one pod
kubectl logs -l app=node-logger --tail=10

# Check current pods
kubectl get pods -l app=node-logger -o wide

# Delete a DaemonSet pod
POD_NAME=$(kubectl get pods -l app=node-logger -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Watch it recreate immediately
kubectl get pods -l app=node-logger -w

# Apply log collector
kubectl apply -f log-collector-daemonset.yaml

# View in kube-system namespace
kubectl get ds -n kube-system

# Check logs
kubectl logs -n kube-system -l app=log-collector --tail=20

# Label a node
kubectl label nodes minikube gpu=true

# Apply selective DaemonSet
kubectl apply -f selective-daemonset.yaml

# Pod only runs on labeled nodes
kubectl get pods -l app=gpu-monitor -o wide

# Remove label - pod gets deleted
kubectl label nodes minikube gpu-

# Pod disappears!
kubectl get pods -l app=gpu-monitor

# Check update strategy
kubectl get ds node-logger -o jsonpath='{.spec.updateStrategy}'

# Update image
kubectl set image daemonset/node-logger logger=busybox:1.36

# Watch rolling update
kubectl rollout status daemonset/node-logger

# View rollout history
kubectl rollout history daemonset/node-logger

# Rollback if needed
kubectl rollout undo daemonset/node-logger

