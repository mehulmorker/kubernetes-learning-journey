# Exercise 3: StatefulSet with Persistent Storage

## Objective
Deploy a StatefulSet with persistent storage using `volumeClaimTemplates`.

## Files
- `statefulset-storage.yaml`: Headless Service and StatefulSet with volumeClaimTemplates

## Instructions

1. Apply the manifest:
```bash
kubectl apply -f statefulset-storage.yaml
```

2. Wait for all pods to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=nginx-sts --timeout=120s
```

3. Check PVCs - one per pod:
```bash
kubectl get pvc
```

You should see:
- `www-web-0`
- `www-web-1`
- `www-web-2`

4. Write unique data to each pod:
```bash
for i in 0 1 2; do
  kubectl exec web-$i -- sh -c "echo 'Pod web-$i' > /usr/share/nginx/html/index.html"
done
```

5. Verify each pod has unique data:
```bash
for i in 0 1 2; do
  echo "=== web-$i ==="
  kubectl exec web-$i -- cat /usr/share/nginx/html/index.html
done
```

6. Test persistence by deleting a pod:
```bash
kubectl delete pod web-1
```

7. Wait for pod to be recreated:
```bash
kubectl wait --for=condition=ready pod web-1 --timeout=60s
```

8. Verify data persists:
```bash
kubectl exec web-1 -- cat /usr/share/nginx/html/index.html
```

Expected output: "Pod web-1" - data persisted! 🎯

## Key Concepts
- **volumeClaimTemplates**: Creates a unique PVC for each StatefulSet pod
- **StatefulSet naming**: Pods are named `web-0`, `web-1`, `web-2`
- **PVC naming**: PVCs are named `www-web-0`, `www-web-1`, `www-web-2`
- **Headless Service**: Required for StatefulSet (clusterIP: None)
- **Ordered deployment**: StatefulSet creates pods in order (0, 1, 2)
- **Stable identity**: Each pod maintains its identity and storage across restarts

## Cleanup
```bash
kubectl delete -f statefulset-storage.yaml
```


