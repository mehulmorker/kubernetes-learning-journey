# Day 9: Namespaces & Resource Organization

Great progress! Today we'll learn how to organize Kubernetes resources using Namespaces - virtual clusters that provide isolation, organization, and boundaries for teams, environments, and applications.

## Part 1: Why Namespaces? (15 minutes)

### The Isolation Problem

Imagine a shared Kubernetes cluster with:

- 5 development teams
- 3 environments (dev, staging, prod)
- 20+ applications
- 500+ pods

**Without namespaces:**

```bash
kubectl get pods
# Returns ALL 500 pods mixed together! 😱

# Risks:
# - Accidentally delete production pods
# - Name conflicts (two teams want "api" deployment)
# - No resource quotas per team
# - Difficult to organize and manage
```

**With namespaces:**

```bash
kubectl get pods -n team-frontend    # Only frontend team's pods
kubectl get pods -n production       # Only production pods
kubectl get pods -n development      # Only dev pods

# Benefits:
# ✅ Isolation and organization
# ✅ No name conflicts
# ✅ Resource quotas per namespace
# ✅ Access control boundaries
# ✅ Better operational safety
```

### **What Are Namespaces?**

Namespaces provide:
- **Logical separation** of resources
- **Name scoping** (names must be unique within namespace, not across)
- **Resource isolation** (quotas, limits, policies)
- **Access control** (RBAC boundaries)
- **Organization** (by team, environment, application, customer)

```
┌─────────────────────────────────────────────┐
│         Kubernetes Cluster                  │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Namespace:   │  │ Namespace:   │       │
│  │ production   │  │ development  │       │
│  │              │  │              │       │
│  │ - Pods       │  │ - Pods       │       │
│  │ - Services   │  │ - Services   │       │
│  │ - ConfigMaps │  │ - ConfigMaps │       │
│  └──────────────┘  └──────────────┘       │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Namespace:   │  │ Namespace:   │       │
│  │ team-a       │  │ team-b       │       │
│  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────┘
```

## Part 2: Default Namespaces (10 minutes)

### Built-in Namespaces

Kubernetes comes with default namespaces:

```bash
# List all namespaces
kubectl get namespaces
# or shorthand:
kubectl get ns
```

You'll see:

| Namespace | Purpose |
|-----------|---------|
| default | Default namespace for objects with no namespace specified |
| kube-system | Kubernetes system components (DNS, metrics, etc.) |
| kube-public | Publicly readable (even by unauthenticated users) |
| kube-node-lease | Node heartbeat/lease objects |

```bash
# View resources in each namespace
kubectl get pods -n default
kubectl get pods -n kube-system
kubectl get all -n kube-system  # See system components
```

**Important:** Most Kubernetes system components run in kube-system:

```bash
kubectl get pods -n kube-system

# You'll see:
# - coredns (DNS server)
# - kube-proxy (networking)
# - etcd (data store)
# - kube-apiserver, kube-controller-manager, kube-scheduler
```

## Part 3: Creating and Using Namespaces (25 minutes)

### Method 1: Imperative

```bash
# Create namespace
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# Or shorthand:
kubectl create ns team-frontend
kubectl create ns team-backend

# List namespaces
kubectl get ns

# Delete namespace (⚠️ deletes ALL resources in it!)
kubectl delete namespace team-backend
```

### Method 2: Declarative (YAML)

Create `namespaces.yaml`:

```yaml
# Development namespace
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: development
    team: all
  annotations:
    description: "Development environment for all teams"

---
# Staging namespace
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    team: all
  annotations:
    description: "Staging environment for testing"

---
# Production namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    team: all
  annotations:
    description: "Production environment - CRITICAL"
    contact: "ops-team@company.com"

---
# Team-based namespace
apiVersion: v1
kind: Namespace
metadata:
  name: team-platform
  labels:
    team: platform
    cost-center: engineering
  annotations:
    description: "Platform team namespace"
    owner: "platform-team@company.com"
```

```bash
# Apply namespaces
kubectl apply -f namespaces.yaml

# View with labels
kubectl get ns --show-labels

# Query namespaces by label
kubectl get ns -l environment=production
kubectl get ns -l team=platform
```

