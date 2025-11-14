# Day 3: Deployments - Production-Ready Applications

Excellent! Today we'll learn why Pods alone aren't enough and how Deployments solve real-world problems.

## Part 1: Why Not Just Pods? (10 minutes)

### The Problem with Bare Pods

Let's demonstrate:

```bash
# Create a Pod
kubectl run my-pod --image=node-k8s-demo:v1 --image-pull-policy=Never

# Check it's running
kubectl get pods

# Now delete it (simulating a crash)
kubectl delete pod my-pod

# Check again
kubectl get pods
# It's gone! No automatic recovery!
```

Real-world scenarios where Pods fail:

```javascript
// Problems you'll face in production:
const productionProblems = {
  podCrashes: "App crashes, Pod dies, no auto-restart",
  nodeFailure: "Server dies, all Pods on it are lost",
  scaling: "Need 10 copies? Create 10 Pods manually?",
  updates: "How to update without downtime?",
  rollback: "New version broken? Manually recreate old Pods?",
  selfHealing: "No automatic recovery"
};
```

**Enter Deployments!** They manage Pods for you with:
- ✅ Desired state management
- ✅ Automatic Pod replacement
- ✅ Scaling (horizontal)
- ✅ Rolling updates
- ✅ Rollback capability
- ✅ Version history

---

## **Part 2: Your First Deployment (20-30 minutes)**

### **Understanding the Hierarchy**

```
Deployment (manages)
    ↓
ReplicaSet (ensures N replicas)
    ↓
Pods (actual running containers)
```

### Method 1: Imperative (Quick Start)

Make sure you're using minikube's Docker:

```bash
# Set Docker environment
eval $(minikube docker-env)

# Rebuild image if needed
cd ~/node-k8s-demo
docker build -t node-k8s-demo:v1 .

# Create a Deployment with 3 replicas
kubectl create deployment node-app --image=node-k8s-demo:v1 --replicas=3

# Watch it create Pods
kubectl get deployments
kubectl get replicasets
kubectl get pods

# See the naming convention:
# node-app-<replicaset-id>-<pod-id>
```

### Explore the Deployment:

```bash
# Detailed view
kubectl describe deployment node-app

# See all resources
kubectl get all

# Notice:
# - 1 Deployment
# - 1 ReplicaSet
# - 3 Pods (all running)
```

### Method 2: Declarative (Production Way)

Create deployment.yaml:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-deployment
  labels:
    app: node-demo
spec:
  replicas: 3                    # Desired number of Pods
  selector:
    matchLabels:
      app: node-demo              # Must match Pod labels
  template:                       # Pod template
    metadata:
      labels:
        app: node-demo            # Pod labels
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
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

### Understanding the structure:

```javascript
// Think of it like this:
const deployment = {
  metadata: {
    name: 'node-app-deployment'  // Deployment name
  },
  spec: {
    replicas: 3,                  // How many Pods
    selector: {
      matchLabels: { app: 'node-demo' }  // Find Pods with this label
    },
    template: {                   // Pod blueprint
      metadata: {
        labels: { app: 'node-demo' }     // Label for selector
      },
      spec: {
        containers: [/* container spec */]
      }
    }
  }
};
```

### Apply it:

```bash
# Delete previous deployment first
kubectl delete deployment node-app

# Create from YAML
kubectl apply -f deployment.yaml

# Watch the rollout
kubectl rollout status deployment/node-app-deployment

# Check everything
kubectl get deployments
kubectl get replicasets
kubectl get pods --show-labels
```

## Part 3: Self-Healing in Action (15 minutes)

### Experiment 1: Delete a Pod

```bash
# List Pods
kubectl get pods

# Delete one Pod (copy actual Pod name)
kubectl delete pod node-app-deployment-xxxxx-xxxxx

# Immediately check again
kubectl get pods

# 🎯 Notice: A new Pod is created automatically!
# Kubernetes maintains the desired state (3 replicas)
```

### Experiment 2: Simulate Node Failure

