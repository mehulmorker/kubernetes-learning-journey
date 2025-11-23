# Exercise 5: Redis Cluster with StatefulSet

## Objective
Deploy a 3-replica Redis cluster using StatefulSet with persistent storage and AOF (Append-Only File) persistence.

## Prerequisites
- Kubernetes cluster
- StorageClass available
- kubectl configured

## Files
- `redis-statefulset.yaml` - Redis StatefulSet, Service, and ConfigMap
- `redis-test.sh` - Test script for persistence

## Steps

### 1. Deploy Redis Cluster
```bash
kubectl apply -f redis-statefulset.yaml
```

### 2. Watch Pod Creation
```bash
kubectl get pods -w
# Observe: redis-0 → redis-1 → redis-2
```

### 3. Verify Deployment
```bash
# Check StatefulSet
kubectl get sts redis

# Check pods
kubectl get pods -l app=redis

# Check PVCs
kubectl get pvc
# Should see: data-redis-0, data-redis-1, data-redis-2

# Check ConfigMap
kubectl get configmap redis-config
```

### 4. Test Redis Operations
```bash
# Set data in redis-0
kubectl exec -it redis-0 -- redis-cli SET key1 "value from redis-0"
kubectl exec -it redis-0 -- redis-cli SET key2 "value from redis-0"

# Set data in redis-1
kubectl exec -it redis-1 -- redis-cli SET key3 "value from redis-1"

# Get data
kubectl exec -it redis-0 -- redis-cli GET key1
kubectl exec -it redis-1 -- redis-cli GET key3
```

### 5. Test Persistence
```bash
# Write data to redis-0
kubectl exec -it redis-0 -- redis-cli SET persistent-key "This should persist"

# Verify it's written
kubectl exec -it redis-0 -- redis-cli GET persistent-key

# Delete pod
kubectl delete pod redis-0

# Wait for recreation
kubectl wait --for=condition=ready pod/redis-0 --timeout=120s

# Verify data persists
kubectl exec -it redis-0 -- redis-cli GET persistent-key
```

### 6. Check AOF File
```bash
# Verify AOF is enabled and working
kubectl exec -it redis-0 -- redis-cli CONFIG GET appendonly
kubectl exec -it redis-0 -- ls -la /data
```

### 7. Test Scaling
```bash
# Scale up
kubectl scale statefulset redis --replicas=5
kubectl get pods -w

# Scale down
kubectl scale statefulset redis --replicas=3
kubectl get pods -w
```

## Configuration Details

### Redis ConfigMap
The ConfigMap configures:
- `appendonly yes` - Enable AOF persistence
- `protected-mode no` - Allow connections (adjust for production)
- `bind 0.0.0.0` - Listen on all interfaces
- `port 6379` - Standard Redis port

### Storage
- Each pod gets 1Gi persistent storage
- AOF files stored in `/data` directory
- Data persists across pod restarts

## Expected Results
- 3 Redis pods with stable names (redis-0, redis-1, redis-2)
- Each pod has its own 1Gi PVC
- AOF persistence enabled
- Data persists across pod restarts
- Ordered scaling

## Production Considerations

### Security
- Enable `protected-mode` with password
- Use Redis AUTH
- Network policies to restrict access
- TLS encryption

### High Availability
- Configure Redis Sentinel for failover
- Use Redis Cluster mode for sharding
- Implement proper backup strategy

### Monitoring
- Monitor memory usage
- Track AOF file size
- Alert on pod failures

## Cleanup
```bash
kubectl delete -f redis-statefulset.yaml

# PVCs are retained by default
# To delete manually:
kubectl delete pvc -l app=redis
```

