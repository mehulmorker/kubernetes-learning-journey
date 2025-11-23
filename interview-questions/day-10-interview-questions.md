# Day 10: DaemonSets & StatefulSets - Interview Questions

## Descriptive Questions

### 1. Explain the key differences between DaemonSet, StatefulSet, and Deployment. When would you choose each one?

**Answer:**

- **Deployment**: Used for stateless applications. Pods have random names, can run on any node, share storage or use none, and scale instantly in any direction. Best for web servers, APIs, microservices.

- **DaemonSet**: Ensures one pod runs on every node (or selected nodes). Pods have random names but are automatically scheduled on all nodes. Used for node-level services like log collectors (Fluentd), monitoring agents (Prometheus Node Exporter), network plugins (Calico), or storage daemons.

- **StatefulSet**: Manages stateful applications requiring stable identity. Pods have ordered names (app-0, app-1, app-2), ordered creation/deletion, unique persistent storage per pod via PVCs, and stable DNS entries. Best for databases (MySQL, PostgreSQL), distributed systems (Kafka, Zookeeper), and clustered applications (Elasticsearch, Cassandra).

**Choose based on:**

- Need one pod per node? → DaemonSet
- Need stable identity/persistent storage? → StatefulSet
- Otherwise → Deployment

---

### 2. What is a headless service and why is it required for StatefulSets?

**Answer:**
A headless service is a Kubernetes Service with `clusterIP: None`. Instead of load balancing, it returns individual pod IPs directly.

**Why required for StatefulSets:**

1. **Stable DNS**: Each StatefulSet pod gets a stable DNS entry: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`
2. **Direct pod access**: Applications can directly connect to specific pods (e.g., database primary vs replicas)
3. **Cluster discovery**: Distributed systems can discover peers using DNS
4. **Identity preservation**: Pods maintain stable network identity even after recreation

**Example:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None # Headless
  selector:
    app: mysql
```

---

### 3. How does StatefulSet ensure ordered pod creation and deletion? Why is this important?

**Answer:**
StatefulSet creates pods sequentially (0→1→2) and deletes them in reverse order (2→1→0). Each pod must be Running and Ready before the next one starts.

**How it works:**

- Pods are created one at a time, waiting for the previous pod to be Ready
- Deletion happens in reverse ordinal order
- Controlled by `podManagementPolicy` (default: `OrderedReady`, can be `Parallel`)

**Why important:**

1. **Database replication**: Primary (pod-0) must start before replicas
2. **Cluster formation**: Master nodes must initialize before followers
3. **Data consistency**: Prevents race conditions in distributed systems
4. **Dependency management**: Ensures dependencies are ready before dependents

**Example:**

```bash
# Scale up: web-0 → web-1 → web-2 (sequential)
kubectl scale sts web --replicas=3

# Scale down: web-2 → web-1 → web-0 (reverse order)
kubectl scale sts web --replicas=1
```

---

### 4. Explain how `volumeClaimTemplates` work in StatefulSets. What happens when you scale a StatefulSet?

**Answer:**
`volumeClaimTemplates` automatically create a PersistentVolumeClaim (PVC) for each StatefulSet pod. Each pod gets its own unique, persistent storage.

**How it works:**

- Template defines PVC specification
- Kubernetes creates PVCs named: `<volume-name>-<statefulset-name>-<ordinal>`
- Each pod mounts its corresponding PVC
- PVCs persist even if pods are deleted

**Scaling behavior:**

- **Scale up**: New pods get new PVCs created automatically (e.g., `data-mysql-3`, `data-mysql-4`)
- **Scale down**: PVCs are retained by default (data preserved), unless `persistentVolumeClaimRetentionPolicy` is set to delete

**Example:**

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

**Resulting PVCs:**

- `data-mysql-0`
- `data-mysql-1`
- `data-mysql-2`

---

### 5. What are the security and resource considerations when using DaemonSets?

**Answer:**

**Security considerations:**

