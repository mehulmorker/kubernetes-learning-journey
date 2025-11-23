# Day 05: ConfigMaps & Secrets - Interview Questions

## 1. What is the difference between ConfigMaps and Secrets in Kubernetes?

**Answer:**

| Feature | ConfigMaps | Secrets |
|---------|-----------|---------|
| **Purpose** | Non-sensitive configuration data | Sensitive data (passwords, tokens, keys) |
| **Encoding** | Plain text | Base64 encoded (not encrypted by default) |
| **Size limit** | No specific limit | 1MB per Secret |
| **Use cases** | App config, environment variables, config files | Passwords, API keys, TLS certificates |
| **Security** | Visible in YAML, logs | Base64 encoded (still readable, needs encryption at rest) |
| **RBAC** | Standard access control | More restricted access policies |

**When to use:**
- **ConfigMap**: Port numbers, log levels, feature flags, database hosts
- **Secret**: Passwords, API keys, TLS certificates, OAuth tokens

**Best Practice:** Never put sensitive data in ConfigMaps. Always use Secrets (and consider external secret managers for production).

---

## 2. Explain the different methods to create ConfigMaps.

**Answer:**

**Method 1: From literal values**
```bash
kubectl create configmap app-config \
  --from-literal=PORT=8080 \
  --from-literal=LOG_LEVEL=info \
  --from-literal=NODE_ENV=production
```

**Method 2: From file**
```bash
kubectl create configmap app-config \
  --from-file=app.properties
```

**Method 3: From directory**
```bash
kubectl create configmap app-config \
  --from-file=configs/
```

**Method 4: From YAML (Declarative)**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  PORT: "8080"
  LOG_LEVEL: "info"
  app.properties: |
    server.port=8080
    server.host=0.0.0.0
```

**Best Practice:** Use YAML (Method 4) for production as it's version-controlled and reproducible.

---

## 3. Multiple Choice: How are Secrets stored in Kubernetes by default?

A. Encrypted with AES-256  
B. Base64 encoded (not encrypted)  
C. Plain text  
D. Hashed with SHA-256

**Answer: B**

**Explanation:** Secrets are Base64 encoded by default, but NOT encrypted. They can be encrypted at rest if the cluster is configured with encryption at rest, but the default is just Base64 encoding. Anyone with access to the Secret can decode it.

---

## 4. What are the different ways to use ConfigMaps in Pods?

**Answer:**

**Method 1: Individual environment variables**
```yaml
env:
- name: PORT
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: PORT
```

**Method 2: All keys as environment variables (envFrom)**
```yaml
envFrom:
- configMapRef:
    name: app-config
```

**Method 3: Mount as volume (files)**
```yaml
volumeMounts:
- name: config-volume
  mountPath: /etc/config
volumes:
- name: config-volume
  configMap:
    name: app-config
```

**Method 4: Mount specific keys**
```yaml
volumes:
- name: config-volume
  configMap:
    name: app-config
    items:
    - key: app.properties
      path: application.properties
```

**When to use:**
- **env/envFrom**: Simple key-value pairs, environment variables
- **volume mount**: Configuration files, when app reads from files

---

## 5. Multiple Choice: What happens to environment variables in a Pod when you update a ConfigMap?

A. They are updated immediately  
B. They are updated after Pod restart  
C. They are never updated  
D. They are updated after 60 seconds

**Answer: C**

**Explanation:** Environment variables injected from ConfigMaps are NOT updated automatically. They are set only when the Pod starts. To pick up changes, you must restart the Pod (e.g., `kubectl rollout restart deployment/<name>`).

**Note:** Volume-mounted ConfigMaps ARE updated automatically (after ~60 seconds), but environment variables are not.

---

## 6. Explain how to create and use Secrets in Kubernetes.

**Answer:**

**Create Secret:**

**Method 1: From literals**
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=SuperSecret123!
```

**Method 2: From files**
```bash
echo -n 'admin' > username.txt
echo -n 'SuperSecret123!' > password.txt
kubectl create secret generic db-creds \
  --from-file=username=username.txt \
  --from-file=password=password.txt
```

**Method 3: From YAML**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Base64 encoded values
  database-password: U3VwZXJTZWNyZXQxMjMh
stringData:
  # Plain text (auto-encoded)
  api-key: "plain-text-value"
```

**Use in Pod:**

**As environment variables:**
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secrets
      key: database-password
```

