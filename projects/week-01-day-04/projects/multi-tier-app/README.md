# Multi-Tier Application Project

This project demonstrates a complete 3-tier application with proper service discovery in Kubernetes.

## Architecture

```
Frontend (NodePort) 
    ↓
Backend Service (ClusterIP)
    ↓
Database Service (ClusterIP)
```

## Components

1. **Frontend**: Node.js app exposed via NodePort
2. **Backend**: Node.js API service (ClusterIP)
3. **Database**: Simulated database service (ClusterIP)

## Prerequisites

- Minikube running
- Docker environment configured
- Node.js images built

## Deployment Steps

### 1. Build Images

```bash
# Set Docker environment
eval $(minikube docker-env)

# Build backend image (if not already built)
docker build -t node-k8s-demo:v1 .

# Build frontend image
docker build -t frontend-app:v1 -f Dockerfile.frontend .
```

### 2. Deploy Backend

```bash
kubectl apply -f backend-deployment.yaml
```

### 3. Deploy Frontend

```bash
kubectl apply -f frontend-deployment.yaml
```

### 4. Verify Deployment

```bash
# Check all components
kubectl get deployments
kubectl get services
kubectl get pods

# Check endpoints
kubectl get endpoints
```

### 5. Test the Application

```bash
# Get minikube IP
minikube ip

# Access frontend (NodePort 30081)
curl http://$(minikube ip):30081

# Or use minikube service
minikube service frontend-service
```

## Service Discovery

The frontend automatically discovers the backend using Kubernetes DNS:

```javascript
// Frontend code uses service name
const response = await axios.get('http://backend-service:80');
```

## Files

- `backend-deployment.yaml`: Backend deployment and service
- `frontend-deployment.yaml`: Frontend deployment and service
- `Dockerfile.frontend`: Frontend container image
- `frontend-app.js`: Frontend application code
- `package.json`: Frontend dependencies

## Troubleshooting

### Check Service Connectivity

```bash
# Test backend from a Pod
kubectl run test --image=alpine --rm -it -- sh
apk add --no-cache curl
curl http://backend-service:80
```

### Check DNS Resolution

```bash
kubectl run test --image=alpine --rm -it -- sh
apk add --no-cache bind-tools
nslookup backend-service
nslookup frontend-service
```

### View Logs

```bash
# Frontend logs
kubectl logs -l app=frontend

# Backend logs
kubectl logs -l app=backend
```

## Cleanup

```bash
kubectl delete -f frontend-deployment.yaml
kubectl delete -f backend-deployment.yaml
```

