# Health Check System

This project implements a health check system using CronJobs to periodically verify the health of application services.

## Overview

The health checker runs every 10 minutes and checks:
- Frontend service health
- Backend service health
- Database health (commented example)

## Features

- Periodic health checks (every 10 minutes)
- Checks multiple services
- Exits with non-zero status on failure
- Lightweight resource usage
- History tracking for monitoring

## Usage

### Deploy
```bash
kubectl apply -f health-checker-cronjob.yaml
```

### Monitor
```bash
# Check CronJob status
kubectl get cronjobs health-checker
kubectl describe cronjob health-checker

# View created Jobs
kubectl get jobs -l cronjob=health-checker

# View logs from latest check
LATEST_JOB=$(kubectl get jobs -l cronjob=health-checker -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -l job-name=$LATEST_JOB
```

### Manual Trigger
```bash
kubectl create job --from=cronjob/health-checker manual-check-$(date +%s)
```

### Check Results
```bash
# View all health check jobs
kubectl get jobs -l cronjob=health-checker --sort-by=.metadata.creationTimestamp

# Check if any failed recently
kubectl get jobs -l cronjob=health-checker --field-selector status.successful=0
```

## Configuration

- **Schedule**: `*/10 * * * *` (every 10 minutes)
- **History**: Keeps 6 successful and 6 failed jobs (1 hour)
- **Concurrency**: Allow (can run concurrently)
- **Timeout**: 5 minutes per check
- **Resources**: Minimal (50m CPU, 64Mi memory)

## Customization

### Adjust Schedule
```yaml
spec:
  schedule: "*/5 * * * *"  # Every 5 minutes
  # or
  schedule: "0 * * * *"    # Every hour
```

### Add More Services
```yaml
command:
  - sh
  - -c
  - |
    # Check service 1
    curl -f http://service1/health || exit 1
    
    # Check service 2
    curl -f http://service2/health || exit 1
    
    # Check service 3
    curl -f http://service3/health || exit 1
```

### Database Health Check
Uncomment and configure the database check:
```yaml
# Install postgres client or use appropriate tool
image: postgres:15-alpine
command:
  - sh
  - -c
  - |
    pg_isready -h db-service -p 5432 || exit 1
```

## Integration with Monitoring

### Prometheus Alert
```yaml
# Alert if health check fails
- alert: HealthCheckFailed
  expr: kube_job_status_failed{job_name=~"health-checker-.*"} > 0
  for: 5m
  annotations:
    summary: "Health check failed"
```

### Slack Notification
Use a webhook to send notifications on failure:
```yaml
command:
  - sh
  - -c
  - |
    if ! curl -f http://service/health; then
      curl -X POST $SLACK_WEBHOOK -d '{"text":"Health check failed"}'
      exit 1
    fi
```

## Best Practices

1. **Set appropriate schedule**: Balance between timely detection and resource usage
2. **Use lightweight images**: `curlimages/curl` is minimal
3. **Set timeouts**: Prevent hanging checks
4. **Monitor failures**: Alert on consecutive failures
5. **Keep history**: Useful for debugging and trend analysis

