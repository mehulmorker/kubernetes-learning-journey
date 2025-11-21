# Day 4 Homework Exercises

Complete these exercises to master Kubernetes Services.

## Exercise 1: Multi-Port Service

Create a service that exposes multiple ports (HTTP and metrics).

**Files:**
- `multi-port-service.yaml`

**Steps:**
1. Apply the multi-port service
2. Verify both ports are accessible
3. Test connectivity to each port

```bash
kubectl apply -f multi-port-service.yaml
kubectl describe svc multi-port-service
```

## Exercise 2: Headless Service

Create a headless service and verify DNS returns all Pod IPs.

**Files:**
- `headless-service.yaml`
- `test-headless-dns.sh`

**Steps:**
1. Apply the headless service
2. Run DNS lookup from a Pod
3. Verify multiple A records are returned

```bash
kubectl apply -f headless-service.yaml
./test-headless-dns.sh
```

## Exercise 3: Service Without Selector

Create a service that points to an external database.

**Files:**
- `external-service.yaml`

**Steps:**
1. Apply the external service and endpoints
2. Verify the service is created
3. Test connectivity (if external DB is available)

```bash
kubectl apply -f external-service.yaml
kubectl get svc external-db
kubectl get endpoints external-db
```

## Exercise 4: Complete 3-Tier Application

Deploy a complete application with Frontend, Backend, and Database services.

**Architecture:**
```
Frontend (NodePort) 
    ↓
Backend Service (ClusterIP)
    ↓
Database Service (ClusterIP)
```

**Steps:**
1. Create database deployment and service
2. Create backend deployment and service
3. Create frontend deployment and service
4. Verify all services can communicate
5. Test end-to-end connectivity

## Exercise 5: Service Debugging

Practice debugging service connectivity issues.

**Files:**
- `service-debugging.sh`

**Steps:**
1. Create a service with incorrect selector
2. Debug why it has no endpoints
3. Fix the selector
4. Verify endpoints are created

```bash
./service-debugging.sh
```

## Solutions

All solution files are provided in the `code-examples/` directory.

## Verification Checklist

After completing exercises, verify:

- [ ] Multi-port service exposes all ports correctly
- [ ] Headless service returns multiple DNS records
- [ ] External service endpoints are configured
- [ ] 3-tier app components communicate via DNS
- [ ] Can debug and fix service connectivity issues
- [ ] Understand relationship between Services and Endpoints