### Deploying Resources to Namespaces

#### Method 1: Specify in command

```bash
# Create pod in specific namespace
kubectl run nginx --image=nginx -n development

# Create deployment in namespace
kubectl create deployment web --image=nginx --replicas=3 -n staging

# View resources
kubectl get pods -n development
kubectl get deployments -n staging
```

#### Method 2: Specify in YAML

Create `namespaced-app.yaml`:

```yaml
# Development deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: development    # 👈 Specify namespace
  labels:
    app: web
    environment: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        environment: dev
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80

---
# Service in same namespace
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: development    # 👈 Must match deployment namespace
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP

---
# Staging deployment (same app, different namespace)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: staging        # 👈 Different namespace, same name!
  labels:
    app: web
    environment: staging
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        environment: staging
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: staging
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

```bash
# Apply - creates same-named resources in different namespaces
kubectl apply -f namespaced-app.yaml

# View both
kubectl get deployments -n development
kubectl get deployments -n staging

# Notice: Same name "web-app" in different namespaces!
```

## Part 4: Working Across Namespaces (20 minutes)

### Setting Default Namespace

Instead of typing `-n namespace` every time:

```bash
# View current context
kubectl config current-context

# Set default namespace for current context
kubectl config set-context --current --namespace=development

# Now all commands use development namespace by default
kubectl get pods        # Shows development pods
kubectl get services    # Shows development services

# Switch to different namespace
kubectl config set-context --current --namespace=staging

# View current namespace
kubectl config view --minify | grep namespace:

# Reset to default namespace
kubectl config set-context --current --namespace=default
```

### **Cross-Namespace Communication**

Services in different namespaces can communicate:

**DNS format:**
```
<service-name>.<namespace>.svc.cluster.local
```

Create `cross-namespace-demo.yaml`:

```yaml
# Namespace for backend
apiVersion: v1
kind: Namespace
metadata:
  name: backend-ns

---
# Backend service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: backend-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: api
        image: node:18-alpine
        command: ['sh', '-c']
        args:
          - |
            cat > server.js << 'EOF'
            const http = require('http');
            const server = http.createServer((req, res) => {
              res.writeHead(200, {'Content-Type': 'application/json'});
              res.end(JSON.stringify({
                message: 'Backend API',
                namespace: 'backend-ns',
                hostname: require('os').hostname()
              }));
            });
            server.listen(3000, () => console.log('Backend listening on 3000'));
            EOF
            node server.js
        ports:
        - containerPort: 3000

---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend-ns
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000

---
# Namespace for frontend
apiVersion: v1
kind: Namespace
metadata:
  name: frontend-ns

---
# Frontend calling backend in different namespace
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: frontend-ns
spec:
  containers:
  - name: curl
    image: alpine
    command: ['sh', '-c']
    args:
      - |
        apk add --no-cache curl
        echo "Frontend in frontend-ns"
        echo "Calling backend in backend-ns..."
        while true; do
          echo "=== Calling backend-service.backend-ns.svc.cluster.local ==="
          curl -s http://backend-service.backend-ns.svc.cluster.local:3000
          echo ""
          sleep 10
        done
```

```bash
# Apply
kubectl apply -f cross-namespace-demo.yaml

# Watch frontend logs (calling backend in different namespace)
kubectl logs -n frontend-ns frontend -f

# You'll see successful cross-namespace communication!
```

### DNS Resolution Examples:

```bash
# From frontend-ns pod, you can call:
# Same namespace (if backend was in frontend-ns):
curl http://backend-service:3000

# Different namespace (short form):
curl http://backend-service.backend-ns:3000

# Different namespace (full FQDN):
curl http://backend-service.backend-ns.svc.cluster.local:3000
```

## Part 5: Namespace-Scoped vs Cluster-Scoped Resources (15 minutes)

### Not all resources are namespaced!

#### Namespace-Scoped Resources

Most resources are namespace-scoped:

```bash
# These MUST belong to a namespace:
- Pods
- Deployments
- ReplicaSets
- Services
- ConfigMaps
- Secrets
- PersistentVolumeClaims
- Jobs
- CronJobs
```

#### Cluster-Scoped Resources

Some resources are cluster-wide:

```bash
# These exist at cluster level (no namespace):
- Namespaces (obviously!)
- Nodes
- PersistentVolumes
- StorageClasses
- ClusterRoles
- ClusterRoleBindings
```

### Check resource scope:

```bash
# List all API resources and their scope
kubectl api-resources

