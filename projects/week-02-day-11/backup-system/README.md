# Comprehensive Backup System

This project implements a comprehensive backup system with both full and incremental backups using CronJobs.

## Overview

The backup system consists of:
1. **Full Backup**: Weekly full backup (Sunday at midnight)
2. **Incremental Backup**: Daily incremental backup (Monday-Saturday at 2 AM)
3. **Persistent Storage**: Uses PVC for backup storage

## Architecture

```
┌─────────────────────────────────────┐
│     Full Backup CronJob             │
│     Schedule: 0 0 * * 0            │
│     (Weekly Sunday midnight)        │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│     Incremental Backup CronJob      │
│     Schedule: 0 2 * * 1-6           │
│     (Daily Mon-Sat at 2 AM)         │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│     PersistentVolumeClaim           │
│     Storage: 10Gi                    │
└─────────────────────────────────────┘
```

## Files

- `backup-pvc.yaml`: Persistent volume claim for backup storage
- `full-backup-cronjob.yaml`: Weekly full backup CronJob
- `incremental-backup-cronjob.yaml`: Daily incremental backup CronJob

## Usage

### 1. Create PVC
```bash
kubectl apply -f backup-pvc.yaml
```

### 2. Deploy Backup CronJobs
```bash
kubectl apply -f full-backup-cronjob.yaml
kubectl apply -f incremental-backup-cronjob.yaml
```

### 3. Verify Deployment
```bash
# Check CronJobs
kubectl get cronjobs

# Check PVC
kubectl get pvc backup-pvc
```

### 4. Monitor Backups
```bash
# View CronJob status
kubectl describe cronjob full-backup
kubectl describe cronjob incremental-backup

# View created Jobs
kubectl get jobs -l cronjob=full-backup
kubectl get jobs -l cronjob=incremental-backup

# View logs from latest backup
kubectl logs -l job-name=$(kubectl get jobs -l cronjob=full-backup -o jsonpath='{.items[-1].metadata.name}')
```

### 5. Manual Trigger (Testing)
```bash
# Trigger full backup manually
kubectl create job --from=cronjob/full-backup manual-full-backup-$(date +%s)

# Trigger incremental backup manually
kubectl create job --from=cronjob/incremental-backup manual-incr-backup-$(date +%s)
```

## Configuration

### Full Backup
- **Schedule**: `0 0 * * 0` (Sunday midnight)
- **History**: Keeps 4 successful, 2 failed
- **Concurrency**: Forbid (no overlaps)
- **Timeout**: 2 hours

### Incremental Backup
- **Schedule**: `0 2 * * 1-6` (Mon-Sat at 2 AM)
- **History**: Keeps 7 successful, 3 failed
- **Concurrency**: Forbid (no overlaps)
- **Timeout**: 1 hour

## Production Considerations

1. **Replace busybox with actual backup tool**:
   - PostgreSQL: `postgres:15-alpine` with `pg_dump`
   - MySQL: `mysql:8` with `mysqldump`
   - Files: `tar` or `rsync`

2. **Add backup verification**:
   - Verify backup integrity
   - Test restore procedures
   - Monitor backup sizes

3. **Implement retention policy**:
   - Delete old backups automatically
   - Keep backups based on policy (e.g., 30 days)

4. **Add monitoring**:
   - Alert on backup failures
   - Monitor backup sizes
   - Track backup duration

5. **Security**:
   - Use Secrets for credentials
   - Encrypt backups
   - Secure backup storage

## Example: PostgreSQL Backup

Replace the busybox command with:
```bash
pg_dump -h $DB_HOST -U $DB_USER $DB_NAME | gzip > $BACKUP_DIR/db-$(date +%Y%m%d-%H%M%S).sql.gz
```

