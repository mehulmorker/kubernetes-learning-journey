#!/bin/bash
# Homework Exercises

# Exercise 1: Create a Deployment with Labels
kubectl apply -f labeled-deployment.yaml
kubectl get deployments --show-labels
kubectl get pods -l tier=backend
kubectl get pods -l environment=development
kubectl get all -l app=demo

# Exercise 2: Practice Scaling
kubectl scale deployment labeled-app --replicas=6
kubectl get pods

kubectl scale deployment labeled-app --replicas=2
kubectl get pods

kubectl scale deployment labeled-app --replicas=10
kubectl get pods

# Exercise 3: Rolling Update Practice
eval $(minikube docker-env)
docker build -t node-k8s-demo:v1 .
docker build -t node-k8s-demo:v2 .
docker build -t node-k8s-demo:v3 .

kubectl set image deployment/labeled-app node-app=node-k8s-demo:v1
kubectl set image deployment/labeled-app node-app=node-k8s-demo:v2
kubectl rollout status deployment/labeled-app
kubectl set image deployment/labeled-app node-app=node-k8s-demo:v3
kubectl rollout status deployment/labeled-app
kubectl rollout undo deployment/labeled-app
kubectl rollout undo deployment/labeled-app --to-revision=1

# Exercise 4: Update Strategy Experiment
kubectl apply -f fast-update.yaml
kubectl apply -f slow-update.yaml
kubectl set image deployment/fast-update node-app=node-k8s-demo:v2
kubectl set image deployment/slow-update node-app=node-k8s-demo:v2
kubectl get pods -l app=fast -w
kubectl get pods -l app=slow -w

# Exercise 5: Debugging Deployments
kubectl apply -f broken-deployment.yaml
kubectl get deployments
kubectl get replicasets
kubectl get pods
kubectl describe deployment broken-app
kubectl describe pod <pod-name>
kubectl logs <pod-name>

