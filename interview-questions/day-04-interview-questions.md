# Day 04: Services - Interview Questions

## 1. Why do we need Services in Kubernetes when Pods already have IP addresses?

**Answer:**
Pods have ephemeral IP addresses that change when Pods are recreated, making direct IP access unreliable.

**Problems with Pod IPs:**
- **Dynamic**: IPs change when Pods restart or are recreated
- **No load balancing**: Can't distribute traffic across multiple Pods
- **No service discovery**: Other services don't know how to find Pods
- **Ephemeral**: Pods come and go, IPs are temporary
- **Scaling**: New Pods get new IPs, hard to track

**Services solve:**
- ✅ **Stable endpoint**: Service has stable IP and DNS name
- ✅ **Load balancing**: Automatically distributes traffic to Pods
- ✅ **Service discovery**: DNS-based discovery (`service-name.namespace.svc.cluster.local`)
- ✅ **Abstraction**: Clients don't need to know Pod IPs
- ✅ **Dynamic updates**: Endpoints update automatically as Pods change

**Example:**
```
Without Service:
  Client → Pod IP: 172.17.0.5 (changes when Pod restarts) ❌

With Service:
  Client → Service: myapp-service (stable) → Load balances → Pods ✅
```

---

## 2. Explain the different Service types in Kubernetes.

**Answer:**

**1. ClusterIP (Default)**
- **Access**: Only within cluster
- **Use case**: Internal services, microservices communication
- **IP**: Virtual IP in cluster IP range (10.96.x.x)
- **Example**: Backend API accessed by frontend

**2. NodePort**
- **Access**: External via `<NodeIP>:<NodePort>`
- **Use case**: Development, testing, simple external access
- **Port range**: 30000-32767
- **Example**: Access app via `http://<node-ip>:30080`

**3. LoadBalancer**
- **Access**: External via cloud provider's load balancer
- **Use case**: Production external access (cloud environments)
- **Requires**: Cloud provider support (AWS ELB, GCP LB, Azure LB)
- **Example**: Public-facing web application

**4. ExternalName**
- **Access**: Maps to external DNS name
- **Use case**: Access external services as if they were internal
- **Example**: Connect to external database

**Comparison:**
```
ClusterIP:    Internal only
NodePort:     NodeIP:Port (external)
LoadBalancer: Cloud LB → NodePort → ClusterIP → Pods
ExternalName: DNS alias to external service
```

---

## 3. Multiple Choice: What is the default Service type?

A. NodePort  
B. LoadBalancer  
C. ClusterIP  
D. ExternalName

**Answer: C**

**Explanation:** ClusterIP is the default Service type. If you don't specify `type`, it defaults to ClusterIP.

---

## 4. How does Service discovery work in Kubernetes using DNS?

**Answer:**
Kubernetes provides automatic DNS-based service discovery.

**DNS Naming Convention:**
```
<service-name>.<namespace>.svc.cluster.local
```

**Examples:**
- Same namespace: `myapp-service` or `myapp-service.default`
- Different namespace: `myapp-service.production`
- Fully qualified: `myapp-service.default.svc.cluster.local`

**How it works:**
1. Service gets DNS name automatically
2. Pods can resolve service names to ClusterIP
3. DNS server (CoreDNS) handles resolution
4. No configuration needed

**Example:**
```javascript
// In a Pod, you can call:
fetch('http://backend-service/api/users')
// DNS resolves: backend-service → 10.96.123.45
```

**Benefits:**
- No hardcoded IPs
- Works across namespaces
- Automatic updates when Service IP changes
- Standard DNS protocol

---

## 5. What are Endpoints in Kubernetes, and how do they relate to Services?

**Answer:**
Endpoints are automatically created objects that contain the list of Pod IPs that match a Service's selector.

**Relationship:**
```
Service (selector: app=myapp)
    ↓ (automatically creates)
Endpoints (list of Pod IPs matching selector)
    ↓ (used by)
Service (routes traffic to these IPs)
```

**How it works:**
1. Service has a selector (e.g., `app: myapp`)
2. Kubernetes finds all Pods matching the selector
3. Endpoints object is created/updated with Pod IPs
4. Service uses Endpoints to route traffic

