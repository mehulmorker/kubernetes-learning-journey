#!/bin/bash
# Get detailed info
kubectl describe pod my-node-pod

# View logs (just like docker logs)
kubectl logs my-node-pod

# Follow logs in real-time
kubectl logs -f my-node-pod

# Execute commands inside the Pod (like docker exec)
kubectl exec -it my-node-pod -- sh

