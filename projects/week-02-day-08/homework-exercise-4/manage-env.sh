#!/bin/bash
# manage-env.sh
# Script to manage Kubernetes resources by environment using labels

ENV=$1
ACTION=$2

if [ -z "$ENV" ] || [ -z "$ACTION" ]; then
  echo "Usage: $0 <environment> <list|scale-up|scale-down|delete>"
  exit 1
fi

case $ACTION in
  "list")
    echo "=== $ENV Resources ==="
    kubectl get all -l environment=$ENV
    ;;
  "scale-up")
    echo "Scaling up all deployments in $ENV to 5 replicas..."
    kubectl scale deployment -l environment=$ENV --replicas=5
    ;;
  "scale-down")
    echo "Scaling down all deployments in $ENV to 1 replica..."
    kubectl scale deployment -l environment=$ENV --replicas=1
    ;;
  "delete")
    echo "WARNING: This will delete all resources in $ENV environment!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
      kubectl delete all -l environment=$ENV
    else
      echo "Operation cancelled."
    fi
    ;;
  *)
    echo "Usage: $0 <environment> <list|scale-up|scale-down|delete>"
    echo ""
    echo "Actions:"
    echo "  list       - List all resources in the environment"
    echo "  scale-up   - Scale all deployments to 5 replicas"
    echo "  scale-down - Scale all deployments to 1 replica"
    echo "  delete     - Delete all resources in the environment"
    exit 1
    ;;
esac


