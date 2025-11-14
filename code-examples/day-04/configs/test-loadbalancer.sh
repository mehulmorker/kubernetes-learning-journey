#!/bin/bash
# Minikube provides a tunnel for LoadBalancer services
minikube tunnel

# In another terminal:
kubectl get svc node-app-lb
# Now you should see EXTERNAL-IP

# Access it
curl http://<EXTERNAL-IP>

# Or use:
minikube service node-app-lb

