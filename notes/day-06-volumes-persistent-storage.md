# Day 6: Volumes & Persistent Storage

Excellent! Today we'll learn how to persist data in Kubernetes - crucial for databases, file uploads, logs, and any stateful applications.

## Part 1: The Storage Problem (10 minutes)

### Why Do We Need Volumes?

#### The Container Filesystem Problem:

```bash
# Let's demonstrate the problem
kubectl run test-pod --image=alpine -- sh -c "echo 'Important data' > /data.txt && sleep 3600"

# Write some data
kubectl exec test-pod -- sh -c "echo 'My important file' > /myfile.txt"

# Verify it exists
kubectl exec test-pod -- cat /myfile.txt

# Delete the pod (simulating a crash)
kubectl delete pod test-pod

# Recreate it
kubectl run test-pod --image=alpine -- sh -c "sleep 3600"

# Try to read the file
kubectl exec test-pod -- cat /myfile.txt
# Error: No such file or directory
# 🎯 Data is GONE!
```

#### Problems without persistent storage:

```javascript
const storageProblems = {
  ephemeral: "Container filesystem is temporary",
  crashes: "Data lost when pod restarts",
  updates: "Data lost during rolling updates",
  scaling: "Each pod has separate filesystem",
  databases: "Can't run databases without persistence",
  sharing: "Containers can't share data easily",
};

// Volumes solve all of these!
```

## Part 2: Volume Types Overview (15 minutes)

Kubernetes supports many volume types:

```javascript
const volumeTypes = {
  // Temporary (lifecycle tied to Pod)
  emptyDir: "Temporary directory, deleted with Pod",

  // Node-local
  hostPath: "Mount directory from Node filesystem",

  // Network storage
  nfs: "Network File System",

  // Cloud provider
  awsElasticBlockStore: "AWS EBS",
  gcePersistentDisk: "Google Cloud PD",
  azureDisk: "Azure Disk",

  // Special
  configMap: "ConfigMap as volume (we learned this!)",
  secret: "Secret as volume (we learned this!)",

  // Persistent
  persistentVolumeClaim: "Claim from PersistentVolume pool",
};
```

## Part 3: emptyDir - Temporary Storage (15 minutes)

**emptyDir** = Created when Pod is assigned to a Node, deleted when Pod is removed.

### Use Cases:

- Scratch space
- Cache
- Sharing data between containers in same Pod

### Create pod-emptydir.yaml:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
    # Container 1: Writer
    - name: writer
      image: alpine
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
          echo "$(date) - Writing to shared volume" >> /data/log.txt;
          sleep 5;
          done
      volumeMounts:
        - name: shared-data
          mountPath: /data

    # Container 2: Reader
    - name: reader
      image: alpine
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
          echo "=== Reading from shared volume ===";
          tail -n 5 /data/log.txt;
          sleep 10;
          done
      volumeMounts:
        - name: shared-data
          mountPath: /data

  volumes:
    - name: shared-data
      emptyDir: {} # Empty directory
```

```bash
# Apply it
kubectl apply -f pod-emptydir.yaml

# Watch writer logs
kubectl logs emptydir-demo -c writer -f

# In another terminal, watch reader logs
kubectl logs emptydir-demo -c reader -f

# Both containers see the same data!
```

### emptyDir with size limit and memory backing:

```yaml
volumes:
  - name: cache-volume
    emptyDir:
      sizeLimit: 1Gi # Limit size
      medium: Memory # Use RAM instead of disk (faster, but limited)
```

## Part 4: hostPath - Node Storage (15 minutes)

**hostPath** = Mounts a file or directory from the Node's filesystem.

⚠️ **Warning:** Use only for specific cases (logs, docker socket). Not portable across nodes!

### Create pod-hostpath.yaml:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
    - name: container
      image: alpine
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
          echo "$(date) - Node log entry" >> /host-logs/app.log;
          ls -lh /host-logs/;
          sleep 10;
          done
      volumeMounts:
        - name: host-volume
          mountPath: /host-logs

  volumes:
    - name: host-volume
      hostPath:
        path: /tmp/k8s-logs # Path on Node
        type: DirectoryOrCreate # Create if doesn't exist
```

```bash
kubectl apply -f pod-hostpath.yaml

# View logs
kubectl logs hostpath-demo -f

# SSH into minikube and check the host directory
minikube ssh
ls -la /tmp/k8s-logs/
cat /tmp/k8s-logs/app.log
exit
```

### hostPath types:

```yaml
volumes:
  - name: example
    hostPath:
      path: /path/on/host
      type: Directory # Must exist
      # type: DirectoryOrCreate  # Create if needed
      # type: File               # Must be a file
      # type: Socket             # Unix socket
```

