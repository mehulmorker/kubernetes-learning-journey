#!/bin/bash
# Create a service pointing to non-existent Pods
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: broken-service
spec:
  selector:
    app: nonexistent
  ports:
  - port: 80
EOF

# Debug it:
kubectl get svc broken-service
kubectl get endpoints broken-service  # Empty!
kubectl describe svc broken-service

# Fix by updating selector to match existing Pods

