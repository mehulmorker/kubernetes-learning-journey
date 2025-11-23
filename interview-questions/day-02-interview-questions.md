# Day 02: Setting Up Kubernetes & Your First Pod - Interview Questions

## 1. What is a Pod in Kubernetes, and why is it the smallest deployable unit?

**Answer:**
A Pod is the smallest and simplest unit in Kubernetes. It represents a single instance of a running process in your cluster.

**Key characteristics:**
- Contains one or more containers that share:
  - Network namespace (same IP address)
  - Storage volumes
  - IPC (Inter-Process Communication)
- Containers in a Pod are always co-located and co-scheduled
- Pods are ephemeral - they can be created, destroyed, and recreated

**Why smallest unit:**
- Kubernetes doesn't run containers directly
- Pods provide a logical host for containers
- Pods enable shared resources between containers (sidecar pattern)
- Pods are the unit of replication and scaling

**Analogy:** Think of a Pod as a "logical host" - like a physical server that can run multiple processes.

---

## 2. Explain the main components of Kubernetes architecture.

**Answer:**

**Control Plane (Master Node):**
- **API Server**: Central management point, validates and processes requests
- **etcd**: Distributed key-value store for cluster state
- **Scheduler**: Assigns Pods to nodes based on resources and constraints
- **Controller Manager**: Runs controllers that maintain desired state

**Worker Nodes:**
- **Kubelet**: Agent that communicates with API server, manages Pods
- **Kube-proxy**: Network proxy handling service load balancing
- **Container Runtime**: Runs containers (Docker, containerd, etc.)

**Communication Flow:**
```
User → kubectl → API Server → etcd (store state)
                    ↓
              Scheduler (assign Pod)
                    ↓
              Kubelet (on node) → Container Runtime
```

---

## 3. Multiple Choice: What command is used to create a Pod imperatively?

A. `kubectl create pod`  
B. `kubectl run`  
C. `kubectl apply pod`  
D. `kubectl new pod`

**Answer: B**

**Explanation:** `kubectl run` creates a Pod imperatively. `kubectl apply` is for declarative YAML files. There is no `kubectl create pod` or `kubectl new pod` command.

---

## 4. What is the difference between imperative and declarative approaches in Kubernetes?

**Answer:**

**Imperative (Command-based):**
- You tell Kubernetes **what to do** (commands)
- Example: `kubectl run nginx --image=nginx`
- Quick for testing, but not reproducible
- Hard to version control

**Declarative (YAML-based):**
- You tell Kubernetes **what you want** (desired state)
- Example: Create `pod.yaml` and `kubectl apply -f pod.yaml`
- Reproducible and version-controlled
- Kubernetes figures out how to achieve the desired state

**Best Practice:** Always use declarative approach (YAML) for production. Imperative is fine for quick tests.

---

## 5. Explain the Pod lifecycle states.

**Answer:**

**Pod States:**
1. **Pending**: Pod is accepted but containers not created yet
2. **Running**: Pod is bound to a node, all containers created and at least one is running
3. **Succeeded**: All containers terminated successfully (for Jobs)
4. **Failed**: At least one container terminated with failure
5. **Unknown**: Pod state cannot be determined (usually node communication issue)

**Container States (within Pod):**
- **Waiting**: Container is waiting to start
- **Running**: Container is executing
- **Terminated**: Container completed execution

**Common Status Issues:**
- **ImagePullBackOff**: Cannot pull image
- **CrashLoopBackOff**: Container keeps crashing
- **Pending**: Waiting for resources or scheduling

---

## 6. Multiple Choice: Which command shows detailed information about a Pod including events?

A. `kubectl get pod <name>`  
B. `kubectl describe pod <name>`  
C. `kubectl show pod <name>`  
D. `kubectl info pod <name>`

**Answer: B**

**Explanation:** `kubectl describe` shows detailed information including events, conditions, and resource usage. `kubectl get` shows basic information in table format.

---

## 7. What is the purpose of labels in Pods, and how are they used?

**Answer:**
Labels are key-value pairs attached to Pods (and other resources) for identification and organization.

**Purpose:**
- **Organization**: Group related resources
- **Selection**: Services use labels to find Pods
- **Querying**: Filter and find resources
- **Operations**: Perform bulk operations on labeled resources

**Example:**
```yaml
metadata:
  labels:
    app: nginx
    environment: production
    version: v1.0
```

**Usage:**
```bash
# Query by label
kubectl get pods -l app=nginx

# Service selector uses labels
spec:
  selector:
    app: nginx
```

---

## 8. Scenario: You need to access a Pod running on port 3000 from your local machine. How would you do it?

**Answer:**
Use `kubectl port-forward`:

```bash
# Forward local port 8080 to Pod port 3000
kubectl port-forward <pod-name> 8080:3000

# Or forward to a specific port
kubectl port-forward <pod-name> 3000:3000

# Access via localhost
curl http://localhost:8080
```

**Alternative:** Use a Service with NodePort or LoadBalancer type (covered in Day 4).

