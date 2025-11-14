# 🚀 Day 4: Services - Kubernetes Networking

Awesome! Today we'll solve a critical problem: how to reliably access your Pods.

## Part 1: The Problem - Why Services? (10 minutes)

### The Pod IP Problem

Let's demonstrate the issue:

```bash
# Get your running Pods
kubectl get pods -o wide

# Note the IP addresses - they're dynamic!
# Example: 172.17.0.5, 172.17.0.6, 172.17.0.7

# Get a Pod's IP
POD_NAME=$(kubectl get pods -l app=node-demo -o jsonpath='{.items[0].metadata.name}')
POD_IP=$(kubectl get pod $POD_NAME -o jsonpath='{.status.podIP}')
echo "Pod IP: $POD_IP"

# Now delete the Pod
kubectl delete pod $POD_NAME

# Check the new Pod's IP
sleep 5
NEW_POD_NAME=$(kubectl get pods -l app=node-demo -o jsonpath='{.items[0].metadata.name}')
NEW_POD_IP=$(kubectl get pod $NEW_POD_NAME -o jsonpath='{.status.podIP}')
echo "New Pod IP: $NEW_POD_IP"

# 🎯 IP changed! How can clients reliably connect?
```

**Problems with using Pod IPs directly:**

```javascript
// Problems in production:
const podIpProblems = {
  dynamic: "Pod IPs change when Pods restart",
  scaling: "How to balance traffic across 10 Pods?",
  discovery: "How do other services find your app?",
  ephemeral: "Pods come and go, IPs are temporary",
  noLoadBalancing: "No built-in traffic distribution"
};

// Services solve all these problems!
```

---

## Part 2: Service Basics (15 minutes)

### What is a Service?

A Service is a **stable network endpoint** that routes traffic to a set of Pods.

```
┌─────────────────────┐
│      Service        │  ← Stable IP: 10.96.100.50
│   (node-app-svc)    │  ← Stable DNS: node-app-svc.default.svc.cluster.local
└──────────┬──────────┘
           │ Load balances traffic
           ├──────────┬──────────┬──────────┐
           ↓          ↓          ↓          ↓
        Pod-1      Pod-2      Pod-3      Pod-4
     (IP changes) (IP changes) (IP changes)
```

### Service Types

- **ClusterIP** (default) - Internal only, within cluster
- **NodePort** - Exposes on each Node's IP at a static port
- **LoadBalancer** - Cloud load balancer (AWS ELB, GCP LB, etc.)
- **ExternalName** - Maps to an external DNS name

---

## Part 3: ClusterIP Service (20 minutes)

**ClusterIP = Service accessible only within the cluster.**

### Create a Deployment First

```bash
# Ensure you have a deployment running
kubectl get deployments

# If not, create one:
eval $(minikube docker-env)
cd ~/node-k8s-demo
docker build -t node-k8s-demo:v1 .

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: node-demo
  template:
    metadata:
      labels:
        app: node-demo
    spec:
      containers:
      - name: node-app
        image: node-k8s-demo:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
EOF
```

### Method 1: Imperative Service Creation

```bash
# Expose the deployment
kubectl expose deployment node-app --type=ClusterIP --port=80 --target-port=3000

# Check the service
kubectl get services
kubectl get svc  # shorthand

# Describe it
kubectl describe svc node-app
```

**Understanding the output:**

```bash
# You'll see:
# Name:              node-app
# Type:              ClusterIP
# IP:                10.96.xxx.xxx    ← Stable cluster IP
# Port:              80               ← Service port
# TargetPort:        3000             ← Pod port
# Endpoints:         172.17.0.x:3000,... ← Pod IPs
```

### Method 2: Declarative Service (YAML)

Create `service-clusterip.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-app-service
  labels:
    app: node-demo
spec:
  type: ClusterIP
  selector:
    app: node-demo           # Matches Pods with this label
  ports:
  - port: 80                 # Service port
    targetPort: 3000         # Pod port
    protocol: TCP
    name: http
```

**Understanding the structure:**

```javascript
// Think of it like:
const service = {
  metadata: {
    name: 'node-app-service'
  },
  spec: {
    type: 'ClusterIP',        // Service type
    selector: {
      app: 'node-demo'        // Find Pods with this label
    },
    ports: [{
      port: 80,               // External port (Service)
      targetPort: 3000,       // Internal port (Pod)
      protocol: 'TCP'
    }]
  }
};

// Traffic flow:
// Client → Service:80 → (load balanced) → Pod:3000
```

