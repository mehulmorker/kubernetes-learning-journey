# Week 1 Mini-Project: E-Commerce Microservices

## Architecture

3-tier application demonstrating core Kubernetes concepts:

- **Frontend**: NGINX serving static HTML/JS (3 replicas)
- **Backend**: Node.js REST API (3 replicas)
- **Database**: PostgreSQL with persistent storage (1 replica)

## Technologies Used

- Kubernetes (minikube)
- Docker
- Node.js + Express
- PostgreSQL
- NGINX

## Kubernetes Concepts Demonstrated

✅ Deployments with multiple replicas
✅ StatefulSet for database
✅ Services (ClusterIP, NodePort, Headless)
✅ ConfigMaps for configuration
✅ Secrets for sensitive data
✅ PersistentVolumes and PersistentVolumeClaims
✅ Resource limits and requests
✅ Health checks (liveness and readiness probes)
✅ Rolling updates
✅ Service discovery via DNS
✅ Multi-tier application architecture
✅ Namespaces for isolation

## Deployment Instructions

### Prerequisites

- minikube running
- kubectl configured
- Docker installed

### Build Images

```bash
# Set Docker environment to minikube
eval $(minikube docker-env)

# Build backend
cd backend
docker build -t ecommerce-backend:1.0 .

# Build frontend
cd ../frontend
docker build -t ecommerce-frontend:1.0 .
```

### Deploy Application

```bash
cd k8s-manifests

# Create namespace
kubectl apply -f namespace.yaml

# Deploy database
kubectl apply -f database.yaml
kubectl wait --for=condition=ready pod -l app=postgres -n ecommerce --timeout=120s

# Deploy backend
kubectl apply -f backend.yaml
kubectl wait --for=condition=ready pod -l app=backend -n ecommerce --timeout=120s

# Deploy frontend
kubectl apply -f frontend.yaml

# Access application
minikube service frontend-service -n ecommerce
```

## Testing

```bash
# Check all resources
kubectl get all -n ecommerce

# View logs
kubectl logs -n ecommerce -l app=backend
kubectl logs -n ecommerce -l app=frontend

# Test API endpoint
kubectl port-forward -n ecommerce svc/backend-service 3000:3000
curl http://localhost:3000/api/products
```

## Cleanup

```bash
kubectl delete namespace ecommerce
```

## Screenshots

[Add screenshots of your running application]

## Lessons Learned

- [Document what you learned during the project]
- [Challenges faced and how you solved them]
- [Improvements you would make]

## Future Enhancements

- [ ] Add Ingress for better routing
- [ ] Implement HPA for autoscaling
- [ ] Add monitoring with Prometheus
- [ ] Implement CI/CD pipeline
- [ ] Add caching layer (Redis)

