# Day 2 Homework Exercises

This directory contains all the homework exercises from Day 2.

## Exercise 1: Create Multiple Pods

Create 3 different Pods with different versions (v1, v2, v3).

**Files:**
- `pod-v1.yaml`
- `pod-v2.yaml`
- `pod-v3.yaml`

**Commands:**
```bash
kubectl apply -f pod-v1.yaml
kubectl apply -f pod-v2.yaml
kubectl apply -f pod-v3.yaml

# List all Pods
kubectl get pods

# List Pods with labels
kubectl get pods --show-labels

# Filter by label
kubectl get pods -l app=node-demo
kubectl get pods -l version=v1
```

## Exercise 2: Practice kubectl Commands

Practice various kubectl commands to interact with Pods.

**Script:** `kubectl-practice.sh`

**Commands to practice:**
- `kubectl get pods -o wide` - Get Pods with more details
- `kubectl get pods -o yaml` - Get Pods in YAML format
- `kubectl get pods -o json` - Get Pods in JSON format
- `kubectl get pods -w` - Watch Pods for changes
- `kubectl delete pod <name>` - Delete a Pod
- `kubectl delete pods -l app=node-demo` - Delete Pods by label

## Exercise 3: Pod with Resource Limits

Create a Pod with CPU and memory resource limits.

**File:** `resource-pod.yaml`

**Apply and inspect:**
```bash
kubectl apply -f resource-pod.yaml
kubectl describe pod resource-limited-pod
# Look at the Resources section
```

## Exercise 4: Debugging Practice

Practice debugging common Pod issues:
1. Wrong image name
2. Wrong port
3. Missing environment variable

**Debugging commands:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events
```

## Files Location

All YAML files are located in:
- `../code-examples/days-02/pods/` directory

All scripts are located in:
- `../code-examples/days-02/scripts/` directory

