# Day 6: Volumes & Persistent Storage - Cheat Sheet

## Quick Reference

### Volume Types

| Type | Use Case | Lifecycle |
|------|----------|-----------|
| `emptyDir` | Temporary storage, cache, shared data between containers | Deleted with Pod |
| `hostPath` | Node-local files, logs, docker socket | Persists on node |
| `persistentVolumeClaim` | Production persistent storage | Independent of Pod |

### Access Modes

- **ReadWriteOnce (RWO)**: Single node read-write
- **ReadOnlyMany (ROX)**: Multiple nodes read-only
- **ReadWriteMany (RWX)**: Multiple nodes read-write (NFS, cloud)
- **ReadWriteOncePod**: Single pod read-write (K8s 1.27+)

### Reclaim Policies

- **Retain**: Manual cleanup, data preserved
- **Delete**: Auto-delete PV and data when PVC deleted
- **Recycle**: Deprecated

## Common Commands

### Basic Operations

```bash
# List volumes
kubectl get pv
kubectl get pvc
kubectl get sc

# Describe resources
kubectl describe pv <name>
kubectl describe pvc <name>
kubectl describe sc <name>

# Apply manifests
kubectl apply -f <file>.yaml

# Delete resources
kubectl delete pv <name>
kubectl delete pvc <name>
```

### Volume Expansion

```bash
# Check if expansion is allowed
kubectl get sc <name> -o yaml | grep allowVolumeExpansion

# Expand PVC
kubectl patch pvc <name> -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'

# Watch expansion
kubectl get pvc <name> -w
```

### Testing Persistence

```bash
# Write data to pod
kubectl exec <pod> -- sh -c "echo 'data' > /data/file.txt"

# Delete pod
kubectl delete pod <pod>

# Recreate and verify data persists
kubectl get pod <pod>
kubectl exec <pod> -- cat /data/file.txt
```

## YAML Templates

### emptyDir Volume

```yaml
volumes:
- name: shared-data
  emptyDir: {}
  # With limits:
  # emptyDir:
  #   sizeLimit: 1Gi
  #   medium: Memory
```

### hostPath Volume

```yaml
volumes:
- name: host-volume
  hostPath:
    path: /tmp/k8s-logs
    type: DirectoryOrCreate
```

### PersistentVolume

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data
    type: DirectoryOrCreate
```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
```

### StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
```

### Pod with PVC

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: alpine
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
```

### StatefulSet with volumeClaimTemplates

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: nginx-headless
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: standard
      resources:
        requests:
          storage: 1Gi
```

## Key Concepts

### PV/PVC Binding Flow

1. Admin creates PV (or StorageClass auto-creates)
2. Developer creates PVC
3. Kubernetes binds PVC to matching PV
4. Pod uses PVC as volume
5. Data persists across pod restarts

### StorageClass Dynamic Provisioning

- User creates PVC with `storageClassName`
- StorageClass provisioner creates PV automatically
- PVC binds to new PV
- No manual PV creation needed

### Best Practices

- **Stateless apps**: Use Deployments without volumes
- **Stateful apps**: Use StatefulSets with volumeClaimTemplates
- **Temporary data**: Use emptyDir
- **Persistent data**: Use PVC with StorageClass
- **Databases**: Always use persistent volumes
- **Production**: Use Retain reclaim policy
- **Multi-node**: Use RWX access mode
- **Single-node**: Use RWO access mode

## Troubleshooting

### PVC Stuck in Pending

```bash
# Check events
kubectl describe pvc <name>

# Check StorageClass
kubectl get sc

# Check PV availability
kubectl get pv
```

### PV Stuck in Released

```bash
# PV with Retain policy needs manual cleanup
kubectl delete pv <name>
# Then recreate if needed
```

### Volume Mount Issues

```bash
# Check pod events
kubectl describe pod <name>

# Check volume mounts
kubectl get pod <name> -o yaml | grep -A 10 volumeMounts

# Verify PVC is bound
kubectl get pvc <name>
```

## Quick Tips

- **RWO volumes**: Only 1 pod can mount at a time
- **RWX volumes**: Multiple pods can mount simultaneously
- **emptyDir**: Fast but temporary, good for cache
- **hostPath**: Not portable, use only for specific cases
- **PVC**: Production-ready, portable across nodes
- **StorageClass**: Enables dynamic provisioning
- **volumeClaimTemplates**: Creates unique PVC per StatefulSet pod


