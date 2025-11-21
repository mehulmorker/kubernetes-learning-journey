# Day 8: Labels, Selectors & Annotations

Excellent work completing Week 1! 🎉 You now have a solid foundation. Week 2 focuses on organizing and managing Kubernetes resources at scale.

Today we'll learn how to organize, query, and manage your Kubernetes resources effectively using labels, selectors, and annotations.

## Part 1: Why Labels Matter (15 minutes)

### The Organization Problem

Imagine you have 100+ pods across multiple applications, environments, and teams. How do you:

- Find all pods for a specific application?
- Update only production resources?
- Route traffic to specific versions?
- Organize resources by team, environment, or release?

**Labels solve this!**

### What Are Labels?

Labels are key-value pairs attached to Kubernetes objects for identification and organization.

```javascript
// Think of labels like object properties:
const pod = {
  metadata: {
    name: 'my-app-pod-xyz',
    labels: {
      app: 'my-app',           // Application name
      environment: 'production', // Environment
      version: 'v1.2.3',        // Version
      tier: 'backend',          // Tier/layer
      team: 'platform'          // Team ownership
    }
  }
};

// Now you can query: "Show me all production backend pods"
```

### Labels vs Annotations

| Feature | Labels | Annotations |
|---------|--------|-------------|
| **Purpose** | Identification & selection | Metadata & documentation |
| **Used by** | Kubernetes (selectors) | Humans & tools |
| **Size limit** | 63 chars (value) | 256 KB total |
| **Examples** | `app=frontend`, `env=prod` | `description="User service"` |
| **Queryable** | Yes (with selectors) | No |

## Part 2: Working with Labels (30 minutes)

### Label Syntax Rules

```yaml
# Valid labels
app: frontend               # Simple value
version: 1.0.0             # With dots
environment: production     # Descriptive
team.name: platform        # With subdomain
app.kubernetes.io/name: nginx  # Recommended prefix

# Invalid labels
app: "with spaces"         # ❌ No spaces
version: "ver@1.0"        # ❌ No special chars (except - _ .)
toolongkeythatexceedssixtythreecharacterslimitisnotallowed: value  # ❌ Too long
```

**Best Practice Naming:**

```yaml
# Recommended label keys (from Kubernetes)
app.kubernetes.io/name: nginx
app.kubernetes.io/instance: my-nginx
app.kubernetes.io/version: "1.0.0"
app.kubernetes.io/component: backend
app.kubernetes.io/part-of: ecommerce
app.kubernetes.io/managed-by: helm
```

### Creating Resources with Labels

**Method 1: Imperative**

```bash
# Create pod with labels
kubectl run nginx-pod \
  --image=nginx \
  --labels="app=nginx,env=dev,tier=frontend"

# Verify labels
kubectl get pods --show-labels

# Add label to existing pod
kubectl label pod nginx-pod version=1.0

# Update existing label (requires --overwrite)
kubectl label pod nginx-pod version=2.0 --overwrite

# Remove label (use minus sign)
kubectl label pod nginx-pod version-
```

**Method 2: Declarative (YAML)**

See `code-examples/pods/labeled-pods.yaml` for the complete example.

```bash
# Apply all pods
kubectl apply -f labeled-pods.yaml

# View all pods with labels
kubectl get pods --show-labels

# View specific label columns
kubectl get pods -L app,environment,version
```

## Part 3: Label Selectors - Querying Resources (30 minutes)

### Equality-Based Selectors

```bash
# Select by single label
kubectl get pods -l app=ecommerce

# Select by multiple labels (AND condition)
kubectl get pods -l app=ecommerce,environment=production

# Select where label does NOT equal value
kubectl get pods -l environment!=development

# Select pods without a specific label
kubectl get pods -l '!version'

# Combine multiple conditions
kubectl get pods -l 'app=ecommerce,environment!=development'
```

### Set-Based Selectors

