# Day 5 Cheat Sheet — ConfigMaps & Secrets

## ConfigMaps
- Create from literals:
  `kubectl create configmap app-config --from-literal=PORT=8080 --from-literal=LOG_LEVEL=info`
- From file:
  `kubectl create configmap app-config-from-file --from-file=app.properties`
- From directory:
  `kubectl create configmap app-configs --from-file=configs/`
- Apply YAML:
  `kubectl apply -f configmap.yaml`
- View:
  `kubectl get configmap node-app-config -o yaml`

## Use ConfigMaps
- As env var (single key):
  ```yaml
  env:
  - name: PORT
    valueFrom:
      configMapKeyRef:
        name: node-app-config
        key: PORT
  ```
- Import all keys:
  ```yaml
  envFrom:
  - configMapRef:
      name: node-app-config
  ```
- Mount as volume:
  ```yaml
  volumes:
  - name: config-volume
    configMap:
      name: node-app-config
  ```

## Secrets
- Create from literals:
  `kubectl create secret generic db-credentials --from-literal=username=admin --from-literal=password=SuperSecret123!`
- From files:
  `kubectl create secret generic db-creds --from-file=username=username.txt --from-file=password=password.txt`
- Declarative YAML:
  `kubectl apply -f secret.yaml`
- View (base64):
  `kubectl get secret db-credentials -o yaml`
- Decode:
  `kubectl get secret db-credentials -o jsonpath='{.data.username}' | base64 --decode`

## Use Secrets
- Env var from secret:
  ```yaml
  env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: database-password
  ```
- Import all keys:
  ```yaml
  envFrom:
  - secretRef:
      name: app-secrets
  ```
- Mount secret as files:
  ```yaml
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
  ```

## Updating & Rolling
- Restart deployment to pick env var changes:
  `kubectl rollout restart deployment/node-app-with-config`
- Edit secret:
  `kubectl edit secret app-secrets` (values are base64)
- Replace secret:
  `kubectl create secret generic app-secrets --from-literal=database-password=NewPassword --from-literal=api-key=newkey --dry-run=client -o yaml | kubectl apply -f -`
