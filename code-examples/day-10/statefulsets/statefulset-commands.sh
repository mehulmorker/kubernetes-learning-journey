#!/bin/bash

# Apply StatefulSet
kubectl apply -f simple-statefulset.yaml

# Watch pods being created in order
kubectl get pods -w

# View StatefulSet
kubectl get statefulsets
kubectl get sts  # shorthand

# View pods
kubectl get pods -l app=nginx

# Test DNS resolution
kubectl run -it --rm debug --image=alpine --restart=Never -- sh

# Inside debug pod (run manually):
# apk add --no-cache bind-tools
# nslookup web-0.web.default.svc.cluster.local
# nslookup web-1.web.default.svc.cluster.local
# nslookup web-2.web.default.svc.cluster.local
# wget -qO- http://web-0.web.default.svc.cluster.local
# exit

# Scale up (creates web-3, web-4)
kubectl scale statefulset web --replicas=5

# Watch ordered creation
kubectl get pods -w

# Scale down (deletes web-4, web-3)
kubectl scale statefulset web --replicas=3

# Apply StatefulSet with storage
kubectl apply -f statefulset-with-storage.yaml

# Watch pods and PVCs being created
kubectl get pods -w
kubectl get pvc

# Write data to each pod
for i in 0 1 2; do
  kubectl exec nginx-sts-$i -- sh -c "echo 'Custom data for pod $i' >> /usr/share/nginx/html/custom.txt"
done

# Read data
for i in 0 1 2; do
  echo "=== Pod nginx-sts-$i ==="
  kubectl exec nginx-sts-$i -- cat /usr/share/nginx/html/custom.txt
done

# Delete a pod
kubectl delete pod nginx-sts-1

# Wait for it to recreate
kubectl wait --for=condition=ready pod/nginx-sts-1

# Check data - it persists!
kubectl exec nginx-sts-1 -- cat /usr/share/nginx/html/custom.txt

# Apply MySQL StatefulSet
kubectl apply -f mysql-statefulset.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod/mysql-0 --timeout=120s

# Connect to MySQL
kubectl exec -it mysql-0 -- mysql -u root -prootpassword

# Inside MySQL (run manually):
# SHOW DATABASES;
# USE myapp;
# CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(50));
# INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
# SELECT * FROM users;
# exit

# Delete pod to test persistence
kubectl delete pod mysql-0

# Wait for recreation
kubectl wait --for=condition=ready pod/mysql-0 --timeout=120s

# Connect again - data persists!
kubectl exec -it mysql-0 -- mysql -u root -prootpassword -e "SELECT * FROM myapp.users"

# Update with partition=2 (only web-2 gets updated)
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'

# Update image
kubectl set image statefulset/web nginx=nginx:1.21

# Only web-2 updates! web-0 and web-1 stay on old version
kubectl get pods -l app=nginx

# Remove partition to update all
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'