# Filter namespaced resources
kubectl api-resources --namespaced=true

# Filter cluster-scoped resources
kubectl api-resources --namespaced=false
```

## Part 6: Resource Quotas per Namespace (25 minutes)

### Why Resource Quotas?

Prevent one namespace from consuming all cluster resources:

```javascript
// Without quotas:
const problems = {
  teamA: "Uses 90% of cluster CPU",
  teamB: "Can't deploy due to resource exhaustion",
  dev: "Accidentally creates 1000 pods",
  noControl: "No limits on resource usage"
};

// With quotas:
const solution = {
  teamA: "Limited to 10 CPU cores",
  teamB: "Guaranteed minimum resources",
  dev: "Max 50 pods allowed",
  control: "Fair resource distribution"
};
```

### Creating ResourceQuota

Create `resource-quotas.yaml`:

```yaml
# Development namespace with quotas
apiVersion: v1
kind: Namespace
metadata:
  name: dev-limited

---
# ResourceQuota for dev namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev-limited
spec:
  hard:
    # Compute resources
    requests.cpu: "2"           # Total CPU requests: 2 cores
    requests.memory: "4Gi"      # Total memory requests: 4GB
    limits.cpu: "4"             # Total CPU limits: 4 cores
    limits.memory: "8Gi"        # Total memory limits: 8GB
    
    # Object counts
    pods: "10"                  # Max 10 pods
    services: "5"               # Max 5 services
    configmaps: "10"            # Max 10 ConfigMaps
    secrets: "10"               # Max 10 Secrets
    persistentvolumeclaims: "3" # Max 3 PVCs
    
    # Storage
    requests.storage: "50Gi"    # Total storage requests: 50GB

---
# Production namespace with higher quotas
apiVersion: v1
kind: Namespace
metadata:
  name: prod-limited

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: prod-limited
spec:
  hard:
    requests.cpu: "20"
    requests.memory: "64Gi"
    limits.cpu: "40"
    limits.memory: "128Gi"
    pods: "100"
    services: "50"
```

```bash
# Apply quotas
kubectl apply -f resource-quotas.yaml

# View quotas
kubectl get resourcequota -n dev-limited
kubectl describe resourcequota dev-quota -n dev-limited
```

### Testing Resource Quotas

Try to exceed quota:

```bash
# This will fail if it exceeds quota
kubectl apply -n dev-limited -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
spec:
  replicas: 15              # 👈 Exceeds pod quota (max 10)
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
EOF

# Check quota usage
kubectl describe resourcequota dev-quota -n dev-limited
```

**Important:** When ResourceQuota is active, all pods MUST specify resource requests/limits!

```yaml
# This will be REJECTED in a namespace with ResourceQuota:
spec:
  containers:
  - name: app
    image: nginx
    # ❌ No resources specified!

# This will be ACCEPTED:
spec:
  containers:
  - name: app
    image: nginx
    resources:                # ✅ Resources specified
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
```

## Part 7: LimitRange - Default Resource Limits (20 minutes)

**Problem:** Every pod needs resource requests/limits when quota exists. Tedious!

**Solution:** LimitRange sets defaults automatically.

Create `limit-ranges.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: auto-limited

---
# LimitRange sets defaults and boundaries
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: auto-limited
spec:
  limits:
  # Container limits
  - type: Container
    default:                    # Default limits (if not specified)
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:             # Default requests (if not specified)
      cpu: "100m"
      memory: "128Mi"
    max:                        # Maximum allowed
      cpu: "2"
      memory: "2Gi"
    min:                        # Minimum required
      cpu: "50m"
      memory: "64Mi"
    maxLimitRequestRatio:       # Max ratio of limit/request
      cpu: "4"
      memory: "4"
  
  # Pod limits (sum of all containers)
  - type: Pod
    max:
      cpu: "4"
      memory: "4Gi"
  
  # PVC limits
  - type: PersistentVolumeClaim
    min:
      storage: "1Gi"
    max:
      storage: "50Gi"
