# Immutable ConfigMaps and Secrets

This project demonstrates how to create immutable ConfigMaps that cannot be updated once created.

## Exercise Overview

Create an immutable ConfigMap and understand the implications of immutability.

## Files

- `immutable-config.yaml` - Immutable ConfigMap manifest

## Instructions

1. Create the immutable ConfigMap:

   ```bash
   kubectl apply -f immutable-config.yaml
   ```

2. Verify it's created:

   ```bash
   kubectl get configmap immutable-config -o yaml
   ```

3. Try to edit it (this will fail):

   ```bash
   kubectl edit configmap immutable-config
   # Error: field is immutable
   ```

4. Try to update it via YAML (this will also fail):

   ```bash
   # Edit immutable-config.yaml to change VERSION
   kubectl apply -f immutable-config.yaml
   # Error: field is immutable
   ```

5. To update, you must delete and recreate:
   ```bash
   kubectl delete configmap immutable-config
   kubectl apply -f immutable-config.yaml
   ```

## Expected Results

- ConfigMap is created successfully
- Attempts to update fail with "field is immutable" error
- Must delete and recreate to make changes

## Use Cases

Immutable ConfigMaps are useful for:

- Version information
- Release dates
- Build numbers
- Any configuration that should never change