---

## Part 5: PersistentVolumes (PV) & PersistentVolumeClaims (PVC) (40 minutes)

This is the **production way** to handle storage!

### Concept Overview

```
┌──────────────────────────────────────┐
│        Cluster Admin                 │
│  Creates PersistentVolumes (PV)      │
│  (Storage pool)                      │
└────────────┬─────────────────────────┘
             │
             ↓
┌────────────────────────────────────────┐
│     PersistentVolume (PV)              │
│  - 10Gi storage                        │
│  - ReadWriteOnce                       │
│  - Fast SSD                            │
└────────────┬───────────────────────────┘
             │ Binds to
             ↓
┌────────────────────────────────────────┐
│  PersistentVolumeClaim (PVC)           │
│  "I need 5Gi of storage"               │
│  (Created by Developer)                │
└────────────┬───────────────────────────┘
             │ Used by
             ↓
┌────────────────────────────────────────┐
│           Pod                          │
│  Uses PVC as volume                    │
└────────────────────────────────────────┘
```

### Key Concepts:

```javascript
const pvPvcConcepts = {
  PV: "Cluster resource representing storage",
  PVC: "Request for storage by a user/pod",
  binding: "PVC binds to a matching PV",
  lifecycle: "PV exists independently of Pods",
  reclaimPolicy: "What happens to PV when PVC is deleted",
};
```

### Access Modes

```yaml
accessModes:
  - ReadWriteOnce (RWO) # Single node read-write
  - ReadOnlyMany (ROX) # Multiple nodes read-only
  - ReadWriteMany (RWX) # Multiple nodes read-write (NFS, cloud)
  - ReadWriteOncePod # Single pod read-write (K8s 1.27+)
```

### Create a PersistentVolume

Create **pv.yaml**:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
  labels:
    type: local
spec:
  capacity:
    storage: 1Gi # Size

  accessModes:
    - ReadWriteOnce # Access mode

  persistentVolumeReclaimPolicy: Retain # Retain, Delete, or Recycle

  storageClassName: manual # Storage class name

  hostPath: # Using hostPath for demo
    path: /mnt/data # (In production, use NFS, cloud storage, etc.)
    type: DirectoryOrCreate
```

```bash
# Apply it
kubectl apply -f pv.yaml

# Check PV
kubectl get pv
kubectl describe pv my-pv

# Status should be "Available"
```

### Create a PersistentVolumeClaim

Create **pvc.yaml**:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce # Must match PV

  resources:
    requests:
      storage: 500Mi # Request 500Mi (PV has 1Gi, so it fits)

  storageClassName: manual # Must match PV

  selector: # Optional: select specific PV
    matchLabels:
      type: local
```

```bash
# Apply it
kubectl apply -f pvc.yaml

# Check PVC
kubectl get pvc
kubectl describe pvc my-pvc

# Check PV again
kubectl get pv
# Status changed from "Available" to "Bound"!

# See the binding
kubectl get pvc my-pvc -o yaml | grep -A 3 "volumeName"
```

### Use PVC in a Pod

Create **pod-with-pvc.yaml**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-pvc
spec:
  containers:
    - name: app
      image: alpine
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
          echo "$(date) - Persistent data!" >> /data/persistent.log;
          echo "Content of /data:";
          ls -lh /data/;
          sleep 10;
          done
      volumeMounts:
        - name: persistent-storage
          mountPath: /data

  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: my-pvc # Reference the PVC
```

```bash
# Apply it
kubectl apply -f pod-with-pvc.yaml

# Watch logs
kubectl logs pod-with-pvc -f

# Check the data in minikube node
minikube ssh
ls -la /mnt/data/
cat /mnt/data/persistent.log
exit
```

### Test Persistence

```bash
# Delete the pod
kubectl delete pod pod-with-pvc

# Recreate it
kubectl apply -f pod-with-pvc.yaml

# Check logs - old data still there!
kubectl logs pod-with-pvc

# Verify file has old timestamps
kubectl exec pod-with-pvc -- cat /data/persistent.log
# 🎯 Data survived pod deletion!
```

---

## Part 6: StorageClass - Dynamic Provisioning (25 minutes)

**Problem with manual PV/PVC:**

- Admin must pre-create PVs
- Not scalable

**Solution: StorageClass + Dynamic Provisioning**

```
User creates PVC
      ↓
StorageClass automatically creates PV
      ↓
PVC binds to new PV
      ↓
