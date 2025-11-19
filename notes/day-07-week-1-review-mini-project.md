# 🚀 Day 7: Week 1 Review & Mini-Project

Excellent! Time to consolidate everything you've learned this week by building a complete, production-like application!

## Part 1: Week 1 Concepts Review (30 minutes)

Let's quickly review the key concepts before diving into the project.

### Quick Knowledge Check

Answer these mentally (or write down):

**Containers & Docker:**

- What's the difference between an image and a container?
- Why use multi-stage Dockerfiles?

**Pods:**

- Why don't we use bare Pods in production?
- When would you use multi-container Pods?

**Deployments:**

- What's the hierarchy: Deployment → ? → ?
- How do you perform a zero-downtime update?

**Services:**

- What are the 3 main service types and when to use each?
- How does service discovery work via DNS?

**ConfigMaps & Secrets:**

- When to use env vars vs volume mounts?
- What's the difference between ConfigMap and Secret?

**Storage:**

- What's the difference between PV and PVC?
- What are the 3 access modes (RWO, ROX, RWX)?

## Key kubectl Commands Review

```bash
# Pods
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- sh

# Deployments
kubectl get deployments
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# Services
kubectl get svc
kubectl expose deployment <name> --port=80 --target-port=8080

# ConfigMaps & Secrets
kubectl create configmap <name> --from-literal=key=value
kubectl create secret generic <name> --from-literal=key=value

# Storage
kubectl get pv
kubectl get pvc
kubectl get sc

# General
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>
kubectl get all
```

---

## **Part 2: Mini-Project - E-Commerce Microservices Application** (2-3 hours)

### **Project Overview**

You'll build a **3-tier e-commerce application** with:

1. **Frontend** - NGINX serving a static web interface
2. **Backend API** - Node.js REST API for products
3. **Database** - PostgreSQL for data persistence

**Architecture Diagram:**

```
┌─────────────────────────────────────────────┐
│             Internet/Browser                │
└──────────────────┬──────────────────────────┘
                   │
                   ↓ (NodePort 30080)
┌──────────────────────────────────────────────┐
│          Frontend Service (NodePort)         │
│              frontend-service                │
└──────────────┬───────────────────────────────┘
               │
               ↓ Calls backend via DNS
┌──────────────────────────────────────────────┐
│    Frontend Deployment (3 replicas)          │
│           NGINX + Static HTML/JS             │
│      ConfigMap: API_URL, THEME_COLOR         │
└──────────────────────────────────────────────┘
               │
               ↓ HTTP request to backend-service
┌──────────────────────────────────────────────┐
│       Backend Service (ClusterIP)            │
│            backend-service                   │
└──────────────┬───────────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────────┐
│   Backend API Deployment (3 replicas)        │
│         Node.js/Express REST API             │
│   ConfigMap: PORT, LOG_LEVEL                 │
│   Secret: DB_PASSWORD                        │
└──────────────┬───────────────────────────────┘
               │
               ↓ Connects to postgres-service
┌──────────────────────────────────────────────┐
│      Database Service (ClusterIP)            │
│           postgres-service                   │
└──────────────┬───────────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────────┐
│   Database StatefulSet (1 replica)           │
│            PostgreSQL 15                     │
│   Secret: POSTGRES_PASSWORD                  │
│   PVC: postgres-data (5Gi)                   │
└──────────────────────────────────────────────┘
```

## Part 3: Step-by-Step Implementation

### Step 1: Project Setup

```bash
# Create project directory
mkdir -p ~/kubernetes-learning-journey/projects/week-01-mini-project
cd ~/kubernetes-learning-journey/projects/week-01-mini-project

# Create subdirectories
mkdir -p backend frontend k8s-manifests
```

### Step 2: Build the Backend API

See code examples in `code-examples/backend/` directory.

### Step 3: Build the Frontend

See code examples in `code-examples/frontend/` directory.

### Step 4: Create Kubernetes Manifests

See code examples in `code-examples/k8s-manifests/` directory.

### Step 5: Deploy the Application

```bash
cd k8s-manifests

# Create namespace
kubectl apply -f namespace.yaml

# Deploy database (wait for it to be ready)
kubectl apply -f database.yaml

# Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n ecommerce --timeout=120s

# Deploy backend
kubectl apply -f backend.yaml

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend -n ecommerce --timeout=120s

# Deploy frontend
kubectl apply -f frontend.yaml

# Check all resources
kubectl get all -n ecommerce
```

### Step 6: Verify and Test