1. **Host path mounts**: DaemonSets often mount host directories (`/var/log`, `/proc`, `/sys`). This requires careful security:

   - Use `readOnly: true` when possible
   - Limit which paths are mounted
   - Use `hostNetwork: true` only when necessary
   - Consider security contexts and RBAC

2. **Privileged access**: Some DaemonSets need privileged mode for system-level operations. Use sparingly and with proper RBAC.

3. **Node-level access**: DaemonSets run on every node, so a compromised pod affects the entire node.

**Resource considerations:**

1. **Multiply by node count**: Resource usage multiplies across all nodes

   - Example: 50m CPU per pod × 100 nodes = 5000m (5 cores total)
   - Always set resource limits to prevent node exhaustion

2. **Cluster-wide impact**: Updates affect all nodes simultaneously (with RollingUpdate)

3. **Scheduling pressure**: DaemonSet pods must run on every node, which can delay node readiness

**Best practices:**

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi # Per node!
```

---

### 6. How do you implement a canary deployment strategy with StatefulSets?

**Answer:**
Use the `partition` field in the StatefulSet update strategy to control which pods get updated.

**How it works:**

- `partition: N` means only pods with ordinal >= N will be updated
- Pods with ordinal < N remain on the old version
- Gradually reduce partition to roll out to all pods

**Example:**

```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 2 # Only update pods >= 2 (web-2, web-3, ...)
```

**Canary process:**

1. Set `partition: 2` (only web-2, web-3 get new version)
2. Test the updated pods
3. If successful, set `partition: 1` (web-1, web-2, web-3 updated)
4. Finally, set `partition: 0` (all pods updated)

**Commands:**

```bash
# Update with partition
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'

# Update image
kubectl set image statefulset/web nginx=nginx:1.21

# Only web-2 and above update
kubectl get pods -l app=nginx

# Roll out to all
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

---

### 7. Describe a scenario where you would use a DaemonSet with nodeSelector. Provide an example.

**Answer:**
Use `nodeSelector` when you want DaemonSet pods to run only on specific nodes with certain labels, not all nodes.

**Common scenarios:**

1. **GPU monitoring**: Only run on nodes with GPUs
2. **SSD storage daemons**: Only on nodes with SSD storage
3. **Edge nodes**: Only on edge/worker nodes, not master nodes
4. **Zone-specific agents**: Only on nodes in specific availability zones

**Example: GPU Monitor DaemonSet**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: gpu-monitor
spec:
  selector:
    matchLabels:
      app: gpu-monitor
  template:
    metadata:
      labels:
        app: gpu-monitor
    spec:
      nodeSelector:
        gpu: "true" # Only nodes with gpu=true label
      containers:
        - name: monitor
          image: gpu-monitor:latest
```

**Setup:**

```bash
# Label nodes with GPUs
kubectl label nodes node-1 gpu=true
kubectl label nodes node-2 gpu=true

# Apply DaemonSet
kubectl apply -f gpu-monitor-daemonset.yaml

# Pods only run on labeled nodes
kubectl get pods -l app=gpu-monitor -o wide

# Remove label - pod gets deleted
kubectl label nodes node-1 gpu-
```

---

### 8. What happens to StatefulSet pods and their storage when you delete a StatefulSet? How can you control this behavior?

**Answer:**

**Default behavior:**

- Pods are deleted in reverse order (highest ordinal first)
- PVCs are **retained** by default (data preserved)
- This is a safety feature to prevent accidental data loss

**Controlling PVC retention:**
Use `persistentVolumeClaimRetentionPolicy` to control PVC lifecycle:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain # Keep PVCs when StatefulSet deleted
    whenScaled: Delete # Delete PVCs when scaled down
  # ...
```

**Options:**

- `whenDeleted: Retain` - Keep PVCs when StatefulSet is deleted (default)
- `whenDeleted: Delete` - Delete PVCs when StatefulSet is deleted
- `whenScaled: Retain` - Keep PVCs when pods are scaled down (default)
- `whenScaled: Delete` - Delete PVCs when pods are scaled down

