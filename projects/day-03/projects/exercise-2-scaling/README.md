# Exercise 2: Practice Scaling

## Objective
Practice scaling deployments up and down, observing how Kubernetes manages Pod lifecycle.

## Prerequisites
- Exercise 1 completed (labeled-app deployment exists)

## Steps

1. Scale up to 6 replicas:
   ```bash
   kubectl scale deployment labeled-app --replicas=6
   kubectl get pods
   ```

2. Scale down to 2 replicas:
   ```bash
   kubectl scale deployment labeled-app --replicas=2
   kubectl get pods
   ```

3. Scale up to 10 replicas:
   ```bash
   kubectl scale deployment labeled-app --replicas=10
   kubectl get pods
   ```

4. Watch the scaling process in real-time:
   ```bash
   kubectl get pods -w
   ```

## Expected Outcome
- Understand how Kubernetes creates and terminates Pods
- Observe Pod lifecycle during scaling operations
- Learn that scaling is immediate and declarative

## Notes
- Use `kubectl get pods -w` to watch Pods in real-time
- Scaling operations are immediate
- Kubernetes maintains the desired number of replicas

