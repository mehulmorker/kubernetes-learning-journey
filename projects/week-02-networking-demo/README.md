# Week 02 Networking Demo

This project demonstrates Kubernetes Services in a multi-tier setup:

## 🧱 Components
- **Backend Service:** ClusterIP (internal-only)
- **Frontend Service:** NodePort (external access)
- **Sticky Service:** Demonstrates ClientIP session affinity
- **Headless Service:** DNS-based discovery for databases
- **External Service:** Connects to external IPs (e.g., databases)

## 🧩 Run the Demo
```bash
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
minikube service frontend-service
```

## 🎯 Learnings
- Service discovery through DNS
- Load balancing and sticky sessions
- Internal vs. external networking