**Manual cleanup:**

```bash
# Delete StatefulSet (PVCs remain)
kubectl delete statefulset mysql

# Manually delete PVCs if needed
kubectl delete pvc data-mysql-0 data-mysql-1 data-mysql-2
```

**Best practice:** Use `Retain` in production to prevent accidental data loss. Only use `Delete` in development or with proper backup strategies.

---

## Multiple Choice Questions (MCQ)

### 9. What is the default update strategy for DaemonSets?

A) OnDelete  
B) RollingUpdate  
C) Recreate  
D) BlueGreen

**Answer: B) RollingUpdate**

**Explanation:** DaemonSets use `RollingUpdate` by default, which updates pods on each node one at a time. You can change it to `OnDelete` for manual control.

---

### 10. Which of the following is NOT a requirement for StatefulSets?

A) Headless service  
B) volumeClaimTemplates  
C) Ordered pod names  
D) LoadBalancer service

**Answer: D) LoadBalancer service**

**Explanation:** StatefulSets require a headless service (`clusterIP: None`), not a LoadBalancer. They use stable DNS entries for pod discovery, not load balancing.

---

### 11. When scaling a StatefulSet from 3 to 5 replicas, in what order are the new pods created?

A) web-3, web-4 (simultaneously)  
B) web-4, web-3  
C) web-3, then web-4  
D) Random order

**Answer: C) web-3, then web-4**

**Explanation:** StatefulSets create pods sequentially in ascending order. web-3 must be Running and Ready before web-4 starts.

---

### 12. A DaemonSet with resource requests of 100m CPU and 128Mi memory is deployed on a 50-node cluster. What is the total resource usage?

A) 100m CPU, 128Mi memory  
B) 5 CPU, 6.4Gi memory  
C) 50m CPU, 64Mi memory  
D) Cannot be determined

**Answer: B) 5 CPU, 6.4Gi memory**

**Explanation:** DaemonSet resources multiply by node count:

- CPU: 100m × 50 = 5000m = 5 CPU
- Memory: 128Mi × 50 = 6400Mi = 6.4Gi

---

### 13. What DNS entry would you use to access the first pod (pod-0) of a StatefulSet named "mysql" with service "mysql" in the "default" namespace?

A) mysql-0.mysql.default.svc.cluster.local  
B) mysql.mysql-0.default.svc.cluster.local  
C) mysql-0.default.svc.cluster.local  
D) mysql.default.svc.cluster.local

**Answer: A) mysql-0.mysql.default.svc.cluster.local**

