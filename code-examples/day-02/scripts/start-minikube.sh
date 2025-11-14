#!/bin/bash
# Start minikube (this may take 2-5 minutes first time)
minikube start --driver=docker

# Verify cluster is running
kubectl cluster-info
kubectl get nodes

