# Exercise 1: Label Organization System

This exercise demonstrates creating a complete labeling scheme for a multi-environment application.

## Files

- `dev-app.yaml` - Development environment deployment (1 replica)
- `staging-app.yaml` - Staging environment deployment (2 replicas)
- `prod-app.yaml` - Production environment deployment (5 replicas)

## Deployment

```bash
# Deploy all environments
kubectl apply -f dev-app.yaml
kubectl apply -f staging-app.yaml
kubectl apply -f prod-app.yaml
```

## Query Exercises

```bash
# Query production deployments
kubectl get deployments -l environment=production

# Query staging and production
kubectl get deployments -l 'environment in (staging,production)'

# Query by team
kubectl get pods -l team=teamA

# Query all app resources
kubectl get all -l app=myapp
```

## Labels Used

- `app`: Application name
- `environment`: Environment (development, staging, production)
- `version`: Application version
- `tier`: Application tier (backend)
- `team`: Team ownership