```

```bash
# Apply
kubectl apply -f limit-ranges.yaml

# View LimitRange
kubectl get limitrange -n auto-limited
kubectl describe limitrange resource-limits -n auto-limited
```

### Testing LimitRange

Create pod WITHOUT specifying resources:

```bash
# This pod doesn't specify resources
kubectl apply -n auto-limited -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: auto-resources
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    # 👈 No resources specified!
EOF

# Check what resources were automatically assigned
kubectl describe pod auto-resources -n auto-limited | grep -A 10 "Limits\|Requests"

# You'll see default values from LimitRange were applied!
```

Try to exceed limits:

```bash
# This will be REJECTED (exceeds max CPU)
kubectl apply -n auto-limited -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: too-big
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    resources:
      requests:
        cpu: "3"        # 👈 Exceeds max CPU (2)
        memory: "512Mi"
EOF

# Error: exceeded quota
```

## Part 8: Multi-Tenant Cluster Example (20 minutes)

Let's build a complete multi-tenant setup:

Create `multi-tenant-cluster.yaml`:

```yaml
# Team A Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    team: team-a
    cost-center: engineering

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "5"
    requests.memory: "10Gi"
    limits.cpu: "10"
    limits.memory: "20Gi"
    pods: "20"
    services: "10"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: team-a-limits
  namespace: team-a
spec:
  limits:
  - type: Container
    default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "1"
      memory: "2Gi"

---
# Team B Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: team-b
  labels:
    team: team-b
    cost-center: engineering

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-b-quota
  namespace: team-b
spec:
  hard:
    requests.cpu: "3"
    requests.memory: "6Gi"
    limits.cpu: "6"
    limits.memory: "12Gi"
    pods: "15"
    services: "8"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: team-b-limits
  namespace: team-b
spec:
  limits:
  - type: Container
    default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "1"
      memory: "2Gi"

---
# Shared Services Namespace (no quota)
apiVersion: v1
kind: Namespace
metadata:
  name: shared-services
  labels:
    type: shared
    cost-center: platform
```

```bash
# Apply multi-tenant setup
kubectl apply -f multi-tenant-cluster.yaml

# Deploy apps for each team
kubectl create deployment app-a --image=nginx --replicas=3 -n team-a
kubectl create deployment app-b --image=nginx --replicas=2 -n team-b

# Check resource usage per team
echo "=== Team A Resources ==="
kubectl top pods -n team-a
kubectl describe resourcequota team-a-quota -n team-a

echo "=== Team B Resources ==="
kubectl top pods -n team-b
kubectl describe resourcequota team-b-quota -n team-b

# List all team namespaces
kubectl get ns -l cost-center=engineering
```

## 📝 Day 9 Homework (40-50 minutes)

### Exercise 1: Environment-Based Namespaces

Create complete environment separation:

```yaml
# environments.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: dev
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
```

Deploy the same application to all three with different configurations:

```bash
# Deploy to dev
kubectl create deployment myapp --image=nginx --replicas=1 -n development

# Deploy to staging
kubectl create deployment myapp --image=nginx --replicas=2 -n staging

# Deploy to production
kubectl create deployment myapp --image=nginx --replicas=5 -n production

# List all deployments across environments
kubectl get deployments --all-namespaces -l app=myapp
```

### Exercise 2: Microservices with Namespaces

Create namespace per microservice:

```yaml
# microservices.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: user-service
---
apiVersion: v1
kind: Namespace
metadata:
  name: order-service
---
apiVersion: v1
kind: Namespace
metadata:
  name: payment-service
```

Deploy services and test cross-namespace communication.

### Exercise 3: Resource Quota Management

Create a namespace with tight quotas and test limits:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: quota-test
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tight-quota
  namespace: quota-test
spec:
  hard:
    pods: "5"
    requests.cpu: "1"
    requests.memory: "1Gi"
```

