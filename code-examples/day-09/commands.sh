#!/bin/bash
# Common kubectl commands for namespace management

# List all namespaces
kubectl get namespaces
kubectl get ns

# View resources in each namespace
kubectl get pods -n default
kubectl get pods -n kube-system
kubectl get all -n kube-system  # See system components

# Create namespace imperatively
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production
kubectl create ns team-frontend
kubectl create ns team-backend

# Delete namespace (⚠️ deletes ALL resources in it!)
kubectl delete namespace team-backend

# Apply namespaces from YAML
kubectl apply -f namespaces.yaml

# View with labels
kubectl get ns --show-labels

# Query namespaces by label
kubectl get ns -l environment=production
kubectl get ns -l team=platform

# Create pod in specific namespace
kubectl run nginx --image=nginx -n development

# Create deployment in namespace
kubectl create deployment web --image=nginx --replicas=3 -n staging

# View resources
kubectl get pods -n development
kubectl get deployments -n staging

# Set default namespace for current context
kubectl config set-context --current --namespace=development

# View current namespace
kubectl config view --minify | grep namespace:

# Reset to default namespace
kubectl config set-context --current --namespace=default

# Cross-namespace DNS examples
# Same namespace:
# curl http://backend-service:3000

# Different namespace (short form):
# curl http://backend-service.backend-ns:3000

# Different namespace (full FQDN):
# curl http://backend-service.backend-ns.svc.cluster.local:3000

# Check resource scope
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false

# View quotas
kubectl get resourcequota -n dev-limited
kubectl describe resourcequota dev-quota -n dev-limited

# View LimitRange
kubectl get limitrange -n auto-limited
kubectl describe limitrange resource-limits -n auto-limited

# Check what resources were automatically assigned
kubectl describe pod auto-resources -n auto-limited | grep -A 10 "Limits\|Requests"

# Multi-tenant operations
kubectl create deployment app-a --image=nginx --replicas=3 -n team-a
kubectl create deployment app-b --image=nginx --replicas=2 -n team-b

# Check resource usage per team
kubectl top pods -n team-a
kubectl describe resourcequota team-a-quota -n team-a
kubectl top pods -n team-b
kubectl describe resourcequota team-b-quota -n team-b

# List all team namespaces
kubectl get ns -l cost-center=engineering


