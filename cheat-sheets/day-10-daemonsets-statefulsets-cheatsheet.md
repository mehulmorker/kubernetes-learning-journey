# Day 10: DaemonSets & StatefulSets Cheat Sheet

## Quick Reference

### DaemonSet vs StatefulSet vs Deployment

| Feature | Deployment | DaemonSet | StatefulSet |
|---------|------------|-----------|-------------|
| **Pod Names** | Random | Random | Ordered (name-0, name-1) |
| **Replicas** | Specified | One per node | Specified |
| **Scaling** | Any direction | Auto with nodes | Ordered |
| **Pod Identity** | No | No | Yes (stable) |
| **Storage** | Shared/none | Usually hostPath | Unique PVC per pod |
| **Network ID** | No | No | Yes (stable DNS) |
| **Use Case** | Stateless apps | Node agents | Stateful apps |

---

## DaemonSet Commands

### Basic Operations
```bash
# Create DaemonSet
kubectl apply -f daemonset.yaml

# View DaemonSets
kubectl get daemonsets
kubectl get ds  # shorthand

# View pods created by DaemonSet
kubectl get pods -l app=<label> -o wide

# Describe DaemonSet
kubectl describe ds <name>

# View logs
kubectl logs -l app=<label> --tail=10
```

### Updates
```bash
# Check update strategy
kubectl get ds <name> -o jsonpath='{.spec.updateStrategy}'

# Update image
kubectl set image daemonset/<name> <container>=<image>:<tag>

# Watch rollout
kubectl rollout status daemonset/<name>

# View history
kubectl rollout history daemonset/<name>

# Rollback
kubectl rollout undo daemonset/<name>

# Restart
kubectl rollout restart daemonset/<name>
```

### Node Management
```bash
# Label node for nodeSelector
kubectl label nodes <node-name> <key>=<value>

# Remove label
kubectl label nodes <node-name> <key>-

# Check node labels
kubectl get nodes --show-labels

# Check node taints
kubectl describe nodes | grep Taints
```

---

## StatefulSet Commands

### Basic Operations
```bash
# Create StatefulSet
kubectl apply -f statefulset.yaml

# View StatefulSets
kubectl get statefulsets
kubectl get sts  # shorthand

# View pods
kubectl get pods -l app=<label>

# Describe StatefulSet
kubectl describe sts <name>
```

### Scaling
```bash
# Scale up (ordered: 0→1→2→...)
kubectl scale statefulset <name> --replicas=<count>

# Scale down (ordered: ...→2→1→0)
kubectl scale statefulset <name> --replicas=<count>

# Watch ordered creation/deletion
kubectl get pods -w
```

### DNS & Networking
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=alpine --restart=Never -- sh

# Inside pod:
nslookup <pod-name>.<service-name>.<namespace>.svc.cluster.local
# Example: web-0.web.default.svc.cluster.local
```

### Storage
```bash
# View PVCs created by StatefulSet
kubectl get pvc

# Check PVC status
kubectl describe pvc <pvc-name>

# View PVs
kubectl get pv
```

### Updates
```bash
# Update with partition (canary)
kubectl patch statefulset <name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'

# Update image
kubectl set image statefulset/<name> <container>=<image>:<tag>

# Remove partition (update all)
kubectl patch statefulset <name> -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

---

## DaemonSet YAML Template

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: <name>
  namespace: <namespace>  # optional
spec:
  selector:
    matchLabels:
      app: <label>
  template:
    metadata:
      labels:
        app: <label>
    spec:
      # Node selector (optional)
      nodeSelector:
        <key>: "<value>"
      
      # Tolerations (for master nodes)
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      
      containers:
      - name: <container-name>
        image: <image>
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
        volumeMounts:
        - name: <volume-name>
          mountPath: <path>
      volumes:
      - name: <volume-name>
        hostPath:
          path: <host-path>