**Explanation:** StatefulSet pod DNS format is: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`

---

### 14. Which controller would you use to deploy a log collection agent that needs to run on every node in the cluster?

A) Deployment  
B) DaemonSet  
C) StatefulSet  
D) ReplicaSet

**Answer: B) DaemonSet**

**Explanation:** DaemonSets ensure one pod runs on every node, perfect for node-level services like log collectors, monitoring agents, or network plugins.

---

### 15. What happens if you delete a StatefulSet pod manually?

A) It is recreated with a new random name  
B) It is recreated with the same name and same storage  
C) It is not recreated  
D) A new pod with next ordinal is created

**Answer: B) It is recreated with the same name and same storage**

**Explanation:** StatefulSet maintains pod identity. When a pod is deleted, Kubernetes recreates it with the same name (e.g., `web-1`) and reattaches the same PVC, preserving data.

---

### 16. Which field in a StatefulSet specification controls canary/partitioned updates?

A) `updateStrategy.type`  
B) `updateStrategy.rollingUpdate.partition`  
C) `strategy.partition`  
D) `rollingUpdate.partition`

**Answer: B) `updateStrategy.rollingUpdate.partition`**

**Explanation:** The `partition` field under `updateStrategy.rollingUpdate` controls which pods get updated. Pods with ordinal >= partition are updated.

---

### 17. A StatefulSet uses `volumeClaimTemplates` with name "data". If the StatefulSet is named "postgres" with 3 replicas, what are the PVC names?

A) data-0, data-1, data-2  
B) postgres-0, postgres-1, postgres-2  
C) data-postgres-0, data-postgres-1, data-postgres-2  
D) postgres-data-0, postgres-data-1, postgres-data-2

**Answer: C) data-postgres-0, data-postgres-1, data-postgres-2**

**Explanation:** PVC naming format is: `<volume-name>-<statefulset-name>-<ordinal>`

---

### 18. What is the purpose of tolerations in a DaemonSet that needs to run on master nodes?

A) To limit resource usage  
B) To allow pods to run on tainted nodes  
C) To improve performance  
D) To enable host networking

**Answer: B) To allow pods to run on tainted nodes**

**Explanation:** Master nodes typically have taints (e.g., `node-role.kubernetes.io/control-plane:NoSchedule`). Tolerations allow DaemonSet pods to schedule on these nodes despite the taint.

---

### 19. Which of the following is TRUE about StatefulSet pod deletion order?

A) Pods are deleted in random order  
B) Pods are deleted in ascending order (0→1→2)  
C) Pods are deleted in descending order (2→1→0)  
D) All pods are deleted simultaneously

**Answer: C) Pods are deleted in descending order (2→1→0)**

**Explanation:** StatefulSets delete pods in reverse ordinal order (highest to lowest) to maintain cluster stability, especially important for distributed systems where lower-ordinal pods may be leaders/masters.

---

### 20. What is the default value of `podManagementPolicy` for StatefulSets?

A) Parallel  
B) OrderedReady  
C) Sequential  
D) Random

**Answer: B) OrderedReady**

**Explanation:** The default `podManagementPolicy` is `OrderedReady`, which creates pods sequentially. You can set it to `Parallel` if order doesn't matter for faster startup.

---

## Scenario-Based Questions

### 21. You need to deploy a 3-node Elasticsearch cluster in Kubernetes. Each node needs 10Gi of persistent storage and stable network identity for cluster discovery. Which controller should you use and why?

**Answer:**
Use **StatefulSet** because:

1. **Stable identity**: Each Elasticsearch node needs a stable name (es-0, es-1, es-2) for cluster membership
2. **Persistent storage**: Each node needs its own 10Gi PVC via `volumeClaimTemplates`
3. **Stable DNS**: Cluster discovery requires stable DNS entries (es-0.elasticsearch.svc.cluster.local)
4. **Ordered startup**: Master nodes should start before data nodes

**Implementation:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
spec:
  clusterIP: None # Headless
  selector:
    app: elasticsearch

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
spec:
  serviceName: elasticsearch
  replicas: 3
  selector:
    matchLabels:
      app: elasticsearch
  template:
    # ... pod template
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
```

---

### 22. Your cluster has 100 nodes, and you want to deploy a monitoring agent that collects metrics from each node. The agent needs 50m CPU and 64Mi memory per node. What are the considerations?

**Answer:**

**Use DaemonSet** for node-level monitoring.

**Considerations:**

1. **Total resource usage:**

   - CPU: 50m × 100 = 5000m (5 cores total)
   - Memory: 64Mi × 100 = 6400Mi (6.4Gi total)
   - Must ensure cluster has capacity

2. **Resource limits:**

   ```yaml
   resources:
     requests:
       cpu: 50m
       memory: 64Mi
     limits:
       cpu: 100m
       memory: 128Mi # Per node!
   ```

3. **Update strategy:**

   - RollingUpdate updates all nodes (can be disruptive)
   - Consider OnDelete for critical monitoring

4. **Node coverage:**

   - Verify pods run on all nodes: `kubectl get pods -l app=monitor -o wide`
   - Handle new nodes automatically

5. **Monitoring the monitor:**
   - Track DaemonSet status: `kubectl get ds monitor`
   - Alert if `numberReady < desiredNumberScheduled`
