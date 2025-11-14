# Exercise 4: Update Strategy Experiment

## Objective
Compare different rolling update strategies (fast vs slow) and understand their impact on deployments.

## Steps

1. Apply both deployments:
   ```bash
   kubectl apply -f fast-update.yaml
   kubectl apply -f slow-update.yaml
   ```

2. Update both deployments simultaneously:
   ```bash
   kubectl set image deployment/fast-update node-app=node-k8s-demo:v2
   kubectl set image deployment/slow-update node-app=node-k8s-demo:v2
   ```

3. Watch both deployments in separate terminals:
   ```bash
   # Terminal 1
   kubectl get pods -l app=fast -w
   
   # Terminal 2
   kubectl get pods -l app=slow -w
   ```

4. Observe the differences:
   - **Fast update**: More Pods created simultaneously (maxSurge: 3)
   - **Slow update**: One Pod at a time (maxSurge: 1, maxUnavailable: 0)

## Files
- `fast-update.yaml` - Deployment with aggressive update strategy
- `slow-update.yaml` - Deployment with conservative update strategy

## Strategy Comparison

### Fast Update Strategy
- `maxSurge: 3` - Can create 3 extra Pods during update
- `maxUnavailable: 2` - Allows 2 Pods to be unavailable
- **Result**: Faster updates, more resource usage

### Slow Update Strategy
- `maxSurge: 1` - Only 1 extra Pod during update
- `maxUnavailable: 0` - No Pods unavailable (zero downtime)
- **Result**: Slower updates, guaranteed availability

## Expected Outcome
- Understand how `maxSurge` and `maxUnavailable` affect update speed
- Learn to choose appropriate update strategies for different scenarios
- Observe real-time differences in update behavior