```

---

## StatefulSet YAML Template

```yaml
# Headless Service (REQUIRED)
apiVersion: v1
kind: Service
metadata:
  name: <service-name>
spec:
  clusterIP: None  # Headless!
  selector:
    app: <label>
  ports:
  - port: <port>

---
# StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: <name>
spec:
  serviceName: <service-name>  # Must match service above
  replicas: <count>
  selector:
    matchLabels:
      app: <label>
  template:
    metadata:
      labels:
        app: <label>
    spec:
      containers:
      - name: <container-name>
        image: <image>
        volumeMounts:
        - name: <volume-name>
          mountPath: <path>
        readinessProbe:  # Important!
          httpGet:
            path: /health
            port: <port>
          initialDelaySeconds: 10
          periodSeconds: 5
  
  # Volume Claim Template (creates PVC per pod)
  volumeClaimTemplates:
  - metadata:
      name: <volume-name>
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: <storage-class>
      resources:
        requests:
          storage: <size>
```

---

## Key Concepts

### DaemonSet
- **Purpose**: One pod per node
- **Use Cases**: Logging, monitoring, networking, storage
- **Scheduling**: Automatic on all nodes (or selected via nodeSelector)
- **Updates**: RollingUpdate (default) or OnDelete
- **Resource Impact**: Multiply by node count!

### StatefulSet
- **Purpose**: Stateful apps with stable identity
- **Use Cases**: Databases, distributed systems, clustered apps
- **Pod Naming**: `<name>-0`, `<name>-1`, `<name>-2` (stable)
- **Ordering**: Create 0→1→2, Delete 2→1→0
- **Storage**: Each pod gets own PVC via `volumeClaimTemplates`
- **DNS**: Stable DNS entries per pod
- **Service**: Must use headless service (`clusterIP: None`)

---

## Decision Tree

```
Need to run on every node?
  YES → DaemonSet
  NO → Need stable identity/persistent storage?
    YES → StatefulSet
    NO → Deployment
```

---

## Common Patterns

### DaemonSet: Log Collector
```yaml
# Mount host logs
volumeMounts:
- name: varlog
  mountPath: /var/log
  readOnly: true
volumes:
- name: varlog
  hostPath:
    path: /var/log
```

### StatefulSet: Database
```yaml
# Each pod gets own storage
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

### StatefulSet: Partitioned Updates (Canary)
```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 2  # Only update pods >= 2
```

---

## Troubleshooting

### DaemonSet Pods Not Running
```bash
# Check node labels
kubectl get nodes --show-labels

# Check taints
kubectl describe nodes | grep Taints

# Check DaemonSet
kubectl describe ds <name>
```

### StatefulSet Pods Stuck
```bash
# Check PVC status
kubectl get pvc

# Check storage class
kubectl get sc

# Check events
kubectl describe sts <name>
kubectl get events --sort-by='.lastTimestamp'
```

### Data Not Persisting
```bash
# Verify PVC bound
kubectl get pvc

# Check volume mounts
kubectl describe pod <pod-name>

# Test write
kubectl exec <pod-name> -- ls -la /data
```

---

## Best Practices

### DaemonSet
- ✅ Always set resource limits (affects ALL nodes)
- ✅ Use tolerations for master nodes
- ✅ Mount host paths carefully (security)
- ✅ Test on single node first

### StatefulSet
- ✅ Always use headless service
- ✅ Use `volumeClaimTemplates` for storage
- ✅ Implement readiness probes
- ✅ Test pod recreation
- ✅ Plan for ordered operations
- ✅ Implement backup strategy

---

## Quick Tips

1. **DaemonSet resource calculation**: `per-node-resource × node-count = total`
2. **StatefulSet DNS format**: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`
3. **StatefulSet PVC naming**: `<volume-name>-<statefulset-name>-<ordinal>`
4. **Ordered scaling**: StatefulSet always scales in order (0→1→2 up, 2→1→0 down)
5. **Headless service**: Required for StatefulSet stable DNS

