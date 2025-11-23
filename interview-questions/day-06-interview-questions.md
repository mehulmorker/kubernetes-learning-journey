# Day 06: Volumes & Persistent Storage - Interview Questions

## 1. Why do we need volumes in Kubernetes when containers already have a filesystem?

**Answer:**
Container filesystems are ephemeral - data is lost when containers restart or are deleted.

**Problems without volumes:**
- **Data loss**: Files written to container filesystem are lost when Pod restarts
- **No persistence**: Database data, logs, user uploads are lost
- **No sharing**: Containers can't share data
- **Updates**: Data lost during rolling updates (old Pods deleted)

**Volumes solve:**
- ✅ **Persistence**: Data survives Pod restarts and deletions
- ✅ **Sharing**: Multiple containers in same Pod can share data
- ✅ **Stateful apps**: Run databases, file servers, etc.
- ✅ **Updates**: Data persists across rolling updates

**Example:**
```
Without volume:
  Pod writes data → Pod deleted → Data lost ❌

With volume:
  Pod writes data → Pod deleted → New Pod created → Data still there ✅
```

---

## 2. Explain the difference between emptyDir, hostPath, and PersistentVolumeClaim volumes.

**Answer:**

**emptyDir:**
- **Lifecycle**: Created when Pod starts, deleted when Pod terminates
- **Scope**: Node-local (only accessible on same node)
- **Use case**: Temporary storage, cache, sharing data between containers in same Pod
- **Persistence**: No (data lost when Pod deleted)

**hostPath:**
- **Lifecycle**: Mounts directory from node's filesystem
- **Scope**: Node-local (not portable across nodes)
- **Use case**: Node-specific data (logs, Docker socket), development
- **Persistence**: Yes (on node), but not portable
- **Warning**: Not recommended for production (not portable, security risks)

**PersistentVolumeClaim (PVC):**
- **Lifecycle**: Independent of Pod lifecycle
- **Scope**: Cluster-wide (portable across nodes)
- **Use case**: Production persistent storage (databases, file storage)
- **Persistence**: Yes (data survives Pod/node failures)
- **Best Practice**: Use for production stateful applications

**Comparison:**
```
emptyDir:     Temporary, Pod-scoped, fast
hostPath:     Node-local, not portable, risky
PVC:          Persistent, portable, production-ready
```

---

## 3. Multiple Choice: What happens to data in an emptyDir volume when a Pod is deleted?

A. Data is preserved  
B. Data is deleted  
C. Data is moved to another Pod  
D. Data is backed up automatically

**Answer: B**

**Explanation:** emptyDir volumes are created when Pod starts and deleted when Pod terminates. Data is ephemeral and lost when Pod is deleted.

---

## 4. Explain the PersistentVolume (PV) and PersistentVolumeClaim (PVC) model.

**Answer:**

**Concept:**
```
Cluster Admin creates PVs (storage pool)
    ↓
Developer creates PVC (requests storage)
    ↓
Kubernetes binds PVC to matching PV
    ↓
Pod uses PVC as volume
```

**PersistentVolume (PV):**
- Cluster-level resource (like a node)
- Represents actual storage (NFS, cloud disk, etc.)
- Created by cluster administrator
- Has capacity, access modes, storage class

**PersistentVolumeClaim (PVC):**
- Namespace-level resource (like a Pod)
- Request for storage by user/application
- Specifies size, access mode, storage class
- Kubernetes finds matching PV and binds them

**Benefits:**
- **Abstraction**: Developers don't need to know storage details
- **Flexibility**: Can use different storage backends
- **Portability**: Same PVC works across different clusters
- **Dynamic provisioning**: StorageClass can auto-create PVs

**Example:**
```yaml
# PV (created by admin)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data

# PVC (created by developer)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 5Gi
```

---

## 5. What are the different access modes for PersistentVolumes?

**Answer:**

**ReadWriteOnce (RWO):**
- Single node can mount for read-write
- Most common for databases
- Example: MySQL, PostgreSQL

**ReadOnlyMany (ROX):**
- Multiple nodes can mount read-only
- Use case: Shared configuration, read-only data
- Example: Shared config files

**ReadWriteMany (RWX):**
- Multiple nodes can mount read-write
- Requires network storage (NFS, cloud storage)
- Example: Shared file storage, content management

**ReadWriteOncePod (RWO - K8s 1.27+):**
- Single Pod can mount read-write
- More restrictive than RWO
- Use case: StatefulSets where each Pod needs exclusive access

**Example:**
```yaml
accessModes:
  - ReadWriteOnce  # Most common
  # - ReadOnlyMany
  # - ReadWriteMany
```

**Storage support:**
- **RWO**: Most storage types (EBS, GCE PD, Azure Disk)
- **RWX**: NFS, cloud file storage (EFS, Azure Files)
- **ROX**: Some cloud storage

