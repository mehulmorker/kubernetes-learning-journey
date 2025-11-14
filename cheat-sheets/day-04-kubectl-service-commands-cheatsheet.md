# Day 4: Kubernetes Services Cheat Sheet

## Service Types Quick Reference

| Type | Use Case | Access | Port Range |
|------|----------|--------|------------|
| **ClusterIP** | Internal services | Within cluster only | Any |
| **NodePort** | Development/testing | NodeIP:30000-32767 | 30000-32767 |
| **LoadBalancer** | Production external access | Cloud LB IP | Any |
| **ExternalName** | External services | DNS alias | N/A |

## Core Commands

### Service Management

```bash
# Create service imperatively
kubectl expose deployment <name> --type=ClusterIP --port=80 --target-port=3000

# List all services
kubectl get services
kubectl get svc

# Describe service
kubectl describe svc <service-name>

# Delete service
kubectl delete svc <service-name>

# Apply service from YAML
kubectl apply -f service.yaml
```

### Service Discovery & Testing

```bash
# Test service from within cluster
kubectl run test-pod --image=alpine --rm -it -- sh
curl http://<service-name>:<port>

# Get service IP
kubectl get svc <service-name> -o jsonpath='{.spec.clusterIP}'

# Access NodePort
minikube service <service-name>
curl http://$(minikube ip):<nodePort>

# LoadBalancer tunnel (minikube)
minikube tunnel
```

### Endpoints

```bash
# View endpoints (Pod IPs)
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>

# Watch endpoints update
kubectl get endpoints <service-name> -w
```

## Service YAML Template

### ClusterIP (Default)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
```

### NodePort

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30080  # Optional (30000-32767)
```

### LoadBalancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 3000
```

### Headless Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  clusterIP: None  # Headless!
  selector:
    app: my-app
  ports:
  - port: 3000
```

### Multi-Port Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - name: http
    port: 80
    targetPort: 3000
  - name: metrics
    port: 9090
    targetPort: 9090
```

### Session Affinity

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  ports:
  - port: 80
    targetPort: 3000
```

## DNS Naming

### Service DNS Format

```
<service-name>.<namespace>.svc.cluster.local
```

### Examples

```bash
# Same namespace (shortest)
my-service

# Explicit namespace
my-service.default

# Fully qualified
my-service.default.svc.cluster.local
```

### Usage in Code

```javascript
// Frontend calling backend
const response = await axios.get('http://backend-service:80');
```

## Service Without Selector (External Service)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
  - port: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db
subsets:
- addresses:
  - ip: 192.168.1.100
  ports:
  - port: 5432
```

## Key Concepts

### Port Mapping

- **port**: Service port (what clients connect to)
- **targetPort**: Pod container port (where traffic goes)
- **nodePort**: Node port for NodePort services (30000-32767)

### Service Selector

- Uses **labels** to find Pods
- Must match Pod labels exactly
- Creates Endpoints automatically

### Load Balancing

- **Default**: Random distribution
- **Session Affinity**: Sticky sessions by client IP
- **Round-robin**: Automatic across all Pods

## Troubleshooting

### Service Has No Endpoints

```bash
# Check selector matches Pod labels
kubectl get pods --show-labels
kubectl get svc <service-name> -o yaml | grep selector

# Check endpoints
kubectl get endpoints <service-name>
```

### Service Not Accessible

```bash
# Verify service exists
kubectl get svc

# Check Pods are running
kubectl get pods -l app=<label>

# Test from within cluster
kubectl run test --image=alpine --rm -it -- wget -qO- http://<service-name>
```

### DNS Not Resolving

```bash
# Test DNS from Pod
kubectl run test --image=alpine --rm -it -- sh
apk add --no-cache bind-tools
nslookup <service-name>
```

## Service Patterns

| Pattern | Service Type | When to Use |
|---------|-------------|-------------|
| Internal API | ClusterIP | Microservices communication |
| Development | NodePort | Local testing, quick access |
| Production Web | LoadBalancer | External user access |
| Stateful Sets | Headless | Direct Pod access, DNS records |
| External DB | Service + Endpoints | Connect to external resources |

## Quick Reference: Service Lifecycle

1. **Create Service** → Kubernetes assigns ClusterIP
2. **Selector matches Pods** → Endpoints created automatically
3. **Pods change** → Endpoints update automatically
4. **DNS entry created** → `<service-name>.<namespace>.svc.cluster.local`
5. **Traffic routes** → Load balanced to Pod IPs

## Common Workflows

### Expose Deployment

```bash
# Quick expose
kubectl expose deployment my-app --port=80 --target-port=3000

# With specific type
kubectl expose deployment my-app --type=NodePort --port=80 --target-port=3000
```

### Update Service

```bash
# Edit service
kubectl edit svc <service-name>

# Or apply updated YAML
kubectl apply -f service.yaml
```

### Scale and Verify

```bash
# Scale deployment
kubectl scale deployment my-app --replicas=5

# Watch endpoints update
kubectl get endpoints my-service -w
```

## Best Practices

✅ **DO:**
- Use DNS names, not IPs
- Use ClusterIP for internal services
- Use descriptive service names
- Match selectors to Pod labels exactly
- Use named ports for multi-port services

❌ **DON'T:**
- Hardcode Pod IPs
- Use NodePort in production (unless needed)
- Create services without matching Pods
- Forget to check endpoints
- Use default namespace in production

