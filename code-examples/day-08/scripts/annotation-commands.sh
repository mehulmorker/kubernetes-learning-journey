#!/bin/bash
# Annotation Management Commands

# View annotations
kubectl describe deployment annotated-app | grep -A 10 Annotations

# Add annotation
kubectl annotate deployment annotated-app \
  last-updated="$(date)" \
  updated-by="$(whoami)"

# Update annotation (requires --overwrite)
kubectl annotate deployment annotated-app \
  version="2.1.0" --overwrite

# Remove annotation
kubectl annotate deployment annotated-app version-

# View pod annotations
kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.annotations}' | jq


