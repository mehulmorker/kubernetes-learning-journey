# 🚀 Day 2: Setting Up Kubernetes & Your First Pod

Great! Today we'll get Kubernetes running on your Linux machine and deploy your Node.js app to it.

## Part 1: Install Kubernetes Locally (20-30 minutes)

For local development, we'll use minikube - a single-node Kubernetes cluster perfect for learning.

### Step 1: Install minikube

```bash
# Download minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install it
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify installation
minikube version
```

### Step 2: Install kubectl

kubectl is the Kubernetes command-line tool (like docker CLI, but for Kubernetes).

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install it
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

### Step 3: Start your Kubernetes cluster

```bash
# Start minikube (this may take 2-5 minutes first time)
minikube start --driver=docker

# Verify cluster is running
kubectl cluster-info
kubectl get nodes

# You should see one node (minikube) in "Ready" status
```

**Understanding what just happened:**
- Minikube created a Kubernetes cluster inside a Docker container
- Your cluster has 1 node (in production, you'd have many)
- kubectl is now configured to talk to this cluster

---

## Part 2: Kubernetes Architecture Quick Overview (10 minutes)

Before we deploy, understand the key components:

```
┌─────────────────────────────────────────┐
│         CONTROL PLANE (Master)          │
│  ┌─────────────────────────────────┐    │
│  │ API Server (kubectl talks here) │    │
│  │ etcd (database/state storage)   │    │
│  │ Scheduler (decides where to run)│    │
│  │ Controller Manager (maintains)  │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│          WORKER NODE (minikube)         │
│  ┌─────────────────────────────────┐    │
│  │ Kubelet (runs containers)       │    │
│  │ Container Runtime (Docker)      │    │
│  │ Kube-proxy (networking)         │    │
│  │                                 │    │
│  │  [Your Containers Run Here]     │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

Key concept: You tell the API Server what you want (declarative), and Kubernetes makes it happen.

## Part 3: Your First Pod (30-40 minutes)

### What is a Pod?

- Smallest deployable unit in Kubernetes
- Wraps one or more containers
- Containers in a Pod share network and storage
- Think of it as a "logical host" for your app

### Method 1: Imperative (Quick Test)

First, let's use your Docker image with minikube:

```bash
# Point your Docker CLI to minikube's Docker daemon
# (so minikube can see your locally built images)
eval $(minikube docker-env)

# Rebuild your image (now it's inside minikube)
cd ~/node-k8s-demo  # or wherever you created it
docker build -t node-k8s-demo:v1 .

# Verify image is available
docker images | grep node-k8s-demo
```

Now create a Pod:

```bash
# Create a Pod imperatively
kubectl run my-node-pod --image=node-k8s-demo:v1 --port=3000 --image-pull-policy=Never

# Check Pod status
kubectl get pods

# Wait until STATUS shows "Running" (might take 10-30 seconds)
kubectl get pods -w  # -w watches for changes (Ctrl+C to exit)
```

Explore your Pod:

```bash
# Get detailed info
kubectl describe pod my-node-pod

# View logs (just like docker logs)
kubectl logs my-node-pod

# Follow logs in real-time
kubectl logs -f my-node-pod

# Execute commands inside the Pod (like docker exec)
kubectl exec -it my-node-pod -- sh
# Inside the container:
# ls
# ps aux
# exit
```

Access your application:

```bash
# Forward a local port to the Pod
kubectl port-forward my-node-pod 3000:3000

# In another terminal, test it:
curl http://localhost:3000
curl http://localhost:3000/health

# Notice the hostname is now the Pod name!
```

### Method 2: Declarative (The Kubernetes Way)

In Kubernetes, we define resources in YAML files. Let's create one:

Create `pod.yaml`:

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
    imagePullPolicy: Never
    ports:
    - containerPort: 3000
    env:
    - name: NODE_ENV
      value: "production"
    - name: PORT
      value: "3000"
```

Understanding the YAML:

```javascript
// Think of it like this JavaScript object:
const pod = {
  apiVersion: 'v1',          // API version to use
  kind: 'Pod',               // Type of resource
  metadata: {
    name: 'node-app-pod',    // Unique name
    labels: {                // Key-value pairs for organization
      app: 'node-demo',
      version: 'v1'
    }
  },
  spec: {                    // Specification/desired state
    containers: [{
      name: 'node-app',
      image: 'node-k8s-demo:v1',
      ports: [{ containerPort: 3000 }],
      env: [
        { name: 'NODE_ENV', value: 'production' }
      ]
    }]
  }
};
```

Apply the YAML:

```bash
# Delete the previous Pod first
kubectl delete pod my-node-pod

# Create Pod from YAML
kubectl apply -f pod.yaml

# Check it
kubectl get pods
kubectl describe pod node-app-pod

# Test it
kubectl port-forward node-app-pod 3000:3000
# In another terminal: curl http://localhost:3000
```

## Part 4: Pod Lifecycle & Troubleshooting (20 minutes)

### Understanding Pod States:

```bash
# Get Pod with more details
kubectl get pods -o wide

# Common statuses:
# Pending    - Waiting to be scheduled
# Running    - All containers running
# Succeeded  - Completed successfully (for Jobs)
# Failed     - Container exited with error
# CrashLoopBackOff - Container keeps crashing
```

### Hands-on: Break and Fix

#### Exercise 1: Wrong image name

```yaml
# Create broken-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod
spec:
  containers:
  - name: app
    image: node-k8s-demo:wrong-tag  # Wrong tag!
    imagePullPolicy: Never
```

```bash
kubectl apply -f broken-pod.yaml
kubectl get pods  # Status: ImagePullBackOff or ErrImagePull
kubectl describe pod broken-pod  # See the error in Events section
kubectl delete pod broken-pod
```

#### Exercise 2: Container crashes

Modify your app.js temporarily:

```javascript
// Add this at the top of app.js
if (process.env.CRASH === 'true') {
  throw new Error('Intentional crash!');
}
```

Rebuild and create a crashing Pod:

```bash
eval $(minikube docker-env)
docker build -t node-k8s-demo:crash .

# Create crash-pod.yaml
cat > crash-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: crash-pod
spec:
  containers:
  - name: app
    image: node-k8s-demo:crash
    imagePullPolicy: Never
    env:
    - name: CRASH
      value: "true"
EOF

kubectl apply -f crash-pod.yaml
kubectl get pods  # Status: CrashLoopBackOff
kubectl logs crash-pod  # See the error
kubectl describe pod crash-pod  # See restart count
kubectl delete pod crash-pod
```

Key Learning: Kubernetes automatically tries to restart crashed containers!

## Part 5: Multi-Container Pods (15 minutes)

Pods can have multiple containers (sidecar pattern):

Create `multi-container-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  # Main application
  - name: node-app
    image: node-k8s-demo:v1
    imagePullPolicy: Never
    ports:
    - containerPort: 3000
  
  # Sidecar: nginx reverse proxy
  - name: nginx-sidecar
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/conf.d
  
  volumes:
  - name: nginx-config
    configMap:
      name: nginx-config
```

(We'll fully explore this pattern later, but good to know it exists)

## 📝 Day 2 Homework (20-30 minutes)

### Exercise 1: Create Multiple Pods

Create 3 different Pods with different versions:

```yaml
# pod-v1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: node-app-v1
  labels:
    app: node-demo
    version: v1
spec:
  containers:
  - name: node-app
    image: node-k8s-demo:v1
    imagePullPolicy: Never
    ports:
    - containerPort: 3000
```

Create v2 and v3 similarly (just change names and labels).

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

### Exercise 2: Practice kubectl commands

```bash
# Get Pods in different formats
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json

# Watch Pods (useful for seeing changes)
kubectl get pods -w

# Delete a Pod
kubectl delete pod node-app-v3

# Delete multiple Pods
kubectl delete pod node-app-v1 node-app-v2

# Delete using label selector
kubectl delete pods -l app=node-demo
```

### Exercise 3: Pod with Resource Limits

```yaml
# Create resource-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limited-pod
spec:
  containers:
  - name: node-app
    image: node-k8s-demo:v1
    imagePullPolicy: Never
    ports:
    - containerPort: 3000
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

```bash
kubectl apply -f resource-pod.yaml
kubectl describe pod resource-limited-pod
# Look at the Resources section
```

### Exercise 4: Debugging Practice

```bash
# Create a Pod and intentionally make mistakes
# 1. Wrong image name
# 2. Wrong port
# 3. Missing environment variable

# Practice using:
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events
```

## ✅ Day 2 Checklist

Before moving to Day 3, ensure you can:

- [ ] Start and stop minikube
- [ ] Create Pods imperatively with kubectl run
- [ ] Create Pods declaratively with YAML files
- [ ] View Pod status, logs, and details
- [ ] Port-forward to access Pods locally
- [ ] Understand Pod lifecycle states
- [ ] Debug common Pod issues
- [ ] Use labels to organize and filter Pods

