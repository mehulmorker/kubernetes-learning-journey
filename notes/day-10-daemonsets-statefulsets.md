# Day 10: DaemonSets & StatefulSets

Excellent progress! Today we'll learn about two specialized workload controllers that solve specific problems regular Deployments can't handle.

## Part 1: Introduction to Specialized Workloads (15 minutes)

### The Problem with Regular Deployments

Deployments are great, but have limitations:

```javascript
const deploymentLimitations = {
  nodeSpecific: "Can't guarantee one pod per node",
  identity: "Pods have random names (web-abc-xyz)",
  storage: "Each pod can't have unique storage easily",
  ordering: "Pods start/stop randomly",
  networking: "No stable network identity",

  // Example problems:
  logging: "Need log collector on EVERY node",
  monitoring: "Need metrics agent on EVERY node",
  databases: "Need stable names and persistent storage",
  zookeeper: "Need ordered startup (server-0, server-1, server-2)",
};
```

**Solution: Specialized Controllers**

| Controller      | Use Case            | Key Feature                      |
| --------------- | ------------------- | -------------------------------- |
| **Deployment**  | Stateless apps      | Random pod names, any node       |
| **DaemonSet**   | Node-level services | One pod per node                 |
| **StatefulSet** | Stateful apps       | Stable identity, ordered startup |

---

## Part 2: DaemonSets - One Pod Per Node (30 minutes)

### What is a DaemonSet?

A DaemonSet ensures a copy of a Pod runs on **all (or selected) nodes** in the cluster.

```
┌─────────────────────────────────────────────┐
│         Kubernetes Cluster                  │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │   Node 1     │  │   Node 2     │       │
│  │              │  │              │       │
│  │  [Pod A]     │  │  [Pod B]     │       │
│  │  Your App    │  │  Your App    │       │
│  │  [Logger]◄───┼──┼─►[Logger]    │       │
│  └──────────────┘  └──────────────┘       │
│                                             │
│  ┌──────────────┐  ┌──────────────┐       │
│  │   Node 3     │  │   Node 4     │       │
│  │  [Pod C]     │  │  [Pod D]     │       │
│  │  Your App    │  │  Your App    │       │
│  │  [Logger]◄───┼──┼─►[Logger]    │       │
│  └──────────────┘  └──────────────┘       │
│                                             │
│  DaemonSet: log-collector                  │
│  Runs on ALL nodes automatically!          │
└─────────────────────────────────────────────┘
```

**Common Use Cases:**

- Logging agents (Fluentd, Filebeat) - collect logs from all nodes
- Monitoring agents (Prometheus Node Exporter) - metrics from all nodes
- Network plugins (Calico, Weave) - networking on all nodes
- Storage daemons (Gluster, Ceph) - distributed storage
- Security agents (Falco) - security monitoring

### Creating Your First DaemonSet

Create `simple-daemonset.yaml`:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-logger
  labels:
    app: logger
spec:
  selector:
    matchLabels:
      app: node-logger
  template:
    metadata:
      labels:
        app: node-logger
    spec:
      containers:
        - name: logger
          image: busybox
          command:
            - sh
            - -c
            - |
              echo "Logger started on node: $(hostname)"
              while true; do
                echo "$(date) - Logging from node: $NODE_NAME"
                echo "  Hostname: $(hostname)"
                echo "  Node IP: $NODE_IP"
                sleep 30
              done
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: NODE_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
```

```bash
# Apply DaemonSet
kubectl apply -f simple-daemonset.yaml

# View DaemonSet
kubectl get daemonsets
kubectl get ds  # shorthand

# View pods created by DaemonSet
kubectl get pods -l app=node-logger -o wide

# Notice: One pod per node!

# Describe DaemonSet
kubectl describe ds node-logger

# View logs from one pod
kubectl logs -l app=node-logger --tail=10
```

### DaemonSet Behavior

Test automatic scheduling:

```bash
# Check current pods
kubectl get pods -l app=node-logger -o wide

