# Exercise 2: Database with Persistent Storage

## Objective
Deploy PostgreSQL with persistent data storage using PVC.

## Files
- `postgres-with-storage.yaml`: PVC, Deployment, and Service for PostgreSQL

## Instructions

1. Apply the manifest:
```bash
kubectl apply -f postgres-with-storage.yaml
```

2. Wait for the pod to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s
```

3. Connect to PostgreSQL and create data:
```bash
kubectl exec -it deployment/postgres -- psql -U postgres
```

Inside psql:
```sql
CREATE DATABASE testdb;
\c testdb
CREATE TABLE users (id SERIAL, name VARCHAR(50));
INSERT INTO users (name) VALUES ('Alice'), ('Bob');
SELECT * FROM users;
\q
```

4. Delete the pod to test persistence:
```bash
kubectl delete pod -l app=postgres
```

5. Wait for the new pod to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s
```

6. Verify data persists:
```bash
kubectl exec -it deployment/postgres -- psql -U postgres -d testdb -c "SELECT * FROM users;"
```

Expected output: You should see Alice and Bob - data persisted! 🎯

## Key Concepts
- **PVC for databases**: Always use persistent volumes for databases
- **ReadWriteOnce**: Only one pod can mount the volume (appropriate for single-replica database)
- **PGDATA**: PostgreSQL environment variable to specify data directory
- **Persistence**: Data survives pod restarts and deletions

## Cleanup
```bash
kubectl delete -f postgres-with-storage.yaml
```


