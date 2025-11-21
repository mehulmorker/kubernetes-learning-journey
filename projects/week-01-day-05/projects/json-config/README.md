# ConfigMap from JSON/YAML Files

This project demonstrates how to create ConfigMaps from complex JSON configuration files and use them in pods.

## Exercise Overview

Create a ConfigMap from a JSON file and mount it as a volume in a pod.

## Files

- `app-config.json` - Complex JSON configuration file
- `pod-with-json-config.yaml` - Pod manifest using the JSON ConfigMap

## Instructions

1. Create the ConfigMap from JSON file:

   ```bash
   kubectl create configmap app-json-config --from-file=app-config.json
   ```

2. Verify the ConfigMap:

   ```bash
   kubectl get configmap app-json-config -o yaml
   ```

3. Create a pod that uses the ConfigMap:

   ```bash
   kubectl apply -f pod-with-json-config.yaml
   ```

4. Verify the JSON file is mounted:

   ```bash
   kubectl exec json-config-pod -- cat /app/config/app-config.json
   ```

5. Verify the JSON is valid:
   ```bash
   kubectl exec json-config-pod -- cat /app/config/app-config.json | jq .
   ```

## Expected Results

- ConfigMap contains the JSON file as a single key
- Pod has the JSON file mounted at /app/config/app-config.json
- JSON file is accessible and readable in the pod
