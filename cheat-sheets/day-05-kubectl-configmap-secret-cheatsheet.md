# Day 5: ConfigMaps & Secrets Cheat Sheet

## Quick Reference

### ConfigMaps vs Secrets

| Feature | ConfigMap | Secret |
|---------|-----------|--------|
| **Purpose** | Non-sensitive config | Sensitive data |
| **Encoding** | Plain text | Base64 encoded |
| **Size Limit** | 1MB | 1MB |
| **Use Cases** | Ports, log levels, feature flags | Passwords, API keys, tokens |
| **Security** | Less restricted | More restricted RBAC |

---

## ConfigMaps

### Create ConfigMaps

```bash
# Method 1: From literals
kubectl create configmap app-config \
  --from-literal=PORT=8080 \
  --from-literal=LOG_LEVEL=info

# Method 2: From file
kubectl create configmap app-config \
  --from-file=app.properties

# Method 3: From directory
kubectl create configmap app-config \
  --from-file=configs/

# Method 4: From YAML
kubectl apply -f configmap.yaml
```

### View ConfigMaps

```bash
# List all
kubectl get configmap

# Describe
kubectl describe configmap app-config

# View YAML
kubectl get configmap app-config -o yaml

# View specific key
kubectl get configmap app-config -o jsonpath='{.data.PORT}'
```

### Use ConfigMap in Pods

#### As Environment Variables (Individual)

```yaml
env:
- name: PORT
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: PORT
```

#### As Environment Variables (All Keys)

```yaml
envFrom:
- configMapRef:
    name: app-config
```

#### As Volume (Files)

```yaml
volumeMounts:
- name: config-volume
  mountPath: /etc/config
  readOnly: true
volumes:
- name: config-volume
  configMap:
    name: app-config
```

#### As Volume (Selective Keys)

```yaml
volumes:
- name: config-volume
  configMap:
    name: app-config
    items:
    - key: app.properties
      path: application.properties
```

### Update ConfigMap

```bash
# Edit directly
kubectl edit configmap app-config

# Update from YAML
kubectl apply -f configmap.yaml

# Restart pods to pick up changes (for env vars)
kubectl rollout restart deployment/myapp
```

**Important:** 
- Env vars: **NOT updated** - Pod restart required
- Volumes: **Auto-updated** after ~60 seconds

---

## Secrets

### Create Secrets

```bash
# Method 1: From literals
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password=secret123

# Method 2: From files
kubectl create secret generic db-creds \
  --from-file=username=username.txt \
  --from-file=password=password.txt

# Method 3: TLS secret
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key

# Method 4: Docker registry
kubectl create secret docker-registry reg-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=email@example.com

# Method 5: From YAML
kubectl apply -f secret.yaml
```

### View Secrets

```bash
# List all
kubectl get secret

# Describe (doesn't show values)
kubectl describe secret db-creds

# View YAML (base64 encoded)
kubectl get secret db-creds -o yaml

# Decode a value
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 --decode
```

### Use Secret in Pods

#### As Environment Variables (Individual)

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secrets
      key: database-password
```

#### As Environment Variables (All Keys)

```yaml
envFrom:
- secretRef:
    name: app-secrets
```

#### As Volume (More Secure)

```yaml
volumeMounts:
- name: secret-volume
  mountPath: /etc/secrets
  readOnly: true
volumes:
- name: secret-volume
  secret:
    secretName: app-secrets
    defaultMode: 0400
```

### Update Secret

```bash
# Edit (base64 encoded)
kubectl edit secret app-secrets

# Delete and recreate
kubectl delete secret app-secrets
kubectl create secret generic app-secrets \
  --from-literal=password=NewPassword

# Restart pods
kubectl rollout restart deployment/myapp
```

---

## Base64 Encoding

```bash
# Encode
echo -n 'my-secret' | base64

# Decode
echo 'bXktc2VjcmV0' | base64 --decode

# Decode from secret
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 --decode
```

---

## Secret YAML with stringData

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:  # Plain text (auto-encoded)
  password: "SuperSecret123!"
  api-key: "abcdef1234567890"
data:  # Base64 encoded
  existing-key: U3VwZXJTZWNyZXQxMjMh
```

---

## Immutable ConfigMaps/Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
immutable: true  # Cannot be updated!
data:
  VERSION: "1.0.0"
```

**Note:** Must delete and recreate to change.

---

## Best Practices

✅ **DO:**
- Use ConfigMaps for non-sensitive config
- Use Secrets for sensitive data
- Prefer volumes over env vars for secrets
- Use `envFrom` for importing all keys
- Use descriptive names: `app-config-prod`
- Always trigger rollout restart after updates
- Keep ConfigMaps/Secrets small (<1MB)
- Use `stringData` in YAML for readability

❌ **DON'T:**
- Hardcode config in images
- Commit secrets to git
- Use env vars for large secrets
- Forget to restart pods after env var updates
- Store secrets in ConfigMaps

---

## Common Commands

```bash
# Create ConfigMap from literals
kubectl create configmap <name> --from-literal=<key>=<value>

# Create Secret from literals
kubectl create secret generic <name> --from-literal=<key>=<value>

# View ConfigMap data
kubectl get configmap <name> -o yaml

# View Secret data (encoded)
kubectl get secret <name> -o yaml

# Decode Secret value
kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 --decode

# Restart deployment
kubectl rollout restart deployment/<name>

# Watch rollout
kubectl rollout status deployment/<name>

# Edit ConfigMap
kubectl edit configmap <name>

# Edit Secret
kubectl edit secret <name>

# Delete ConfigMap
kubectl delete configmap <name>

# Delete Secret
kubectl delete secret <name>
```

---

## Quick Troubleshooting

```bash
# Check if ConfigMap exists
kubectl get configmap app-config

# Check if Secret exists
kubectl get secret app-secrets

# Verify env vars in pod
kubectl exec -it <pod-name> -- env | grep PORT

# Verify mounted files
kubectl exec -it <pod-name> -- ls -la /etc/config
kubectl exec -it <pod-name> -- cat /etc/config/app.properties

# Check pod events
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>
```

---

## Environment-Specific ConfigMaps

```bash
# Development
kubectl create configmap app-config-dev \
  --from-literal=NODE_ENV=development \
  --from-literal=LOG_LEVEL=debug

# Production
kubectl create configmap app-config-prod \
  --from-literal=NODE_ENV=production \
  --from-literal=LOG_LEVEL=error
```

Then reference in deployment:

```yaml
envFrom:
- configMapRef:
    name: app-config-prod  # Change based on environment
```

