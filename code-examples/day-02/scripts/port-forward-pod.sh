#!/bin/bash
# Forward a local port to the Pod
kubectl port-forward my-node-pod 3000:3000

# In another terminal, test it:
# curl http://localhost:3000
# curl http://localhost:3000/health

