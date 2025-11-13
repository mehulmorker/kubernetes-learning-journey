# Week 03 — ConfigMaps & Secrets Demo

## Overview
This project demonstrates:
- Creating ConfigMaps and Secrets with multiple methods
- Injecting config via env vars and volumes
- Using secrets for sensitive data
- Updating configs and performing rolling restarts

## Quick Start
1. Apply ConfigMap and Secret:
   `kubectl apply -f code-examples/day-05/configmap.yaml`
   `kubectl apply -f code-examples/day-05/secret.yaml`

2. Deploy the app with config and secrets:
   `kubectl apply -f code-examples/day-05/deployment-with-configmap.yaml`
   `kubectl apply -f code-examples/day-05/deployment-with-secrets.yaml`

3. Expose the app:
   `kubectl expose deployment node-app-with-config --type=NodePort --port=80 --target-port=8080`
   `minikube service node-app-with-config`

## Exercises
- Create dev/staging/prod ConfigMaps and deploy the same image with different configs.
- Practice secret rotation and rolling restarts.
- Mount parts of the ConfigMap as files and verify application reads them.
