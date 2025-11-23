# Day 9 Homework Exercises

This directory contains all homework exercises for Day 9: Namespaces & Resource Organization.

## Exercise 1: Environment-Based Namespaces

Create complete environment separation with development, staging, and production namespaces.

**Files:**
- `exercise-1-environments.yaml` - Namespace definitions
- `exercise-1-deploy.sh` - Deployment script

**To run:**
```bash
chmod +x exercise-1-deploy.sh
./exercise-1-deploy.sh
```

## Exercise 2: Microservices with Namespaces

Create namespace per microservice and test cross-namespace communication.

**Files:**
- `exercise-2-microservices.yaml` - Complete microservices setup

**To run:**
```bash
kubectl apply -f exercise-2-microservices.yaml

# Test cross-namespace communication
kubectl logs -n user-service test-client
```

## Exercise 3: Resource Quota Management

Create a namespace with tight quotas and test limits.

**Files:**
- `exercise-3-quota-test.yaml` - Namespace with tight quotas
- `exercise-3-test.sh` - Test script

**To run:**
```bash
chmod +x exercise-3-test.sh
./exercise-3-test.sh
```

**Expected results:**
- Test 1: Should fail (exceeds pod quota)
- Test 2: Should fail (no resource specs)
- Test 3: Should succeed (within limits)

## Exercise 4: Complete Multi-Environment Project

Deploy your Week 1 e-commerce project to multiple namespaces.

**Files:**
- `exercise-4-multi-env-deploy.sh` - Multi-environment deployment script

**To run:**
```bash
chmod +x exercise-4-multi-env-deploy.sh
./exercise-4-multi-env-deploy.sh
```

**Note:** If you have existing `k8s-manifests/` directory, it will use those. Otherwise, it creates sample deployments.

## Exercise 5: Namespace Cleanup Script

A management script for namespace operations.

**Files:**
- `../namespace-manager/namespace-manager.sh` - Main script
- `../namespace-manager/README.md` - Detailed documentation

**To run:**
```bash
cd ../namespace-manager
chmod +x namespace-manager.sh
./namespace-manager.sh create my-namespace
```

## General Instructions

1. Make scripts executable: `chmod +x *.sh`
2. Review YAML files before applying
3. Clean up resources after exercises: `kubectl delete ns <namespace>`
4. Use `kubectl get all -n <namespace>` to verify deployments

## Cleanup

To clean up all exercise resources:

```bash
kubectl delete ns development staging production
kubectl delete ns user-service order-service payment-service
kubectl delete ns quota-test
kubectl delete ns ecommerce-dev ecommerce-staging ecommerce-prod
```