Try to:

1. Deploy 10 pods (should fail)
2. Deploy pods without resource specs (should fail)
3. Deploy within limits (should succeed)

### Exercise 4: Complete Multi-Environment Project

Deploy your Week 1 e-commerce project to multiple namespaces:

```bash
# Create namespaces
kubectl create ns ecommerce-dev
kubectl create ns ecommerce-staging
kubectl create ns ecommerce-prod

# Deploy to each (adjust replicas and resources per environment)
kubectl apply -f k8s-manifests/ -n ecommerce-dev
kubectl apply -f k8s-manifests/ -n ecommerce-staging
kubectl apply -f k8s-manifests/ -n ecommerce-prod

# Access each environment
minikube service frontend-service -n ecommerce-dev
minikube service frontend-service -n ecommerce-staging
minikube service frontend-service -n ecommerce-prod
```

### Exercise 5: Namespace Cleanup Script

Create a management script:

```bash
#!/bin/bash
# namespace-manager.sh

ACTION=$1
ENV=$2

case $ACTION in
  "create")
    kubectl create ns $ENV
    kubectl label ns $ENV environment=$ENV
    ;;
  "list")
    kubectl get all -n $ENV
    ;;
  "quota")
    kubectl describe resourcequota -n $ENV
    ;;
  "cleanup")
    kubectl delete ns $ENV
    ;;
  *)
    echo "Usage: $0 {create|list|quota|cleanup} <namespace>"
    ;;
esac
```

## ✅ Day 9 Checklist

Before moving to Day 10, ensure you can:

- [ ] Explain why namespaces are needed
- [ ] Create namespaces imperatively and declaratively
- [ ] Deploy resources to specific namespaces
- [ ] Set default namespace for kubectl context
- [ ] Understand cross-namespace communication (DNS)
- [ ] Differentiate namespace-scoped vs cluster-scoped resources
- [ ] Create and apply ResourceQuotas
- [ ] Create and apply LimitRanges
- [ ] Understand quota enforcement
- [ ] Design multi-tenant cluster layout
- [ ] Query resources across namespaces
- [ ] Use labels to organize namespaces

## 🎯 Key Takeaways

```javascript
const namespaceBestPractices = {
  organization: {
    byEnvironment: "dev, staging, prod namespaces",
    byTeam: "team-a, team-b namespaces",
    byService: "user-svc, order-svc namespaces",
    hybrid: "team-a-prod, team-a-dev"
  },
  
  quotas: {
    always: "Set quotas for non-prod environments",
    careful: "Be generous with prod quotas",
    monitor: "Watch quota usage regularly"
  },
  
  communication: {
    sameNamespace: "service-name",
    crossNamespace: "service-name.namespace.svc.cluster.local",
    external: "Use Ingress or LoadBalancer"
  },
  
  avoid: [
    "Too many namespaces (management overhead)",
    "Not using namespaces (chaos)",
    "Forgetting to specify namespace in YAML",
    "No quotas (resource exhaustion risk)"
  ]
};
```

## 🔜 What's Next?

**Day 10 Preview:** Tomorrow we'll learn about DaemonSets & StatefulSets - specialized workload controllers for:

**DaemonSets:**
- Run one pod on every node
- Perfect for: logging agents, monitoring, network plugins
- Auto-scales with cluster (new node = new pod)

**StatefulSets:**
- For stateful applications (databases, message queues)
- Stable network identities
- Ordered deployment and scaling
- Persistent storage per pod

**Sneak peek:**

```yaml
# DaemonSet - automatically runs on all nodes
kind: DaemonSet
# Every node gets a log-collector pod!

# StatefulSet - stable identities
kind: StatefulSet
# Pods named: db-0, db-1, db-2 (stable, predictable)
```

**When ready:**
- ✅ "Day 9 complete" - move to Day 10 (DaemonSets & StatefulSets)
- ❓ Questions? - namespace strategies, quotas, multi-tenancy?
- 🔄 Need more practice? - I can create additional scenarios

How did Day 9 go? Namespaces making sense for organization? 🗂️


