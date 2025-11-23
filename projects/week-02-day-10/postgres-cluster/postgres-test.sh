#!/bin/bash

# Connect to each instance
for i in 0 1 2; do
  echo "=== postgres-$i ==="
  kubectl exec -it postgres-$i -- psql -U postgres -c "SELECT current_database();"
done

# Create data in postgres-0
kubectl exec -it postgres-0 -- psql -U postgres -c "CREATE DATABASE testdb;"

# Verify persistence after pod restart
kubectl delete pod postgres-0
kubectl wait --for=condition=ready pod/postgres-0
kubectl exec -it postgres-0 -- psql -U postgres -c "\l"