```bash
# Check all pods are running
kubectl get pods -n ecommerce

# Check services
kubectl get svc -n ecommerce

# Check PVC
kubectl get pvc -n ecommerce

# View logs
kubectl logs -n ecommerce -l app=backend --tail=50
kubectl logs -n ecommerce -l app=postgres --tail=50

# Get frontend URL
echo "Frontend URL: http://$(minikube ip):30080"

# Or use minikube service
minikube service frontend-service -n ecommerce
```

Access the application in your browser!

### Step 7: Test Application Features

#### Test 1: Product Display

- Open browser to http://<minikube-ip>:30080
- Verify products are displayed
- Check server info shows backend hostname

#### Test 2: Backend API directly

```bash
# Get backend pod name
BACKEND_POD=$(kubectl get pod -n ecommerce -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Port-forward to backend
kubectl port-forward -n ecommerce $BACKEND_POD 3000:3000

# In another terminal, test API
curl http://localhost:3000/health
curl http://localhost:3000/api/products
curl http://localhost:3000/api/info
```

#### Test 3: Database Persistence

```bash
# Connect to database
kubectl exec -it -n ecommerce postgres-0 -- psql -U ecommerceuser -d ecommerce

# Inside psql:
\dt                                    # List tables
SELECT * FROM products;                # View products
INSERT INTO products (name, description, price, stock) 
VALUES ('New Product', 'Test product', 99.99, 10);
SELECT * FROM products;
\q

# Delete backend pods (they'll recreate)
kubectl delete pods -n ecommerce -l app=backend

# Refresh browser - new product should still be there!
```

#### Test 4: Scaling

```bash
# Scale backend
kubectl scale deployment backend -n ecommerce --replicas=5

# Watch pods
kubectl get pods -n ecommerce -w

# Scale down
kubectl scale deployment backend -n ecommerce --replicas=2
```

#### Test 5: Rolling Update

```bash
# Update backend image (simulate new version)
# Edit backend/server.js - change version to 1.1.0
# Rebuild image
cd backend
eval $(minikube docker-env)
docker build -t ecommerce-backend:1.1 .

# Update deployment
kubectl set image deployment/backend -n ecommerce backend=ecommerce-backend:1.1

# Watch rollout
kubectl rollout status deployment/backend -n ecommerce

# Verify new version
curl http://$(minikube ip):30080/api/info | jq .version
```

#### Test 6: Configuration Update

```bash
# Update ConfigMap
kubectl edit configmap backend-config -n ecommerce
# Change LOG_LEVEL to "debug"

# Restart backend to pick up changes
kubectl rollout restart deployment/backend -n ecommerce

# Check logs show debug level
kubectl logs -n ecommerce -l app=backend --tail=20
```

### Step 8: Cleanup (Optional)

```bash
# Delete everything
kubectl delete namespace ecommerce

# Or delete individually
kubectl delete -f frontend.yaml
kubectl delete -f backend.yaml
kubectl delete -f database.yaml
kubectl delete -f namespace.yaml
```

## 📝 Project Documentation

See `projects/week-01-mini-project/README.md` for complete documentation.

## 📊 Project Checklist

### **Core Requirements**
- [ ] All 3 tiers deployed successfully
- [ ] Frontend accessible via NodePort
- [ ] Backend API responding to requests
- [ ] Database storing and retrieving data
- [ ] Services communicating via DNS
- [ ] ConfigMaps used for configuration
- [ ] Secrets used for passwords
- [ ] PVC providing persistent storage
- [ ] Multiple replicas for frontend and backend
- [ ] All pods have resource limits

