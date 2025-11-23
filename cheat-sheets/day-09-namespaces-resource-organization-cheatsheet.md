# Day 9: Namespaces & Resource Organization - Cheat Sheet

## Quick Reference

### Namespace Basics

```bash
# List all namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace <name>
kubectl create ns <name>

# Delete namespace (⚠️ deletes ALL resources!)
kubectl delete namespace <name>

# View resources in namespace
kubectl get pods -n <namespace>
kubectl get all -n <namespace>

# Set default namespace
kubectl config set-context --current --namespace=<namespace>

# View current namespace
kubectl config view --minify | grep namespace:
```

### Default Namespaces

| Namespace | Purpose |
|-----------|---------|
| `default` | Default for objects with no namespace |
| `kube-system` | Kubernetes system components |
| `kube-public` | Publicly readable |
| `kube-node-lease` | Node heartbeat/lease objects |

### Creating Namespaces (YAML)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <namespace-name>
  labels:
    environment: dev
    team: frontend
  annotations:
    description: "Description here"
```

### Deploying to Namespaces

**In command:**
```bash
kubectl run nginx --image=nginx -n <namespace>
kubectl create deployment web --image=nginx -n <namespace>
```

**In YAML:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: development  # 👈 Specify here
spec:
  # ...
```

### Cross-Namespace Communication

**DNS Format:**
```
<service-name>.<namespace>.svc.cluster.local
```

**Examples:**
```bash
# Same namespace
curl http://backend-service:3000

# Different namespace (short)
curl http://backend-service.backend-ns:3000

# Different namespace (full FQDN)
curl http://backend-service.backend-ns.svc.cluster.local:3000
```

### Resource Scopes

**Namespace-Scoped (most resources):**
- Pods, Deployments, Services
- ConfigMaps, Secrets
- PersistentVolumeClaims
- Jobs, CronJobs

**Cluster-Scoped:**
- Namespaces
- Nodes
- PersistentVolumes
- StorageClasses
- ClusterRoles, ClusterRoleBindings

**Check scope:**
```bash
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false
```

### ResourceQuota

**Create ResourceQuota:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: <quota-name>
  namespace: <namespace>
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    pods: "10"
    services: "5"
    configmaps: "10"
    secrets: "10"
    persistentvolumeclaims: "3"
    requests.storage: "50Gi"
```

**View quotas:**
```bash
kubectl get resourcequota -n <namespace>
kubectl describe resourcequota <quota-name> -n <namespace>
```

**Important:** When ResourceQuota exists, ALL pods MUST specify resource requests/limits!

### LimitRange

**Create LimitRange:**
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: <limit-name>
  namespace: <namespace>
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
  - type: Pod
    max:
      cpu: "4"
      memory: "4Gi"
  - type: PersistentVolumeClaim
    min:
      storage: "1Gi"
    max:
      storage: "50Gi"
```

**View LimitRange:**
```bash
kubectl get limitrange -n <namespace>
kubectl describe limitrange <limit-name> -n <namespace>
```

### Querying with Labels

```bash
# Query namespaces by label
kubectl get ns -l environment=production
kubectl get ns -l team=platform

# View labels
kubectl get ns --show-labels

# Query resources across namespaces
kubectl get deployments --all-namespaces -l app=myapp
```

### Multi-Tenant Setup

**Complete example:**
```yaml
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    team: team-a

---
# ResourceQuota
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

---
# LimitRange
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
```

### Common Patterns

**Environment-based:**
```bash
kubectl create ns development
kubectl create ns staging
kubectl create ns production
```

**Team-based:**
```bash
kubectl create ns team-frontend
kubectl create ns team-backend
kubectl create ns team-platform
```

**Service-based:**
```bash
kubectl create ns user-service
kubectl create ns order-service
kubectl create ns payment-service
```

### Best Practices

✅ **DO:**
- Use namespaces for organization (by team, environment, service)
- Set ResourceQuotas for non-prod environments
- Use LimitRange to set defaults
- Label namespaces for easy querying
- Use cross-namespace DNS for service communication

❌ **DON'T:**
- Create too many namespaces (management overhead)
- Forget to specify namespace in YAML
- Skip quotas (resource exhaustion risk)
- Use default namespace for production
- Delete namespaces without checking contents

### Troubleshooting

**Check namespace resources:**
```bash
kubectl get all -n <namespace>
kubectl describe namespace <namespace>
```

**Check quota usage:**
```bash
kubectl describe resourcequota -n <namespace>
```

**Check if resource is namespaced:**
```bash
kubectl api-resources | grep <resource-type>
```

**View resources across all namespaces:**
```bash
kubectl get pods --all-namespaces
kubectl get deployments --all-namespaces
```

### Key Concepts

- **Namespaces** = Virtual clusters for isolation and organization
- **ResourceQuota** = Limits total resources per namespace
- **LimitRange** = Sets default and max/min limits per container/pod
- **DNS** = `<service>.<namespace>.svc.cluster.local` for cross-namespace
- **Scope** = Most resources are namespace-scoped, some are cluster-scoped


