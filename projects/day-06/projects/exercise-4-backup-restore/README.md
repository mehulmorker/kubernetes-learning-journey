# Exercise 4: Backup and Restore

## Objective
Practice backing up PVC data using a Kubernetes Job.

## Files
- `backup-test.yaml`: PVC and Pod with sample data
- `backup-job.yaml`: Job that backs up PVC data to hostPath

## Instructions

1. Create the PVC and data pod:
```bash
kubectl apply -f backup-test.yaml
```

2. Wait for pod to be ready:
```bash
kubectl wait --for=condition=ready pod data-pod --timeout=60s
```

3. Verify data exists:
```bash
kubectl exec data-pod -- cat /data/important.txt
```

4. Create the backup job:
```bash
kubectl apply -f backup-job.yaml
```

5. Wait for job to complete:
```bash
kubectl wait --for=condition=complete job/backup-job --timeout=60s
```

6. Check job logs:
```bash
kubectl logs job/backup-job
```

7. Check backup on minikube node:
```bash
minikube ssh
ls -la /tmp/backups/
cat /tmp/backups/backup.tar.gz  # Should show binary data
exit
```

8. (Optional) Restore from backup:
```bash
# Create a restore job
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: restore-job
spec:
  template:
    spec:
      containers:
      - name: restore
        image: alpine
        command: ["/bin/sh", "-c"]
        args:
          - tar xzf /backup/backup.tar.gz -C /restore &&
            echo "Restore completed" &&
            ls -lh /restore/
        volumeMounts:
        - name: restore
          mountPath: /restore
        - name: backup
          mountPath: /backup
          readOnly: true
      restartPolicy: Never
      volumes:
      - name: restore
        persistentVolumeClaim:
          claimName: restore-test-pvc
      - name: backup
        hostPath:
          path: /tmp/backups
          type: Directory
EOF
```

## Key Concepts
- **Backup strategy**: Use Jobs to backup PVC data
- **readOnly mount**: Mount source data as read-only for safety
- **hostPath for backup**: Store backups on node filesystem (or use cloud storage in production)
- **tar for backup**: Common tool for creating archives
- **Job for one-time tasks**: Jobs are perfect for backup/restore operations

## Production Considerations
- Use cloud storage (S3, GCS, Azure Blob) instead of hostPath
- Implement scheduled backups using CronJob
- Encrypt backups
- Test restore procedures regularly
- Store backups in different regions

## Cleanup
```bash
kubectl delete -f backup-test.yaml
kubectl delete job backup-job
kubectl delete job restore-job 2>/dev/null || true
```


