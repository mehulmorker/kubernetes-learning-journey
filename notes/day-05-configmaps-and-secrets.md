# Day 5: ConfigMaps & Secrets - Configuration Management
Excellent! Today we'll learn how to externalize configuration and manage sensitive data properly in Kubernetes.

Part 1: Why ConfigMaps & Secrets? (10 minutes)
The Problem with Hard-Coded Configuration
Bad Practice (what we've been doing):
```javascript
// app.js with hardcoded values
const PORT = 3000;  // Hardcoded!
const DB_HOST = 'localhost';  // Hardcoded!
const API_KEY = 'secret123';  // Hardcoded in code! 😱

app.listen(PORT, () => {
  console.log(`Server on port ${PORT}`);
});
```
Problems:
```javascript
const problems = {
  environments: "Different configs for dev/staging/prod",
  secrets: "API keys, passwords in source code",
  changes: "Need to rebuild image for config changes",
  security: "Secrets visible in version control",
  reusability: "Can't reuse same image with different configs"
};
```
**Kubernetes Solution:**
- **ConfigMaps** → Non-sensitive configuration
- **Secrets** → Sensitive data (passwords, tokens, keys)

---

## Part 2: ConfigMaps Basics (25 minutes)

### What is a ConfigMap?
ConfigMap = Key-value pairs for configuration data
```
┌──────────────────┐
│   ConfigMap      │
│  "app-config"    │
├──────────────────┤
│ PORT: "8080"     │
│ LOG_LEVEL: "info"│
│ DB_HOST: "db.svc"│
└────────┬─────────┘
         │
         ↓ (injected into)
    ┌────────┐
    │  Pod   │
    └────────┘
```
Create ConfigMaps - 4 Methods
Method 1: From Literal Values (Quick)
```bash
# Create ConfigMap with key-value pairs
kubectl create configmap app-config   --from-literal=PORT=8080   --from-literal=LOG_LEVEL=info   --from-literal=NODE_ENV=production

# View it
kubectl get configmap app-config
kubectl describe configmap app-config

# See the actual data
kubectl get configmap app-config -o yaml
```
Method 2: From File
```bash
# Create a config file
cat > app.properties << EOF
PORT=8080
LOG_LEVEL=debug
DATABASE_HOST=postgres.default.svc.cluster.local
DATABASE_PORT=5432
MAX_CONNECTIONS=100
FEATURE_FLAG_NEW_UI=true
EOF

# Create ConfigMap from file
kubectl create configmap app-config-from-file   --from-file=app.properties

# View it
kubectl get configmap app-config-from-file -o yaml
# Notice: The entire file is stored as ONE key
```
Method 3: From Multiple Files
```bash
# Create multiple config files
mkdir configs
cat > configs/database.conf << EOF
host=postgres.default.svc.cluster.local
port=5432
max_connections=100
EOF

cat > configs/api.conf << EOF
endpoint=https://api.example.com
timeout=30
retry=3
EOF

# Create ConfigMap from directory
kubectl create configmap app-configs   --from-file=configs/

# View it
kubectl describe configmap app-configs
# Each file becomes a separate key
```
Method 4: Declarative YAML (Production Way)
Create configmap.yaml:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-app-config
  labels:
    app: node-demo
data:
  # Simple key-value pairs
  PORT: "8080"
  LOG_LEVEL: "info"
  NODE_ENV: "production"
  
  # Multi-line values
  app.properties: |
    server.port=8080
    server.host=0.0.0.0
    log.level=info
    
  # JSON config
  features.json: |
    {
      "newUI": true,
      "darkMode": false,
      "maxUsers": 1000
    }
```
```bash
# Apply it
kubectl apply -f configmap.yaml

# View it
kubectl get configmap node-app-config -o yaml
```

---

## Part 3: Using ConfigMaps in Pods (30 minutes)

Method 1: Environment Variables (Simple Values)
Update your Node.js app to use env vars:
```javascript
// app.js
const express = require('express');
const app = express();

// Read from environment variables
const PORT = process.env.PORT || 3000;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const NODE_ENV = process.env.NODE_ENV || 'development';
const FEATURE_NEW_UI = process.env.FEATURE_NEW_UI === 'true';

app.get('/', (req, res) => {
  res.json({ 
    message: 'ConfigMap Demo',
    config: {
      port: PORT,
      logLevel: LOG_LEVEL,
      environment: NODE_ENV,
      featureNewUI: FEATURE_NEW_UI
    },
    hostname: require('os').hostname()
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${NODE_ENV} mode`);
});
```
```bash
# Rebuild image
eval $(minikube docker-env)
cd ~/node-k8s-demo
docker build -t node-k8s-demo:config-v1 .
```
Create deployment using ConfigMap:
Create deployment-with-configmap.yaml:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-with-config
spec:
  replicas: 2
  selector:
    matchLabels:
      app: node-config-demo
  template:
    metadata:
      labels:
        app: node-config-demo
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        
        # Method 1: Individual env vars from ConfigMap
        env:
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: node-app-config
              key: PORT
        
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: node-app-config
              key: LOG_LEVEL
        
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: node-app-config
              key: NODE_ENV
```
```bash
kubectl apply -f deployment-with-configmap.yaml

# Create a service to access it
kubectl expose deployment node-app-with-config --type=NodePort --port=80 --target-port=8080

# Test it
minikube service node-app-with-config
# Or
curl http://$(minikube ip):<node-port>
```
Method 2: All Keys as Environment Variables
```yaml
# deployment-envfrom.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-envfrom
spec:
  replicas: 2
  selector:
    matchLabels:
      app: node-envfrom-demo
  template:
    metadata:
      labels:
        app: node-envfrom-demo
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        
        # Method 2: Import ALL keys from ConfigMap
        envFrom:
        - configMapRef:
            name: node-app-config
        
        # Can also add individual env vars
        env:
        - name: FEATURE_NEW_UI
          value: "true"
```
```bash
kubectl apply -f deployment-envfrom.yaml

# Verify all env vars are set
kubectl exec -it deployment/node-app-envfrom -- env | grep -E 'PORT|LOG_LEVEL|NODE_ENV'
```
Method 3: Mount as Volume (Files)
```yaml
# deployment-volume.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-volume
spec:
  replicas: 2
  selector:
    matchLabels:
      app: node-volume-demo
  template:
    metadata:
      labels:
        app: node-volume-demo
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        
        # Basic env vars
        env:
        - name: PORT
          value: "8080"
        
        # Mount ConfigMap as volume
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config          # Mount path in container
          readOnly: true
      
      volumes:
      - name: config-volume
        configMap:
          name: node-app-config
```
```bash
kubectl apply -f deployment-volume.yaml

# Verify files are mounted
kubectl exec -it deployment/node-app-volume -- ls -la /etc/config
kubectl exec -it deployment/node-app-volume -- cat /etc/config/app.properties
kubectl exec -it deployment/node-app-volume -- cat /etc/config/features.json
```
Method 4: Mount Specific Keys
```yaml
# deployment-selective-mount.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-selective
spec:
  replicas: 1
  selector:
    matchLabels:
      app: node-selective-demo
  template:
    metadata:
      labels:
        app: node-selective-demo
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      
      volumes:
      - name: config-volume
        configMap:
          name: node-app-config
          items:                          # Select specific keys
          - key: app.properties
            path: application.properties  # Rename the file
          - key: features.json
            path: features.json
```
```bash
kubectl apply -f deployment-selective-mount.yaml

# Verify only selected files are present
kubectl exec -it deployment/node-app-selective -- ls -la /etc/config
```

---

## Part 4: Secrets (30 minutes)

What are Secrets?
Secrets are like ConfigMaps but for sensitive data:

Passwords
API keys
Tokens
TLS certificates

Key Differences:
```javascript
const differences = {
  storage: "Base64 encoded (not encrypted by default)",
  access: "More restricted RBAC policies",
  usage: "Same as ConfigMaps (env vars or volumes)",
  size: "Limited to 1MB",
  security: "Can be encrypted at rest (cluster config)"
};
```
Create Secrets - Multiple Methods
Method 1: From Literal Values
```bash
# Create a generic secret
kubectl create secret generic db-credentials   --from-literal=username=admin   --from-literal=password=SuperSecret123!

# View it (data is base64 encoded)
kubectl get secret db-credentials -o yaml

# Decode the values
kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 --decode
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 --decode
```
Method 2: From Files
```bash
# Create credential files
echo -n 'admin' > username.txt
echo -n 'SuperSecret123!' > password.txt

# Create secret from files
kubectl create secret generic db-creds-from-file   --from-file=username=username.txt   --from-file=password=password.txt

# Clean up files
rm username.txt password.txt
```
Method 3: Declarative YAML
```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Values must be base64 encoded
  database-password: U3VwZXJTZWNyZXQxMjMh    # SuperSecret123!
  api-key: YWJjZGVmMTIzNDU2Nzg5MA==        # abcdef1234567890

# Alternative: Use stringData for plain text (auto-encoded)
stringData:
  smtp-password: "plain-text-password"
  jwt-secret: "my-jwt-secret-key"
```
```bash
# To encode values manually:
echo -n 'SuperSecret123!' | base64
echo -n 'abcdef1234567890' | base64

# Apply the secret
kubectl apply -f secret.yaml

# View it
kubectl get secret app-secrets -o yaml
```
Method 4: TLS Secret (for HTTPS)
```bash
# Generate self-signed certificate (for demo)
openssl req -x509 -nodes -days 365 -newkey rsa:2048   -keyout tls.key -out tls.crt   -subj "/CN=myapp.example.com/O=myapp"

# Create TLS secret
kubectl create secret tls myapp-tls   --cert=tls.crt   --key=tls.key

# View it
kubectl describe secret myapp-tls

# Clean up
rm tls.key tls.crt
```
Method 5: Docker Registry Secret
```bash
# For pulling images from private registry
kubectl create secret docker-registry my-registry-secret   --docker-server=https://index.docker.io/v1/   --docker-username=myusername   --docker-password=mypassword   --docker-email=myemail@example.com

# Use in Pod spec:
# spec:
#   imagePullSecrets:
#   - name: my-registry-secret
```

---

## Part 5: Using Secrets in Pods (20 minutes)

Method 1: As Environment Variables
Create deployment-with-secrets.yaml:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-with-secrets
spec:
  replicas: 2
  selector:
    matchLabels:
      app: node-secrets-demo
  template:
    metadata:
      labels:
        app: node-secrets-demo
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        
        env:
        # From ConfigMap
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: node-app-config
              key: PORT
        
        # From Secret
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-password
        
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
```
```bash
kubectl apply -f deployment-with-secrets.yaml

# Verify secrets are set (DON'T DO THIS IN PRODUCTION!)
kubectl exec -it deployment/node-app-with-secrets -- env | grep -E 'DB_PASSWORD|API_KEY'
```
Method 2: All Keys from Secret
```yaml
# deployment-secret-envfrom.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-secret-envfrom
spec:
  replicas: 1
  selector:
    matchLabels:
      app: node-secret-envfrom
  template:
    metadata:
      labels:
        app: node-secret-envfrom
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        
        # Import all from ConfigMap
        envFrom:
        - configMapRef:
            name: node-app-config
        
        # Import all from Secret
        - secretRef:
            name: app-secrets
```
Method 3: Mount as Volume (More Secure)
```yaml
# deployment-secret-volume.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-secret-volume
spec:
  replicas: 1
  selector:
    matchLabels:
      app: node-secret-volume
  template:
    metadata:
      labels:
        app: node-secret-volume
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        
        volumeMounts:
        # Mount secrets as files
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
        
        # Mount config
        - name: config-volume
          mountPath: /etc/config
          readOnly: true
      
      volumes:
      - name: secret-volume
        secret:
          secretName: app-secrets
          defaultMode: 0400        # Read-only for owner
      
      - name: config-volume
        configMap:
          name: node-app-config
```
```bash
kubectl apply -f deployment-secret-volume.yaml

# Verify secrets are mounted as files
kubectl exec -it deployment/node-app-secret-volume -- ls -la /etc/secrets
kubectl exec -it deployment/node-app-secret-volume -- cat /etc/secrets/database-password
```

---

## Part 6: Updating ConfigMaps & Secrets (15 minutes)

Update ConfigMap
```bash
# Method 1: Edit directly
kubectl edit configmap node-app-config

# Method 2: Update YAML and re-apply
# Edit configmap.yaml (change LOG_LEVEL to "debug")
kubectl apply -f configmap.yaml

# Check the change
kubectl get configmap node-app-config -o yaml
```
Important: Pod behavior after updates:
```javascript
const updateBehavior = {
  envVars: "NOT updated - Pod restart required",
  volumes: "Auto-updated after ~60 seconds (kubelet sync)",
  recommendation: "For env vars, trigger rolling restart"
};
```
Trigger rolling restart:
```bash
# Force pods to restart and pick up new config
kubectl rollout restart deployment/node-app-with-config

# Watch the rollout
kubectl rollout status deployment/node-app-with-config
```
Update Secret
```bash
# Edit secret (values are base64 encoded)
kubectl edit secret app-secrets

# Or delete and recreate
kubectl delete secret app-secrets
kubectl create secret generic app-secrets   --from-literal=database-password=NewPassword456   --from-literal=api-key=newkey9876543210

# Restart pods to pick up changes
kubectl rollout restart deployment/node-app-with-secrets
```

---

## Day 5 Homework (30-40 minutes)

Exercise 1: Multi-Environment Configuration
```bash
# Development config
kubectl create configmap app-config-dev   --from-literal=NODE_ENV=development   --from-literal=LOG_LEVEL=debug   --from-literal=DB_HOST=localhost

# Staging config
kubectl create configmap app-config-staging   --from-literal=NODE_ENV=staging   --from-literal=LOG_LEVEL=info   --from-literal=DB_HOST=staging-db.default.svc

# Production config
kubectl create configmap app-config-prod   --from-literal=NODE_ENV=production   --from-literal=LOG_LEVEL=error   --from-literal=DB_HOST=prod-db.default.svc

# Create deployments using different configs
```

Exercise 2: Complete App with ConfigMap and Secret
```yaml
# complete-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  PORT: "8080"
  LOG_LEVEL: "info"
  DATABASE_HOST: "postgres.default.svc.cluster.local"
  DATABASE_PORT: "5432"
  REDIS_HOST: "redis.default.svc.cluster.local"
---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
type: Opaque
stringData:
  database-username: "appuser"
  database-password: "SuperSecurePass123!"
  redis-password: "RedisPass456!"
  jwt-secret: "my-super-secret-jwt-key"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: node-k8s-demo:config-v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        
        envFrom:
        - configMapRef:
            name: myapp-config
        
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: jwt-secret
        
        volumeMounts:
        - name: secret-files
          mountPath: /etc/secrets
          readOnly: true
      
      volumes:
      - name: secret-files
        secret:
          secretName: myapp-secrets
          items:
          - key: jwt-secret
            path: jwt.key
```
```bash
kubectl apply -f complete-app.yaml
kubectl get pods
kubectl logs deployment/myapp
```

Exercise 3: ConfigMap from JSON/YAML Files
```bash
# Create a complex config file
cat > app-config.json << EOF
{
  "server": {
    "port": 8080,
    "host": "0.0.0.0"
  },
  "database": {
    "host": "postgres.default.svc.cluster.local",
    "port": 5432,
    "pool": {
      "min": 2,
      "max": 10
    }
  },
  "features": {
    "newUI": true,
    "betaFeatures": false
  }
}
EOF

# Create ConfigMap
kubectl create configmap app-json-config --from-file=app-config.json

# Use it in a Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: json-config-pod
spec:
  containers:
  - name: app
    image: node-k8s-demo:config-v1
    imagePullPolicy: Never
    volumeMounts:
    - name: config
      mountPath: /app/config
  volumes:
  - name: config
    configMap:
      name: app-json-config
EOF

# Verify
kubectl exec json-config-pod -- cat /app/config/app-config.json
```
Exercise 4: Immutable ConfigMaps and Secrets
```yaml
# immutable-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
immutable: true    # Cannot be updated!
data:
  VERSION: "1.0.0"
  RELEASE_DATE: "2025-10-10"
```
```bash
kubectl apply -f immutable-config.yaml

# Try to edit (will fail)
kubectl edit configmap immutable-config
# Error: field is immutable

# Must delete and recreate to change
```
Exercise 5: Secret Rotation Practice
```bash
# 1. Create initial secret
kubectl create secret generic rotating-secret   --from-literal=api-key=initial-key-123

# 2. Deploy app using it
kubectl create deployment secret-app   --image=node-k8s-demo:config-v1   --dry-run=client -o yaml > secret-app.yaml

# Edit to use the secret, then apply

# 3. Update secret
kubectl create secret generic rotating-secret   --from-literal=api-key=new-key-456   --dry-run=client -o yaml | kubectl apply -f -

# 4. Restart deployment
kubectl rollout restart deployment/secret-app

# 5. Verify new secret is used
kubectl exec -it deployment/secret-app -- env | grep api-key
```

---

## ✅ Day 5 Checklist
Before moving to Day 6, ensure you can:

 Create ConfigMaps using 4 different methods
 Create Secrets using multiple methods
 Inject ConfigMaps as environment variables
 Inject Secrets as environment variables
 Mount ConfigMaps as volumes
 Mount Secrets as volumes
 Understand the difference between ConfigMaps and Secrets
 Update ConfigMaps and trigger pod restarts
 Use envFrom to import all keys
 Mount specific keys from ConfigMaps/Secrets
 Understand base64 encoding in Secrets
 Know when to use env vars vs volumes


---

## 🎯 Best Practices
```javascript
const bestPractices = {
  separation: "Never hardcode config in images",
  secrets: "Never commit secrets to git",
  volumes: "Prefer volumes over env vars for secrets",
  immutable: "Use immutable ConfigMaps for versions",
  naming: "Use descriptive names: app-config-prod",
  updates: "Always trigger rollout restart after updates",
  size: "Keep ConfigMaps small (<1MB)",
  organization: "One ConfigMap per app/environment"
};
```