```bash
# IN operator - matches any of the values
kubectl get pods -l 'environment in (staging,production)'

# NOT IN operator
kubectl get pods -l 'environment notin (development)'

# Check if label exists (regardless of value)
kubectl get pods -l version

# Check if label doesn't exist
kubectl get pods -l '!version'

# Complex query
kubectl get pods -l 'app=ecommerce,environment in (staging,production),tier=web'
```

### Practical Examples

See `code-examples/pods/multi-tier-app.yaml` for the complete example.

```bash
# Apply all
kubectl apply -f multi-tier-app.yaml

# Query examples
echo "=== All shop app pods ==="
kubectl get pods -l app=shop

echo "=== All production pods ==="
kubectl get pods -l env=prod

echo "=== All frontend pods ==="
kubectl get pods -l tier=frontend

echo "=== Production frontend pods ==="
kubectl get pods -l 'app=shop,tier=frontend,env=prod'

echo "=== All v1 pods ==="
kubectl get pods -l version=v1

echo "=== Non-production pods ==="
kubectl get pods -l 'env!=prod'

echo "=== Frontend or backend (not database) ==="
kubectl get pods -l 'tier in (frontend,backend)'
```

## Part 4: Labels in Services (20 minutes)

Services use label selectors to find pods.

See `code-examples/services/service-with-labels.yaml` for the complete example.

```bash
# Apply
kubectl apply -f service-with-labels.yaml

# Check service endpoints
kubectl get endpoints web-service

# Describe service to see selector
kubectl describe svc web-service

# View which pods match the service selector
kubectl get pods -l app=myapp,tier=frontend
```

### Label-Based Routing

You can use labels for canary deployments or A/B testing:

See `code-examples/deployments/canary-deployment.yaml` for the complete example.

## Part 5: Annotations (15 minutes)

### What Are Annotations?

Annotations store non-identifying metadata - information for humans or tools.

**Common Use Cases:**

```yaml
metadata:
  annotations:
    # Documentation
    description: "User authentication service"
    owner: "platform-team@company.com"
    repository: "https://github.com/company/user-service"
    
    # Build information
    build-date: "2024-11-19"
    git-commit: "a3f5d2e"
    built-by: "jenkins"
    
    # Kubernetes-specific
    kubernetes.io/change-cause: "Updated to version 2.0"
    
    # Tool-specific (Ingress, Prometheus, etc.)
    nginx.ingress.kubernetes.io/rewrite-target: "/"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
```

### Working with Annotations

See `code-examples/deployments/annotated-deployment.yaml` for the complete example.

```bash
# Apply
kubectl apply -f annotated-deployment.yaml

# View annotations
kubectl describe deployment annotated-app | grep -A 10 Annotations

# Add annotation
kubectl annotate deployment annotated-app \
  last-updated="$(date)" \
  updated-by="$(whoami)"

# Update annotation (requires --overwrite)
kubectl annotate deployment annotated-app \
  version="2.1.0" --overwrite

# Remove annotation
kubectl annotate deployment annotated-app version-

# View pod annotations
kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.annotations}' | jq
```

## Part 6: Real-World Label Strategy (20 minutes)

### Best Practices

**1. Standard Label Set**

Every resource should have these labels:

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

**2. Multi-Tier Application Example**

See `code-examples/deployments/complete-labeled-app.yaml` for the complete example.

```bash
# Apply all
kubectl apply -f complete-labeled-app.yaml

# Query by different criteria
echo "=== All ecommerce components ==="
kubectl get all -l app.kubernetes.io/part-of=ecommerce

echo "=== All production resources ==="
kubectl get all -l environment=production

echo "=== All backend team resources ==="
kubectl get all -l team=backend-team

echo "=== All web components ==="
kubectl get all -l app.kubernetes.io/component=web

echo "=== Resources NOT managed by specific team ==="
kubectl get all -l 'team!=platform-team'
```

## 📝 Day 8 Homework (30-40 minutes)