Ready to use!
```

### Check Default StorageClass

```bash
# List storage classes
kubectl get storageclass
kubectl get sc  # shorthand

# Minikube comes with "standard" StorageClass
kubectl describe sc standard
```

### Create Custom StorageClass

Create **storageclass.yaml**:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: k8s.io/minikube-hostpath # For minikube
parameters:
  type: pd-ssd # Provider-specific
reclaimPolicy: Delete # Delete PV when PVC deleted
volumeBindingMode: Immediate # Immediate or WaitForFirstConsumer
allowVolumeExpansion: true # Allow resizing
```

```bash
kubectl apply -f storageclass.yaml
kubectl get sc
```

### Use StorageClass with Dynamic Provisioning

Create **pvc-dynamic.yaml**:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce

  storageClassName: standard # Use default StorageClass

  resources:
    requests:
      storage: 2Gi
```

```bash
# Apply it
kubectl apply -f pvc-dynamic.yaml

# Watch PVC and PV creation
kubectl get pvc -w
# Status: Pending → Bound

# Check PV - it was created automatically!
kubectl get pv

# Notice the PV name matches the PVC
```

### Use Dynamic PVC in Deployment

Create **deployment-with-storage.yaml**:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-storage
spec:
  replicas: 1                    # Only 1 replica with RWO!
  selector:
    matchLabels:
      app: storage-demo
  template:
    metadata:
      labels:
        app: storage-demo
    spec:
      containers:
      - name: app
        image: alpine
        command: ["/bin/sh", "-c"]
        args:
          - while true; do
              echo "$(date) - Counter: $(($(cat /data/counter.txt 2>/dev/null || echo 0) + 1))" | tee /data/counter.txt;
              sleep 5;
            done
        volumeMounts:
        - name: data
          mountPath: /data

      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: app-data-pvc
```

```bash
# Apply it
kubectl apply -f deployment-with-storage.yaml

# Watch logs - counter increments
kubectl logs -f deployment/app-with-storage

# Delete the pod (deployment recreates it)
kubectl delete pod -l app=storage-demo

# Watch logs again - counter continues from where it left off!
kubectl logs -f deployment/app-with-storage
# 🎯 Persistent state across pod restarts!
```

## Part 7: Reclaim Policies (10 minutes)

What happens to PV when PVC is deleted?

### Reclaim Policies:

```yaml
persistentVolumeReclaimPolicy: Retain # Manual cleanup
# persistentVolumeReclaimPolicy: Delete   # Auto-delete PV and data
# persistentVolumeReclaimPolicy: Recycle  # Deprecated
```

### Test Retain Policy:

```bash
# Create PV with Retain policy
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: retain-pv
spec:
  capacity:
    storage: 500Mi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/retain-data
    type: DirectoryOrCreate
EOF

# Create PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: retain-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 500Mi
EOF

# Check binding
kubectl get pv retain-pv
kubectl get pvc retain-pvc

# Delete PVC
kubectl delete pvc retain-pvc

# Check PV status
kubectl get pv retain-pv
# Status: Released (not Available, not Deleted)
# Data still exists, but PV can't be claimed again until cleaned up

# To reuse, delete and recreate PV
kubectl delete pv retain-pv
```

## Part 8: Volume Expansion (10 minutes)

Resize volumes without recreating them:

```bash
# Check if StorageClass allows expansion
kubectl get sc standard -o yaml | grep allowVolumeExpansion

# Create a PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: expandable-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
EOF

# Check size
kubectl get pvc expandable-pvc

# Expand it (edit the YAML)
kubectl patch pvc expandable-pvc -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'

# Watch the expansion
kubectl get pvc expandable-pvc -w
# Condition: FileSystemResizePending → then resized

# Check new size
kubectl describe pvc expandable-pvc
```

## 📝 Day 6 Homework (40-50 minutes)

### Exercise 1: Multi-Container Pod with Shared Volume

Create a Pod where one container writes logs and another analyzes them:

```yaml
# log-analyzer.yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-analyzer
spec:
  containers:
    # Web server generating logs
    - name: web-server
      image: nginx:alpine
      volumeMounts:
        - name: logs
          mountPath: /var/log/nginx

    # Log analyzer
    - name: analyzer
      image: alpine
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
          echo "=== Log Analysis ===";
          echo "Total requests:";
          wc -l /logs/access.log 2>/dev/null || echo "No logs yet";
          sleep 30;
          done
      volumeMounts:
        - name: logs
          mountPath: /logs
          readOnly: true

  volumes:
    - name: logs
      emptyDir: {}
```

### Exercise 2: Database with Persistent Storage

Deploy PostgreSQL with persistent data:

