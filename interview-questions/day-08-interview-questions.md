# Day 08: Labels, Selectors & Annotations - Interview Questions

## 1. What is the difference between labels and annotations in Kubernetes?

**Answer:**

| Feature | Labels | Annotations |
|---------|--------|-------------|
| **Purpose** | Identification and selection | Metadata and documentation |
| **Used by** | Kubernetes (selectors, Services) | Humans and external tools |
| **Queryable** | Yes (with selectors) | No |
| **Size limit** | 63 chars per value | 256 KB total |
| **Examples** | `app=frontend`, `env=prod` | `description="User service"`, `git-commit="abc123"` |
| **Use cases** | Grouping, selection, routing | Documentation, build info, tool config |

**Labels:**
- Used for selection and grouping
- Services use labels to find Pods
- Can query resources by labels
- Example: `app: myapp`, `environment: production`

**Annotations:**
- Store non-identifying metadata
- Not used for selection
- Used by tools (Ingress, Prometheus, etc.)
- Example: `description: "Main API service"`, `prometheus.io/scrape: "true"`

**Best Practice:** Use labels for things you want to query/select. Use annotations for metadata that tools or humans need to read.

---

## 2. Multiple Choice: Which of the following is a valid label key?

A. `app name`  
B. `app.name`  
C. `app@name`  
D. `app/name with spaces`

**Answer: B**

**Explanation:** Label keys can contain:
- Alphanumeric characters
- Hyphens (-)
- Underscores (_)
- Dots (.)
- Forward slashes (/) for subdomains

