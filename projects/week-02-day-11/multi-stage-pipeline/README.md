# Multi-Stage Data Pipeline

This project demonstrates a multi-stage data processing pipeline using Kubernetes Jobs.

## Overview

The pipeline consists of two sequential stages:
1. **Stage 1 - Extract**: Extracts data and saves to CSV
2. **Stage 2 - Transform**: Transforms the extracted data

## Files

- `stage1-extract.yaml`: First stage job that extracts data
- `stage2-transform.yaml`: Second stage job that transforms data

## Usage

### Run Stage 1
```bash
kubectl apply -f stage1-extract.yaml
kubectl wait --for=condition=complete job/stage1-extract --timeout=60s
```

### Run Stage 2
```bash
kubectl apply -f stage2-transform.yaml
kubectl wait --for=condition=complete job/stage2-transform --timeout=60s
```

### Check Results
```bash
# View logs from both stages
kubectl logs -l job-name=stage1-extract
kubectl logs -l job-name=stage2-transform
```

## Notes

- In production, you'd use a shared PersistentVolume for data between stages
- Consider using a workflow orchestration tool (Argo Workflows, Tekton) for complex pipelines
- Stage 2 includes an initContainer that waits for stage 1 completion

