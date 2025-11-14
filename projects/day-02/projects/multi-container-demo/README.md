# Multi-Container Pod Demo

This project demonstrates a Pod with multiple containers (sidecar pattern).

## Overview

The multi-container Pod includes:
- **Main application**: Node.js app (node-app)
- **Sidecar**: Nginx reverse proxy (nginx-sidecar)

## Architecture

```
┌─────────────────────────────┐
│   Multi-Container Pod       │
│  ┌───────────────────────┐  │
│  │  node-app (port 3000) │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ nginx-sidecar (port 80)│  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Shared Volume        │  │
│  │  (nginx-config)       │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

## Files

- `multi-container-pod.yaml` - Main Pod definition

**Location:** `../code-examples/days-02/pods/multi-container-pod.yaml`

## Prerequisites

1. Create the nginx ConfigMap (if needed):
```bash
kubectl create configmap nginx-config --from-file=nginx.conf
```

2. Ensure your Node.js image is built:
```bash
eval $(minikube docker-env)
docker build -t node-k8s-demo:v1 .
```

## Usage

```bash
# Apply the Pod
kubectl apply -f ../code-examples/days-02/pods/multi-container-pod.yaml

# Check Pod status
kubectl get pods

# View logs from specific container
kubectl logs multi-container-pod -c node-app
kubectl logs multi-container-pod -c nginx-sidecar

# Port forward to nginx
kubectl port-forward multi-container-pod 8080:80

# Port forward to node app
kubectl port-forward multi-container-pod 3000:3000
```

## Key Concepts

- Containers in a Pod share the same network namespace
- Containers can share volumes
- Sidecar pattern: helper container alongside main app
- Each container can be accessed independently via logs/exec

## Notes

This is a basic example. In production, you would:
- Configure nginx properly with ConfigMap
- Set up proper service discovery
- Add health checks
- Configure resource limits

