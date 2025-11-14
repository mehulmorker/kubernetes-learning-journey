#!/bin/bash
# Point your Docker CLI to minikube's Docker daemon
# (so minikube can see your locally built images)
eval $(minikube docker-env)

# Rebuild your image (now it's inside minikube)
cd ~/node-k8s-demo  # or wherever you created it
docker build -t node-k8s-demo:v1 .

# Verify image is available
docker images | grep node-k8s-demo

