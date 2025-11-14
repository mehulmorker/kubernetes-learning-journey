#!/bin/bash

# Method 1: From Literal Values
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=SuperSecret123!

# View it (data is base64 encoded)
kubectl get secret db-credentials -o yaml

# Decode the values
kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 --decode
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 --decode

# Method 2: From Files
echo -n 'admin' > username.txt
echo -n 'SuperSecret123!' > password.txt

kubectl create secret generic db-creds-from-file \
  --from-file=username=username.txt \
  --from-file=password=password.txt

# Clean up files
rm username.txt password.txt

# Method 4: TLS Secret (for HTTPS)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.example.com/O=myapp"

kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key

# Clean up
rm tls.key tls.crt

# Method 5: Docker Registry Secret
kubectl create secret docker-registry my-registry-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=myusername \
  --docker-password=mypassword \
  --docker-email=myemail@example.com

