#!/bin/bash
# Cleanup the e-commerce application from Kubernetes

echo "Deleting e-commerce namespace and all resources..."
kubectl delete namespace ecommerce

echo "Cleanup complete!"

