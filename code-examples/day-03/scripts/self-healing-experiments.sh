#!/bin/bash
# Self-Healing Experiments

# Experiment 1: Delete a Pod
kubectl get pods
kubectl delete pod node-app-deployment-xxxxx-xxxxx
kubectl get pods

# Experiment 2: Simulate Node Failure
kubectl scale deployment node-app-deployment --replicas=5
kubectl get pods -o wide
kubectl get nodes
kubectl drain minikube --ignore-daemonsets --delete-emptydir-data --force
kubectl uncordon minikube
kubectl get pods