```bash
# Scale up first
kubectl scale deployment node-app-deployment --replicas=5

# Watch all Pods
kubectl get pods -o wide

# Drain a node (simulates maintenance/failure)
# In minikube, there's only one node, but this shows the concept
kubectl get nodes
kubectl drain minikube --ignore-daemonsets --delete-emptydir-data --force

# Pods will be recreated on available nodes
# (In single-node minikube, they'll be pending)

# Uncordon the node
kubectl uncordon minikube

# Pods will start running again
kubectl get pods
```

## Part 4: Scaling (15 minutes)

### Manual Scaling

```bash
# Scale up to 5 replicas
kubectl scale deployment node-app-deployment --replicas=5

# Watch it scale
kubectl get pods -w

# Scale down to 2
kubectl scale deployment node-app-deployment --replicas=2

# Watch Pods terminate
kubectl get pods -w
```

### Declarative Scaling

```bash
# Edit the deployment.yaml
# Change replicas: 3 to replicas: 4

# Apply the change
kubectl apply -f deployment.yaml

# Kubernetes calculates the diff and makes it happen
kubectl get pods
```

### Check Resource Usage

```bash
# See resource usage (requires metrics-server, install if needed)
minikube addons enable metrics-server

# Wait a minute, then:
kubectl top nodes
kubectl top pods
```

## Part 5: Rolling Updates (30 minutes)

This is where Deployments really shine!

### Update Strategy Concepts

```yaml
# In your deployment.yaml, add under spec:
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max extra Pods during update
      maxUnavailable: 1  # Max Pods down during update
```

### Perform a Rolling Update

#### Step 1: Update your application

Modify app.js:

```javascript
app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from Kubernetes v2!',  // Changed!
    version: '2.0.0',                       // Added!
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});
```

#### Step 2: Build new version

```bash
eval $(minikube docker-env)
docker build -t node-k8s-demo:v2 .

# Verify both versions exist
docker images | grep node-k8s-demo
```

#### Step 3: Update the Deployment

```bash
# Method 1: Direct kubectl command
kubectl set image deployment/node-app-deployment node-app=node-k8s-demo:v2

# Watch the rollout in real-time
kubectl rollout status deployment/node-app-deployment

# Method 2: Edit YAML and apply
# Change image: node-k8s-demo:v1 to image: node-k8s-demo:v2
# Then: kubectl apply -f deployment.yaml
```

#### Step 4: Observe the rolling update

```bash
# In one terminal, watch Pods
kubectl get pods -w

# In another terminal, watch the rollout
kubectl rollout status deployment/node-app-deployment

# You'll see:
# 1. New Pod created (v2)
# 2. New Pod becomes Ready
# 3. Old Pod (v1) terminates
# 4. Repeat until all Pods are v2
```

#### Step 5: Verify the update

```bash
# Check deployment
kubectl describe deployment node-app-deployment
# Look for the new image in "Pod Template" section

# Test the application
kubectl port-forward deployment/node-app-deployment 3000:3000

# In another terminal:
curl http://localhost:3000
# Should show "Hello from Kubernetes v2!" and "version": "2.0.0"
```

## Part 6: Rollback (15 minutes)

What if v2 has a bug? Kubernetes makes rollback easy!

### Check Rollout History

```bash
# See all revisions
kubectl rollout history deployment/node-app-deployment

# See specific revision details
kubectl rollout history deployment/node-app-deployment --revision=2
```

### Rollback to Previous Version

```bash
# Rollback to previous version
kubectl rollout undo deployment/node-app-deployment

# Watch it rollback
kubectl rollout status deployment/node-app-deployment

# Verify
kubectl get pods
curl http://localhost:3000  # Should show v1 message again
```

### Rollback to Specific Revision

```bash
# Rollback to a specific revision
kubectl rollout undo deployment/node-app-deployment --to-revision=1

# Check current revision
kubectl rollout history deployment/node-app-deployment
```

## Part 7: Pause & Resume (10 minutes)

Useful when making multiple changes:

```bash
# Pause rollout
kubectl rollout pause deployment/node-app-deployment

# Make multiple changes (they won't apply yet)
kubectl set image deployment/node-app-deployment node-app=node-k8s-demo:v2
kubectl set resources deployment/node-app-deployment -c node-app --limits=cpu=300m,memory=256Mi

# Resume (all changes applied at once)
kubectl rollout resume deployment/node-app-deployment

# Watch the combined rollout
kubectl rollout status deployment/node-app-deployment
```

