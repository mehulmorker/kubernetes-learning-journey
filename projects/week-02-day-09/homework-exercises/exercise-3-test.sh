#!/bin/bash
# Exercise 3: Test Resource Quota Management
# Try to:
# 1. Deploy 10 pods (should fail)
# 2. Deploy pods without resource specs (should fail)
# 3. Deploy within limits (should succeed)

# Apply quota
kubectl apply -f exercise-3-quota-test.yaml

echo "=== Test 1: Deploy 10 pods (should fail) ==="
kubectl apply -n quota-test -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-fail
spec:
  replicas: 10
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
EOF

echo ""
echo "=== Test 2: Deploy pod without resource specs (should fail) ==="
kubectl apply -n quota-test -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-no-resources
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF

echo ""
echo "=== Test 3: Deploy within limits (should succeed) ==="
kubectl apply -n quota-test -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-success
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-success
  template:
    metadata:
      labels:
        app: test-success
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF

echo ""
echo "=== Check quota usage ==="
kubectl describe resourcequota tight-quota -n quota-test

echo ""
echo "=== List pods in quota-test namespace ==="
kubectl get pods -n quota-test


