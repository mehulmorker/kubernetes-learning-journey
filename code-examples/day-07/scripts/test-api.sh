#!/bin/bash
# Test the backend API endpoints

# Get backend pod name
BACKEND_POD=$(kubectl get pod -n ecommerce -l app=backend -o jsonpath='{.items[0].metadata.name}')

if [ -z "$BACKEND_POD" ]; then
    echo "Error: Backend pod not found"
    exit 1
fi

echo "Testing backend API on pod: $BACKEND_POD"
echo ""

# Port-forward to backend
echo "Setting up port-forward (press Ctrl+C to stop)..."
kubectl port-forward -n ecommerce $BACKEND_POD 3000:3000 &
PORT_FORWARD_PID=$!

# Wait for port-forward to be ready
sleep 3

# Test endpoints
echo "Testing /health endpoint..."
curl http://localhost:3000/health | jq .
echo ""

echo "Testing /api/products endpoint..."
curl http://localhost:3000/api/products | jq .
echo ""

echo "Testing /api/info endpoint..."
curl http://localhost:3000/api/info | jq .
echo ""

# Cleanup
kill $PORT_FORWARD_PID
echo "Port-forward stopped."