```bash
# Delete previous service
kubectl delete svc node-app

# Apply the YAML
kubectl apply -f service-clusterip.yaml

# Verify
kubectl get svc
kubectl describe svc node-app-service
```

### Test the ClusterIP Service

ClusterIP is only accessible inside the cluster, so let's create a test Pod:

```bash
# Create a temporary Pod for testing
kubectl run test-pod --image=alpine --rm -it -- sh

# Inside the test Pod, install curl:
apk add --no-cache curl

# Test using Service IP
curl http://10.96.xxx.xxx:80  # Use actual Service IP

# Test using DNS name (better!)
curl http://node-app-service:80
curl http://node-app-service.default.svc.cluster.local:80

# Test multiple times - you'll hit different Pods
for i in {1..10}; do curl -s http://node-app-service:80 | grep hostname; done

# Exit the test Pod
exit
```

**DNS Naming Convention:**

```
<service-name>.<namespace>.svc.cluster.local

Examples:
- node-app-service                              (same namespace)
- node-app-service.default                      (explicit namespace)
- node-app-service.default.svc.cluster.local    (fully qualified)
```

---

## Part 4: NodePort Service (20 minutes)

**NodePort = Exposes service on each Node's IP at a static port (30000-32767).**

### Create NodePort Service

Create `service-nodeport.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-app-nodeport
spec:
  type: NodePort
  selector:
    app: node-demo
  ports:
  - port: 80              # Service port (internal)
    targetPort: 3000      # Pod port
    nodePort: 30080       # Node port (external, optional)
    protocol: TCP
```

```bash
# Apply it
kubectl apply -f service-nodeport.yaml

# Check it
kubectl get svc node-app-nodeport
```

**Understanding NodePort:**

```
┌─────────────────────────────────┐
│         Your Machine            │
│                                 │
│  http://localhost:30080         │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│      Minikube Node              │
│                                 │
│    NodePort: 30080              │
│         ↓                       │
│    Service: 80                  │
│         ↓                       │
│    Load Balances                │
│    ↓      ↓      ↓              │
│  Pod:3000 Pod:3000 Pod:3000     │
└─────────────────────────────────┘
```

### Access NodePort Service

```bash
# Get minikube IP
minikube ip

# Access via Node IP and NodePort
curl http://$(minikube ip):30080

# Or use minikube service command (easier)
minikube service node-app-nodeport

# This opens in your browser!
```

**Test load balancing:**

```bash
# Multiple requests - different Pods respond
for i in {1..10}; do 
  curl -s http://$(minikube ip):30080 | grep hostname
done
```

---

## Part 5: LoadBalancer Service (15 minutes)

**LoadBalancer = Cloud provider's load balancer (in minikube, it simulates one).**

### Create LoadBalancer Service

Create `service-loadbalancer.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-app-lb
spec:
  type: LoadBalancer
  selector:
    app: node-demo
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
```

```bash
# Apply it
kubectl apply -f service-loadbalancer.yaml

# Check it
kubectl get svc node-app-lb

# In real cloud (AWS, GCP, Azure), you'd get an external IP
# In minikube, it stays <pending>, but we can still access it
```

### Access LoadBalancer Service (Minikube)

```bash
# Minikube provides a tunnel for LoadBalancer services
minikube tunnel

# In another terminal:
kubectl get svc node-app-lb
# Now you should see EXTERNAL-IP

# Access it
curl http://<EXTERNAL-IP>

# Or use:
minikube service node-app-lb
```

---

## Part 6: Service Discovery & DNS (15 minutes)

### Automatic Service Discovery

Let's create a multi-tier application to see service discovery in action.

**Create a backend service:**

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: node-k8s-demo:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 3000
```

**Create a frontend that calls the backend:**

First, create a new frontend app:

```javascript
// frontend-app.js
const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;

