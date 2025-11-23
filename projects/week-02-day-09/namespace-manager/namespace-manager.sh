#!/bin/bash
# Exercise 5: Namespace Cleanup Script
# namespace-manager.sh - Manage Kubernetes namespaces

ACTION=$1
ENV=$2

if [ -z "$ACTION" ] || [ -z "$ENV" ]; then
  echo "Usage: $0 {create|list|quota|cleanup} <namespace>"
  exit 1
fi

case $ACTION in
  "create")
    echo "Creating namespace: $ENV"
    kubectl create ns $ENV
    kubectl label ns $ENV environment=$ENV
    echo "Namespace $ENV created and labeled"
    ;;
  "list")
    echo "Listing all resources in namespace: $ENV"
    kubectl get all -n $ENV
    ;;
  "quota")
    echo "Resource quotas for namespace: $ENV"
    kubectl describe resourcequota -n $ENV
    ;;
  "cleanup")
    echo "⚠️  WARNING: This will delete namespace $ENV and ALL resources in it!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
      kubectl delete ns $ENV
      echo "Namespace $ENV deleted"
    else
      echo "Cancelled"
    fi
    ;;
  *)
    echo "Usage: $0 {create|list|quota|cleanup} <namespace>"
    exit 1
    ;;
esac


