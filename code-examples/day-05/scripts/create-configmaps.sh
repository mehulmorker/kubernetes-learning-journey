#!/bin/bash

# Method 1: From Literal Values
kubectl create configmap app-config \
  --from-literal=PORT=8080 \
  --from-literal=LOG_LEVEL=info \
  --from-literal=NODE_ENV=production

# View it
kubectl get configmap app-config
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml

# Method 2: From File
cat > app.properties << EOF
PORT=8080
LOG_LEVEL=debug
DATABASE_HOST=postgres.default.svc.cluster.local
DATABASE_PORT=5432
MAX_CONNECTIONS=100
FEATURE_FLAG_NEW_UI=true
EOF

kubectl create configmap app-config-from-file \
  --from-file=app.properties

# Method 3: From Multiple Files
mkdir -p configs
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

kubectl create configmap app-configs \
  --from-file=configs/

