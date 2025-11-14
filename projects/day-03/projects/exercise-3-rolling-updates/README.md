# Exercise 3: Rolling Update Practice

## Objective
Practice performing rolling updates and rollbacks with multiple application versions.

## Prerequisites
- Node.js application with multiple versions (v1, v2, v3)
- Docker images built for each version

## Steps

### 1. Build Application Versions

Create three versions of your app:

**v1:**
```javascript
app.get('/', (req, res) => {
  res.json({ message: "Version 1", version: "1.0.0" });
});
```

**v2:**
```javascript
app.get('/', (req, res) => {
  res.json({ message: "Version 2", version: "2.0.0" });
});
```

**v3:**
```javascript
app.get('/', (req, res) => {
  res.json({ message: "Version 3", version: "3.0.0" });
});
```

### 2. Build Docker Images

```bash
eval $(minikube docker-env)
docker build -t node-k8s-demo:v1 .
docker build -t node-k8s-demo:v2 .
docker build -t node-k8s-demo:v3 .
```

### 3. Practice Updates and Rollbacks

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

### 4. Check Rollout History

```bash
kubectl rollout history deployment/labeled-app
kubectl rollout history deployment/labeled-app --revision=1
kubectl rollout history deployment/labeled-app --revision=2
```

## Expected Outcome
- Successfully perform rolling updates between versions
- Understand how Kubernetes maintains service availability during updates
- Practice rollback procedures
- Learn to use rollout history

## Files
- `app-v1.js` - Version 1 of the application
- `app-v2.js` - Version 2 of the application
- `app-v3.js` - Version 3 of the application (create based on pattern)

