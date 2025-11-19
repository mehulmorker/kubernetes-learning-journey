# Day 7 Cheat Sheet: Week 1 Review & Mini-Project

## Quick Knowledge Check Answers

### Containers & Docker
- **Image vs Container**: Image is a template/blueprint; Container is a running instance
- **Multi-stage Dockerfiles**: Reduce final image size by using intermediate build stages

### Pods
- **Why not bare Pods in production**: No self-healing, no scaling, no rolling updates
- **Multi-container Pods**: Use when containers need to share network/volumes (sidecar pattern)

### Deployments
- **Hierarchy**: Deployment → ReplicaSet → Pod
- **Zero-downtime update**: Rolling update strategy (default)

### Services
- **3 Main Types**:
  - **ClusterIP**: Internal cluster communication (default)
  - **NodePort**: Expose on each node's IP at static port
  - **LoadBalancer**: External load balancer (cloud provider)
- **Service Discovery**: Via DNS: `<service-name>.<namespace>.svc.cluster.local`

### ConfigMaps & Secrets
- **env vars vs volume mounts**: 
  - Env vars: Simple config, single values
  - Volume mounts: Files, directories, config files
- **Difference**: ConfigMap for non-sensitive data; Secret for sensitive data (base64 encoded)

### Storage
- **PV vs PVC**: PV is cluster resource; PVC is user request for storage
- **Access Modes**:
  - **RWO**: ReadWriteOnce (single node)
  - **ROX**: ReadOnlyMany (multiple nodes, read-only)
  - **RWX**: ReadWriteMany (multiple nodes, read-write)

## Essential kubectl Commands

### Pods
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- sh
kubectl delete pod <pod-name>
```

### Deployments
```bash
kubectl get deployments
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout restart deployment/<name>
kubectl set image deployment/<name> <container>=<new-image>
```

### Services
```bash
kubectl get svc
kubectl expose deployment <name> --port=80 --target-port=8080
kubectl get endpoints
kubectl port-forward svc/<service-name> <local-port>:<service-port>
```

### ConfigMaps & Secrets
```bash
kubectl create configmap <name> --from-literal=key=value
kubectl create secret generic <name> --from-literal=key=value
kubectl get configmap
kubectl get secret
kubectl describe configmap <name>
kubectl edit configmap <name>
```

### Storage
```bash
kubectl get pv
kubectl get pvc
kubectl get sc
kubectl describe pvc <name>
```

### General
```bash
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>
kubectl get all
kubectl get all -n <namespace>
kubectl get pods -n <namespace> -w  # Watch mode
```

## Mini-Project Architecture

```
Internet → NodePort Service (30080) → Frontend (3 replicas)
                                        ↓
                                    Backend Service (ClusterIP)
                                        ↓
                                    Backend (3 replicas)
                                        ↓
                                    PostgreSQL Service (Headless)
                                        ↓
                                    PostgreSQL StatefulSet (1 replica)
                                        ↓
                                    PersistentVolumeClaim (5Gi)
```

## Key Components

### Frontend
- **Image**: ecommerce-frontend:1.0
- **Service**: NodePort (port 30080)
- **Replicas**: 3
- **ConfigMap**: API_URL configuration
- **Health Check**: /health endpoint

### Backend
- **Image**: ecommerce-backend:1.0
- **Service**: ClusterIP (port 3000)
- **Replicas**: 3
- **ConfigMap**: PORT, LOG_LEVEL, DB config
- **Secret**: DB credentials
- **Health Check**: /health endpoint

### Database
- **Image**: postgres:15-alpine
- **Service**: Headless (ClusterIP: None)
- **Type**: StatefulSet (1 replica)
- **Secret**: Database credentials
- **PVC**: 5Gi persistent storage
- **Health Check**: pg_isready

## Deployment Workflow

1. **Build Images**
   ```bash
   eval $(minikube docker-env)
   docker build -t ecommerce-backend:1.0 ./backend
   docker build -t ecommerce-frontend:1.0 ./frontend
   ```

2. **Deploy in Order**
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f database.yaml
   kubectl wait --for=condition=ready pod -l app=postgres -n ecommerce
   kubectl apply -f backend.yaml
   kubectl wait --for=condition=ready pod -l app=backend -n ecommerce
   kubectl apply -f frontend.yaml
   ```

