#!/bin/bash

# Set data in redis-0
kubectl exec -it redis-0 -- redis-cli SET key1 "value from redis-0"

# Read from redis-1 (each has own storage)
kubectl exec -it redis-1 -- redis-cli SET key2 "value from redis-1"

# Verify persistence
kubectl delete pod redis-0
kubectl wait --for=condition=ready pod/redis-0
kubectl exec -it redis-0 -- redis-cli GET key1