Cannot contain:
- Spaces
- Special characters (@, #, $, etc.)
- Values longer than 63 characters

Valid examples: `app.name`, `app/name`, `app-name`, `app_name`

---

## 3. Explain the recommended label keys from Kubernetes.

**Answer:**

Kubernetes recommends these standard label keys:

**app.kubernetes.io/name:**
- Application name
- Example: `app.kubernetes.io/name: nginx`

**app.kubernetes.io/instance:**
- Unique instance name
- Example: `app.kubernetes.io/instance: my-nginx`

**app.kubernetes.io/version:**
- Application version
- Example: `app.kubernetes.io/version: "1.0.0"`

**app.kubernetes.io/component:**
- Component within architecture
- Example: `app.kubernetes.io/component: backend`

**app.kubernetes.io/part-of:**
- Higher-level application
- Example: `app.kubernetes.io/part-of: ecommerce-platform`

**app.kubernetes.io/managed-by:**
- Tool used to manage resource
- Example: `app.kubernetes.io/managed-by: helm`

**Benefits:**
- Consistency across organization
- Tool compatibility
- Better organization
- Standard queries

**Example:**
```yaml
metadata:
  labels:
    app.kubernetes.io/name: user-service
    app.kubernetes.io/instance: user-service-prod
    app.kubernetes.io/version: "2.0.0"
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: ecommerce
    app.kubernetes.io/managed-by: helm
```

---

## 4. What are equality-based and set-based selectors?

**Answer:**

**Equality-Based Selectors:**
- Match labels using `=`, `!=`, or existence checks
- Simple and common
- Examples:
  ```bash
  # Exact match
  kubectl get pods -l app=myapp
  
  # Not equal
  kubectl get pods -l environment!=development
  
  # Label exists
  kubectl get pods -l version
  
  # Label doesn't exist
  kubectl get pods -l '!version'
  ```

**Set-Based Selectors:**
- Match labels using `in`, `notin`, `exists`
- More powerful for complex queries
- Examples:
  ```bash
  # In operator
  kubectl get pods -l 'environment in (staging,production)'
  
  # Not in operator
  kubectl get pods -l 'environment notin (development)'
  
  # Exists (same as equality-based)
  kubectl get pods -l version
  
  # Doesn't exist
  kubectl get pods -l '!version'
  ```

**Combining selectors:**
```bash
# Complex query
kubectl get pods -l 'app=myapp,environment in (staging,production),tier=backend'
```

**When to use:**
- **Equality**: Simple queries, exact matches
- **Set-based**: Complex queries, multiple values, production use

---

## 5. Multiple Choice: How do Services use labels to find Pods?

A. By Pod name  
B. By label selectors  
C. By IP address  
D. By namespace

**Answer: B**

**Explanation:** Services use label selectors in `spec.selector` to find Pods. The Service selector must match the Pod labels.

**Example:**
```yaml
# Service
apiVersion: v1
kind: Service
spec:
  selector:
    app: myapp      # Selector
    tier: backend

# Pod (must have matching labels)
metadata:
  labels:
    app: myapp      # Matches!
    tier: backend   # Matches!
```

---

## 6. Explain how to use labels for canary deployments.

**Answer:**

**Canary Deployment Strategy:**
- Deploy new version to small percentage of traffic
- Gradually increase traffic to new version
- Rollback if issues detected

**Implementation with labels:**

**Step 1: Create v1 Deployment (90% traffic)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-v1
spec:
  replicas: 9
  template:
    metadata:
      labels:
        app: myapp
        version: v1
        track: stable
```

**Step 2: Create v2 Deployment (10% traffic)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: myapp
        version: v2
        track: canary
```

**Step 3: Service routes to both**
```yaml
apiVersion: v1
kind: Service
spec:
  selector:
    app: myapp  # Matches both v1 and v2
  # Traffic distributed 90% v1, 10% v2
```

**Step 4: Gradually increase canary**
```bash
# Scale v2 to 2 replicas (20% traffic)
kubectl scale deployment myapp-v2 --replicas=2

# If successful, scale v2 to 5 (50% traffic)
kubectl scale deployment myapp-v2 --replicas=5

# Eventually replace v1
kubectl scale deployment myapp-v1 --replicas=0
```

**Alternative: Use separate Service for canary**
```yaml
# Main service (v1)
selector:
  app: myapp
  version: v1

# Canary service (v2)
selector:
  app: myapp
  version: v2
# Use Ingress to route percentage of traffic
```

---

## 7. How do you add, update, and remove labels on existing resources?

**Answer:**

**Add label:**
```bash
kubectl label pod mypod environment=production
```

**Update existing label:**
```bash
kubectl label pod mypod environment=staging --overwrite
```

**Remove label:**
```bash
kubectl label pod mypod environment-
```

**Multiple labels:**
```bash
kubectl label pod mypod app=myapp tier=backend version=v1
```

**Bulk operations:**
```bash
# Label all Pods matching selector
kubectl label pods -l app=myapp environment=production

# Label all resources in namespace
kubectl label all --all environment=production -n mynamespace
```

**Declarative (YAML):**
```bash
# Edit resource
kubectl edit pod mypod
# Add/update labels in metadata.labels section

# Or edit YAML file and apply
kubectl apply -f pod.yaml
```

**Verify:**
```bash
# View labels
kubectl get pods --show-labels

# View specific label columns
kubectl get pods -L app,environment,version
```

---

## 8. Multiple Choice: What is the maximum size limit for annotations?

A. 63 KB  
B. 256 KB  
C. 1 MB  
D. No limit

**Answer: B**

**Explanation:** Annotations have a total size limit of 256 KB per resource. This is the combined size of all annotation keys and values.

---

## 9. Explain how to use labels for multi-environment resource management.

**Answer:**

**Labeling Strategy:**
```yaml
metadata:
  labels:
    app: myapp
    environment: production  # or development, staging
    team: backend-team
    cost-center: engineering
```

**Query by environment:**
```bash
# All production resources
kubectl get all -l environment=production

# All development Pods
kubectl get pods -l environment=development

# All staging deployments
kubectl get deployments -l environment=staging
```

**Operations by environment:**
```bash
# Scale only production
kubectl scale deployment -l environment=production --replicas=5

# Delete development resources
kubectl delete all -l environment=development

# Get logs from production
kubectl logs -l environment=production --tail=50
```

**Resource quotas by environment:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
  selector:
    matchLabels:
      environment: production
```

**Best Practice:**
- Use consistent label keys across environments
- Combine with namespaces for better isolation
- Use labels for cost tracking and resource management

---

## 10. What are common use cases for annotations?

**Answer:**

**1. Documentation:**
```yaml
annotations:
  description: "User authentication service"
  owner: "platform-team@company.com"
  repository: "https://github.com/company/user-service"
```

**2. Build/Deployment Information:**
```yaml
annotations:
  build-date: "2024-01-15"
  git-commit: "a3f5d2e1b4c6"
  built-by: "jenkins"
  image-tag: "v1.2.3"
```

**3. Kubernetes-Specific:**
```yaml
annotations:
  kubernetes.io/change-cause: "Updated to version 2.0"
```

**4. Tool-Specific Configuration:**
```yaml
# Ingress annotations
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: "/"
  nginx.ingress.kubernetes.io/ssl-redirect: "true"

# Prometheus annotations
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9090"
  prometheus.io/path: "/metrics"

# Cert-manager annotations
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

**5. External System Integration:**
```yaml
annotations:
  external-system/id: "12345"
  external-system/url: "https://external-system.com/resource/12345"
```

**Key Point:** Annotations are for metadata that tools or humans read, not for Kubernetes selection.

---

## 11. Multiple Choice: Which command shows resources with a specific label?

A. `kubectl get pods --label app=myapp`  
B. `kubectl get pods -l app=myapp`  
C. `kubectl get pods --selector app=myapp`  
D. Both B and C

**Answer: D**

**Explanation:** Both `-l` (shorthand) and `--selector` work for label selection. `-l` is more commonly used.

---

## 12. Explain how to use labels for A/B testing.

**Answer:**

**A/B Testing Setup:**

**Step 1: Create variant A (50% traffic)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-variant-a
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: myapp
        variant: a
        version: v1
```

**Step 2: Create variant B (50% traffic)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-variant-b
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: myapp
        variant: b
        version: v2
```

**Step 3: Service routes to both**
```yaml
apiVersion: v1
kind: Service
spec:
  selector:
    app: myapp  # Matches both variants
  # Traffic split 50/50
```

**Step 4: Use Ingress for precise control**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "50"  # 50% to variant-b
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-variant-b
            port:
              number: 80
```

**Monitor and adjust:**
```bash
# Check traffic distribution
kubectl get pods -l app=myapp --show-labels

# Adjust ratio
# Edit Ingress canary-weight annotation

# Analyze results and choose winner
# Scale down losing variant
kubectl scale deployment myapp-variant-a --replicas=0
```

---

## 13. How do you query resources using complex label selectors?

**Answer:**

**Complex queries with multiple conditions:**

**AND conditions:**
```bash
# All conditions must match
kubectl get pods -l 'app=myapp,environment=production,tier=backend'
```

**OR conditions (set-based):**
```bash
# Match any of the values
kubectl get pods -l 'environment in (staging,production)'
```

**NOT conditions:**
```bash
# Exclude specific value
kubectl get pods -l 'environment!=development'

# Exclude multiple values
kubectl get pods -l 'environment notin (development,test)'
```

**Combined:**
```bash
# Complex query
kubectl get pods -l 'app=myapp,environment in (staging,production),tier!=database,version'
```

**Label existence:**
```bash
# Has label (any value)
kubectl get pods -l version

# Doesn't have label
kubectl get pods -l '!version'
```

**Multiple label keys:**
```bash
# At least one must exist
kubectl get pods -l 'app,environment'
```

**Best Practice:**
- Use set-based selectors for production
- Test queries before using in scripts
- Document complex queries

---

## 14. Multiple Choice: Can you use annotations in Service selectors?

A. Yes, always  
B. No, only labels can be used  
C. Sometimes, depending on the Service type  
D. Only in Ingress

**Answer: B**

**Explanation:** Service selectors can ONLY use labels, not annotations. Annotations are not queryable and cannot be used for selection.

---

## 15. Explain the best practices for labeling resources in Kubernetes.

**Answer:**

**1. Use Standard Labels:**
```yaml
labels:
  app.kubernetes.io/name: myapp
  app.kubernetes.io/component: backend
  app.kubernetes.io/version: "1.0.0"
  app.kubernetes.io/part-of: platform
```

**2. Be Consistent:**
- Use same label keys across all resources
- Agree on label values (e.g., `prod` vs `production`)
- Document labeling strategy

**3. Keep It Simple:**
- 3-8 labels per resource (not too many)
- Use meaningful names
- Avoid redundant labels

**4. Use Namespaces with Labels:**
- Combine namespaces and labels for organization
- Namespace for isolation, labels for selection

**5. Label Everything:**
- All resources should have labels
- Makes querying and management easier

**6. Avoid Special Characters:**
- Use alphanumeric, hyphens, underscores, dots
- No spaces or special characters

**7. Version Labels:**
- Include version in labels for tracking
- Helps with rollbacks and canary deployments

**Example - Good Labeling:**
```yaml
metadata:
  labels:
    app.kubernetes.io/name: user-service
    app.kubernetes.io/component: api
    app.kubernetes.io/version: "2.0.0"
    app.kubernetes.io/part-of: ecommerce
    environment: production
    team: backend-team
```

**Example - Bad Labeling:**
```yaml
metadata:
  labels:
    app: "my app"  # ❌ Spaces
    env: prod,staging  # ❌ Multiple values (use separate labels)
    version: v1.0.0.0.0.0  # ❌ Too long
    # Missing standard labels
```

---

## 16. How do labels help with resource organization and cost tracking?

**Answer:**

**Organization:**
```bash
# Group by team
kubectl get all -l team=backend-team

# Group by application
kubectl get all -l app.kubernetes.io/part-of=ecommerce

# Group by environment
kubectl get all -l environment=production
```

**Cost Tracking:**
```yaml
# Label resources with cost center
labels:
  cost-center: engineering
  project: ecommerce-platform
  budget-code: ENG-2024-Q1
```

**Query costs:**
```bash
# All resources for a cost center
kubectl get all -l cost-center=engineering

# Calculate resource usage
kubectl top pods -l cost-center=engineering
```

**Resource Quotas by Labels:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: Namespace
      values: ["team-backend"]
```

**Reporting:**
- Use labels to generate cost reports
- Track resource usage by team/project
- Allocate costs accurately

---

## 17. Multiple Choice: What happens if you delete a Pod that has a label used by a Service selector?

A. Service stops working  
B. Service automatically finds other Pods with matching labels  
C. Service is deleted  
D. Nothing happens

**Answer: B**

**Explanation:** Services continuously monitor Pods matching their selector. When a Pod is deleted, the Service automatically removes it from endpoints and continues routing to other Pods with matching labels. This is how Services provide high availability.

