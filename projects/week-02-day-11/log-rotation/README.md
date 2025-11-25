# Log Rotation CronJob

This project implements automated log rotation using a CronJob to manage log files and prevent disk space issues.

## Overview

The log rotation CronJob:
- Archives logs older than 7 days (compressed with gzip)
- Deletes archived logs older than 30 days
- Reports disk usage
- Runs daily at midnight

## Features

- **Automatic Archival**: Compresses and archives old logs
- **Retention Policy**: Keeps archives for 30 days
- **Disk Usage Reporting**: Shows current disk usage
- **Safe Operation**: Uses `Forbid` concurrency to prevent overlaps

## Usage

### Deploy
```bash
kubectl apply -f log-rotation-cronjob.yaml
```

### Monitor
```bash
# Check CronJob status
kubectl get cronjobs log-rotation
kubectl describe cronjob log-rotation

# View created Jobs
kubectl get jobs -l cronjob=log-rotation

# View logs from latest rotation
LATEST_JOB=$(kubectl get jobs -l cronjob=log-rotation -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -l job-name=$LATEST_JOB
```

### Manual Trigger
```bash
kubectl create job --from=cronjob/log-rotation manual-rotation-$(date +%s)
```

## Configuration

### Current Settings
- **Schedule**: `0 0 * * *` (daily at midnight)
- **Archive Threshold**: 7 days
- **Archive Retention**: 30 days
- **Concurrency**: Forbid (no overlaps)
- **Timeout**: 30 minutes

### Customization

#### Change Schedule
```yaml
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
```

#### Adjust Retention
```yaml
command:
  - sh
  - -c
  - |
    # Archive logs older than 14 days
    find $LOG_DIR -name "*.log" -mtime +14 -type f | ...
    
    # Keep archives for 60 days
    find $ARCHIVE_DIR -name "*.gz" -mtime +60 -delete
```

#### Use PVC Instead of HostPath
```yaml
volumes:
  - name: logs
    persistentVolumeClaim:
      claimName: logs-pvc
```

## Log Directory Structure

```
/logs/
├── app.log
├── error.log
├── access.log
└── archive/
    ├── app.log.20240115.gz
    ├── error.log.20240115.gz
    └── access.log.20240115.gz
```

## Production Considerations

### 1. Use PersistentVolume
Replace `hostPath` with a PVC for persistent storage:
```yaml
volumes:
  - name: logs
    persistentVolumeClaim:
      claimName: logs-pvc
```

### 2. Add Log Shipping
Integrate with log aggregation systems:
```yaml
command:
  - sh
  - -c
  - |
    # Archive logs
    gzip -c $logfile > $ARCHIVE_DIR/${filename}.gz
    
    # Ship to log aggregation
    curl -X POST https://logs.example.com/api/upload \
      -F "file=@$ARCHIVE_DIR/${filename}.gz"
```

### 3. Add Monitoring
Monitor disk usage and rotation success:
```yaml
# Add metrics export
echo "log_rotation_disk_usage_bytes $(du -sb $LOG_DIR | cut -f1)" | \
  curl -X POST http://metrics-service:9091/metrics/job/log-rotation
```

### 4. Handle Large Log Files
For very large log files, consider:
- Rotating by size instead of age
- Using `logrotate` tool
- Streaming logs to external storage

### 5. Security
- Ensure proper file permissions
- Use read-only mounts where possible
- Encrypt archived logs if sensitive

## Alternative: Using logrotate

For more advanced log rotation, use a container with `logrotate`:
```yaml
containers:
  - name: log-rotator
    image: blacklabelops/logrotate
    env:
      - name: LOGS_DIRECTORIES
        value: "/logs"
      - name: LOGROTATE_INTERVAL
        value: "daily"
      - name: LOGROTATE_COPIES
        value: "30"
```

## Troubleshooting

### Check Log Directory
```bash
# If using hostPath, check on the node
kubectl debug node/<node-name> -it --image=busybox
# Then: ls -la /var/log/myapp
```

### Verify Permissions
Ensure the CronJob has proper permissions to read/write logs.

### Check Disk Space
```bash
kubectl exec -it <pod-name> -- df -h /logs
```

### View Rotation History
```bash
kubectl get jobs -l cronjob=log-rotation --sort-by=.metadata.creationTimestamp
```