3. **Verify**
   ```bash
   kubectl get all -n ecommerce
   minikube service frontend-service -n ecommerce
   ```

## Testing Commands

### Test Frontend
```bash
# Get URL
echo "http://$(minikube ip):30080"
# Or
minikube service frontend-service -n ecommerce
```

### Test Backend API
```bash
# Port-forward
kubectl port-forward -n ecommerce svc/backend-service 3000:3000

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3000/api/products
curl http://localhost:3000/api/info
```

### Test Database
```bash
# Connect to database
kubectl exec -it -n ecommerce postgres-0 -- psql -U ecommerceuser -d ecommerce

# Inside psql
\dt                    # List tables
SELECT * FROM products;
\q                     # Quit
```

## Scaling & Updates

### Scale Deployment
```bash
kubectl scale deployment backend -n ecommerce --replicas=5
kubectl get pods -n ecommerce -w  # Watch
```

### Rolling Update
```bash
# Update image
kubectl set image deployment/backend -n ecommerce backend=ecommerce-backend:1.1

# Watch rollout
kubectl rollout status deployment/backend -n ecommerce

# Rollback if needed
kubectl rollout undo deployment/backend -n ecommerce
```

### Update Configuration
```bash
# Edit ConfigMap
kubectl edit configmap backend-config -n ecommerce

# Restart to pick up changes
kubectl rollout restart deployment/backend -n ecommerce
```

## Troubleshooting Quick Reference

### Pod Issues
```bash
kubectl describe pod <pod-name> -n ecommerce
kubectl logs <pod-name> -n ecommerce
kubectl logs <pod-name> -n ecommerce --previous  # Previous container
```

### Service Issues
```bash
kubectl get endpoints -n ecommerce  # Check if endpoints exist
kubectl describe svc <service-name> -n ecommerce
```

### Storage Issues
```bash
kubectl get pvc -n ecommerce
kubectl describe pvc <pvc-name> -n ecommerce
kubectl get pv
```

### Network/DNS Issues
```bash
# Test from pod
kubectl exec -it <pod-name> -n ecommerce -- sh
ping <service-name>
nslookup <service-name>.<namespace>.svc.cluster.local
```

## Cleanup

```bash
# Delete everything
kubectl delete namespace ecommerce

# Or delete individually
kubectl delete -f frontend.yaml
kubectl delete -f backend.yaml
kubectl delete -f database.yaml
kubectl delete -f namespace.yaml
```

## Week 1 Concepts Summary

✅ **Docker**: Images, containers, Dockerfiles, multi-stage builds
✅ **Pods**: Smallest deployable unit, multi-container patterns
✅ **Deployments**: Self-healing, scaling, rolling updates
✅ **Services**: ClusterIP, NodePort, LoadBalancer, DNS discovery
✅ **ConfigMaps**: Non-sensitive configuration
✅ **Secrets**: Sensitive data (base64 encoded)
✅ **Storage**: PV, PVC, StorageClass, access modes
✅ **kubectl**: Command-line tool mastery

## Project Checklist

- [ ] All 3 tiers deployed
- [ ] Frontend accessible via NodePort
- [ ] Backend API responding
- [ ] Database storing data
- [ ] Services communicating via DNS
- [ ] ConfigMaps configured
- [ ] Secrets configured
- [ ] PVC providing persistence
- [ ] Multiple replicas running
- [ ] Resource limits set
- [ ] Health checks working
- [ ] Scaling tested
- [ ] Rolling update tested

## Next Steps (Week 2 Preview)

- Labels & Selectors
- Namespaces (advanced)
- DaemonSets
- StatefulSets (advanced)
- Jobs & CronJobs
- Advanced ConfigMaps & Secrets

