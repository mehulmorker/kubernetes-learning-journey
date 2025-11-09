# Day 4: Services - Kubernetes Networking

Today we'll solve a critical problem: how to reliably access your Pods.

---

## 📘 Table of Contents
1. [Part 1: The Problem - Why Services?](#part-1-the-problem---why-services)
2. [Part 2: Service Basics](#part-2-service-basics)
3. [Part 3: ClusterIP Service](#part-3-clusterip-service)
4. [Part 4: NodePort Service](#part-4-nodeport-service)
5. [Part 5: LoadBalancer Service](#part-5-loadbalancer-service)
6. [Part 6: Service Discovery & DNS](#part-6-service-discovery--dns)
7. [Part 7: Endpoints & Session Affinity](#part-7-endpoints--session-affinity)
8. [Homework](#homework)
9. [Checklist](#day-4-checklist)
10. [Key Concepts](#key-concepts)
11. [Next Steps](#whats-next)

---

## Part 1: The Problem - Why Services?

### 🧩 The Pod IP Problem
```bash
kubectl get pods -o wide
POD_NAME=$(kubectl get pods -l app=node-demo -o jsonpath='{.items[0].metadata.name}')
POD_IP=$(kubectl get pod $POD_NAME -o jsonpath='{.status.podIP}')
echo "Pod IP: $POD_IP"
kubectl delete pod $POD_NAME
sleep 5
NEW_POD_NAME=$(kubectl get pods -l app=node-demo -o jsonpath='{.items[0].metadata.name}')
NEW_POD_IP=$(kubectl get pod $NEW_POD_NAME -o jsonpath='{.status.podIP}')
echo "New Pod IP: $NEW_POD_IP"
```

Pod IPs change dynamically when Pods are recreated. That makes it impossible for clients or other services to reliably connect.

```javascript
const podIpProblems = {
  dynamic: "Pod IPs change when Pods restart",
  scaling: "How to balance traffic across 10 Pods?",
  discovery: "How do other services find your app?",
  ephemeral: "Pods come and go, IPs are temporary",
  noLoadBalancing: "No built-in traffic distribution"
};
```

**🎯 Solution:** Kubernetes Services provide a stable IP and DNS name to access dynamic Pods.

---

## Part 2: Service Basics

### 🔍 What is a Service?
A **Service** is a stable network abstraction that routes traffic to a set of Pods.

Service Types:
- **ClusterIP** (default) – Internal access only within the cluster  
- **NodePort** – Exposes app externally via each Node’s IP and a static port  
- **LoadBalancer** – Integrates with cloud load balancers  
- **ExternalName** – Maps to external DNS name

---

## Part 3: ClusterIP Service

ClusterIP = Internal-only communication within cluster.

**Declarative YAML**
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
    app: node-demo
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
```

**Test it**
```bash
kubectl run test-pod --image=alpine --rm -it -- sh
apk add --no-cache curl
curl http://node-app-service:80
```

**DNS Naming Convention**
```
<service-name>.<namespace>.svc.cluster.local
```

---

## Part 4: NodePort Service

NodePort exposes a Service externally on a static port (30000–32767).

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
  - port: 80
    targetPort: 3000
    nodePort: 30080
    protocol: TCP
```
```bash
kubectl apply -f service-nodeport.yaml
minikube service node-app-nodeport
```

---

## Part 5: LoadBalancer Service

Used for cloud load balancing (Minikube simulates this).

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
minikube tunnel
kubectl get svc node-app-lb
minikube service node-app-lb
```

---

## Part 6: Service Discovery & DNS

### Backend Deployment
```yaml
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

### Frontend Deployment
```yaml
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

**Test**
```bash
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
curl http://$(minikube ip):30081
```

---

## Part 7: Endpoints & Session Affinity

**Sticky Sessions Example**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  selector:
    app: node-demo
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  ports:
  - port: 80
    targetPort: 3000
```

---

## Homework
- Create Multi-Port, Headless, and ExternalName services  
- Build a 3-tier app (Frontend → Backend → DB)  
- Debug broken selectors

---

## Day 4 Checklist
✅ Explain why Pods need Services  
✅ Understand ClusterIP, NodePort, LoadBalancer  
✅ Create Services declaratively  
✅ Use service discovery via DNS  
✅ Understand Endpoints and Affinity  
✅ Debug connectivity

---

## Key Concepts
```javascript
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

## What's Next
Day 5 → **ConfigMaps & Secrets**
Manage configuration and sensitive data in Kubernetes properly.