app.get('/', async (req, res) => {
  try {
    // Call backend using Service DNS name!
    const response = await axios.get('http://backend-service:80');
    res.json({
      message: 'Frontend calling backend',
      backendResponse: response.data
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Frontend running on port ${PORT}`);
});
```

```bash
# Install axios
npm install axios

# Build frontend image
eval $(minikube docker-env)
docker build -t frontend-app:v1 -f - . <<EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY frontend-app.js app.js
EXPOSE 3000
CMD ["node", "app.js"]
EOF
```

**Deploy frontend:**

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: frontend-app:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30081
```

```bash
# Apply everything
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# Test the frontend (it calls backend internally)
curl http://$(minikube ip):30081
```

🎯 **Key Learning:** Frontend found backend using just the service name `backend-service`!

---

## Part 7: Endpoints & Session Affinity (15 minutes)

### Understanding Endpoints

```bash
# Services create Endpoints automatically
kubectl get endpoints node-app-service

# Describe them
kubectl describe endpoints node-app-service

# Endpoints = list of Pod IPs that match the selector
```

**Watch Endpoints update dynamically:**

```bash
# In one terminal, watch endpoints
kubectl get endpoints node-app-service -w

# In another, scale the deployment
kubectl scale deployment node-app --replicas=5

# Watch endpoints update in real-time!
```

### Session Affinity (Sticky Sessions)

By default, Services load balance randomly. Sometimes you want sessions to stick to the same Pod:

```yaml
# service-with-affinity.yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  selector:
    app: node-demo
  sessionAffinity: ClientIP      # Sticky sessions based on client IP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600       # 1 hour timeout
  ports:
  - port: 80
    targetPort: 3000
```

```bash
kubectl apply -f service-with-affinity.yaml

# Test - same client hits same Pod
for i in {1..10}; do 
  kubectl run test-$i --image=alpine --rm -it -- wget -qO- http://sticky-service | grep hostname
done
```

---

## 📝 Day 4 Homework (30-40 minutes)

### Exercise 1: Create Multi-Port Service

Some apps expose multiple ports (e.g., HTTP and metrics):

```yaml
# multi-port-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: node-demo
  ports:
  - name: http
    port: 80
    targetPort: 3000
  - name: metrics
    port: 9090
    targetPort: 9090
```

```bash
kubectl apply -f multi-port-service.yaml
kubectl describe svc multi-port-service
```

### Exercise 2: Headless Service

Headless services (ClusterIP: None) don't load balance - they return all Pod IPs:

```yaml
# headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-service
spec:
  clusterIP: None          # Headless!
  selector:
    app: node-demo
  ports:
  - port: 3000
```

```bash
kubectl apply -f headless-service.yaml

# Test DNS - returns all Pod IPs
kubectl run test-pod --image=alpine --rm -it -- sh
apk add --no-cache bind-tools
nslookup headless-service
# You'll see multiple A records (one per Pod)
```

### Exercise 3: Service Without Selector

For external services:

```yaml
# external-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
  - port: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db
subsets:
- addresses:
  - ip: 192.168.1.100    # External database IP
  ports:
  - port: 5432
```

### Exercise 4: Complete 3-Tier Application

Deploy a complete app with proper service discovery:

```
Frontend (NodePort) 
    ↓
Backend Service (ClusterIP)
    ↓
Database Service (ClusterIP)
```

Create 3 deployments and 3 services, connect them using DNS.

### Exercise 5: Service Debugging

```bash
# Create a service pointing to non-existent Pods
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: broken-service
spec:
  selector:
    app: nonexistent
  ports:
  - port: 80
EOF

# Debug it:
kubectl get svc broken-service
kubectl get endpoints broken-service  # Empty!
kubectl describe svc broken-service

# Fix by updating selector to match existing Pods
```

---

## ✅ Day 4 Checklist

Before moving to Day 5, ensure you can:

- [ ] Explain why Pods need Services
- [ ] Understand ClusterIP, NodePort, and LoadBalancer types
- [ ] Create Services imperatively and declaratively
- [ ] Use service discovery with DNS names
- [ ] Understand the relationship between Services and Endpoints
- [ ] Configure session affinity
- [ ] Debug service connectivity issues
- [ ] Connect multi-tier applications using services
- [ ] Access services from inside and outside the cluster

---

## 🎯 Key Concepts

```javascript
// Service patterns to remember:
const servicePatterns = {
  internal: "Use ClusterIP for internal services",
  development: "Use NodePort for local testing",
  production: "Use LoadBalancer for external traffic",
  discovery: "Use DNS names, not IPs",
  selector: "Labels connect Services to Pods",
  endpoints: "Auto-updated list of Pod IPs"
};
```

---

## 🔜 What's Next?

**Day 5 Preview:** You've learned to run apps (Deployments) and expose them (Services). But where do you store configuration and secrets? Tomorrow we'll learn:

- ConfigMaps - External configuration
- Secrets - Sensitive data management
- Environment variables, volume mounts
- Configuration best practices

**Sneak peek:**

```yaml
# Instead of hardcoding:
env:
- name: DATABASE_URL
  value: "postgres://localhost:5432"  # Bad!

# You'll use:
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:  # or secretKeyRef
      name: app-config
      key: database-url
```

Take your time with services - they're crucial for networking! Practice creating different service types and connecting applications.