**As volume mount:**
```yaml
volumeMounts:
- name: secret-volume
  mountPath: /etc/secrets
  readOnly: true
volumes:
- name: secret-volume
  secret:
    secretName: app-secrets
```

---

## 7. What is the difference between `data` and `stringData` in Secrets?

**Answer:**

**data:**
- Values must be Base64 encoded
- Used when you have pre-encoded values
- Example: `database-password: U3VwZXJTZWNyZXQxMjMh`

**stringData:**
- Values are plain text
- Kubernetes automatically Base64 encodes them
- Easier to read and maintain
- Example: `api-key: "my-secret-key"`

**Important:** After creation, `stringData` is merged into `data` and `stringData` is removed. When you view the Secret, you'll only see `data` with Base64 values.

**Example:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  encoded-value: U3VwZXJTZWNyZXQ=  # Pre-encoded
stringData:
  plain-value: "my-secret"  # Auto-encoded
```

**After creation:**
```bash
kubectl get secret my-secret -o yaml
# Shows both in 'data' as Base64
```

---

## 8. Multiple Choice: Which method of using Secrets is more secure?

A. Environment variables  
B. Volume mounts  
C. Both are equally secure  
D. Neither is secure

**Answer: B**

**Explanation:** Volume mounts are generally more secure because:
- Secrets are mounted as files (not in process environment)
- Less likely to be exposed in logs or process lists
- Can set file permissions (e.g., `defaultMode: 0400`)
- Environment variables can be visible in process lists and logs

**However:** Both methods have the Secret data in memory, so neither is completely secure. For production, consider external secret managers (Vault, AWS Secrets Manager, etc.).

---

## 9. Explain how to update a ConfigMap and make Pods pick up the changes.

**Answer:**

**Step 1: Update ConfigMap**
```bash
# Method 1: Edit directly
kubectl edit configmap app-config

# Method 2: Update YAML and apply
kubectl apply -f configmap.yaml
```

**Step 2: Make Pods pick up changes**

**For environment variables:**
- Environment variables are NOT updated automatically
- Must restart Pods:
```bash
kubectl rollout restart deployment/<name>
```

**For volume mounts:**
- Volume-mounted ConfigMaps ARE updated automatically
- Takes ~60 seconds (kubelet sync interval)
- No Pod restart needed

**Best Practice:**
- Use volume mounts if you need hot-reloading
- Use environment variables if you need explicit restarts
- Always trigger rolling restart after ConfigMap updates for env vars

---

## 10. What are the different types of Secrets in Kubernetes?

**Answer:**

**1. Opaque (Generic)**
- Default type for arbitrary user data
- Most common type
- Example: Database credentials, API keys

**2. kubernetes.io/dockerconfigjson**
- For Docker registry authentication
- Used with `imagePullSecrets`
- Example: Private container registry credentials

**3. kubernetes.io/tls**
- For TLS certificates and keys
- Contains `tls.crt` and `tls.key`
- Example: HTTPS certificates

**4. kubernetes.io/basic-auth**
- For basic authentication
- Contains `username` and `password`

**5. kubernetes.io/ssh-auth**
- For SSH authentication
- Contains `ssh-privatekey`

**Example - TLS Secret:**
```bash
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key
```

**Example - Docker Registry Secret:**
```bash
kubectl create secret docker-registry my-registry-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

---

## 11. Multiple Choice: What is the maximum size limit for a Secret?

A. 100KB  
B. 1MB  
C. 10MB  
D. No limit

**Answer: B**

**Explanation:** Each Secret has a size limit of 1MB. This is to prevent etcd (where Secrets are stored) from being overwhelmed with large data.

---

## 12. Scenario: You need to provide different configurations for dev, staging, and production environments. How would you do this?

**Answer:**

**Method 1: Separate ConfigMaps per environment**
```bash
# Development
kubectl create configmap app-config-dev \
  --from-literal=NODE_ENV=development \
  --from-literal=LOG_LEVEL=debug \
  --from-literal=DB_HOST=localhost

# Staging
kubectl create configmap app-config-staging \
  --from-literal=NODE_ENV=staging \
  --from-literal=LOG_LEVEL=info \
  --from-literal=DB_HOST=staging-db.default.svc

# Production
kubectl create configmap app-config-prod \
  --from-literal=NODE_ENV=production \
  --from-literal=LOG_LEVEL=error \
  --from-literal=DB_HOST=prod-db.default.svc
```

