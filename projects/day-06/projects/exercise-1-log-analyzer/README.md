# Exercise 1: Multi-Container Pod with Shared Volume

## Objective

Create a Pod where one container writes logs and another analyzes them using a shared `emptyDir` volume.

## Files

- `log-analyzer.yaml`: Pod with web-server and analyzer containers

## Instructions

1. Apply the manifest:

```bash
kubectl apply -f log-analyzer.yaml
```

2. Watch the analyzer logs:

```bash
kubectl logs log-analyzer -c analyzer -f
```

3. Generate some traffic to the web server:

```bash
kubectl port-forward log-analyzer 8080:80
# In another terminal, make requests:
curl http://localhost:8080
```

4. Observe the analyzer processing the logs in real-time.

## Key Concepts

- **emptyDir**: Temporary storage shared between containers in the same Pod
- **readOnly**: Analyzer mounts the volume as read-only for safety
- **Multi-container Pod**: Containers can share volumes within the same Pod