**View Endpoints:**
```bash
kubectl get endpoints <service-name>
kubectl describe endpoints <service-name>
```

**Dynamic updates:**
- When Pod is created → Added to Endpoints
- When Pod is deleted → Removed from Endpoints
- When Pod IP changes → Endpoints updated
- Happens automatically, no manual intervention

**Example:**
```bash
# Service
kubectl get svc myapp
# NAME    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)
# myapp   ClusterIP   10.96.1.2     <none>        80/TCP

# Endpoints (automatically created)
kubectl get endpoints myapp
# NAME    ENDPOINTS
# myapp   172.17.0.5:8080,172.17.0.6:8080,172.17.0.7:8080
```

---

## 6. Multiple Choice: How do Services find which Pods to route traffic to?

A. By Pod name  
B. By Pod IP address  
C. By label selectors  
D. By namespace

**Answer: C**

**Explanation:** Services use label selectors to find Pods. The Service's `spec.selector` must match the Pod's labels.

---

## 7. Explain the difference between Service `port` and `targetPort`.

**Answer:**

**port:**
- Port exposed by the Service (external port)
- Used by clients to connect to the Service
- Example: `port: 80` means clients connect to Service on port 80

**targetPort:**
- Port on the Pod/container (internal port)
- Where the application actually listens
- Example: `targetPort: 3000` means traffic is forwarded to Pod port 3000

**Flow:**
```
Client → Service:80 → (load balanced) → Pod:3000
         (port)                        (targetPort)
```

**Example:**
```yaml
spec:
  ports:
  - port: 80           # Service port
    targetPort: 3000   # Pod port (where app listens)
    protocol: TCP
```

**Why different?**
- Decoupling: Service port can differ from app port
- Flexibility: Change app port without changing Service
- Standardization: Expose apps on standard ports (80, 443) regardless of internal port

---

## 8. What is a Headless Service, and when would you use it?

**Answer:**
A Headless Service is a Service with `clusterIP: None`, which doesn't provide a single ClusterIP. Instead, it returns all Pod IPs directly.

**Characteristics:**
- No load balancing (returns all Pod IPs)
- DNS returns multiple A records (one per Pod)
- Used for StatefulSets, service discovery
- Pods get stable DNS names

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-service
spec:
  clusterIP: None  # Headless!
  selector:
    app: myapp
  ports:
  - port: 80
```

**Use cases:**
1. **StatefulSets**: Each Pod needs stable identity
2. **Service discovery**: Clients need to discover all Pods
3. **Database clusters**: Direct connection to specific instances
4. **Peer discovery**: Applications that need to know all peers

**DNS behavior:**
```bash
# Normal Service: Returns Service IP
nslookup myapp-service
# Returns: 10.96.1.2

# Headless Service: Returns all Pod IPs
nslookup headless-service
# Returns: 172.17.0.5, 172.17.0.6, 172.17.0.7
```

---

## 9. Multiple Choice: What is session affinity in Services?

A. Sticky sessions that route same client to same Pod  
B. Load balancing algorithm  
C. Service type  
D. Pod selection method

**Answer: A**

**Explanation:** Session affinity (sticky sessions) ensures requests from the same client IP are routed to the same Pod. Configured with `sessionAffinity: ClientIP`.

---

## 10. How do you configure session affinity in a Service?

**Answer:**
Use `sessionAffinity` and `sessionAffinityConfig`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 3000
  sessionAffinity: ClientIP  # Enable sticky sessions
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600  # 1 hour timeout
```

**How it works:**
- First request from client IP → Routed to Pod A
- Subsequent requests from same IP → Routed to same Pod A
- After timeout → May route to different Pod

**Use cases:**
- Applications with server-side sessions
- Stateful applications
- When Pod maintains client state

**Note:** Default is `None` (no session affinity, round-robin load balancing).

---

## 11. Explain how to connect a multi-tier application using Services.

**Answer:**
Use Services for service discovery between tiers.

**Architecture:**
```
Frontend (NodePort Service)
    ↓ (calls backend via DNS)
Backend (ClusterIP Service)
    ↓ (connects to database via DNS)
Database (ClusterIP Service)
```

