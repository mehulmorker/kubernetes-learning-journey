# Exercise 3: Selective Operations with Labels

This exercise demonstrates performing selective operations on Kubernetes resources using label selectors.

## Commands

### Delete Only Development Pods
```bash
kubectl delete pods -l environment=development
```

### Scale Only Production Deployments
```bash
kubectl scale deployment -l environment=production --replicas=5
```

### Get Logs from All Backend Pods
```bash
kubectl logs -l tier=backend --tail=10
```

### Port-Forward to Specific Version
```bash
kubectl port-forward -l version=v2 8080:80
```

## Prerequisites

Before running these commands, ensure you have resources with appropriate labels:

- Pods with `environment=development` label
- Deployments with `environment=production` label
- Pods with `tier=backend` label
- Pods with `version=v2` label

## Use Cases

- **Bulk Operations**: Perform operations on multiple resources at once
- **Environment Management**: Manage resources by environment
- **Version Control**: Target specific application versions
- **Tier Management**: Operate on specific application tiers

## Safety Tips

- Always verify labels before running destructive operations
- Use `--dry-run=client` to preview changes
- Test on non-production environments first
- Use specific label selectors to avoid unintended matches


