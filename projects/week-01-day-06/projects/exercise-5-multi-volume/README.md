# Exercise 5: Multiple PVCs in One Pod

## Objective
Create a Pod that uses multiple PersistentVolumeClaims for different purposes.

## Files
- `multi-volume-pod.yaml`: Two PVCs and a Pod using both

## Instructions

1. Apply the manifest:
```bash
kubectl apply -f multi-volume-pod.yaml
```

2. Wait for pod to be ready:
```bash
kubectl wait --for=condition=ready pod multi-volume-pod --timeout=60s
```

3. Check that both PVCs are bound:
```bash
kubectl get pvc
```

You should see:
- `data-pvc` - Bound
- `config-pvc` - Bound

4. Verify the pod is writing to both volumes:
```bash
kubectl logs multi-volume-pod -f
```

5. Check data in both volumes:
```bash
# Check data volume
kubectl exec multi-volume-pod -- cat /data/logs.txt

# Check config volume
kubectl exec multi-volume-pod -- cat /config/settings.txt
```

6. Test persistence by deleting and recreating the pod:
```bash
kubectl delete pod multi-volume-pod
kubectl apply -f multi-volume-pod.yaml
kubectl wait --for=condition=ready pod multi-volume-pod --timeout=60s
```

7. Verify data persists in both volumes:
```bash
kubectl exec multi-volume-pod -- cat /data/logs.txt
kubectl exec multi-volume-pod -- cat /config/settings.txt
```

Expected: Both files should contain previous data! 🎯

## Key Concepts
- **Multiple volumes**: A pod can mount multiple PVCs
- **Different mount paths**: Each volume has its own mount path
- **Separate storage**: Data and config are stored separately
- **Independent lifecycle**: Each PVC has its own lifecycle
- **Use cases**: 
  - Separate data and configuration
  - Different access modes for different volumes
  - Different storage classes for different purposes

## Use Cases
- **Data separation**: Logs vs configuration
- **Different access modes**: RWO for data, ROX for config
- **Different storage classes**: Fast storage for data, standard for config
- **Backup strategy**: Backup data volume more frequently than config

## Cleanup
```bash
kubectl delete -f multi-volume-pod.yaml
```