**Example:**

**Frontend Deployment:**
```yaml
# Frontend calls backend using Service DNS name
env:
- name: BACKEND_URL
  value: "http://backend-service:80"
```

**Backend Service:**
```yaml
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

**Backend Deployment:**
```yaml
# Backend connects to database using Service DNS name
env:
- name: DB_HOST
  value: "postgres-service"
- name: DB_PORT
  value: "5432"
```

**Database Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
```

**Key points:**
- Use Service DNS names, not Pod IPs
- Services in same namespace: use service name
- Services in different namespace: use `service.namespace`
- Automatic load balancing
- Automatic failover if Pod fails

---

## 12. Multiple Choice: What happens to Service endpoints when a Pod is deleted?

A. Endpoints are manually updated  
B. Endpoints are automatically updated to remove the Pod IP  
C. Service stops working  
D. Nothing happens

**Answer: B**

**Explanation:** Endpoints are automatically updated when Pods are created or deleted. Kubernetes continuously monitors Pods matching the Service selector and updates the Endpoints object accordingly.

---

## 13. What is the difference between a Service without selector and a Service with selector?

**Answer:**

**Service with selector (normal):**
- Automatically creates Endpoints from Pods matching selector
- Endpoints updated automatically
- Most common use case

**Service without selector:**
- No automatic Endpoints creation
- Must manually create Endpoints object
- Used for external services

**Example - Service without selector:**
```yaml
# Service
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
  - port: 5432
---
# Manual Endpoints
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db
subsets:
- addresses:
  - ip: 192.168.1.100  # External database IP
  ports:
  - port: 5432
```

**Use case:** Connect to external database/service as if it were internal.

---

## 14. Scenario: Your Service has no endpoints. How would you troubleshoot this?

**Answer:**

**Step 1: Check Service selector**
```bash
kubectl describe svc <service-name>
# Look for Selector in output
```

**Step 2: Check if Pods exist with matching labels**
```bash
# Get Service selector
kubectl get svc <service-name> -o jsonpath='{.spec.selector}'

# Find Pods with those labels
kubectl get pods -l <key>=<value>
```

**Step 3: Verify Pod labels match Service selector**
```bash
# Check Pod labels
kubectl get pods --show-labels

# Compare with Service selector
kubectl get svc <service-name> -o yaml | grep selector
```

**Step 4: Check Pod status**
```bash
kubectl get pods
# Pods must be Running and Ready
```

**Common issues:**
- **Selector mismatch**: Pod labels don't match Service selector
- **No Pods**: No Pods exist with matching labels
- **Pods not Ready**: Pods exist but readiness probe failing
- **Wrong namespace**: Service and Pods in different namespaces

**Fix:**
- Update Pod labels to match selector, OR
- Update Service selector to match Pod labels

---

## 15. Explain how NodePort Service works and its limitations.

**Answer:**

**How it works:**
1. Service type: `NodePort`
2. Kubernetes allocates a port (30000-32767) on each node
3. Traffic to `<NodeIP>:<NodePort>` is forwarded to Service
4. Service load balances to Pods

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-nodeport
spec:
  type: NodePort
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30080  # Optional: specify port
```

**Access:**
```bash
# Get node IP
minikube ip  # or kubectl get nodes -o wide

# Access via any node IP
curl http://<node-ip>:30080
```

**Limitations:**
- **Port range**: Only 30000-32767 available
- **Security**: Exposes port on all nodes (firewall rules needed)
- **Not for production**: Use LoadBalancer or Ingress for production
- **Single port**: One NodePort per Service port
- **No TLS termination**: Need to handle TLS in application

**When to use:**
- Development and testing
- Local Kubernetes (minikube, kind)
- Quick external access
- Not recommended for production

---

## 16. Multiple Choice: What is the fully qualified DNS name for a Service named "api" in the "production" namespace?

A. `api.production`  
B. `api.production.svc`  
C. `api.production.svc.cluster.local`  
D. `api.svc.production.cluster.local`

**Answer: C**

**Explanation:** The fully qualified DNS name format is `<service-name>.<namespace>.svc.cluster.local`.