### Exercise 1: Label Organization System

Create a complete labeling scheme for a multi-environment application.

See `projects/homework-exercise-1/` for complete files.

```bash
# Deploy all
kubectl apply -f dev-app.yaml
kubectl apply -f staging-app.yaml
kubectl apply -f prod-app.yaml

# Query exercises
kubectl get deployments -l environment=production
kubectl get deployments -l 'environment in (staging,production)'
kubectl get pods -l team=teamA
kubectl get all -l app=myapp
```

### Exercise 2: Canary Deployment with Labels

Create two versions of an app.

See `projects/homework-exercise-2/` for complete files.

```bash
kubectl apply -f v1-deployment.yaml
kubectl apply -f v2-deployment.yaml

# Test multiple times - you should see v2 ~10% of the time
for i in {1..20}; do
  kubectl run test-$i --image=alpine --rm -it --restart=Never -- \
    wget -qO- myapp-service
done
```

### Exercise 3: Selective Operations with Labels

```bash
# Delete only development pods
kubectl delete pods -l environment=development

# Scale only production deployments
kubectl scale deployment -l environment=production --replicas=5

# Get logs from all backend pods
kubectl logs -l tier=backend --tail=10

# Port-forward to specific version
kubectl port-forward -l version=v2 8080:80
```

### Exercise 4: Label-Based Resource Management

Create a script to manage resources by environment.

See `projects/homework-exercise-4/manage-env.sh` for the complete script.

### Exercise 5: Annotation Practice

Add comprehensive annotations to your deployment:

```bash
kubectl annotate deployment myapp-v1 \
  description="Main application deployment" \
  owner="platform-team@company.com" \
  git-repo="https://github.com/company/myapp" \
  git-commit="$(git rev-parse HEAD)" \
  deployed-at="$(date -Iseconds)" \
  deployed-by="$(whoami)"

# View all annotations
kubectl describe deployment myapp-v1 | grep -A 20 Annotations
```

## ✅ Day 8 Checklist

Before moving to Day 9, ensure you can:

- [ ] Explain the difference between labels and annotations
- [ ] Create resources with labels
- [ ] Add/update/remove labels on existing resources
- [ ] Use equality-based selectors
- [ ] Use set-based selectors (in, notin)
- [ ] Query resources with complex label selectors
- [ ] Understand how Services use label selectors
- [ ] Implement label-based routing (canary)
- [ ] Add and manage annotations
- [ ] Design a labeling strategy for multi-tier apps
- [ ] Use labels for operational tasks (scale, delete, etc.)

## 🎯 Key Takeaways

```javascript
const labelBestPractices = {
  purpose: "Labels for identification, annotations for metadata",
  consistency: "Use standard label keys across organization",
  automation: "Labels enable powerful automation and querying",
  services: "Services use labels to find pods",
  operations: "Labels make mass operations safe and targeted",
  
  recommended: [
    "app.kubernetes.io/name",
    "app.kubernetes.io/component",
    "app.kubernetes.io/part-of",
    "app.kubernetes.io/version",
    "environment",
    "team"
  ],
  
  avoid: [
    "Using spaces in values",
    "Too many labels (3-8 is ideal)",
    "Forgetting to label new resources",
    "Using annotations for selection"
  ]
};
```

## 🔜 What's Next?

**Day 9 Preview:** Tomorrow we'll learn about Namespaces - Kubernetes' way to create virtual clusters within a cluster for:

- Multi-tenancy (multiple teams/projects)
- Resource isolation and organization
- Environment separation (dev, staging, prod)
- Resource quotas and limits per namespace
- Access control boundaries

**Sneak peek:**

```bash
# Instead of mixing everything:
kubectl get pods  # 100+ pods from all teams!

# With namespaces:
kubectl get pods -n team-a    # Only team-a pods
kubectl get pods -n team-b    # Only team-b pods
kubectl get pods -n production  # Only prod pods
```