```yaml
# postgres-with-storage.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15-alpine
          env:
            - name: POSTGRES_PASSWORD
              value: mysecretpassword
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data

      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
```

```bash
kubectl apply -f postgres-with-storage.yaml

# Connect and create data
kubectl exec -it deployment/postgres -- psql -U postgres
# CREATE DATABASE testdb;
# \c testdb
# CREATE TABLE users (id SERIAL, name VARCHAR(50));
# INSERT INTO users (name) VALUES ('Alice'), ('Bob');
# SELECT * FROM users;
# \q

# Delete pod
kubectl delete pod -l app=postgres

# Reconnect after pod recreates
kubectl exec -it deployment/postgres -- psql -U postgres -d testdb -c "SELECT * FROM users;"
# 🎯 Data persists!
```

### Exercise 3: StatefulSet with Persistent Storage

```yaml
# statefulset-storage.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None
  selector:
    app: nginx-sts
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: nginx-headless
  replicas: 3
  selector:
    matchLabels:
      app: nginx-sts
  template:
    metadata:
      labels:
        app: nginx-sts
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html

  volumeClaimTemplates: # PVC template for each pod
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

```bash
kubectl apply -f statefulset-storage.yaml

# Check PVCs - one per pod!
kubectl get pvc

# Write unique data to each pod
for i in 0 1 2; do
  kubectl exec web-$i -- sh -c "echo 'Pod web-$i' > /usr/share/nginx/html/index.html"
done

# Verify each pod has unique data
for i in 0 1 2; do
  echo "=== web-$i ==="
  kubectl exec web-$i -- cat /usr/share/nginx/html/index.html
done

# Delete a pod
kubectl delete pod web-1

# After recreation, data persists
kubectl exec web-1 -- cat /usr/share/nginx/html/index.html
```

### Exercise 4: Backup and Restore

Practice backing up PVC data:

```bash
# Create a pod with data
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
spec:
  containers:
  - name: app
    image: alpine
    command: ["/bin/sh", "-c", "echo 'Important data' > /data/important.txt && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: backup-test-pvc
EOF

# Backup using a job
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: backup-job
spec:
  template:
    spec:
      containers:
      - name: backup
        image: alpine
        command: ["/bin/sh", "-c"]
        args:
          - tar czf /backup/backup.tar.gz -C /data . &&
            echo "Backup completed" &&
            ls -lh /backup/
        volumeMounts:
        - name: data
          mountPath: /data
          readOnly: true
        - name: backup
          mountPath: /backup
      restartPolicy: Never
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: backup-test-pvc
      - name: backup
        hostPath:
          path: /tmp/backups
          type: DirectoryOrCreate
EOF

# Check backup
minikube ssh
ls -la /tmp/backups/
exit
```

### Exercise 5: Multiple PVCs in One Pod

```yaml
# multi-volume-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-volume-pod
spec:
  containers:
    - name: app
      image: alpine
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
          echo "$(date)" >> /data/logs.txt;
          echo "$(date)" >> /config/settings.txt;
          sleep 10;
          done
      volumeMounts:
        - name: data-volume
          mountPath: /data
        - name: config-volume
          mountPath: /config

  volumes:
    - name: data-volume
      persistentVolumeClaim:
        claimName: data-pvc
    - name: config-volume
      persistentVolumeClaim:
        claimName: config-pvc
```

## ✅ Day 6 Checklist

Before moving to Day 7, ensure you can:

- [ ] Understand why volumes are needed
- [ ] Use emptyDir for temporary storage
- [ ] Use hostPath for node-local storage
- [ ] Create PersistentVolumes (PV)
- [ ] Create PersistentVolumeClaims (PVC)
- [ ] Understand PV/PVC binding
- [ ] Use PVCs in Pods and Deployments
- [ ] Understand access modes (RWO, ROX, RWX)
- [ ] Use StorageClasses for dynamic provisioning
- [ ] Understand reclaim policies
- [ ] Expand volumes
- [ ] Use volumeClaimTemplates in StatefulSets

## 🎯 Storage Best Practices

```javascript
const storageBestPractices = {
  stateless: "Use Deployments without volumes",
  stateful: "Use StatefulSets with volumeClaimTemplates",
  temporary: "Use emptyDir for cache/scratch space",
  persistent: "Use PVC with StorageClass",
  databases: "Always use persistent volumes",
  backups: "Implement backup strategies for PVCs",
  reclaimPolicy: "Use Retain for production data",
  accessMode: "Use RWO for single-node, RWX for multi-node",
  sizing: "Start small, enable expansion",
};
```

