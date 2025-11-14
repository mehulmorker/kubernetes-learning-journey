#!/bin/bash
kubectl apply -f headless-service.yaml

# Test DNS - returns all Pod IPs
kubectl run test-pod --image=alpine --rm -it -- sh
apk add --no-cache bind-tools
nslookup headless-service
# You'll see multiple A records (one per Pod)

