# Parallel Batch Processor

This project demonstrates parallel batch processing using Kubernetes Jobs with multiple completions and parallelism.

## Overview

Processes 100 items using 10 parallel workers. Each worker processes a single item with a simulated 10% failure rate.

## Configuration

- **Completions**: 100 (process 100 items)
- **Parallelism**: 10 (up to 10 workers running simultaneously)
- **Restart Policy**: OnFailure (automatic retry on failure)

## Usage

### Deploy
```bash
kubectl apply -f batch-processor.yaml
```

### Monitor Progress
```bash
# Watch job status
kubectl get jobs batch-processor -w

# Watch pods
kubectl get pods -l job-name=batch-processor -w

# Check completion count
kubectl get job batch-processor -o jsonpath='{.status.succeeded}/{.spec.completions}'
```

### View Logs
```bash
# All workers
kubectl logs -l job-name=batch-processor --tail=20

# Specific pod
kubectl logs <pod-name>
```

### Check Status
```bash
# Job details
kubectl describe job batch-processor

# Completion status
kubectl get job batch-processor -o jsonpath='{.status}'
```

## Expected Behavior

- Up to 10 pods run simultaneously
- As each pod completes, a new one starts
- Failed pods are automatically retried (up to backoffLimit)
- Job completes when 100 successful completions are achieved

## Customization

Adjust `completions` and `parallelism` based on:
- Total number of items to process
- Cluster capacity
- Resource requirements per item
- Desired processing speed

