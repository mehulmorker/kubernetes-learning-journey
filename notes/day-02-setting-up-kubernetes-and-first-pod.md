# Day 2: Setting Up Kubernetes & Your First Pod

Today we install Kubernetes (via Minikube) locally, understand its architecture, and deploy our Node.js container as a Pod. We'll explore imperative and declarative Pod creation, troubleshooting, and multi-container setups.

## Part 1: Install Kubernetes Locally
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

### Start Cluster
```bash
minikube start --driver=docker
kubectl cluster-info
kubectl get nodes
```

---

## Part 2: Kubernetes Architecture Overview

**Control Plane (Master):**
- API Server
- etcd (cluster store)
- Scheduler
- Controller Manager

**Worker Node:**
- Kubelet
- Container Runtime (Docker)
- Kube-proxy

Declarative model: you define desired state, Kubernetes enforces it.

---

## Part 3: Your First Pod

### Imperative Way
```bash
eval $(minikube docker-env)
docker build -t node-k8s-demo:v1 .
kubectl run my-node-pod --image=node-k8s-demo:v1 --port=3000 --image-pull-policy=Never
kubectl get pods
kubectl logs my-node-pod
kubectl exec -it my-node-pod -- sh
kubectl port-forward my-node-pod 3000:3000
```

### Declarative Way
`pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: node-app-pod
  labels:
    app: node-demo
    version: v1
spec:
  containers:
  - name: node-app
    image: node-k8s-demo:v1
    ports:
    - containerPort: 3000
```
```bash
kubectl apply -f pod.yaml
kubectl get pods
kubectl port-forward node-app-pod 3000:3000
```

---

## Part 4: Troubleshooting Pods
```bash
kubectl get pods -o wide
kubectl describe pod <name>
kubectl logs <name>
kubectl get events
```
Statuses: Pending, Running, CrashLoopBackOff, Failed, Succeeded

---

## Part 5: Multi-Container Pods
Pods can run multiple containers (e.g. app + sidecar proxy).

---

## Homework
- Create v1/v2/v3 Pods using labels.
- Practice `kubectl` commands.
- Add resource limits to a Pod.
- Debug issues intentionally.

---

## ✅ Checklist
- Installed Minikube and kubectl
- Created and managed Pods (imperative + declarative)
- Explored Pod lifecycle
- Practiced debugging