## 📝 Day 3 Homework (30-40 minutes)

### Exercise 1: Create a Deployment with Labels

```yaml
# Create labeled-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: labeled-app
  labels:
    app: demo
    tier: backend
    environment: development
spec:
  replicas: 4
  selector:
    matchLabels:
      app: demo
      tier: backend
  template:
    metadata:
      labels:
        app: demo
        tier: backend
        environment: development
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
```

```bash
kubectl apply -f labeled-deployment.yaml

# Practice label queries
kubectl get deployments --show-labels
kubectl get pods -l tier=backend
kubectl get pods -l environment=development
kubectl get all -l app=demo
```

### Exercise 2: Practice Scaling

```bash
# Scale to different values and observe
kubectl scale deployment labeled-app --replicas=6
kubectl get pods

kubectl scale deployment labeled-app --replicas=2
kubectl get pods

kubectl scale deployment labeled-app --replicas=10
kubectl get pods
```

### Exercise 3: Rolling Update Practice

Create 3 versions of your app (v1, v2, v3):

```javascript
// v1: message: "Version 1"
// v2: message: "Version 2"
// v3: message: "Version 3"
```

Build all three:

```bash
eval $(minikube docker-env)
docker build -t node-k8s-demo:v1 .
docker build -t node-k8s-demo:v2 .
docker build -t node-k8s-demo:v3 .
```

Practice updates and rollbacks:

```bash
# Start with v1
kubectl set image deployment/labeled-app node-app=node-k8s-demo:v1

# Update to v2
kubectl set image deployment/labeled-app node-app=node-k8s-demo:v2
kubectl rollout status deployment/labeled-app

# Update to v3
kubectl set image deployment/labeled-app node-app=node-k8s-demo:v3
kubectl rollout status deployment/labeled-app

# Rollback to v2
kubectl rollout undo deployment/labeled-app

# Rollback to v1
kubectl rollout undo deployment/labeled-app --to-revision=1
```

### Exercise 4: Update Strategy Experiment

Create two deployments with different strategies:

```yaml
# fast-update.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fast-update
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 3
      maxUnavailable: 2
  selector:
    matchLabels:
      app: fast
  template:
    metadata:
      labels:
        app: fast
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:v1
        imagePullPolicy: Never
```

```yaml
# slow-update.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-update
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: slow
  template:
    metadata:
      labels:
        app: slow
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:v1
        imagePullPolicy: Never
```

```bash
kubectl apply -f fast-update.yaml
kubectl apply -f slow-update.yaml

# Update both and observe the difference
kubectl set image deployment/fast-update node-app=node-k8s-demo:v2
kubectl set image deployment/slow-update node-app=node-k8s-demo:v2

# Watch both in separate terminals
kubectl get pods -l app=fast -w
kubectl get pods -l app=slow -w
```

### Exercise 5: Debugging Deployments

```bash
# Create a broken deployment
cat > broken-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: broken
  template:
    metadata:
      labels:
        app: broken
    spec:
      containers:
      - name: app
        image: node-k8s-demo:nonexistent-tag
        imagePullPolicy: Never
EOF

kubectl apply -f broken-deployment.yaml

# Debug it using:
kubectl get deployments
kubectl get replicasets
kubectl get pods
kubectl describe deployment broken-app
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Fix it and re-apply
```

## ✅ Day 3 Checklist

Before moving to Day 4, ensure you can:

- [ ] Explain the difference between Pods and Deployments
- [ ] Create Deployments imperatively and declaratively
- [ ] Understand the Deployment → ReplicaSet → Pod hierarchy
- [ ] Scale Deployments up and down
- [ ] Perform rolling updates with zero downtime
- [ ] Rollback to previous versions
- [ ] Configure update strategies (maxSurge, maxUnavailable)
- [ ] Pause and resume rollouts
- [ ] Debug Deployment issues
- [ ] Use labels to organize and query resources

## 🎯 Key Takeaways

```javascript
// Production mindset:
const kubernetesWay = {
  never: "Manually create Pods",
  always: "Use Deployments (or other controllers)",
  because: "Controllers provide self-healing, scaling, and updates",
  remember: "Declare desired state, let Kubernetes make it happen"
};
```

