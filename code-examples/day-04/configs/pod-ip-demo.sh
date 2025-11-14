#!/bin/bash
# Get your running Pods
kubectl get pods -o wide

# Note the IP addresses - they're dynamic!
# Example: 172.17.0.5, 172.17.0.6, 172.17.0.7

# Get a Pod's IP
POD_NAME=$(kubectl get pods -l app=node-demo -o jsonpath='{.items[0].metadata.name}')
POD_IP=$(kubectl get pod $POD_NAME -o jsonpath='{.status.podIP}')
echo "Pod IP: $POD_IP"

# Now delete the Pod
kubectl delete pod $POD_NAME

# Check the new Pod's IP
sleep 5
NEW_POD_NAME=$(kubectl get pods -l app=node-demo -o jsonpath='{.items[0].metadata.name}')
NEW_POD_IP=$(kubectl get pod $NEW_POD_NAME -o jsonpath='{.status.podIP}')
echo "New Pod IP: $NEW_POD_IP"

# 🎯 IP changed! How can clients reliably connect?