# If you had multi-node cluster and added a new node:
# minikube node add  # (in multi-node minikube)
# DaemonSet automatically creates pod on new node!

# Delete a DaemonSet pod
POD_NAME=$(kubectl get pods -l app=node-logger -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Watch it recreate immediately
kubectl get pods -l app=node-logger -w
```

### Real-World Example: Log Collector

Create `log-collector-daemonset.yaml`:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  namespace: kube-system
  labels:
    app: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      # Run on all nodes including master
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          effect: NoSchedule
        - key: node-role.kubernetes.io/master
          effect: NoSchedule

      containers:
        - name: log-collector
          image: busybox
          command:
            - sh
            - -c
            - |
              echo "Log collector started on $NODE_NAME"
              while true; do
                # Collect logs from host
                if [ -d /var/log/pods ]; then
                  echo "=== Logs from node $NODE_NAME ==="
                  ls -lh /var/log/pods/ | head -10
                fi
                sleep 60
              done
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName

          # Mount host directories
          volumeMounts:
            - name: varlog
              mountPath: /var/log
              readOnly: true
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true

          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 128Mi

      volumes:
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
```

```bash
# Apply log collector
kubectl apply -f log-collector-daemonset.yaml

# View in kube-system namespace
kubectl get ds -n kube-system

# Check logs
kubectl logs -n kube-system -l app=log-collector --tail=20
```

### DaemonSet with Node Selectors

Run DaemonSet only on specific nodes:

Create `selective-daemonset.yaml`:

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
      # Only run on nodes with GPU
      nodeSelector:
        gpu: "true" # Only nodes with label gpu=true

      containers:
        - name: monitor
          image: busybox
          command:
            - sh
            - -c
            - echo "GPU monitoring on $(hostname)" && sleep 3600
```

```bash
# Label a node
kubectl label nodes minikube gpu=true

# Apply selective DaemonSet
kubectl apply -f selective-daemonset.yaml

# Pod only runs on labeled nodes
kubectl get pods -l app=gpu-monitor -o wide

# Remove label - pod gets deleted
kubectl label nodes minikube gpu-

# Pod disappears!
kubectl get pods -l app=gpu-monitor
```

### Updating DaemonSets

```bash
# Check update strategy
kubectl get ds node-logger -o jsonpath='{.spec.updateStrategy}'

# Default: RollingUpdate (like Deployments)

# Update image
kubectl set image daemonset/node-logger logger=busybox:1.36

# Watch rolling update
kubectl rollout status daemonset/node-logger

# View rollout history
kubectl rollout history daemonset/node-logger

# Rollback if needed
kubectl rollout undo daemonset/node-logger
```

---

## Part 3: StatefulSets - Stable Identity (40 minutes)

### What is a StatefulSet?

StatefulSet manages **stateful applications** that need:

- **Stable, unique network identifiers**
- **Stable, persistent storage**
- **Ordered, graceful deployment and scaling**
- **Ordered, automated rolling updates**

```
Deployment Pods:
web-abc-123  (random name, can be on any node)
web-xyz-789  (random name, can be on any node)

StatefulSet Pods:
web-0  (stable name, persistent storage)
web-1  (stable name, persistent storage)
web-2  (stable name, persistent storage)
```

**Use Cases:**

- Databases (MySQL, PostgreSQL, MongoDB)
- Distributed systems (Kafka, Zookeeper, etcd)
- Clustered applications (Elasticsearch, Cassandra)
- Anything requiring persistent identity

### StatefulSet Key Features

```javascript
const statefulSetFeatures = {
  naming: "Pods: name-0, name-1, name-2 (stable)",
  ordering: "Create: 0→1→2, Delete: 2→1→0",
  storage: "Each pod gets own PVC automatically",
  network: "Stable DNS: pod-name.service-name.namespace",
  updates: "Rolling update respects ordering",

  // Example:
  database: {
    pods: ["db-0", "db-1", "db-2"],
    dns: ["db-0.mysql.default.svc.cluster.local"],
    storage: ["pvc-0", "pvc-1", "pvc-2"],
  },
};
```

### Creating a Simple StatefulSet

Create `simple-statefulset.yaml`:

```yaml
# Headless Service (required for StatefulSet)
apiVersion: v1
kind: Service
metadata:
  name: web
  labels:
    app: nginx
spec:
  ports:
    - port: 80
      name: web
  clusterIP: None # Headless service
  selector:
    app: nginx

---
# StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "web" # Must match service name above
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
              name: web
          command:
            - sh
            - -c
            - |
              echo "I am $(hostname)" > /usr/share/nginx/html/index.html
              nginx -g 'daemon off;'
```

```bash
# Apply StatefulSet
kubectl apply -f simple-statefulset.yaml

# Watch pods being created in order
kubectl get pods -w

# Notice:
# 1. Pods created one at a time: web-0 → web-1 → web-2
# 2. Each waits for previous to be Running before starting

# View StatefulSet
kubectl get statefulsets
kubectl get sts  # shorthand

# View pods
kubectl get pods -l app=nginx

# Notice stable names: web-0, web-1, web-2
```

### StatefulSet DNS and Networking

Each pod gets a stable DNS entry:

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=alpine --restart=Never -- sh

# Inside debug pod:
apk add --no-cache bind-tools

# Resolve StatefulSet pods
nslookup web-0.web.default.svc.cluster.local
nslookup web-1.web.default.svc.cluster.local
nslookup web-2.web.default.svc.cluster.local

# Each pod has unique DNS entry!

# Test connectivity
wget -qO- http://web-0.web.default.svc.cluster.local
wget -qO- http://web-1.web.default.svc.cluster.local
wget -qO- http://web-2.web.default.svc.cluster.local

exit
```

### Scaling StatefulSets

```bash
# Scale up (creates web-3, web-4)
kubectl scale statefulset web --replicas=5

# Watch ordered creation
kubectl get pods -w

# Scale down (deletes web-4, web-3)
kubectl scale statefulset web --replicas=3

# Watch ordered deletion (highest ordinal first)
kubectl get pods -w
```

### StatefulSet with Persistent Storage

Create `statefulset-with-storage.yaml`:

```yaml
# Headless Service
apiVersion: v1
kind: Service
metadata:
  name: nginx-sts
spec:
  clusterIP: None
  selector:
    app: nginx-sts
  ports:
    - port: 80

---
# StatefulSet with volumeClaimTemplates
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-sts
spec:
  serviceName: nginx-sts
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
            - name: www # Mount the PVC
              mountPath: /usr/share/nginx/html
          command:
            - sh
            - -c
            - |
              # Write unique data to each pod's storage
              echo "Data from $(hostname) - $(date)" >> /usr/share/nginx/html/data.txt
              echo "Pod: $(hostname)" > /usr/share/nginx/html/index.html
              while true; do
                echo "$(date) - $(hostname) is alive" >> /usr/share/nginx/html/data.txt
                sleep 30
              done &
              nginx -g 'daemon off;'

  # Volume Claim Template - creates one PVC per pod
  volumeClaimTemplates:
    - metadata:
        name: www
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 1Gi
```

```bash
# Apply StatefulSet with storage
kubectl apply -f statefulset-with-storage.yaml

# Watch pods and PVCs being created
kubectl get pods -w
kubectl get pvc

# Notice: Each pod gets its own PVC!
# www-nginx-sts-0
# www-nginx-sts-1
# www-nginx-sts-2

# View PVCs
kubectl get pvc
```

### Testing StatefulSet Persistence

```bash
# Write data to each pod
for i in 0 1 2; do
  kubectl exec nginx-sts-$i -- sh -c "echo 'Custom data for pod $i' >> /usr/share/nginx/html/custom.txt"
done

# Read data
for i in 0 1 2; do
  echo "=== Pod nginx-sts-$i ==="
  kubectl exec nginx-sts-$i -- cat /usr/share/nginx/html/custom.txt
done

# Delete a pod
kubectl delete pod nginx-sts-1

# Wait for it to recreate
kubectl wait --for=condition=ready pod/nginx-sts-1

# Check data - it persists!
kubectl exec nginx-sts-1 -- cat /usr/share/nginx/html/custom.txt
```

### Real-World Example: MySQL Cluster

Create `mysql-statefulset.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
    - port: 3306

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  my.cnf: |
    [mysqld]
    default-storage-engine=InnoDB
    max_connections=100

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 1 # Start with single instance
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:8.0
          ports:
            - containerPort: 3306
              name: mysql
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: "rootpassword"
            - name: MYSQL_DATABASE
              value: "myapp"
            - name: MYSQL_USER
              value: "appuser"
            - name: MYSQL_PASSWORD
              value: "apppassword"
          volumeMounts:
            - name: data
              mountPath: /var/lib/mysql
            - name: config
              mountPath: /etc/mysql/conf.d
          resources:
            requests:
              cpu: 250m
              memory: 512Mi
            limits:
              cpu: 500m
              memory: 1Gi
          livenessProbe:
            exec:
              command:
                - mysqladmin
                - ping
                - -h
                - localhost
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            exec:
              command:
                - mysql
                - -h
                - localhost
                - -u
                - root
                - -prootpassword
                - -e
                - "SELECT 1"
            initialDelaySeconds: 10
            periodSeconds: 5
      volumes:
        - name: config
          configMap:
            name: mysql-config

  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 5Gi
```

```bash
# Apply MySQL StatefulSet
kubectl apply -f mysql-statefulset.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod/mysql-0 --timeout=120s

# Connect to MySQL
kubectl exec -it mysql-0 -- mysql -u root -prootpassword

# Inside MySQL:
SHOW DATABASES;
USE myapp;
CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(50));
INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
SELECT * FROM users;
exit

# Delete pod to test persistence
kubectl delete pod mysql-0

# Wait for recreation
kubectl wait --for=condition=ready pod/mysql-0 --timeout=120s

# Connect again - data persists!
kubectl exec -it mysql-0 -- mysql -u root -prootpassword -e "SELECT * FROM myapp.users"
```

### StatefulSet Update Strategies

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0 # Update all pods (default)
      # partition: 2      # Only update pods >= ordinal 2 (canary)
```

Test partition updates:

```bash
# Create StatefulSet
kubectl apply -f simple-statefulset.yaml

# Update with partition=2 (only web-2 gets updated)
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'

# Update image
kubectl set image statefulset/web nginx=nginx:1.21

# Only web-2 updates! web-0 and web-1 stay on old version
kubectl get pods -l app=nginx

# Remove partition to update all
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

---

## Part 4: DaemonSet vs StatefulSet vs Deployment (10 minutes)

### Quick Comparison

| Feature      | Deployment        | DaemonSet            | StatefulSet              |
| ------------ | ----------------- | -------------------- | ------------------------ |
| Pod Names    | Random            | Random               | Ordered (name-0, name-1) |
| Replicas     | Specified number  | One per node         | Specified number         |
| Scaling      | Any direction     | Automatic with nodes | Ordered                  |
| Pod Identity | No                | No                   | Yes (stable)             |
| Storage      | Shared or none    | Usually hostPath     | Unique per pod (PVC)     |
| Network ID   | No                | No                   | Yes (stable DNS)         |
| Use Case     | Stateless apps    | Node agents          | Stateful apps            |
| Examples     | Web servers, APIs | Logging, monitoring  | Databases, queues        |

### Decision Tree

```javascript
function chooseController(app) {
  if (app.needsToRunOnEveryNode) {
    return "DaemonSet"; // Log collectors, monitoring agents
  }

  if (app.needsStableIdentity || app.needsPersistentStorage) {
    return "StatefulSet"; // Databases, clustered apps
  }

  return "Deployment"; // Everything else (stateless apps)
}
```

---

## 📝 Day 10 Homework (40-50 minutes)

### Exercise 1: Build a Monitoring Stack

Create DaemonSets for node monitoring:

```yaml
# node-exporter-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
        - name: node-exporter
          image: prom/node-exporter:latest
          args:
            - --path.procfs=/host/proc
            - --path.sysfs=/host/sys
          ports:
            - containerPort: 9100
              hostPort: 9100
          volumeMounts:
            - name: proc
              mountPath: /host/proc
              readOnly: true
            - name: sys
              mountPath: /host/sys
              readOnly: true
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: sys
          hostPath:
            path: /sys
```

### Exercise 2: Deploy PostgreSQL Cluster

Create a 3-replica PostgreSQL StatefulSet:

```yaml
# postgres-cluster.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
    - port: 5432

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
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
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_PASSWORD
              value: password123
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 2Gi
```

Test:

```bash
# Connect to each instance
for i in 0 1 2; do
  echo "=== postgres-$i ==="
  kubectl exec -it postgres-$i -- psql -U postgres -c "SELECT current_database();"
done

# Create data in postgres-0
kubectl exec -it postgres-0 -- psql -U postgres -c "CREATE DATABASE testdb;"

# Verify persistence after pod restart
kubectl delete pod postgres-0
kubectl wait --for=condition=ready pod/postgres-0
kubectl exec -it postgres-0 -- psql -U postgres -c "\l"
```

### Exercise 3: Log Aggregation System

Deploy Fluentd as DaemonSet:

```yaml
# fluentd-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      serviceAccountName: fluentd
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          effect: NoSchedule
      containers:
        - name: fluentd
          image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
          env:
            - name: FLUENT_ELASTICSEARCH_HOST
              value: "elasticsearch.logging.svc.cluster.local"
            - name: FLUENT_ELASTICSEARCH_PORT
              value: "9200"
          volumeMounts:
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
```

### Exercise 4: Elasticsearch Cluster

Deploy Elasticsearch as StatefulSet:

```yaml
# elasticsearch-statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
spec:
  clusterIP: None
  selector:
    app: elasticsearch
  ports:
    - port: 9200
      name: http
    - port: 9300
      name: transport

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
    metadata:
      labels:
        app: elasticsearch
    spec:
      initContainers:
        - name: increase-vm-max-map
          image: busybox
          command: ["sysctl", "-w", "vm.max_map_count=262144"]
          securityContext:
            privileged: true

      containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0
          env:
            - name: cluster.name
              value: k8s-logs
            - name: node.name
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: discovery.seed_hosts
              value: "elasticsearch-0.elasticsearch,elasticsearch-1.elasticsearch,elasticsearch-2.elasticsearch"
            - name: cluster.initial_master_nodes
              value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
            - name: ES_JAVA_OPTS
              value: "-Xms512m -Xmx512m"
            - name: xpack.security.enabled
              value: "false"
          ports:
            - containerPort: 9200
              name: http
            - containerPort: 9300
              name: transport
          volumeMounts:
            - name: data
              mountPath: /usr/share/elasticsearch/data
          resources:
            requests:
              memory: 1Gi
              cpu: 500m
            limits:
              memory: 2Gi
              cpu: 1000m

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

### Exercise 5: Redis Cluster

Deploy Redis with StatefulSet:

```yaml
# redis-statefulset.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
data:
  redis.conf: |
    appendonly yes
    protected-mode no
    bind 0.0.0.0
    port 6379

---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  clusterIP: None
  selector:
    app: redis
  ports:
    - port: 6379

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: redis
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:alpine
          command:
            - redis-server
            - /config/redis.conf
          ports:
            - containerPort: 6379
          volumeMounts:
            - name: data
              mountPath: /data
            - name: config
              mountPath: /config
      volumes:
        - name: config
          configMap:
            name: redis-config

  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 1Gi
```

Test Redis:

```bash
# Set data in redis-0
kubectl exec -it redis-0 -- redis-cli SET key1 "value from redis-0"

# Read from redis-1 (each has own storage)
kubectl exec -it redis-1 -- redis-cli SET key2 "value from redis-1"

# Verify persistence
kubectl delete pod redis-0
kubectl wait --for=condition=ready pod/redis-0
kubectl exec -it redis-0 -- redis-cli GET key1
```

---

## ✅ Day 10 Checklist

Before moving to Day 11, ensure you can:

- [ ] Explain when to use DaemonSet vs StatefulSet vs Deployment
- [ ] Create DaemonSets
- [ ] Understand DaemonSet scheduling (one per node)
- [ ] Use node selectors with DaemonSets
- [ ] Mount host paths in DaemonSets
- [ ] Create StatefulSets with headless services
- [ ] Understand StatefulSet pod naming (stable identity)
- [ ] Use volumeClaimTemplates in StatefulSets
- [ ] Test StatefulSet data persistence
- [ ] Access StatefulSet pods via stable DNS
- [ ] Scale StatefulSets (ordered scaling)
- [ ] Update DaemonSets and StatefulSets
- [ ] Deploy real-world stateful applications

---

## 🎯 Key Takeaways

```javascript
const workloadControllers = {
  deployment: {
    when: "Stateless applications",
    examples: ["Web servers", "REST APIs", "Microservices"],
    features: ["Random pod names", "No persistent storage", "Fast scaling"],
    scaling: "Instant, any direction",
  },
  daemonSet: {
    when: "Need one pod per node",
    examples: ["Log collectors", "Monitoring agents", "Network plugins"],
    features: ["Automatic node coverage", "Survives node addition"],
    scaling: "Automatic with cluster size",
  },
  statefulSet: {
    when: "Stateful applications with persistent identity",
    examples: ["Databases", "Message queues", "Distributed systems"],
    features: ["Stable names", "Ordered operations", "Persistent storage"],
    scaling: "Ordered: 0→1→2 (up), 2→1→0 (down)",
  },
  bestPractices: {
    daemonSet: [
      "Use for node-level services only",
      "Mount host paths carefully (security)",
      "Set resource limits (affects all nodes)",
      "Use tolerations for master nodes",
    ],
    statefulSet: [
      "Always use headless service",
      "Use volumeClaimTemplates for storage",
      "Plan for ordered operations",
      "Implement proper readiness probes",
      "Test disaster recovery",
    ],
  },
};
```

---

## 🔜 What's Next?

**Day 11 Preview:** Tomorrow we'll learn about **Jobs & CronJobs** - controllers for batch processing and scheduled tasks:

**Jobs:**

- Run one-time tasks to completion
- Parallel job execution
- Job completion tracking
- Retry on failure

**CronJobs:**

- Scheduled periodic tasks (like cron)
- Database backups
- Report generation
- Cleanup tasks

**Sneak peek:**

```yaml
# Job - runs once to completion
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processor
spec:
  template:
    spec:
      containers:
        - name: processor
          image: myapp
          command: ["python", "process_data.py"]
      restartPolicy: Never

---
# CronJob - runs on schedule
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
spec:
  schedule: "0 2 * * *" # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: backup-tool
              command: ["./backup.sh"]
          restartPolicy: OnFailure
```

---

## 📚 Additional Resources

### DaemonSets

- [Official DaemonSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- Common DaemonSet use cases
- Node affinity and taints/tolerations

### StatefulSets

- [Official StatefulSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [StatefulSet Basics Tutorial](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/)
- Running replicated stateful applications

### Real-World Examples

- [Running Cassandra with StatefulSets](https://kubernetes.io/docs/tutorials/stateful-application/cassandra/)
- [Running ZooKeeper](https://kubernetes.io/docs/tutorials/stateful-application/zookeeper/)
- Fluentd DaemonSet configurations

---

## 🎓 Reflection Questions

1. **When would you choose StatefulSet over Deployment?**

   - Think: databases, session stores, distributed systems

2. **What are the risks of running DaemonSets?**

   - Consider: resource usage on all nodes, security implications

3. **How would you migrate from Deployment to StatefulSet?**

   - Plan: data migration, downtime considerations

4. **What happens if a StatefulSet pod fails?**

   - Kubernetes recreates it with same identity and storage

5. **How do you backup StatefulSet data?**
   - Think: PVC snapshots, job-based backups, external tools

---

## 💡 Pro Tips

### DaemonSet Tips

```yaml
# Tip 1: Always set resource limits (affects ALL nodes)
resources:
  limits:
    cpu: 100m # Per node!
    memory: 128Mi

# Tip 2: Use tolerations to run on master nodes
tolerations:
  - key: node-role.kubernetes.io/control-plane
    effect: NoSchedule

# Tip 3: Use nodeSelector for targeted deployment
nodeSelector:
  disktype: ssd
```

### StatefulSet Tips

```yaml
# Tip 1: Always use readiness probes (critical for ordered startup)
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

# Tip 2: Use podManagementPolicy for parallel startup (if order doesn't matter)
spec:
  podManagementPolicy: Parallel # Default: OrderedReady

# Tip 3: Implement proper PVC retention
persistentVolumeClaimRetentionPolicy:
  whenDeleted: Retain # Keep PVCs when StatefulSet deleted
  whenScaled: Delete # Delete PVCs when scaled down
```

### Common Pitfalls to Avoid

```javascript
const pitfalls = {
  daemonSet: [
    "❌ Not setting resource limits (can exhaust nodes)",
    "❌ Mounting sensitive host paths",
    "❌ Forgetting about new nodes",
    "✅ Always test on single node first",
  ],

  statefulSet: [
    "❌ Forgetting headless service",
    "❌ Not testing pod recreation",
    "❌ No backup strategy",
    "❌ Scaling too fast",
    "✅ Always test failure scenarios",
    "✅ Implement proper monitoring",
  ],
};
```

---

## 🧪 Testing Scenarios

### Test DaemonSet Behavior

```bash
# Scenario 1: Node addition
minikube node add  # If multi-node
kubectl get pods -l app=node-logger -o wide
# Verify pod appears on new node

# Scenario 2: Node labels
kubectl label nodes <node-name> monitoring=false
# Pods with nodeSelector=monitoring:true won't run there

# Scenario 3: Resource exhaustion
# Deploy DaemonSet with high resource requests
# Observe scheduling failures
```

### Test StatefulSet Behavior

```bash
# Scenario 1: Ordered creation
kubectl apply -f statefulset.yaml
kubectl get pods -w
# Observe: pod-0 → pod-1 → pod-2

# Scenario 2: Pod deletion
kubectl delete pod web-1
# New pod gets same name and storage

# Scenario 3: Data persistence
kubectl exec web-0 -- sh -c "echo test > /data/file.txt"
kubectl delete pod web-0
kubectl exec web-0 -- cat /data/file.txt
# Data persists!

# Scenario 4: Scaling down
kubectl scale sts web --replicas=1
# Deletes web-2, then web-1 (reverse order)
kubectl get pvc
# PVCs remain! (unless retentionPolicy=Delete)
```

---

## 📊 Performance Considerations

### DaemonSet Performance

```javascript
const daemonSetPerformance = {
  resources: {
    perNode: "Multiply by node count for total usage",
    example: "50m CPU × 100 nodes = 5000m (5 cores)",
    recommendation: "Keep DaemonSet pods lightweight",
  },

  scheduling: {
    immediate: "Pods scheduled as soon as node ready",
    impact: "Can delay node readiness",
    solution: "Use init containers for heavy setup",
  },

  updates: {
    rollingUpdate: "Updates all nodes (can be risky)",
    onDelete: "Manual control per node",
    recommendation: "Test updates on non-prod first",
  },
};
```

### StatefulSet Performance

```javascript
const statefulSetPerformance = {
  startup: {
    sequential: "Each pod waits for previous",
    slow: "Can take time with many replicas",
    solution: "Use podManagementPolicy: Parallel if possible",
  },

  storage: {
    pvcs: "Each pod gets own PVC",
    io: "Storage performance critical",
    recommendation: "Use SSD for databases",
  },

  scaling: {
    ordered: "Slower than Deployment",
    safetyFirst: "Prevents corruption",
    planning: "Scale gradually in production",
  },
};
```

---

## 🔍 Debugging Guide

### DaemonSet Issues

**Problem: DaemonSet pods not running on some nodes**

```bash
# Check node labels
kubectl get nodes --show-labels

# Check node taints
kubectl describe nodes | grep Taints

# Check DaemonSet selectors
kubectl describe ds <daemonset-name>

# Solution: Add tolerations or adjust nodeSelector
```

**Problem: DaemonSet update stuck**

```bash
# Check rollout status
kubectl rollout status ds <daemonset-name>

# Check pod events
kubectl get events --sort-by='.lastTimestamp'

# Check pod status on each node
kubectl get pods -o wide -l app=<label>

# Force update
kubectl rollout restart daemonset <daemonset-name>
```

### StatefulSet Issues

**Problem: StatefulSet pods stuck in Pending**

```bash
# Check PVC status
kubectl get pvc

# Check PV availability
kubectl get pv

# Check storage class
kubectl get sc

# Check events
kubectl describe statefulset <name>

# Solution: Ensure StorageClass exists and can provision
```

**Problem: StatefulSet pod won't start (waiting for previous)**

```bash
# Check previous pod status
kubectl get pods -l app=<label>

# Check if previous pod is Ready
kubectl describe pod <pod-name>

# Check readiness probe
kubectl logs <pod-name>

# Solution: Fix previous pod first (ordered startup)
```

**Problem: Data not persisting**

```bash
# Verify PVC is bound
kubectl get pvc

# Check volumeMounts
kubectl describe pod <pod-name>

# Test write permissions
kubectl exec <pod-name> -- ls -la /data

# Verify PV path (if hostPath)
minikube ssh
ls -la /path/to/data
```

---

## 🎯 Real-World Patterns

### Pattern 1: Database Primary-Replica

```yaml
# StatefulSet for PostgreSQL with replicas
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
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
          image: postgres:15
          env:
            - name: POSTGRES_REPLICATION_MODE
              value: "slave"
          # postgres-0 is primary
          # postgres-1, postgres-2 are replicas
```

### Pattern 2: Log Aggregation Pipeline

```yaml
# DaemonSet → Aggregator → Storage
# 1. DaemonSet collects logs on each node
# 2. Sends to central aggregator (Deployment)
# 3. Stores in StatefulSet (Elasticsearch)

# See Exercise 3 for complete implementation
```

### Pattern 3: Distributed Cache

```yaml
# StatefulSet for Redis cluster
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  replicas: 6 # 3 masters + 3 replicas
  # Each pod joins cluster on startup
  # Uses stable DNS for cluster discovery
```

---

## 📈 Monitoring & Observability

### DaemonSet Metrics to Watch

```bash
# Pod count should equal node count
kubectl get ds <name> -o jsonpath='{.status.numberReady}/{.status.desiredNumberScheduled}'

# Check if all nodes covered
kubectl get pods -l app=<label> -o wide

# Resource usage per node
kubectl top pods -l app=<label>
```

### StatefulSet Metrics to Watch

```bash
# Pod readiness
kubectl get sts <name> -o jsonpath='{.status.readyReplicas}/{.status.replicas}'

# PVC status
kubectl get pvc -l app=<label>

# Startup time (for performance tuning)
kubectl get events --sort-by='.lastTimestamp' | grep <pod-name>

# Data persistence verification
# (Application-specific queries)
```

---

## 🚀 Advanced Topics (Optional)

### StatefulSet with Init Containers

```yaml
# Wait for dependencies before starting
spec:
  template:
    spec:
      initContainers:
        - name: wait-for-master
          image: busybox
          command:
            - sh
            - -c
            - |
              # Wait for postgres-0 (master) to be ready
              until nslookup postgres-0.postgres; do
                echo "Waiting for master..."
                sleep 2
              done
```

### DaemonSet with Privileged Mode

```yaml
# For system-level operations (use carefully!)
spec:
  template:
    spec:
      containers:
        - name: privileged-agent
          image: agent
          securityContext:
            privileged: true
          volumeMounts:
            - name: dev
              mountPath: /dev
      volumes:
        - name: dev
          hostPath:
            path: /dev
```
