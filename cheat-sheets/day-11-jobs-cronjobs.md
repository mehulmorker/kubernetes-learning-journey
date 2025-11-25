# Day 11: Jobs & CronJobs Cheat Sheet

## Jobs - Quick Reference

### Basic Job Structure
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
spec:
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Done"']
      restartPolicy: Never  # CRITICAL: Never or OnFailure
  backoffLimit: 4
```

### Key Job Fields
- `completions`: Number of successful completions needed (default: 1)
- `parallelism`: Number of pods to run simultaneously (default: 1)
- `backoffLimit`: Max retries on failure (default: 6)
- `activeDeadlineSeconds`: Max total time for job
- `ttlSecondsAfterFinished`: Auto-delete after completion
- `suspend`: Pause job execution
- `restartPolicy`: **Never** or **OnFailure** (never Always!)

### Job Completion Patterns

**Single Completion (Default)**
```yaml
spec:
  completions: 1
  parallelism: 1
```

**Multiple Sequential**
```yaml
spec:
  completions: 5
  parallelism: 1  # One at a time
```

**Parallel Execution**
```yaml
spec:
  completions: 10
  parallelism: 3  # 3 at a time
```

**Work Queue (No completions)**
```yaml
spec:
  parallelism: 5  # 5 workers, no completion count
```

## CronJobs - Quick Reference

### Basic CronJob Structure
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: my-cronjob
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: worker
            image: busybox
            command: ['sh', '-c', 'echo "Task"']
          restartPolicy: OnFailure
```

### Cron Schedule Format
```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, Sunday=0)
│ │ │ │ │
* * * * *
```

### Common Cron Schedules
- `"0 2 * * *"` - Daily at 2:00 AM
- `"*/15 * * * *"` - Every 15 minutes
- `"0 */6 * * *"` - Every 6 hours
- `"0 9 * * 1"` - Every Monday at 9:00 AM
- `"0 0 1 * *"` - First day of month at midnight
- `"0 0 * * 1-5"` - Weekdays at midnight
- `"*/5 9-17 * * *"` - Every 5 min, 9 AM to 5 PM

### CronJob Configuration
- `schedule`: Cron expression (required)
- `concurrencyPolicy`: Allow | Forbid | Replace
- `successfulJobsHistoryLimit`: Keep N successful jobs (default: 3)
- `failedJobsHistoryLimit`: Keep N failed jobs (default: 1)
- `startingDeadlineSeconds`: Max delay for missed schedule
- `suspend`: Pause CronJob

## Essential kubectl Commands

### Jobs
```bash
# Create job
kubectl apply -f job.yaml

# List jobs
kubectl get jobs
kubectl get jobs -w  # watch mode

# View job details
kubectl describe job <job-name>

# View job pods
kubectl get pods -l job-name=<job-name>

# View logs
kubectl logs -l job-name=<job-name>

# Check completion status
kubectl get job <job-name> -o jsonpath='{.status.succeeded}'

# Suspend/Resume
kubectl patch job <job-name> -p '{"spec":{"suspend":true}}'
kubectl patch job <job-name> -p '{"spec":{"suspend":false}}'

# Delete job
kubectl delete job <job-name>
```

### CronJobs
```bash
# Create CronJob
kubectl apply -f cronjob.yaml

# List CronJobs
kubectl get cronjobs
kubectl get cj  # shorthand

# View CronJob details
kubectl describe cronjob <name>

# View jobs created by CronJob
kubectl get jobs -l cronjob=<cronjob-name>

# Manually trigger CronJob
kubectl create job --from=cronjob/<name> manual-run-1

# Suspend/Resume
kubectl patch cronjob <name> -p '{"spec":{"suspend":true}}'
kubectl patch cronjob <name> -p '{"spec":{"suspend":false}}'

# Check last schedule time
kubectl get cronjob <name> -o jsonpath='{.status.lastScheduleTime}'

# Delete CronJob
kubectl delete cronjob <name>
```

### Debugging
```bash
# Find failed pods
kubectl get pods --field-selector=status.phase=Failed

# View logs of failed pod
kubectl logs <failed-pod-name>

# Check events
kubectl get events | grep <job-name>

# View active jobs only
kubectl get jobs --field-selector status.successful=0

# View completed jobs
kubectl get jobs --field-selector status.successful=1
```

## Best Practices

### Jobs
✅ **DO:**
- Always set `restartPolicy: Never` or `OnFailure`
- Set appropriate `backoffLimit`
- Use `ttlSecondsAfterFinished` for cleanup
- Set resource limits
- Use `activeDeadlineSeconds` for long-running tasks

❌ **DON'T:**
- Use `restartPolicy: Always` (wrong for Jobs!)
- Forget to set restartPolicy (defaults to Always)
- Create Jobs without resource limits
- Leave completed Jobs forever

### CronJobs
✅ **DO:**
- Use `concurrencyPolicy: Forbid` for resource-intensive tasks
- Keep minimal history (3 successful, 1 failed)
- Test schedule with manual trigger first
- Monitor for failures
- Use descriptive names and labels

❌ **DON'T:**
- Schedule too frequently (causes overhead)
- Allow overlapping runs without Forbid
- Forget to monitor failures
- Use unclear schedule expressions

## Common Patterns

### Database Migration
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  backoffLimit: 2
  activeDeadlineSeconds: 300
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: node:18-alpine
        command: ['npm', 'run', 'migrate']
```

### Scheduled Backup
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: postgres:15-alpine
            command: ['pg_dump', ...]
```

### Parallel Processing
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-processor
spec:
  completions: 100
  parallelism: 10
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: processor
        image: python:3.9-slim
        command: ['python', 'process.py']
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Job never completes | Check restartPolicy, logs, resource limits |
| CronJob not running | Check suspend status, schedule syntax, events |
| Too many failed pods | Check backoffLimit, fix underlying issue |
| Jobs consuming resources | Set ttlSecondsAfterFinished, cleanup old jobs |
| Overlapping CronJob runs | Set concurrencyPolicy: Forbid |

## Quick Decision Tree

**Need to run a task?**
- One-time task → **Job**
- Scheduled task → **CronJob**
- Long-running service → **Deployment** (not Job!)

**Job completion pattern?**
- Single run → `completions: 1, parallelism: 1`
- Multiple items sequentially → `completions: N, parallelism: 1`
- Multiple items in parallel → `completions: N, parallelism: M`
- Work queue → `parallelism: N` (no completions)

**CronJob concurrency?**
- Can overlap → `concurrencyPolicy: Allow` (default)
- Must not overlap → `concurrencyPolicy: Forbid`
- Cancel previous if new starts → `concurrencyPolicy: Replace`

