# Exercise 4: Elasticsearch Cluster with StatefulSet

## Objective
Deploy a 3-node Elasticsearch cluster using StatefulSet for log storage and search.

## Prerequisites
- Kubernetes cluster
- StorageClass available
- Sufficient resources (1Gi memory, 500m CPU per pod minimum)
- kubectl configured

## Files
- `elasticsearch-statefulset.yaml` - Elasticsearch StatefulSet and Service

## Important Notes

### Resource Requirements
- Each pod requests: 1Gi memory, 500m CPU
- Each pod limits: 2Gi memory, 1000m CPU
- Total: ~6Gi memory, 3 CPU cores for 3 replicas
- Ensure cluster has sufficient capacity

### VM Max Map Count
The init container sets `vm.max_map_count=262144` which is required for Elasticsearch. This requires privileged mode.

## Steps

### 1. Create Namespace (Optional)
```bash
kubectl create namespace logging
# Update namespace in YAML if using different namespace
```

### 2. Deploy Elasticsearch Cluster
```bash
kubectl apply -f elasticsearch-statefulset.yaml
```

### 3. Watch Ordered Pod Creation
```bash
kubectl get pods -w
# Observe: elasticsearch-0 → elasticsearch-1 → elasticsearch-2
# Each pod waits for previous to be Ready
```

### 4. Verify Deployment
```bash
# Check StatefulSet
kubectl get sts elasticsearch

# Check pods
kubectl get pods -l app=elasticsearch

# Check PVCs
kubectl get pvc
# Should see: data-elasticsearch-0, data-elasticsearch-1, data-elasticsearch-2

# Check service
kubectl get svc elasticsearch
```

### 5. Wait for Cluster to be Ready
```bash
# Wait for all pods to be ready
kubectl wait --for=condition=ready pod/elasticsearch-0 --timeout=300s
kubectl wait --for=condition=ready pod/elasticsearch-1 --timeout=300s
kubectl wait --for=condition=ready pod/elasticsearch-2 --timeout=300s
```

### 6. Test Elasticsearch API
```bash
# Port forward to a pod
kubectl port-forward elasticsearch-0 9200:9200

# In another terminal, test cluster health
curl http://localhost:9200/_cluster/health?pretty

# Check cluster info
curl http://localhost:9200/

# List nodes
curl http://localhost:9200/_cat/nodes?v
```

### 7. Test Cluster Discovery
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Inside pod:
apk add --no-cache bind-tools
nslookup elasticsearch-0.elasticsearch.default.svc.cluster.local
nslookup elasticsearch-1.elasticsearch.default.svc.cluster.local
exit
```

### 8. Create Test Index
```bash
# Port forward
kubectl port-forward elasticsearch-0 9200:9200

# Create index
curl -X PUT http://localhost:9200/test-index?pretty

# Index a document
curl -X POST http://localhost:9200/test-index/_doc \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello Elasticsearch", "timestamp": "2024-01-01"}'

# Search
curl http://localhost:9200/test-index/_search?pretty
```

## Expected Results
- 3 Elasticsearch pods with stable names
- Cluster formed and healthy
- Each pod has 10Gi persistent storage
- Stable DNS entries for cluster discovery
- Data persists across pod restarts

## Troubleshooting

### Pods Stuck in Init
- Check init container logs: `kubectl logs elasticsearch-0 -c increase-vm-max-map`
- Verify privileged mode is allowed

### Pods Not Joining Cluster
- Check discovery configuration in environment variables
- Verify DNS resolution: `kubectl exec elasticsearch-0 -- nslookup elasticsearch-1.elasticsearch`
- Check Elasticsearch logs: `kubectl logs elasticsearch-0`

### Out of Memory
- Reduce `ES_JAVA_OPTS` memory settings
- Reduce replica count
- Increase node resources

## Cleanup
```bash
kubectl delete -f elasticsearch-statefulset.yaml

# PVCs are retained by default
# To delete manually:
kubectl delete pvc -l app=elasticsearch
```