---

## 6. Multiple Choice: What is the default reclaim policy for a PersistentVolume?

A. Retain  
B. Delete  
C. Recycle  
D. None

**Answer: A**

**Explanation:** The default reclaim policy is `Retain`, which means the PV is retained (not deleted) when the PVC is deleted. The data remains but the PV cannot be reused until manually cleaned up.

---

## 7. Explain the difference between Retain, Delete, and Recycle reclaim policies.

**Answer:**

**Retain:**
- PV is retained when PVC is deleted
- Data is preserved
- PV status becomes "Released" (cannot be reused)
- Manual cleanup required
- **Use case**: Production data, important data

**Delete:**
- PV and associated storage are deleted when PVC is deleted
- Data is permanently lost
- Automatic cleanup
- **Use case**: Temporary data, development
- **Requires**: Storage provisioner support

**Recycle:**
- Deprecated (removed in K8s 1.15+)
- Was used to scrub data and make PV available again
- **Don't use**: Use Retain or Delete instead

**Example:**
```yaml
persistentVolumeReclaimPolicy: Retain  # or Delete
```

**Best Practice:**
- **Production**: Use Retain (data safety)
- **Development**: Use Delete (automatic cleanup)
- **Never**: Use Recycle (deprecated)

---

## 8. What is a StorageClass, and how does it enable dynamic provisioning?

**Answer:**

**StorageClass:**
- Defines different "classes" of storage (fast, slow, SSD, HDD)
- Contains provisioner, parameters, reclaim policy
- Enables dynamic provisioning

**Dynamic Provisioning:**
- Automatically creates PV when PVC is created
- No need to pre-create PVs
- PVC specifies StorageClass, provisioner creates matching PV

**How it works:**
```
1. User creates PVC with StorageClass
2. Kubernetes finds StorageClass
3. StorageClass provisioner creates PV automatically
4. PVC binds to new PV
5. Ready to use!
```

**Example:**
```yaml
# StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
reclaimPolicy: Delete
allowVolumeExpansion: true

# PVC (triggers dynamic provisioning)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: fast-ssd
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Benefits:**
- No manual PV creation
- Scalable (create PVCs on demand)
- Flexible (different storage classes)

---

## 9. Multiple Choice: Which access mode allows multiple Pods on different nodes to read and write?

A. ReadWriteOnce  
B. ReadOnlyMany  
C. ReadWriteMany  
D. ReadWriteOncePod

**Answer: C**

**Explanation:** ReadWriteMany (RWX) allows multiple nodes to mount the volume for read-write access. This requires network storage like NFS or cloud file storage.

---

## 10. Scenario: You need to deploy a PostgreSQL database with persistent storage. How would you configure it?

**Answer:**

**Step 1: Create PVC**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce  # Database needs exclusive access
  storageClassName: standard
  resources:
    requests:
      storage: 20Gi  # Adjust based on needs
```

**Step 2: Create Deployment/StatefulSet with PVC**
```yaml
apiVersion: apps/v1
kind: StatefulSet  # Better for databases
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
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:  # For StatefulSet
  - metadata:
      name: postgres-storage
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: standard
      resources:
        requests:
          storage: 20Gi
```

**Key points:**
- Use `ReadWriteOnce` (database needs exclusive access)
- Use StatefulSet for databases (stable identity, ordered deployment)
- Mount to PostgreSQL data directory
- Set `PGDATA` environment variable
- Use Secrets for passwords

---

## 11. Explain when to use emptyDir vs PersistentVolumeClaim.

**Answer:**

**Use emptyDir when:**
- Temporary data (cache, scratch space)
- Sharing data between containers in same Pod
- Data doesn't need to persist (logs, temp files)
- Fast local storage needed
- Example: Web server cache, build artifacts

**Use PersistentVolumeClaim when:**
- Data must persist (databases, file storage)
- Data survives Pod restarts
- Production applications
- Stateful workloads
- Example: Database data, user uploads, application state

**Decision tree:**
```
Need persistence? 
  Yes → Use PVC
  No → Need sharing between containers?
    Yes → Use emptyDir
    No → Use container filesystem
```

**Example - emptyDir:**
```yaml
# Web server with cache
volumes:
- name: cache
  emptyDir: {}
```

**Example - PVC:**
```yaml
# Database with persistent data
volumes:
- name: data
  persistentVolumeClaim:
    claimName: db-pvc
```

---

## 12. Multiple Choice: What happens to a PersistentVolume when its PersistentVolumeClaim is deleted with Retain policy?

A. PV is automatically deleted  
B. PV is deleted but data is backed up  
C. PV is retained but cannot be reused  
D. PV becomes available immediately

**Answer: C**

