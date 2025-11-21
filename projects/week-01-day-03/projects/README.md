# Day 3 Projects - Hands-On Exercises

This directory contains all hands-on exercises for Day 3: Deployments.

## Exercises Overview

### Exercise 1: Create a Deployment with Labels
Learn how to create deployments with multiple labels and practice querying resources using label selectors.

**Location:** `exercise-1-labeled-deployment/`

### Exercise 2: Practice Scaling
Practice scaling deployments up and down, observing how Kubernetes manages Pod lifecycle.

**Location:** `exercise-2-scaling/`

### Exercise 3: Rolling Update Practice
Practice performing rolling updates and rollbacks with multiple application versions.

**Location:** `exercise-3-rolling-updates/`

### Exercise 4: Update Strategy Experiment
Compare different rolling update strategies (fast vs slow) and understand their impact on deployments.

**Location:** `exercise-4-update-strategies/`

### Exercise 5: Debugging Deployments
Learn how to debug deployment issues by creating a broken deployment and fixing it.

**Location:** `exercise-5-debugging/`

## Prerequisites

- Kubernetes cluster running (minikube recommended)
- kubectl installed and configured
- Docker images built and available
- Node.js application code (for exercises 3)

## Running Exercises

Each exercise directory contains:
- `README.md` - Detailed instructions
- Required YAML files
- Additional code files (where applicable)

Follow the README in each exercise directory for step-by-step instructions.

## Tips

1. **Start with Exercise 1** - Builds foundational knowledge
2. **Complete exercises in order** - Each builds on previous concepts
3. **Use `kubectl get pods -w`** - Watch resources in real-time
4. **Check logs** - Use `kubectl logs` to debug issues
5. **Clean up** - Delete deployments after each exercise: `kubectl delete deployment <name>`

## Troubleshooting

If you encounter issues:
1. Check deployment status: `kubectl describe deployment <name>`
2. Check Pod status: `kubectl describe pod <name>`
3. Check logs: `kubectl logs <pod-name>`
4. Verify images exist: `docker images | grep node-k8s-demo`
5. Ensure minikube Docker env: `eval $(minikube docker-env)`

