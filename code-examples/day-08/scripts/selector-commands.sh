#!/bin/bash
# Label Selector Commands

# Equality-Based Selectors
echo "=== Single label ==="
kubectl get pods -l app=ecommerce

echo "=== Multiple labels (AND) ==="
kubectl get pods -l app=ecommerce,environment=production

echo "=== NOT equal ==="
kubectl get pods -l environment!=development

echo "=== Label doesn't exist ==="
kubectl get pods -l '!version'

echo "=== Combined conditions ==="
kubectl get pods -l 'app=ecommerce,environment!=development'

# Set-Based Selectors
echo "=== IN operator ==="
kubectl get pods -l 'environment in (staging,production)'

echo "=== NOT IN operator ==="
kubectl get pods -l 'environment notin (development)'

echo "=== Label exists ==="
kubectl get pods -l version

echo "=== Complex query ==="
kubectl get pods -l 'app=ecommerce,environment in (staging,production),tier=web'


