# Day 07: Week 1 Review & Mini-Project - Interview Questions

## 1. Explain the complete architecture of a 3-tier application in Kubernetes.

**Answer:**

**Architecture:**
```
Internet
    ↓
Frontend (NodePort Service)
    ↓
Frontend Deployment (NGINX + Static Files)
    ↓ (HTTP requests via DNS)
Backend Service (ClusterIP)
    ↓
Backend Deployment (Node.js API)
    ↓ (Database connection via DNS)
Database Service (ClusterIP)
    ↓
Database StatefulSet (PostgreSQL)
    ↓
PersistentVolumeClaim (Data Storage)
```

**Components:**

**1. Frontend Tier:**
- Deployment with 3+ replicas
- NGINX serving static HTML/CSS/JS
- ConfigMap for API URL, theme settings
- NodePort Service for external access
- No persistent storage needed

**2. Backend Tier:**
- Deployment with 3+ replicas
- Node.js/Express REST API
- ConfigMap for configuration (port, log level)
- Secret for database password, API keys
- ClusterIP Service for internal access
- Connects to database via Service DNS

**3. Database Tier:**
- StatefulSet with 1 replica (or more for HA)
- PostgreSQL database
- Secret for database credentials
- ClusterIP Service (often headless for StatefulSet)
- PersistentVolumeClaim for data persistence

**Key Design Decisions:**
- Frontend: Stateless, scalable, external access
- Backend: Stateless, scalable, internal only
- Database: Stateful, persistent, internal only

---

## 2. Multiple Choice: In a 3-tier application, which tier typically uses a StatefulSet?

A. Frontend  
B. Backend  
C. Database  
D. All of them

**Answer: C**

**Explanation:** Databases use StatefulSets because they are stateful applications that need:
- Stable network identity
- Persistent storage
- Ordered deployment
- Stable hostnames

Frontend and backend are typically stateless and use Deployments.

---

## 3. How do you ensure zero-downtime deployment in a multi-tier application?

**Answer:**

**Strategy: Rolling Updates**

**1. Configure Deployment strategy:**
```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Can have 1 extra Pod
      maxUnavailable: 0  # All Pods must be available
```

**2. Health checks:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

**3. Update process:**
```bash
# Update image
kubectl set image deployment/backend backend=myapp:v2

# Watch rollout
kubectl rollout status deployment/backend

# Verify
kubectl get pods -w
```

**How it works:**
- New Pod created and becomes Ready
- Old Pod removed
- Service routes traffic only to Ready Pods
- Process repeats until all Pods updated
- No downtime because at least one Pod always available

**Best Practices:**
- Multiple replicas (minimum 2, preferably 3+)
- Proper readiness probes
- maxUnavailable: 0 for zero downtime
- Test in staging first
- Monitor during rollout

---

## 4. Explain how service discovery works in a multi-tier application.

**Answer:**

**Service Discovery via DNS:**

**1. Services get DNS names automatically:**
```
<service-name>.<namespace>.svc.cluster.local
```

**2. Frontend calls Backend:**
```javascript
// Frontend code
const response = await fetch('http://backend-service/api/products');
// DNS resolves: backend-service → 10.96.123.45
```

**3. Backend connects to Database:**
```javascript
// Backend code
const db = new Client({
  host: 'postgres-service',  // Service DNS name
  port: 5432,
  database: 'mydb'
});
```

**4. Service routing:**
```
Client → Frontend Service → Frontend Pods (load balanced)
Frontend Pod → Backend Service → Backend Pods (load balanced)
Backend Pod → Database Service → Database Pod
```

**Key Points:**
- Use Service DNS names, never Pod IPs
- Same namespace: use service name only
- Different namespace: use `service.namespace`
- Automatic load balancing
- Automatic failover if Pod fails

**Example YAML:**
```yaml
# Backend Service
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 3000
```

---