**Explanation:** With Retain policy, when PVC is deleted, the PV is retained but its status becomes "Released". The data is preserved, but the PV cannot be reused until manually cleaned up (delete PV and recreate, or manually clean data).

---

## 13. What is volumeClaimTemplates in StatefulSets, and why is it important?

**Answer:**

**volumeClaimTemplates:**
- Creates a PVC for each Pod in a StatefulSet
- Each Pod gets its own persistent volume
- PVCs are named: `<volumeClaimTemplate-name>-<statefulset-name>-<ordinal>`

**Why important:**
- **Stable storage**: Each Pod has dedicated storage
- **Pod identity**: Storage follows Pod (even if Pod is recreated)
- **Stateful apps**: Perfect for databases, distributed systems
- **Ordered deployment**: Pods created in order, each gets its own storage

**Example:**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  replicas: 3
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

**Result:**
- Pod `web-0` gets PVC `www-web-0`
- Pod `web-1` gets PVC `www-web-1`
- Pod `web-2` gets PVC `www-web-2`

**Benefits:**
- Each Pod has isolated, persistent storage
- Pod can be deleted and recreated, keeps same storage
- Perfect for stateful applications

---

## 14. How do you expand a PersistentVolumeClaim?

**Answer:**

**Prerequisites:**
- StorageClass must have `allowVolumeExpansion: true`
- Storage provisioner must support expansion

**Method 1: Edit PVC directly**
```bash
kubectl edit pvc my-pvc
# Change: storage: 10Gi → storage: 20Gi
```

**Method 2: Patch command**
```bash
kubectl patch pvc my-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

**Method 3: Update YAML and apply**
```yaml
# Edit pvc.yaml
resources:
  requests:
    storage: 20Gi  # Increased from 10Gi
```

**Process:**
1. Update PVC spec with new size
2. Kubernetes expands the volume
3. PVC status shows `FileSystemResizePending`
4. Kubelet resizes filesystem
5. PVC becomes `Bound` with new size

**Note:** 
- Can only expand, not shrink
- Pod may need to be restarted for filesystem resize
- Some storage types support online expansion (no Pod restart)

---

## 15. Multiple Choice: Which volume type is best for sharing data between containers in the same Pod?

A. hostPath  
B. PersistentVolumeClaim  
C. emptyDir  
D. NFS

**Answer: C**

**Explanation:** emptyDir is perfect for sharing data between containers in the same Pod because:
- Created when Pod starts
- Shared by all containers in the Pod
- Fast (local storage)
- Simple to use
- Data lifecycle matches Pod lifecycle

---

## 16. Explain the difference between static and dynamic provisioning of PersistentVolumes.

**Answer:**

**Static Provisioning:**
- Cluster admin pre-creates PVs
- PVs exist before PVCs are created
- Admin must manage PV lifecycle
- **Process:**
  1. Admin creates PVs
  2. User creates PVC
  3. Kubernetes binds PVC to matching PV

**Dynamic Provisioning:**
- PVs are created automatically when PVC is created
- StorageClass provisioner creates PV on demand
- No manual PV creation needed
- **Process:**
  1. User creates PVC with StorageClass
  2. Provisioner creates PV automatically
  3. PVC binds to new PV

**Comparison:**
```
Static:
  - Manual PV creation
  - Fixed storage pool
  - More control
  - Less scalable

Dynamic:
  - Automatic PV creation
  - On-demand storage
  - Less manual work
  - More scalable
```

**Best Practice:** Use dynamic provisioning for most cases. Use static only when you need specific storage configurations or pre-allocated storage.

---

## 17. Scenario: Your application needs to store user-uploaded files that must persist across Pod restarts. Which volume type would you use and why?

**Answer:**

**Use PersistentVolumeClaim (PVC)** because:

**Requirements:**
- Data must persist (survive Pod restarts)
- User uploads are important (cannot be lost)
- Production application

**Configuration:**
```yaml
# PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: uploads-pvc
spec:
  accessModes:
    - ReadWriteOnce  # or ReadWriteMany if multiple Pods need access
  storageClassName: standard
  resources:
    requests:
      storage: 50Gi  # Adjust based on expected usage

# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: file-server
spec:
  replicas: 1  # RWO allows only 1 replica
  template:
    spec:
      containers:
      - name: app
        image: file-server:latest
        volumeMounts:
        - name: uploads
          mountPath: /uploads
      volumes:
      - name: uploads
        persistentVolumeClaim:
          claimName: uploads-pvc
```

**Why not other options:**
- **emptyDir**: Data lost when Pod deleted ❌
- **hostPath**: Not portable, security risks ❌
- **PVC**: Persistent, portable, production-ready ✅

**Note:** If you need multiple Pods to access same files (e.g., load-balanced file server), use `ReadWriteMany` access mode with network storage (NFS, cloud file storage).