**Method 2: Use namespaces with environment-specific ConfigMaps**
```yaml
# Deploy to different namespaces
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# Create ConfigMap in each namespace
kubectl create configmap app-config \
  --from-literal=NODE_ENV=production \
  -n production
```

**Method 3: Use Helm or Kustomize**
- Helm: Different values files per environment
- Kustomize: Environment-specific overlays

**Best Practice:** Use separate ConfigMaps per environment and reference them in environment-specific deployments.

---

## 13. Explain what happens when you use `envFrom` with both ConfigMap and Secret.

**Answer:**

You can use `envFrom` to import all keys from multiple ConfigMaps and Secrets:

```yaml
envFrom:
- configMapRef:
    name: app-config
- secretRef:
    name: app-secrets
- configMapRef:
    name: feature-flags
```

**Behavior:**
- All keys from all sources are imported as environment variables
- If same key exists in multiple sources, the last one wins
- Keys are case-sensitive
- Invalid keys (not valid env var names) are skipped

**Example:**
```yaml
# ConfigMap
data:
  PORT: "8080"
  LOG_LEVEL: "info"

# Secret
data:
  DB_PASSWORD: <base64>
  API_KEY: <base64>

# Result in Pod:
# PORT=8080
# LOG_LEVEL=info
# DB_PASSWORD=<decoded>
# API_KEY=<decoded>
```

**Best Practice:** Use `envFrom` for convenience, but be careful with key name conflicts.

---

## 14. Multiple Choice: How do you decode a Base64-encoded Secret value?

A. `kubectl decode secret <name>`  
B. `kubectl get secret <name> -o jsonpath='{.data.key}' | base64 --decode`  
C. `kubectl show secret <name>`  
D. Secrets cannot be decoded

**Answer: B**

**Explanation:** You can decode Secret values using:
```bash
# Get and decode a specific key
kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 --decode

# Example
kubectl get secret app-secrets -o jsonpath='{.data.database-password}' | base64 --decode
```

---

## 15. What are immutable ConfigMaps and Secrets, and when should you use them?

**Answer:**

Immutable ConfigMaps/Secrets cannot be updated after creation. They must be deleted and recreated to change.

**How to make immutable:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
immutable: true  # Cannot be updated!
data:
  VERSION: "1.0.0"
  BUILD_DATE: "2024-01-01"
```

**Benefits:**
- **Performance**: Reduces API server load (no watch operations)
- **Safety**: Prevents accidental updates
- **Versioning**: Forces explicit version changes

**When to use:**
- Configuration that should never change (version info, build metadata)
- Large ConfigMaps (reduces watch overhead)
- When you want to enforce versioning
- Production configs that require explicit recreation

**Trade-offs:**
- Cannot update in place (must delete and recreate)
- Pods must be restarted to pick up new ConfigMap
- More operational overhead

**Best Practice:** Use immutable for version info, build metadata. Use mutable for runtime configuration that may need updates.

---

## 16. Scenario: Your application needs to read a configuration file. Should you use ConfigMap as environment variables or volume mount?

**Answer:**

**Use volume mount** when:
- Application reads from files (not environment variables)
- Need hot-reloading (updates without Pod restart)
- Configuration file format (JSON, YAML, properties, etc.)
- Multiple configuration files

**Example:**
```yaml
volumeMounts:
- name: config-volume
  mountPath: /etc/config
volumes:
- name: config-volume
  configMap:
    name: app-config
```

**Use environment variables** when:
- Application reads from environment variables
- Simple key-value pairs
- Don't need hot-reloading
- Prefer explicit Pod restart for config changes

**Best Practice:** 
- If app supports both, prefer volume mounts for better flexibility
- Volume mounts support hot-reloading
- Environment variables are simpler but require Pod restart

---

## 17. Multiple Choice: What happens if a ConfigMap referenced in a Pod doesn't exist?

A. Pod starts normally  
B. Pod fails to start with ConfigMapNotFound error  
C. Pod starts but environment variables are empty  
D. Kubernetes creates the ConfigMap automatically

**Answer: B**

**Explanation:** If a ConfigMap (or Secret) referenced in a Pod doesn't exist, the Pod will fail to start. Kubernetes will show an error like "ConfigMap not found" in the Pod events. You must create the ConfigMap before creating the Pod.

**Exception:** If the ConfigMap is marked as optional:
```yaml
envFrom:
- configMapRef:
    name: optional-config
    optional: true  # Pod starts even if ConfigMap doesn't exist
```