## 5. Multiple Choice: Which resource provides persistent storage for a database in Kubernetes?

A. ConfigMap  
B. Secret  
C. PersistentVolumeClaim  
D. Service

**Answer: C**

**Explanation:** PersistentVolumeClaim (PVC) provides persistent storage that survives Pod restarts, which is essential for databases.

---

## 6. How do you manage configuration for different environments (dev, staging, prod) in Kubernetes?

**Answer:**

**Method 1: Separate ConfigMaps per environment**
```bash
# Development
kubectl create configmap app-config-dev \
  --from-literal=NODE_ENV=development \
  --from-literal=LOG_LEVEL=debug \
  -n development

# Production
kubectl create configmap app-config-prod \
  --from-literal=NODE_ENV=production \
  --from-literal=LOG_LEVEL=error \
  -n production
```

**Method 2: Use namespaces**
```bash
# Create namespaces
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# Deploy same app to different namespaces with different configs
kubectl apply -f deployment.yaml -n development
kubectl apply -f deployment.yaml -n production
```

**Method 3: Helm or Kustomize**
- **Helm**: Different values files per environment
- **Kustomize**: Environment-specific overlays

**Best Practice:**
- Use separate ConfigMaps per environment
- Use namespaces for isolation
- Reference environment-specific ConfigMap in deployment
- Never hardcode environment values in code

---

## 7. Explain the importance of resource limits in a production deployment.

**Answer:**

**Why resource limits matter:**
- **Prevents resource starvation**: One Pod can't consume all node resources
- **Enables scheduling**: Scheduler knows resource requirements
- **Cost control**: Prevents over-provisioning
- **Stability**: Prevents OOM (Out of Memory) kills
- **Predictability**: Consistent performance

**Configuration:**
```yaml
resources:
  requests:
    memory: "256Mi"   # Guaranteed minimum
    cpu: "250m"       # Guaranteed minimum
  limits:
    memory: "512Mi"    # Maximum allowed
    cpu: "500m"        # Maximum allowed
```

**Requests vs Limits:**
- **requests**: Guaranteed resources (scheduler uses for placement)
- **limits**: Maximum resources (enforced, Pod throttled/killed if exceeded)

**Best Practices:**
- Always set requests and limits
- Set requests = limits for predictable performance
- Monitor and adjust based on actual usage
- Use resource quotas per namespace

**Without limits:**
- Pods can consume all node resources
- Other Pods may be evicted
- Node instability
- Unpredictable performance

---

## 8. Multiple Choice: What is the recommended way to expose a frontend application to external users?

A. ClusterIP Service  
B. NodePort Service  
C. LoadBalancer Service  
D. Ingress Controller

**Answer: D** (for production) or **C** (for cloud environments)

**Explanation:** 
- **Ingress Controller**: Best for production (TLS, routing, multiple services)
- **LoadBalancer**: Good for cloud environments (AWS, GCP, Azure)
- **NodePort**: Development/testing only
- **ClusterIP**: Internal only

For production, Ingress Controller is recommended because it provides:
- TLS termination
- Path-based routing
- Multiple services behind one IP
- Better security

---

## 9. How do you ensure database data persists across Pod restarts and updates?

**Answer:**

**1. Use StatefulSet (not Deployment):**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: standard
      resources:
        requests:
          storage: 20Gi
```

**2. Use PersistentVolumeClaim:**
- Data stored in PVC, not in Pod
- PVC survives Pod deletion
- New Pod mounts same PVC

**3. Configure proper reclaim policy:**
```yaml
# In StorageClass or PV
persistentVolumeReclaimPolicy: Retain  # Don't delete data
```

**4. Test persistence:**
```bash
# Create data
kubectl exec -it postgres-0 -- psql -c "CREATE TABLE test (id INT);"

# Delete Pod
kubectl delete pod postgres-0

