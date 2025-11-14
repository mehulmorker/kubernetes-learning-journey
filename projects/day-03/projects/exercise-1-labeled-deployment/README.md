# Exercise 1: Create a Deployment with Labels

## Objective
Learn how to create a Deployment with multiple labels and practice querying resources using label selectors.

## Steps

1. Create the deployment using the provided YAML file:
   ```bash
   kubectl apply -f labeled-deployment.yaml
   ```

2. Practice label queries:
   ```bash
   # Show all deployments with labels
   kubectl get deployments --show-labels
   
   # Get pods by tier label
   kubectl get pods -l tier=backend
   
   # Get pods by environment label
   kubectl get pods -l environment=development
   
   # Get all resources with app label
   kubectl get all -l app=demo
   ```

## Files
- `labeled-deployment.yaml` - Deployment manifest with multiple labels

## Expected Outcome
- Deployment created with 4 replicas
- All pods have labels: `app=demo`, `tier=backend`, `environment=development`
- Ability to query resources using label selectors

