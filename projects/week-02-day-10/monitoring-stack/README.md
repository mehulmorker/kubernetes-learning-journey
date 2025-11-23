# Exercise 1: Monitoring Stack with DaemonSet

## Objective
Deploy a Prometheus Node Exporter as a DaemonSet to collect metrics from all nodes in the cluster.

## Prerequisites
- Kubernetes cluster (minikube, kind, or cloud)
- kubectl configured
- `monitoring` namespace (will be created)

## Files
- `node-exporter-daemonset.yaml` - DaemonSet manifest

## Steps

### 1. Create Namespace
```bash
kubectl create namespace monitoring
```

### 2. Deploy Node Exporter DaemonSet
```bash
kubectl apply -f node-exporter-daemonset.yaml
```

### 3. Verify Deployment
```bash
# Check DaemonSet status
kubectl get ds -n monitoring

# Verify pods are running on all nodes
kubectl get pods -n monitoring -l app=node-exporter -o wide

# Check pod count matches node count
kubectl get nodes --no-headers | wc -l
kubectl get pods -n monitoring -l app=node-exporter --no-headers | wc -l
```

### 4. Test Metrics Endpoint
```bash
# Port forward to a pod
kubectl port-forward -n monitoring <pod-name> 9100:9100

# In another terminal, test metrics
curl http://localhost:9100/metrics
```

### 5. View Logs
```bash
kubectl logs -n monitoring -l app=node-exporter --tail=20
```

## Expected Results
- One pod per node running node-exporter
- Metrics available on port 9100
- Pods automatically created on new nodes

## Cleanup
```bash
kubectl delete -f node-exporter-daemonset.yaml
kubectl delete namespace monitoring
```

