# Day 2 Cheat Sheet: Setting Up Kubernetes & Your First Pod

## Installation Commands

### Install Minikube
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version
```

### Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### Start Minikube
```bash
minikube start --driver=docker
kubectl cluster-info
kubectl get nodes
```

## Basic Pod Operations

### Create Pod (Imperative)
```bash
kubectl run <pod-name> --image=<image> --port=<port> --image-pull-policy=Never
```

### Create Pod (Declarative)
```bash
kubectl apply -f <yaml-file>
```

### View Pods
```bash
kubectl get pods                    # Basic list
kubectl get pods -o wide           # More details
kubectl get pods -o yaml           # YAML output
kubectl get pods -o json           # JSON output
kubectl get pods --show-labels     # Show labels
kubectl get pods -l app=<name>     # Filter by label
kubectl get pods -w                # Watch mode
```

### Pod Details
```bash
kubectl describe pod <pod-name>    # Detailed information
kubectl logs <pod-name>            # View logs
kubectl logs -f <pod-name>         # Follow logs
kubectl exec -it <pod-name> -- sh  # Execute command
```

### Port Forwarding
```bash
kubectl port-forward <pod-name> <local-port>:<pod-port>
```

### Delete Pods
```bash
kubectl delete pod <pod-name>                    # Single pod
kubectl delete pod <pod1> <pod2>                 # Multiple pods
kubectl delete pods -l app=<label>               # By label
kubectl delete -f <yaml-file>                    # From file
```

## Pod YAML Structure

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <pod-name>
  labels:
    app: <app-name>
    version: <version>
spec:
  containers:
  - name: <container-name>
    image: <image:tag>
    imagePullPolicy: Never
    ports:
    - containerPort: <port>
    env:
    - name: <VAR_NAME>
      value: "<value>"
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

## Pod States

| State | Description |
|-------|-------------|
| `Pending` | Waiting to be scheduled |
| `Running` | All containers running |
| `Succeeded` | Completed successfully (for Jobs) |
| `Failed` | Container exited with error |
| `CrashLoopBackOff` | Container keeps crashing |
| `ImagePullBackOff` | Cannot pull image |
| `ErrImagePull` | Error pulling image |

## Troubleshooting Commands

```bash
kubectl describe pod <pod-name>    # Check events and status
kubectl logs <pod-name>             # View container logs
kubectl get events                  # View cluster events
kubectl get pods -o wide           # See node assignment
```

## Docker Environment (Minikube)

```bash
eval $(minikube docker-env)        # Point Docker to minikube
docker build -t <image:tag> .      # Build image in minikube
docker images | grep <image>       # Verify image
```

## Key Concepts

### Pod
- Smallest deployable unit in Kubernetes
- Wraps one or more containers
- Containers share network and storage
- Logical host for your app

### Kubernetes Architecture
- **Control Plane**: API Server, etcd, Scheduler, Controller Manager
- **Worker Node**: Kubelet, Container Runtime, Kube-proxy

### Declarative vs Imperative
- **Imperative**: `kubectl run` (quick test)
- **Declarative**: YAML files (production way)

### Labels
- Key-value pairs for organization
- Used for filtering and selection
- Example: `app: node-demo`, `version: v1`

## Resource Limits

```yaml
resources:
  requests:    # Minimum resources needed
    memory: "64Mi"
    cpu: "250m"
  limits:      # Maximum resources allowed
    memory: "128Mi"
    cpu: "500m"
```

## Multi-Container Pods

Pods can contain multiple containers that share:
- Network namespace (same IP)
- Storage volumes
- IPC namespace

Common pattern: Sidecar containers

## Quick Reference

```bash
# Setup
minikube start --driver=docker
eval $(minikube docker-env)

# Create
kubectl apply -f pod.yaml

# Check
kubectl get pods
kubectl describe pod <name>

# Access
kubectl port-forward <pod> 3000:3000

# Debug
kubectl logs <pod>
kubectl exec -it <pod> -- sh

# Cleanup
kubectl delete pod <name>
```