**Note:** Port-forwarding is for development/testing. Production should use Services.

---

## 9. Multiple Choice: What happens when you delete a Pod?

A. The Pod is immediately removed and cannot be recreated  
B. The Pod is terminated gracefully and can be recreated if managed by a controller  
C. The Pod continues running in the background  
D. The Pod is paused but not removed

**Answer: B**

**Explanation:** When you delete a Pod:
1. Pod receives SIGTERM signal (graceful shutdown)
2. After grace period (default 30s), SIGKILL if still running
3. Pod is removed from etcd
4. If managed by a Deployment/ReplicaSet, a new Pod is created to maintain desired state

---

## 10. Explain when and why you would use multi-container Pods.

**Answer:**
Multi-container Pods are used when containers need to work closely together and share resources.

**Use Cases:**
1. **Sidecar Pattern**: Helper container that enhances main container
   - Example: Log collector, monitoring agent, proxy
2. **Adapter Pattern**: Transforms output of main container
   - Example: Format converter, metrics adapter
3. **Ambassador Pattern**: Proxy for external services
   - Example: Service mesh proxy, API gateway

**Why same Pod:**
- Share network namespace (localhost communication)
- Share storage volumes
- Co-located on same node
- Atomic lifecycle (created/destroyed together)

**Example:**
```yaml
containers:
- name: app
  image: myapp
- name: log-collector
  image: fluentd
  # Both share same network and volumes
```

---

## 11. What is the difference between `kubectl logs` and `kubectl exec`?

**Answer:**

**`kubectl logs`:**
- Shows output from container's stdout/stderr
- Read-only operation
- Shows historical logs
- Example: `kubectl logs <pod-name>`

**`kubectl exec`:**
- Executes a command inside a running container
- Can modify container state
- Interactive or non-interactive
- Example: `kubectl exec -it <pod-name> -- sh`

**Use cases:**
- **logs**: Debugging, monitoring, troubleshooting
- **exec**: Inspecting files, running commands, debugging interactively

---

## 12. Multiple Choice: What is minikube used for?

A. Production Kubernetes cluster  
B. Local Kubernetes development environment  
C. Container registry  
D. CI/CD pipeline tool

**Answer: B**

**Explanation:** Minikube is a tool that runs a single-node Kubernetes cluster locally for development and learning. It's not for production use.

---

## 13. Explain the concept of "desired state" in Kubernetes.

**Answer:**
Desired state is the configuration you declare (in YAML) that describes how you want your application to run.

**How it works:**
1. **You declare**: "I want 3 replicas of my app running"
2. **Kubernetes observes**: Current state (maybe only 2 running)
3. **Kubernetes reconciles**: Creates 1 more Pod to match desired state
4. **Continuous monitoring**: If a Pod crashes, Kubernetes creates a new one

**Example:**
```yaml
spec:
  replicas: 3  # Desired state: 3 Pods
```

**Benefits:**
- Self-healing: Automatically fixes deviations
- Declarative: You say what you want, not how to do it
- Idempotent: Applying same config multiple times has same result

---

## 14. What are the common reasons a Pod might be in "Pending" state?

**Answer:**

**Common causes:**
1. **Insufficient resources**: Not enough CPU/memory on nodes
2. **Node selector mismatch**: Pod requires specific node labels that don't exist
3. **Taints/Tolerations**: Nodes have taints that Pod can't tolerate
4. **PVC not bound**: PersistentVolumeClaim is waiting for a PersistentVolume
5. **Image pull issues**: Cannot pull container image
6. **Scheduler issues**: Scheduler cannot find suitable node

**Debugging:**
```bash
# Check Pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes

# Check PVC status
kubectl get pvc
```

---

## 15. Scenario: Your Pod is in "CrashLoopBackOff" state. How would you troubleshoot it?

**Answer:**

**Step 1: Check Pod status and events**
```bash
kubectl describe pod <pod-name>
# Look for Events section
```

**Step 2: Check container logs**
```bash
kubectl logs <pod-name>
# Or for previous crashed container
kubectl logs <pod-name> --previous
```

**Step 3: Common causes and fixes:**
- **Application error**: Check logs, fix code
- **Missing environment variables**: Add required env vars
- **Wrong image/tag**: Verify image exists and is correct
- **Port conflicts**: Check if port is already in use
- **Resource limits**: Increase memory/CPU limits
- **Missing dependencies**: Ensure all required services are available

**Step 4: Test locally**
```bash
# Run container locally to test
docker run <image> <command>
```

**Step 5: Check resource limits**
```bash
kubectl describe pod <pod-name> | grep -A 5 "Limits"
```

---

## 16. Multiple Choice: Which component is responsible for scheduling Pods to nodes?

A. Kubelet  
B. Scheduler  
C. Controller Manager  
D. API Server

**Answer: B**

**Explanation:** The Scheduler watches for newly created Pods with no assigned node and selects a node for them to run on based on resource requirements, constraints, and policies.

