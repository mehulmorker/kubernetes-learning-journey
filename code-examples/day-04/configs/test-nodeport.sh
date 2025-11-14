#!/bin/bash
# Get minikube IP
minikube ip

# Access via Node IP and NodePort
curl http://$(minikube ip):30080

# Or use minikube service command (easier)
minikube service node-app-nodeport

# This opens in your browser!

# Test load balancing:
# Multiple requests - different Pods respond
for i in {1..10}; do 
  curl -s http://$(minikube ip):30080 | grep hostname
done

