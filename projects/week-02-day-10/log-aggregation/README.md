# Exercise 3: Log Aggregation System with Fluentd DaemonSet

## Objective
Deploy Fluentd as a DaemonSet to collect logs from all nodes and forward them to Elasticsearch.

## Prerequisites
- Kubernetes cluster
- Elasticsearch cluster running (see Exercise 4) or external Elasticsearch endpoint
- ServiceAccount with appropriate permissions (optional, for production)

## Files
- `fluentd-daemonset.yaml` - Fluentd DaemonSet manifest

## Steps

### 1. Deploy Fluentd DaemonSet
```bash
kubectl apply -f fluentd-daemonset.yaml
```

### 2. Verify Deployment
```bash
# Check DaemonSet
kubectl get ds -n kube-system -l app=fluentd

# Check pods (one per node)
kubectl get pods -n kube-system -l app=fluentd -o wide

# Verify pod count matches node count
kubectl get nodes --no-headers | wc -l
kubectl get pods -n kube-system -l app=fluentd --no-headers | wc -l
```

### 3. View Logs
```bash
# Check Fluentd logs
kubectl logs -n kube-system -l app=fluentd --tail=50

# Check specific pod
kubectl logs -n kube-system <fluentd-pod-name>
```

### 4. Verify Log Collection
```bash
# Check if Fluentd is reading logs
kubectl exec -n kube-system <fluentd-pod-name> -- ls -la /var/log/pods
```

## Configuration Notes

### Elasticsearch Connection
The DaemonSet is configured to send logs to:
- Host: `elasticsearch.logging.svc.cluster.local`
- Port: `9200`

If using a different Elasticsearch setup, update the environment variables:
```yaml
env:
- name: FLUENT_ELASTICSEARCH_HOST
  value: "your-elasticsearch-host"
- name: FLUENT_ELASTICSEARCH_PORT
  value: "9200"
```

### ServiceAccount (Optional)
For production, create a ServiceAccount with appropriate RBAC:
```bash
kubectl create serviceaccount fluentd -n kube-system
# Add RBAC rules as needed
```

## Expected Results
- One Fluentd pod per node
- Logs collected from `/var/log` and `/var/lib/docker/containers`
- Logs forwarded to Elasticsearch (if available)

## Troubleshooting

### Pods Not Starting
- Check node taints: `kubectl describe nodes | grep Taints`
- Verify tolerations in DaemonSet

### Logs Not Reaching Elasticsearch
- Verify Elasticsearch is accessible
- Check Fluentd logs for connection errors
- Verify network policies allow traffic

## Cleanup
```bash
kubectl delete -f fluentd-daemonset.yaml
```