# Verify data still exists after Pod recreation
kubectl exec -it postgres-0 -- psql -c "SELECT * FROM test;"
```

**Key Points:**
- StatefulSet provides stable identity
- PVC provides persistent storage
- Data survives Pod restarts, updates, node failures

---

## 10. Scenario: Your backend API is receiving high traffic. How would you scale it?

**Answer:**

**Horizontal Scaling (Recommended):**

**Method 1: Scale Deployment**
```bash
# Scale to 5 replicas
kubectl scale deployment backend --replicas=5

# Or edit deployment
kubectl edit deployment backend
# Change: replicas: 3 → replicas: 5
```

**Method 2: Auto-scaling (HPA)**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Verification:**
```bash
# Check Pod count
kubectl get pods -l app=backend

# Check HPA status
kubectl get hpa backend-hpa

# Monitor scaling
kubectl get pods -w
```

**Considerations:**
- Ensure backend is stateless (can scale horizontally)
- Database connection pooling
- Session management (if using sessions)
- Resource limits set appropriately
- Load testing to verify scaling works

---

## 11. Multiple Choice: What happens when you update a ConfigMap that's used as environment variables in a Deployment?

A. Pods are automatically updated  
B. Pods must be restarted to pick up changes  
C. ConfigMap cannot be updated  
D. Changes are ignored

**Answer: B**

**Explanation:** Environment variables from ConfigMaps are set only when Pods start. To pick up ConfigMap changes, you must restart the Pods (e.g., `kubectl rollout restart deployment/<name>`).

**Note:** Volume-mounted ConfigMaps ARE updated automatically (~60 seconds), but environment variables are not.

---

## 12. Explain the troubleshooting steps for a multi-tier application where the frontend can't connect to the backend.

**Answer:**

**Step 1: Check Pod status**
```bash
kubectl get pods -l app=backend
# Ensure Pods are Running and Ready
```

**Step 2: Check Service exists and has endpoints**
```bash
kubectl get svc backend-service
kubectl get endpoints backend-service
# Endpoints should list Pod IPs
```

**Step 3: Verify Service selector matches Pod labels**
```bash
# Get Service selector
kubectl get svc backend-service -o jsonpath='{.spec.selector}'

# Check Pod labels
kubectl get pods -l app=backend --show-labels

