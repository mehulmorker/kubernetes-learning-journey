# Exercise 5: Annotation Practice

This exercise demonstrates adding and managing annotations on Kubernetes resources.

## Adding Annotations

Add comprehensive annotations to a deployment:

```bash
kubectl annotate deployment myapp-v1 \
  description="Main application deployment" \
  owner="platform-team@company.com" \
  git-repo="https://github.com/company/myapp" \
  git-commit="$(git rev-parse HEAD)" \
  deployed-at="$(date -Iseconds)" \
  deployed-by="$(whoami)"
```

## Viewing Annotations

View all annotations on a deployment:

```bash
# View annotations in describe output
kubectl describe deployment myapp-v1 | grep -A 20 Annotations

# View annotations in JSON format
kubectl get deployment myapp-v1 -o jsonpath='{.metadata.annotations}' | jq

# View pod annotations
kubectl get pods -l app=myapp -o jsonpath='{.items[0].metadata.annotations}' | jq
```

## Common Annotation Use Cases

### Documentation
```bash
kubectl annotate deployment myapp \
  description="User authentication service" \
  owner="platform-team@company.com"
```

### Build Information
```bash
kubectl annotate deployment myapp \
  build-date="2024-11-19" \
  git-commit="a3f5d2e" \
  built-by="jenkins"
```

### Deployment Information
```bash
kubectl annotate deployment myapp \
  deployed-at="$(date -Iseconds)" \
  deployed-by="$(whoami)" \
  deployment-reason="Version update"
```

### Tool-Specific Annotations
```bash
# Prometheus scraping
kubectl annotate deployment myapp \
  prometheus.io/scrape="true" \
  prometheus.io/port="8080" \
  prometheus.io/path="/metrics"

# Ingress annotations
kubectl annotate ingress myapp \
  nginx.ingress.kubernetes.io/rewrite-target="/" \
  cert-manager.io/cluster-issuer="letsencrypt-prod"
```

## Updating Annotations

Update existing annotations (requires `--overwrite`):

```bash
kubectl annotate deployment myapp-v1 \
  version="2.1.0" --overwrite
```

## Removing Annotations

Remove an annotation:

```bash
kubectl annotate deployment myapp-v1 version-
```

## Best Practices

1. **Use annotations for metadata** - Information that doesn't affect resource selection
2. **Document ownership** - Always include owner/team information
3. **Track deployments** - Include git commit, build date, deployer
4. **Tool integration** - Use standard annotation keys for tooling (Prometheus, cert-manager, etc.)
5. **Keep it organized** - Use consistent annotation keys across resources

## Annotation vs Labels

Remember:
- **Labels**: For identification and selection (queryable, used by Kubernetes)
- **Annotations**: For metadata and documentation (not queryable, for humans/tools)


