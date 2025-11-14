#!/bin/bash
kubectl apply -f service-with-affinity.yaml

# Test - same client hits same Pod
for i in {1..10}; do 
  kubectl run test-$i --image=alpine --rm -it -- wget -qO- http://sticky-service | grep hostname
done

