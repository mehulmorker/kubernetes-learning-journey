# Exercise 2: Canary Deployment with Labels

This exercise demonstrates implementing a canary deployment pattern using labels, where version 1 receives 90% of traffic and version 2 (canary) receives 10%.

## Files

- `v1-deployment.yaml` - Version 1 deployment (9 replicas = 90% traffic)
- `v2-deployment.yaml` - Version 2 canary deployment (1 replica = 10% traffic)
- `service.yaml` - Service that targets both versions

## Deployment

```bash
# Deploy both versions
kubectl apply -f v1-deployment.yaml
kubectl apply -f v2-deployment.yaml
kubectl apply -f service.yaml
```

## Testing Canary

```bash
# Test multiple times - you should see v2 ~10% of the time
for i in {1..20}; do
  kubectl run test-$i --image=alpine --rm -it --restart=Never -- \
    wget -qO- myapp-service
done
```

## How It Works

- Both deployments share the `app: myapp` label
- The service selector matches both versions using `app: myapp`
- Traffic is distributed based on replica count (9:1 ratio = 90%:10%)
- Version 2 serves a different response to identify canary traffic

## Cleanup

```bash
kubectl delete -f v1-deployment.yaml
kubectl delete -f v2-deployment.yaml
kubectl delete -f service.yaml
```