# Must match!
```

**Step 4: Test connectivity from frontend Pod**
```bash
# Get frontend Pod name
FRONTEND_POD=$(kubectl get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Test DNS resolution
kubectl exec $FRONTEND_POD -- nslookup backend-service

# Test connectivity
kubectl exec $FRONTEND_POD -- wget -O- http://backend-service/api/health
```

**Step 5: Check backend logs**
```bash
kubectl logs -l app=backend --tail=50
```

**Step 6: Check frontend configuration**
```bash
# Verify ConfigMap
kubectl get configmap frontend-config -o yaml

# Check if API_URL is correct
kubectl exec $FRONTEND_POD -- env | grep API_URL
```

**Common issues:**
- Service selector doesn't match Pod labels
- Pods not Ready (readiness probe failing)
- Wrong Service name in frontend config
- Network policies blocking traffic
- Backend not listening on correct port

---

## 13. How do you perform a rollback if a new deployment version has issues?

**Answer:**

**Method 1: Rollback to previous version**
```bash
# Check rollout history
kubectl rollout history deployment/backend

# Rollback to previous
kubectl rollout undo deployment/backend

# Watch rollback
kubectl rollout status deployment/backend
```

**Method 2: Rollback to specific revision**
```bash
# View specific revision
kubectl rollout history deployment/backend --revision=3

# Rollback to revision 3
kubectl rollout undo deployment/backend --to-revision=3
```

**Method 3: Manual rollback (if needed)**
```bash
# Set image back to previous version
kubectl set image deployment/backend backend=myapp:v1

# Or edit deployment
kubectl edit deployment/backend
# Change image back
```

**Verification:**
```bash
# Check current image
kubectl describe deployment/backend | grep Image

# Check Pods
kubectl get pods -l app=backend

# Test application
curl http://<service>/health
```

**Best Practices:**
- Always test in staging first
- Keep revision history (default: 10)
- Monitor during rollout
- Have rollback plan ready
- Use canary deployments for critical updates

---

## 14. Multiple Choice: Which component ensures that the desired number of Pod replicas are always running?

A. Service  
B. ReplicaSet  
C. ConfigMap  
D. PersistentVolume

**Answer: B**

**Explanation:** ReplicaSet (managed by Deployment) ensures the desired number of Pod replicas are running. It creates/deletes Pods to match the desired count.

---

## 15. Explain the complete deployment process for a 3-tier application from scratch.

**Answer:**

**Step 1: Prepare application images**
```bash
# Build and push images (or use minikube's Docker)
eval $(minikube docker-env)
docker build -t frontend:v1 ./frontend
docker build -t backend:v1 ./backend
```

**Step 2: Create namespace**
```bash
kubectl create namespace myapp
```

**Step 3: Create ConfigMaps and Secrets**
```bash
# Backend config
kubectl create configmap backend-config \
  --from-literal=PORT=3000 \
  --from-literal=LOG_LEVEL=info \
  -n myapp

# Database secret
kubectl create secret generic db-secret \
  --from-literal=password=SuperSecret123! \
  -n myapp
```

**Step 4: Deploy Database (StatefulSet)**
```bash
kubectl apply -f database.yaml -n myapp
kubectl wait --for=condition=ready pod -l app=postgres -n myapp --timeout=120s
```

**Step 5: Deploy Backend**
```bash
kubectl apply -f backend.yaml -n myapp
kubectl wait --for=condition=ready pod -l app=backend -n myapp --timeout=120s
```

**Step 6: Deploy Frontend**
```bash
kubectl apply -f frontend.yaml -n myapp
```

**Step 7: Verify deployment**
```bash
# Check all resources
kubectl get all -n myapp

# Check Pods are Running
kubectl get pods -n myapp

# Check Services
kubectl get svc -n myapp

# Test connectivity
kubectl port-forward -n myapp svc/frontend-service 8080:80
# Access http://localhost:8080
```

**Step 8: Monitor and test**
```bash
# View logs
kubectl logs -n myapp -l app=backend --tail=50

# Test API
curl http://localhost:8080/api/health

# Check database
kubectl exec -n myapp -it postgres-0 -- psql -c "SELECT version();"
```

**Order matters:**
1. Database first (backend depends on it)
2. Backend second (frontend depends on it)
3. Frontend last

---

## 16. What are the key differences between a Deployment and a StatefulSet?

**Answer:**

| Feature | Deployment | StatefulSet |
|---------|-----------|-------------|
| **Use case** | Stateless applications | Stateful applications |
| **Pod naming** | Random (app-abc123-xyz) | Ordered (app-0, app-1, app-2) |
| **Storage** | Shared or none | Each Pod gets own PVC |
| **Network** | Shared Service IP | Stable DNS per Pod |
| **Scaling** | Any order | Ordered (0, 1, 2...) |
| **Updates** | Rolling update | Ordered update |
| **Identity** | No stable identity | Stable identity |
| **Examples** | Web servers, APIs | Databases, message queues |

**When to use:**
- **Deployment**: Stateless apps (frontend, backend API, workers)
- **StatefulSet**: Stateful apps (databases, message queues, distributed systems)

---

## 17. Multiple Choice: In a 3-tier application, which Service type should the database Service use?

A. NodePort  
B. LoadBalancer  
C. ClusterIP  
D. ExternalName

**Answer: C**

**Explanation:** Database Services should use ClusterIP (internal only) because:
- Databases should not be exposed externally (security)
- Only backend needs to access database
- ClusterIP provides internal service discovery
- No external attack surface