### **Testing Requirements**
- [ ] Can view products in browser
- [ ] Backend API endpoints work
- [ ] Database persistence verified (pod restart doesn't lose data)
- [ ] Scaling up/down works
- [ ] Rolling update completes successfully
- [ ] Rollback works
- [ ] Health checks functioning
- [ ] Configuration updates applied

### **Documentation Requirements**
- [ ] README.md created
- [ ] Architecture diagram included
- [ ] Deployment steps documented
- [ ] Testing procedures documented
- [ ] Screenshots taken
- [ ] Code committed to GitHub

---

## **🎯 Bonus Challenges** (Optional)

If you finish early and want to go further:

### **Challenge 1: Add a Cache Layer**

Add Redis between frontend and backend. See `code-examples/k8s-manifests/redis.yaml` for example.

### **Challenge 2: Add Monitoring Dashboard**

Create a simple monitoring pod. See `code-examples/k8s-manifests/monitoring.yaml` for example.

### **Challenge 3: Add Init Container**

Add an init container to backend that waits for database. See `code-examples/k8s-manifests/backend-init-container.yaml` for example.

### **Challenge 4: Multi-Environment Setup**

Create dev, staging, and prod namespaces with different configurations.

### **Challenge 5: Add a Job for Database Backup**

See `code-examples/k8s-manifests/backup-job.yaml` for example.

---

## **🐛 Troubleshooting Guide**

### **Problem: Pods not starting**

```bash
# Check pod status
kubectl get pods -n ecommerce

# Describe pod to see events
kubectl describe pod <pod-name> -n ecommerce

# Check logs
kubectl logs <pod-name> -n ecommerce

# Common issues:
# - ImagePullBackOff: Image not found (check imagePullPolicy: Never)
# - CrashLoopBackOff: Container crashing (check logs)
# - Pending: Resource constraints or PVC issues
```

### **Problem: Backend can't connect to database**

```bash
# Check if database pod is running
kubectl get pods -n ecommerce -l app=postgres

# Check database logs
kubectl logs -n ecommerce postgres-0

# Test connectivity from backend pod
kubectl exec -it -n ecommerce <backend-pod> -- sh
# Inside pod:
ping postgres-service
nslookup postgres-service.ecommerce.svc.cluster.local
wget -O- postgres-service:5432  # Should connect even if rejected
```

### **Problem: Frontend not showing data**

```bash
# Check browser console for errors
# Check if API_URL is correct in config

# Test backend directly
kubectl port-forward -n ecommerce svc/backend-service 3000:3000
curl http://localhost:3000/api/products

# Check frontend logs
kubectl logs -n ecommerce -l app=frontend

# Verify ConfigMap is mounted
kubectl exec -n ecommerce <frontend-pod> -- cat /usr/share/nginx/html/config.js
```

### **Problem: PVC not binding**

```bash
# Check PVC status
kubectl get pvc -n ecommerce

# Check PV status
kubectl get pv

# Check events
kubectl describe pvc postgres-pvc -n ecommerce

# Solution: Ensure StorageClass exists
kubectl get sc
# If needed, create PV manually or check StorageClass provisioner
```

### **Problem: Service not accessible**

```bash
# Check service endpoints
kubectl get endpoints -n ecommerce

# If endpoints are empty, selector doesn't match pods
kubectl get pods -n ecommerce --show-labels
kubectl describe svc <service-name> -n ecommerce

# Check if pods are ready
kubectl get pods -n ecommerce
# STATUS should be Running, READY should show 1/1
```

---

## **📸 Expected Results**

When everything is working, you should see:

**kubectl get all -n ecommerce output:**

```
NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-xxx                 1/1     Running   0          5m
pod/backend-yyy                 1/1     Running   0          5m
pod/backend-zzz                 1/1     Running   0          5m
pod/frontend-aaa                1/1     Running   0          5m
pod/frontend-bbb                1/1     Running   0          5m
pod/frontend-ccc                1/1     Running   0          5m
pod/postgres-0                  1/1     Running   0          10m

NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/backend-service    ClusterIP   10.96.x.x        <none>        3000/TCP       5m
service/frontend-service   NodePort    10.96.y.y        <none>        80:30080/TCP   5m
service/postgres-service   ClusterIP   None             <none>        5432/TCP       10m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend    3/3     3            3           5m
deployment.apps/frontend   3/3     3            3           5m

NAME                       READY   AGE
statefulset.apps/postgres  1/1     10m
```

**Browser view:**
- Clean, gradient background
- Product cards displayed in grid
- Server info showing backend hostname
- All products loaded from database
- No console errors

---

## **✅ Week 1 Final Checklist**

Before moving to Week 2, verify you can:

### **Conceptual Understanding**
- [ ] Explain why we use containers
- [ ] Describe Kubernetes architecture
- [ ] Explain the Pod lifecycle
- [ ] Understand Deployment vs ReplicaSet vs Pod
- [ ] Explain how Services work
- [ ] Understand service discovery via DNS
- [ ] Differentiate ConfigMaps and Secrets
- [ ] Explain persistent storage in Kubernetes

### **Practical Skills**
- [ ] Build Docker images
- [ ] Write Dockerfiles
- [ ] Create Pod YAML manifests
- [ ] Create Deployment YAML manifests
- [ ] Create Service YAML manifests
- [ ] Use ConfigMaps and Secrets
- [ ] Configure PVC and PV
- [ ] Use kubectl commands confidently
- [ ] Debug pod issues
- [ ] Perform rolling updates
- [ ] Scale deployments
- [ ] View logs and describe resources

### **Project Completion**
- [ ] 3-tier application deployed
- [ ] All components communicating
- [ ] Data persisting across restarts
- [ ] Scaling working
- [ ] Updates working
- [ ] Documentation complete
- [ ] Code in GitHub
- [ ] Screenshots taken

---

## **📚 Week 1 Summary - What You've Learned**

Congratulations! In just one week, you've learned:

### **Technologies Mastered**
✅ **Docker** - Containerization, Dockerfiles, images, layers
✅ **Kubernetes Core** - Architecture, components, objects
✅ **Pods** - Smallest unit, multi-container patterns
✅ **Deployments** - Self-healing, scaling, rolling updates
✅ **Services** - ClusterIP, NodePort, LoadBalancer, DNS
✅ **ConfigMaps** - Configuration management
✅ **Secrets** - Sensitive data handling
✅ **Volumes** - Persistent storage, PV, PVC, StorageClass
✅ **kubectl** - Command-line mastery

### **Real-World Skills Gained**
✅ Deploy production-like applications
✅ Configure multi-tier architectures
✅ Manage application configuration
✅ Implement persistent storage
✅ Perform zero-downtime updates
✅ Debug Kubernetes applications
✅ Use service discovery
✅ Implement health checks

### **Projects Completed**
✅ Multiple single-component deployments
✅ Multi-tier e-commerce application
✅ Stateful database deployment
✅ Full CI/CD workflow (build → deploy → test)

---

## **🎓 Reflection Questions**

Take a moment to reflect:

1. **What concept was hardest to understand?**
   - How did you overcome it?

2. **What surprised you most about Kubernetes?**
   - Was it simpler or more complex than expected?

3. **What real-world problem could you solve now?**
   - Think of a project at work or personal use case

4. **What are you most excited to learn next?**
   - Week 2 covers organization, advanced workloads, and more!

---

## **🔜 Preview: Week 2**

Next week, you'll level up with:

**Days 8-14 Focus:**
- **Labels & Selectors** - Advanced organization patterns
- **Namespaces** - Multi-tenancy and isolation
- **DaemonSets** - Run pods on every node
- **StatefulSets** - Advanced stateful applications
- **Jobs & CronJobs** - Batch processing
- **Advanced ConfigMaps & Secrets** - Complex patterns

**Week 2 Project:**
- Production-ready multi-environment setup
- Scheduled backups with CronJobs
- Log collection with DaemonSets
- Complex application with 5+ components

---

## **🎉 Celebrate Your Progress!**

You've accomplished a LOT in one week:

- ✅ Set up complete Kubernetes environment
- ✅ Learned 8+ core concepts
- ✅ Built and deployed real applications
- ✅ Gained practical DevOps skills
- ✅ Created portfolio-worthy project

**Before Week 2:**
1. Commit everything to GitHub
2. Update your README.md progress tracker
3. Add screenshots to your project
4. Write a LinkedIn post about your learning (optional!)
5. Take a day to review if needed

---

## **📝 Action Items**

Complete these before starting Week 2:

### **Required:**
- [ ] Project fully deployed and tested
- [ ] All YAML manifests in GitHub
- [ ] README.md documentation complete
- [ ] Screenshots of running application
- [ ] Update main README.md progress tracker
- [ ] Review Week 1 concepts (30 minutes)

### **Optional but Recommended:**
- [ ] Try bonus challenges
- [ ] Experiment with breaking and fixing things
- [ ] Deploy a second application from scratch
- [ ] Share your progress on social media
- [ ] Join Kubernetes Slack community
- [ ] Read ahead for Week 2 topics

---

## **🆘 Getting Help**

If you're stuck or have questions:

1. **Review official docs**: https://kubernetes.io/docs/
2. **Check logs**: `kubectl logs` and `kubectl describe`
3. **Community**: Kubernetes Slack, Reddit r/kubernetes
4. **Stack Overflow**: Tag your questions with [kubernetes]
5. **Ask me**: Document your issue and we'll troubleshoot together!

---

## **💪 You're Ready for Week 2!**

You now have a **solid foundation** in Kubernetes. Week 2 will build on this with:
- More sophisticated application patterns
- Better organization and isolation
- Specialized workload types
- Production best practices

**When you're ready, say:**
- ✅ **"Week 1 complete, ready for Week 2"** - Start fresh with Day 8
- ❓ **"I have questions about..."** - Let's clarify anything
- 🔄 **"I want to practice more"** - I'll create additional exercises
- 🎯 **"Show me Day 8 preview"** - See what's coming next

---

**How did your mini-project go? Did you successfully deploy the e-commerce application? Any challenges or questions?**

Share your GitHub repo link when ready - I'd love to see what you've built! 🚀

