# Exercise 2: PostgreSQL Cluster with StatefulSet

## Objective
Deploy a 3-replica PostgreSQL cluster using StatefulSet with persistent storage.

## Prerequisites
- Kubernetes cluster
- StorageClass available (e.g., `standard` in minikube)
- kubectl configured

## Files
- `postgres-cluster.yaml` - StatefulSet and Service manifests
- `postgres-test.sh` - Test script

## Steps

### 1. Deploy PostgreSQL Cluster
```bash
kubectl apply -f postgres-cluster.yaml
```

### 2. Watch Pods Being Created (Ordered)
```bash
kubectl get pods -w
# Observe: postgres-0 → postgres-1 → postgres-2
```

### 3. Verify StatefulSet and PVCs
```bash
# Check StatefulSet
kubectl get sts postgres

# Check PVCs (one per pod)
kubectl get pvc
# Should see: data-postgres-0, data-postgres-1, data-postgres-2

# Check pods
kubectl get pods -l app=postgres
```

### 4. Test Database Connectivity
```bash
# Connect to each instance
for i in 0 1 2; do
  echo "=== postgres-$i ==="
  kubectl exec -it postgres-$i -- psql -U postgres -c "SELECT current_database();"
done
```

### 5. Create Test Data
```bash
# Create database in postgres-0
kubectl exec -it postgres-0 -- psql -U postgres -c "CREATE DATABASE testdb;"

# Create table and insert data
kubectl exec -it postgres-0 -- psql -U postgres -d testdb -c "
  CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50));
  INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie');
  SELECT * FROM users;
"
```

### 6. Test Data Persistence
```bash
# Delete pod
kubectl delete pod postgres-0

# Wait for recreation
kubectl wait --for=condition=ready pod/postgres-0 --timeout=120s

# Verify data persists
kubectl exec -it postgres-0 -- psql -U postgres -d testdb -c "SELECT * FROM users;"
```

### 7. Test Scaling
```bash
# Scale up
kubectl scale statefulset postgres --replicas=5
kubectl get pods -w  # Watch ordered creation

# Scale down
kubectl scale statefulset postgres --replicas=3
kubectl get pods -w  # Watch ordered deletion (5→4→3)
```

## Expected Results
- 3 PostgreSQL pods with stable names (postgres-0, postgres-1, postgres-2)
- Each pod has its own PVC
- Data persists across pod restarts
- Ordered scaling (0→1→2 up, 2→1→0 down)

## Cleanup
```bash
kubectl delete -f postgres-cluster.yaml

# PVCs are retained by default (safety feature)
# To delete PVCs manually:
kubectl delete pvc -l app=postgres
```

