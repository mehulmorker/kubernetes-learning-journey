# Day 8: Labels, Selectors & Annotations - Cheat Sheet

## Labels vs Annotations

| Feature | Labels | Annotations |
|---------|--------|-------------|
| **Purpose** | Identification & selection | Metadata & documentation |
| **Used by** | Kubernetes (selectors) | Humans & tools |
| **Size limit** | 63 chars (value) | 256 KB total |
| **Queryable** | Yes (with selectors) | No |

## Label Syntax Rules

### Valid Labels
```yaml
app: frontend
version: 1.0.0
environment: production
team.name: platform
app.kubernetes.io/name: nginx
```

### Invalid Labels
```yaml
app: "with spaces"  # ❌ No spaces
version: "ver@1.0"  # ❌ No special chars (except - _ .)
toolongkeythatexceedssixtythreecharacterslimitisnotallowed: value  # ❌ Too long
```

## Recommended Label Keys

```yaml
app.kubernetes.io/name: nginx
app.kubernetes.io/instance: my-nginx
app.kubernetes.io/version: "1.0.0"
app.kubernetes.io/component: backend
app.kubernetes.io/part-of: ecommerce
app.kubernetes.io/managed-by: helm
```

## Label Commands

### Imperative Label Management
```bash
# Create pod with labels
kubectl run nginx-pod --image=nginx --labels="app=nginx,env=dev"

# View labels
kubectl get pods --show-labels
kubectl get pods -L app,environment,version

# Add label
kubectl label pod nginx-pod version=1.0

# Update label
kubectl label pod nginx-pod version=2.0 --overwrite

# Remove label
kubectl label pod nginx-pod version-
```

### Declarative Labels (YAML)
```yaml
metadata:
  labels:
    app: myapp
    environment: production
    version: "1.0.0"
```

## Label Selectors

### Equality-Based Selectors
```bash
# Single label
kubectl get pods -l app=ecommerce

# Multiple labels (AND)
kubectl get pods -l app=ecommerce,environment=production

# NOT equal
kubectl get pods -l environment!=development

# Label doesn't exist
kubectl get pods -l '!version'

# Combined
kubectl get pods -l 'app=ecommerce,environment!=development'
```

### Set-Based Selectors
```bash
# IN operator
kubectl get pods -l 'environment in (staging,production)'

# NOT IN operator
kubectl get pods -l 'environment notin (development)'

# Label exists
kubectl get pods -l version

# Label doesn't exist
kubectl get pods -l '!version'

# Complex query
kubectl get pods -l 'app=ecommerce,environment in (staging,production),tier=web'
```

## Labels in Services

### Service with Label Selector
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: myapp
    tier: frontend
  ports:
  - port: 80
    targetPort: 80
```

### Check Service Endpoints
```bash
kubectl get endpoints web-service
kubectl describe svc web-service
kubectl get pods -l app=myapp,tier=frontend
```

## Annotations

### Common Annotation Use Cases
```yaml
metadata:
  annotations:
    description: "User authentication service"
    owner: "platform-team@company.com"
    repository: "https://github.com/company/user-service"
    build-date: "2024-11-19"
    git-commit: "a3f5d2e"
    kubernetes.io/change-cause: "Updated to version 2.0"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
```

### Annotation Commands
```bash
# View annotations
kubectl describe deployment myapp | grep -A 10 Annotations

# Add annotation
kubectl annotate deployment myapp \
  last-updated="$(date)" \
  updated-by="$(whoami)"

# Update annotation
kubectl annotate deployment myapp version="2.1.0" --overwrite

# Remove annotation
kubectl annotate deployment myapp version-

# View pod annotations
kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.annotations}' | jq
```

## Label-Based Operations

### Selective Operations
```bash
# Delete by label
kubectl delete pods -l environment=development

# Scale by label
kubectl scale deployment -l environment=production --replicas=5

# Get logs by label
kubectl logs -l tier=backend --tail=10

# Port-forward by label
kubectl port-forward -l version=v2 8080:80
```

### Query All Resources
```bash
# All resources with label
kubectl get all -l app=myapp

# All production resources
kubectl get all -l environment=production

# All team resources
kubectl get all -l team=backend-team
```

## Canary Deployment Pattern

```yaml
# Version 1 (90% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
      labels:
        app: myapp
        version: v1

---
# Version 2 (10% traffic - canary)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: v2
  template:
    metadata:
      labels:
        app: myapp
        version: v2

---
# Service targets both
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp  # Matches both v1 and v2
  ports:
  - port: 80
```

## Standard Label Set

```yaml
metadata:
  labels:
    # What
    app.kubernetes.io/name: user-service
    app.kubernetes.io/component: backend
    
    # Version
    app.kubernetes.io/version: "2.0.0"
    
    # Context
    app.kubernetes.io/part-of: ecommerce-platform
    app.kubernetes.io/managed-by: helm
    
    # Custom
    environment: production
    team: backend-team
    cost-center: engineering
```

## Best Practices

### Do's ✅
- Use standard label keys (`app.kubernetes.io/*`)
- Keep labels consistent across resources
- Use 3-8 labels per resource
- Use labels for identification and selection
- Use annotations for metadata

### Don'ts ❌
- Don't use spaces in label values
- Don't use special characters (except `-`, `_`, `.`)
- Don't exceed 63 characters for label values
- Don't use too many labels (keep it simple)
- Don't use annotations for selection
- Don't forget to label new resources

## Quick Reference

```bash
# Label Management
kubectl label <resource> <name> <key>=<value>
kubectl label <resource> <name> <key>=<value> --overwrite
kubectl label <resource> <name> <key>-

# Annotation Management
kubectl annotate <resource> <name> <key>=<value>
kubectl annotate <resource> <name> <key>=<value> --overwrite
kubectl annotate <resource> <name> <key>-

# Querying
kubectl get <resource> -l <selector>
kubectl get <resource> --show-labels
kubectl get <resource> -L <label1>,<label2>

# Operations
kubectl delete <resource> -l <selector>
kubectl scale deployment -l <selector> --replicas=<n>
kubectl logs -l <selector>
kubectl port-forward -l <selector> <local>:<remote>
```


