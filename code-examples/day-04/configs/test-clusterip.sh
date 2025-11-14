#!/bin/bash
# Create a temporary Pod for testing
kubectl run test-pod --image=alpine --rm -it -- sh

# Inside the test Pod, install curl:
apk add --no-cache curl

# Test using Service IP
curl http://10.96.xxx.xxx:80  # Use actual Service IP

# Test using DNS name (better!)
curl http://node-app-service:80
curl http://node-app-service.default.svc.cluster.local:80

# Test multiple times - you'll hit different Pods
for i in {1..10}; do curl -s http://node-app-service:80 | grep hostname; done

# Exit the test Pod
exit

