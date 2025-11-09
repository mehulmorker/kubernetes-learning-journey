# kubectl Service Commands Cheat Sheet

## Create and Inspect
```bash
kubectl expose deployment node-app --type=ClusterIP --port=80 --target-port=3000
kubectl get svc
kubectl describe svc node-app-service
```

## NodePort Access
```bash
kubectl apply -f service-nodeport.yaml
minikube service node-app-nodeport
```

## LoadBalancer
```bash
kubectl apply -f service-loadbalancer.yaml
minikube tunnel
minikube service node-app-lb
```

## DNS and Discovery
```bash
kubectl run test-pod --image=alpine --rm -it -- sh
apk add --no-cache bind-tools curl
nslookup node-app-service
curl http://node-app-service
```

## Endpoints and Session Affinity
```bash
kubectl get endpoints
kubectl describe svc sticky-service
```