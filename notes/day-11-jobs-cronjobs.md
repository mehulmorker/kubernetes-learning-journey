# Day 11: Jobs & CronJobs - Batch Processing

Excellent! Today we'll learn about Jobs and CronJobs - Kubernetes controllers designed for running tasks to completion rather than keeping services running forever.

## Part 1: Understanding Batch Workloads (15 minutes)

### The Problem with Deployments for Batch Tasks

```javascript
const deploymentLimitations = {
  alwaysRunning: "Deployments keep pods running forever",
  restarts: "Automatically restarts completed tasks",
  wasteResources: "Consumes resources even after done",
  noCompletion: "No concept of 'finished successfully'",
  
  // Example problems:
  dataProcessing: "Process 1M records and exit",
  backup: "Backup database once and stop",
  migration: "Run migration script to completion",
  cleanup: "Delete old files and finish",
  
  // Deployment would keep restarting these!
};

// Solution: Jobs and CronJobs
const jobBenefits = {
  runToCompletion: "Runs until successful completion",
  tracking: "Tracks completions and failures",
  parallelism: "Can run multiple pods in parallel",
  retries: "Automatic retry on failure",
  cleanup: "Can auto-delete after completion",
  scheduled: "CronJobs run on schedule"
};
```

---

## Part 2: Jobs - Run Once to Completion (30 minutes)

### What is a Job?

A Job creates one or more Pods and ensures they successfully complete. Once completed, the Job is marked as successful.

```
┌─────────────────────────────────────────────┐
│              Job Lifecycle                  │
│                                             │
│  Create Job                                 │
│      ↓                                      │
│  Create Pods                                │
│      ↓                                      │
│  Pods Run                                   │
│      ↓                                      │
│  ✅ Success (exit 0)  OR  ❌ Failure        │
│      ↓                          ↓           │
│  Job Complete           Retry (backoff)     │
│                              ↓              │
│                         Max retries?        │
│                              ↓              │
│                         Job Failed          │
└─────────────────────────────────────────────┘
```

### Creating Your First Job

Create `simple-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-job
spec:
  template:
    spec:
      containers:
      - name: hello
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Job started at $(date)"
          echo "Processing data..."
          sleep 10
          echo "Job completed at $(date)"
          echo "Success!"
      restartPolicy: Never    # Important! Never or OnFailure
  backoffLimit: 4             # Retry up to 4 times on failure
```

```bash
# Create the job
kubectl apply -f simple-job.yaml

# Watch job status
kubectl get jobs
kubectl get jobs -w

# View pods created by job
kubectl get pods -l job-name=hello-job

# Check job details
kubectl describe job hello-job

# View logs
kubectl logs -l job-name=hello-job

# Check completion status
kubectl get job hello-job -o jsonpath='{.status.succeeded}'
```

### Job Completion Patterns

#### Pattern 1: Single Completion (Default)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: single-job
spec:
  completions: 1        # Need 1 successful completion (default)
  parallelism: 1        # Run 1 pod at a time (default)
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Processing item" && sleep 5']
      restartPolicy: Never
```

#### Pattern 2: Multiple Completions (Sequential)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-job
spec:
  completions: 5        # Need 5 successful completions
  parallelism: 1        # Run 1 at a time (sequential)
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Worker started: $HOSTNAME"
          echo "Processing batch..."
          sleep 5
          echo "Batch complete"
      restartPolicy: Never
```

```bash
# Apply multi-completion job
kubectl apply -f multi-job.yaml

# Watch pods being created sequentially
kubectl get pods -l job-name=multi-job -w

# You'll see: 5 pods created one after another
# multi-job-xxxxx (completes)
# multi-job-yyyyy (completes)
# multi-job-zzzzz (completes)
# etc...
```

#### Pattern 3: Parallel Execution

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  completions: 10       # Need 10 total completions
  parallelism: 3        # Run 3 pods in parallel
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Parallel worker: $HOSTNAME"
          TASK_ID=$((RANDOM % 1000))
          echo "Processing task $TASK_ID"
          sleep 10
          echo "Task $TASK_ID complete"
      restartPolicy: Never
```

```bash
# Apply parallel job
kubectl apply -f parallel-job.yaml

# Watch multiple pods running simultaneously
kubectl get pods -l job-name=parallel-job -w

# You'll see: Up to 3 pods running at once
# As each completes, a new one starts
# Until 10 total completions reached
```

#### Pattern 4: Work Queue Pattern

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: work-queue-job
spec:
  # No completions specified - pods pull from queue
  parallelism: 5        # 5 workers pulling from queue
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Worker $HOSTNAME starting"
          # In real scenario: pull items from queue (Redis, RabbitMQ)
          # Process until queue empty
          for i in 1 2 3 4 5; do
            echo "Processing item $i"
            sleep 2
          done
          echo "No more work, exiting"
      restartPolicy: Never
```

## Part 3: Job Configuration Options (25 minutes)

### Retry and Backoff Behavior

Create `retry-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-job
spec:
  backoffLimit: 3             # Retry up to 3 times
  activeDeadlineSeconds: 60   # Total time limit (60 seconds)
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Attempt started"
          # Fail randomly (for testing)
          if [ $((RANDOM % 2)) -eq 0 ]; then
            echo "Simulated failure!"
            exit 1
          else
            echo "Success!"
            exit 0
          fi
      restartPolicy: Never
```

```bash
# Apply retry job
kubectl apply -f retry-job.yaml

# Watch it retry on failure
kubectl get pods -l job-name=retry-job -w

# Check job status
kubectl describe job retry-job

# You'll see backoff delays: 10s, 20s, 40s...
```

### RestartPolicy Options:

```yaml
# Option 1: Never (creates new pod on failure)
restartPolicy: Never
# Pod fails → New pod created → backoffLimit applies

# Option 2: OnFailure (restarts container in same pod)
restartPolicy: OnFailure
# Container fails → Container restarted in same pod → backoffLimit applies
```

### TTL (Time To Live) for Finished Jobs

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ttl-job
spec:
  ttlSecondsAfterFinished: 100  # Delete 100 seconds after completion
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Done" && sleep 5']
      restartPolicy: Never
```

```bash
# Apply TTL job
kubectl apply -f ttl-job.yaml

# Wait for completion
kubectl wait --for=condition=complete job/ttl-job

# Job will auto-delete after 100 seconds
# Check again after 2 minutes:
kubectl get job ttl-job
# Error: not found
```

### Suspending Jobs

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: suspend-job
spec:
  suspend: true    # Job won't create pods until suspend=false
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Running" && sleep 10']
      restartPolicy: Never
```

```bash
# Create suspended job
kubectl apply -f suspend-job.yaml

# No pods created yet
kubectl get pods -l job-name=suspend-job

# Resume job
kubectl patch job suspend-job -p '{"spec":{"suspend":false}}'

# Now pods are created
kubectl get pods -l job-name=suspend-job -w
```

## Part 4: Real-World Job Examples (30 minutes)

### Example 1: Database Migration

Create `db-migration-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  labels:
    app: myapp
    job-type: migration
spec:
  backoffLimit: 2
  activeDeadlineSeconds: 300  # 5 minutes max
  template:
    metadata:
      labels:
        app: myapp
        job-type: migration
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: node:18-alpine
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting database migration..."
          echo "Connecting to database..."
          sleep 2
          
          echo "Running migrations..."
          # In real scenario: npm run migrate, flyway migrate, etc.
          echo "- Creating users table..."
          sleep 2
          echo "- Adding email column..."
          sleep 2
          echo "- Creating indexes..."
          sleep 2
          
          echo "Migration completed successfully!"
        env:
        - name: DB_HOST
          value: "postgres.default.svc.cluster.local"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database-name
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
```

### Example 2: Data Processing

Create `data-processor-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: process-data
spec:
  completions: 10       # Process 10 batches
  parallelism: 3        # 3 workers in parallel
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: processor
        image: python:3.9-slim
        command:
        - python
        - -c
        - |
          import time
          import random
          import os
          
          pod_name = os.environ.get('HOSTNAME', 'unknown')
          print(f"Worker {pod_name} starting...")
          
          # Simulate processing
          batch_id = random.randint(1000, 9999)
          print(f"Processing batch {batch_id}")
          
          for i in range(5):
              print(f"  Processing record {i+1}/5")
              time.sleep(2)
          
          print(f"Batch {batch_id} complete!")
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
```

```bash
# Apply data processor
kubectl apply -f data-processor-job.yaml

# Monitor progress
kubectl get jobs process-data -w

# View logs from all workers
kubectl logs -l job-name=process-data --tail=20

# Check completion
kubectl get job process-data -o jsonpath='{.status.succeeded}/{.spec.completions}'
```

### Example 3: Image Processing

Create `image-processor-job.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: image-list
data:
  images.txt: |
    image1.jpg
    image2.jpg
    image3.jpg
    image4.jpg
    image5.jpg

---
apiVersion: batch/v1
kind: Job
metadata:
  name: image-processor
spec:
  completions: 5        # 5 images to process
  parallelism: 2        # Process 2 at a time
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: processor
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Image processor starting: $HOSTNAME"
          
          # Read image list
          IMAGE=$(head -n $((JOB_COMPLETION_INDEX + 1)) /config/images.txt | tail -n 1)
          
          echo "Processing image: $IMAGE"
          echo "- Resizing..."
          sleep 2
          echo "- Compressing..."
          sleep 2
          echo "- Uploading to storage..."
          sleep 2
          echo "Image $IMAGE processed successfully!"
        env:
        - name: JOB_COMPLETION_INDEX
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
        volumeMounts:
        - name: images
          mountPath: /config
      volumes:
      - name: images
        configMap:
          name: image-list
```

---

## Part 5: CronJobs - Scheduled Tasks (35 minutes)

### What is a CronJob?

A CronJob creates Jobs on a schedule (like Unix cron).

```
┌─────────────────────────────────────────────┐
│           CronJob Schedule                  │
│                                             │
│  CronJob (schedule: "0 2 * * *")           │
│      ↓                                      │
│  Runs daily at 2 AM                         │
│      ↓                                      │
│  Creates Job                                │
│      ↓                                      │
│  Job creates Pod(s)                         │
│      ↓                                      │
│  Pod runs to completion                     │
│      ↓                                      │
│  Wait for next schedule...                  │
└─────────────────────────────────────────────┘
```

### Cron Schedule Format

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday=0)
│ │ │ │ │
* * * * *

Examples:
"0 2 * * *"        - Daily at 2:00 AM
"*/15 * * * *"     - Every 15 minutes
"0 */6 * * *"      - Every 6 hours
"0 9 * * 1"        - Every Monday at 9:00 AM
"0 0 1 * *"        - First day of month at midnight
"30 3 * * 0"       - Every Sunday at 3:30 AM
"0 0 * * 1-5"      - Weekdays at midnight
"*/5 9-17 * * *"   - Every 5 min during business hours
```

### Creating Your First CronJob

Create `simple-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cron
spec:
  schedule: "*/2 * * * *"    # Every 2 minutes
  jobTemplate:               # Template for Jobs
    spec:
      template:              # Template for Pods
        spec:
          containers:
          - name: hello
            image: busybox
            command:
            - /bin/sh
            - -c
            - |
              echo "CronJob execution at $(date)"
              echo "Performing scheduled task..."
              sleep 5
              echo "Task complete!"
          restartPolicy: OnFailure
```

```bash
# Create CronJob
kubectl apply -f simple-cronjob.yaml

# View CronJob
kubectl get cronjobs
kubectl get cj  # shorthand

# Wait a few minutes and check Jobs created
kubectl get jobs

# View logs from latest run
kubectl logs -l job-name=$(kubectl get jobs -l app=hello-cron -o jsonpath='{.items[-1].metadata.name}')

# Describe CronJob
kubectl describe cronjob hello-cron
```

### Real-World CronJob Examples

#### Example 1: Database Backup

Create `backup-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"              # Daily at 2 AM
  successfulJobsHistoryLimit: 3     # Keep last 3 successful jobs
  failedJobsHistoryLimit: 1         # Keep last 1 failed job
  concurrencyPolicy: Forbid         # Don't run if previous still running
  
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: postgres:15-alpine
            command:
            - /bin/sh
            - -c
            - |
              echo "Starting backup at $(date)"
              
              BACKUP_FILE="/backup/postgres-$(date +%Y%m%d-%H%M%S).sql"
              
              echo "Backing up database to $BACKUP_FILE"
              # pg_dump -h $DB_HOST -U $DB_USER $DB_NAME > $BACKUP_FILE
              
              # Simulate backup
              sleep 10
              echo "Sample backup data" > $BACKUP_FILE
              
              echo "Backup completed: $(du -h $BACKUP_FILE)"
              
              # Cleanup old backups (keep last 7 days)
              echo "Cleaning up old backups..."
              find /backup -name "postgres-*.sql" -mtime +7 -delete
              
              echo "Backup job finished at $(date)"
            env:
            - name: DB_HOST
              value: "postgres.default.svc.cluster.local"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: username
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            - name: DB_NAME
              value: "myapp"
            volumeMounts:
            - name: backup
              mountPath: /backup
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: backup-pvc
```

#### Example 2: Cleanup Job

Create `cleanup-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cleanup-old-data
spec:
  schedule: "0 1 * * 0"     # Weekly on Sunday at 1 AM
  successfulJobsHistoryLimit: 2
  failedJobsHistoryLimit: 1
  
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: cleanup
            image: postgres:15-alpine
            command:
            - /bin/sh
            - -c
            - |
              echo "Starting cleanup at $(date)"
              
              echo "Connecting to database..."
              # psql -h $DB_HOST -U $DB_USER -d $DB_NAME <<EOF
              # DELETE FROM logs WHERE created_at < NOW() - INTERVAL '30 days';
              # DELETE FROM temp_data WHERE created_at < NOW() - INTERVAL '7 days';
              # VACUUM ANALYZE;
              # EOF
              
              # Simulate cleanup
              sleep 5
              echo "Deleted old logs"
              sleep 5
              echo "Deleted temp data"
              sleep 5
              echo "Database optimized"
              
              echo "Cleanup completed at $(date)"
            env:
            - name: DB_HOST
              value: "postgres.default.svc.cluster.local"
            - name: DB_USER
              value: "cleanup_user"
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: cleanup-secret
                  key: password
            - name: DB_NAME
              value: "myapp"
```

#### Example 3: Report Generation

Create `report-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-report
spec:
  schedule: "0 8 * * 1-5"    # Weekdays at 8 AM
  
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: report-generator
            image: python:3.9-slim
            command:
            - python
            - -c
            - |
              from datetime import datetime
              import time
              
              print(f"Generating daily report at {datetime.now()}")
              
              print("Fetching data from database...")
              time.sleep(3)
              
              print("Calculating metrics...")
              time.sleep(3)
              
              print("Creating charts...")
              time.sleep(3)
              
              print("Generating PDF...")
              time.sleep(3)
              
              report_file = f"/reports/daily-report-{datetime.now().strftime('%Y%m%d')}.pdf"
              print(f"Report saved to {report_file}")
              
              print("Sending email notification...")
              time.sleep(2)
              
              print("Report generation complete!")
            volumeMounts:
            - name: reports
              mountPath: /reports
          volumes:
          - name: reports
            persistentVolumeClaim:
              claimName: reports-pvc
```

### CronJob Configuration Options

Create `advanced-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: advanced-cron
spec:
  schedule: "*/5 * * * *"
  
  # Concurrency policies
  concurrencyPolicy: Forbid
  # - Allow (default): Multiple jobs can run concurrently
  # - Forbid: Skip new run if previous still running
  # - Replace: Cancel previous and start new
  
  # Starting deadline
  startingDeadlineSeconds: 60
  # If job misses schedule (node down, etc.), 
  # start within 60 seconds or skip
  
  # History limits
  successfulJobsHistoryLimit: 3   # Keep 3 successful
  failedJobsHistoryLimit: 1       # Keep 1 failed
  
  # Suspend
  suspend: false                  # Set true to pause
  
  jobTemplate:
    spec:
      backoffLimit: 3
      activeDeadlineSeconds: 300
      ttlSecondsAfterFinished: 3600  # Delete 1 hour after finish
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: worker
            image: busybox
            command: ['sh', '-c', 'echo "Advanced CronJob" && sleep 10']
```

## Part 6: Testing and Debugging (20 minutes)

### Manually Trigger CronJob

```bash
# Create a Job from CronJob immediately
kubectl create job --from=cronjob/hello-cron manual-run-1

# Check the manually created job
kubectl get job manual-run-1

# View logs
kubectl logs -l job-name=manual-run-1
```

### Suspend/Resume CronJob

```bash
# Suspend CronJob (no new jobs created)
kubectl patch cronjob hello-cron -p '{"spec":{"suspend":true}}'

# Verify suspended
kubectl get cronjob hello-cron

# Resume
kubectl patch cronjob hello-cron -p '{"spec":{"suspend":false}}'
```

### Viewing Job/CronJob History

```bash
# List all jobs created by a CronJob
kubectl get jobs -l cronjob=hello-cron

# View events
kubectl get events --sort-by='.lastTimestamp' | grep hello-cron

# Check last schedule time
kubectl get cronjob hello-cron -o jsonpath='{.status.lastScheduleTime}'

# Check next schedule time (not directly available, but can calculate)
```

### Debugging Failed Jobs

```bash
# Find failed pods
kubectl get pods --field-selector=status.phase=Failed

# Describe failed job
kubectl describe job <failed-job-name>

# View logs of failed pod
kubectl logs <failed-pod-name>

# Check events
kubectl get events | grep <job-name>

# Delete failed job to retry
kubectl delete job <failed-job-name>
```

## 📝 Day 11 Homework (40-50 minutes)

### Exercise 1: Multi-Stage Data Pipeline

Create Jobs that run in sequence:

See `projects/multi-stage-pipeline/` for complete implementation.

### Exercise 2: Parallel Batch Processing

Process 100 items with 10 parallel workers:

See `projects/batch-processor/` for complete implementation.

### Exercise 3: Comprehensive Backup System

See `projects/backup-system/` for complete implementation.

### Exercise 4: Health Check System

See `projects/health-checker/` for complete implementation.

### Exercise 5: Log Rotation CronJob

See `projects/log-rotation/` for complete implementation.

---

## ✅ Day 11 Checklist

Before moving to Day 12, ensure you can:
- [ ] Explain the difference between Job and Deployment
- [ ] Create basic Jobs
- [ ] Understand Job completion patterns (single, multiple, parallel)
- [ ] Configure backoffLimit and activeDeadlineSeconds
- [ ] Use restartPolicy (Never vs OnFailure)
- [ ] Implement TTL for finished Jobs
- [ ] Create CronJobs with proper schedule syntax
- [ ] Understand cron schedule format
- [ ] Configure concurrencyPolicy
- [ ] Set successfulJobsHistoryLimit and failedJobsHistoryLimit
- [ ] Manually trigger Jobs from CronJobs
- [ ] Suspend and resume CronJobs
- [ ] Debug failed Jobs
- [ ] Implement real-world batch processing patterns

---

## 🎯 Key Takeaways

```javascript
const jobAndCronJobBestPractices = {
  jobs: {
    when: "One-time tasks, batch processing, migrations",
    restartPolicy: "Always use Never or OnFailure (never Always)",
    retries: "Set appropriate backoffLimit",
    timeout: "Use activeDeadlineSeconds for long-running tasks",
    cleanup: "Use ttlSecondsAfterFinished to auto-cleanup",
    parallelism: "Use for faster processing of multiple items"
  },
  
  cronJobs: {
    when: "Scheduled tasks, backups, reports, cleanup",
    schedule: "Use cron syntax, test thoroughly",
    concurrency: "Usually use Forbid to prevent overlaps",
    history: "Keep minimal history (3 successful, 1 failed)",
    testing: "Use kubectl create job --from=cronjob for testing",
    monitoring: "Always monitor for failures"
  },
  
  patterns: {
    migration: "Job with backoffLimit=0 (fail fast)",
    dataProcessing: "Job with parallelism and completions",
    backup: "CronJob with Forbid concurrency",
    cleanup: "CronJob with long startingDeadlineSeconds",
    reporting: "CronJob with email notification"
  },
  
  avoid: [
    "Using Deployment for batch tasks",
    "Missing restartPolicy (defaults to Always - wrong!)",
    "No resource limits on Jobs",
    "Forgetting to clean up completed Jobs",
    "Not monitoring CronJob failures",
    "Overlapping CronJob runs without Forbid"
  ]
};
```

---

## 🔍 Debugging Scenarios

### Scenario 1: Job Never Completes

```bash
# Check if pods are running
kubectl get pods -l job-name=<job-name>

# Check logs
kubectl logs -l job-name=<job-name>

# Check for resource constraints
kubectl describe job <job-name>

# Common causes:
# - Missing restartPolicy
# - Infinite loop in container
# - Waiting for external resource
# - Resource limits too low
```

### Scenario 2: CronJob Not Running

```bash
# Check if CronJob is suspended
kubectl get cronjob <name> -o jsonpath='{.spec.suspend}'

# Check schedule syntax
kubectl get cronjob <name> -o jsonpath='{.spec.schedule}'

# Check last schedule time
kubectl get cronjob <name> -o jsonpath='{.status.lastScheduleTime}'

# Check events
kubectl get events --sort-by='.lastTimestamp' | grep <cronjob-name>

# Manually trigger to test
kubectl create job --from=cronjob/<name> test-run
```

### Scenario 3: Too Many Failed Pods

```bash
# Check failed pods
kubectl get pods --field-selector=status.phase=Failed

# View logs of failed pod
kubectl logs <failed-pod-name>

# Check backoffLimit
kubectl get job <job-name> -o jsonpath='{.spec.backoffLimit}'

# Check number of retries
kubectl describe job <job-name>

# Solution: Fix the issue and delete job to retry
kubectl delete job <job-name>
```

---

## 💡 Pro Tips

### Job Optimization

```yaml
# Tip 1: Use completionMode for indexed jobs
apiVersion: batch/v1
kind: Job
metadata:
  name: indexed-job
spec:
  completions: 3
  parallelism: 3
  completionMode: Indexed  # Pods get unique completion index
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: worker
        image: busybox
        command:
        - sh
        - -c
        - |
          # Access index via env var
          echo "Processing task $JOB_COMPLETION_INDEX"
        env:
        - name: JOB_COMPLETION_INDEX
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
```

```yaml
# Tip 2: Use podFailurePolicy for better error handling (K8s 1.25+)
apiVersion: batch/v1
kind: Job
metadata:
  name: smart-retry-job
spec:
  backoffLimit: 6
  podFailurePolicy:
    rules:
    - action: FailJob              # Don't retry on certain errors
      onExitCodes:
        containerName: main
        operator: In
        values: [42]               # Exit code 42 = fail immediately
    - action: Ignore               # Ignore certain exit codes
      onExitCodes:
        operator: In
        values: [1]
```

### CronJob Best Practices

```yaml
# Tip 3: Add metadata for tracking
apiVersion: batch/v1
kind: CronJob
metadata:
  name: tracked-cronjob
  labels:
    app: myapp
    component: backup
    criticality: high
  annotations:
    owner: "platform-team@company.com"
    runbook: "https://wiki.company.com/runbooks/backup"
    oncall: "https://pagerduty.com/backup-alerts"
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    metadata:
      labels:
        app: myapp
        component: backup
    spec:
      template:
        metadata:
          labels:
            app: myapp
            component: backup
        spec:
          # ... rest of spec
```

### Resource Management

```yaml
# Tip 4: Always set resource limits for Jobs
apiVersion: batch/v1
kind: Job
metadata:
  name: resource-aware-job
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: worker
        image: myapp
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
            ephemeral-storage: "2Gi"  # Don't forget storage!
```

---

## 📊 Monitoring Jobs and CronJobs

### Useful kubectl Commands

```bash
# View all Jobs
kubectl get jobs --all-namespaces

# View active Jobs only
kubectl get jobs --field-selector status.successful=0

# View completed Jobs
kubectl get jobs --field-selector status.successful=1

# View CronJob status
kubectl get cronjobs -o wide

# Count running Jobs
kubectl get jobs --field-selector status.active=1 --no-headers | wc -l

# Find Jobs older than 1 day
kubectl get jobs --all-namespaces -o json | \
  jq -r '.items[] | select(.status.completionTime != null) | 
  select((now - (.status.completionTime | fromdateiso8601)) > 86400) | 
  .metadata.name'

# Clean up completed Jobs
kubectl delete jobs --field-selector status.successful=1
```

### Metrics to Monitor

```javascript
const jobMetrics = {
  completion: {
    successRate: "Successful completions / Total runs",
    duration: "Time to completion",
    failureRate: "Failed runs / Total runs"
  },
  
  resource: {
    cpuUsage: "Actual CPU used",
    memoryUsage: "Actual memory used",
    duration: "Total runtime"
  },
  
  cronjob: {
    missedRuns: "Schedules missed due to concurrency/errors",
    lastSuccess: "Time since last successful run",
    consecutiveFailures: "Number of consecutive failures"
  },
  
  alerts: [
    "CronJob hasn't run in expected timeframe",
    "Job failure rate > 10%",
    "Job duration exceeds threshold",
    "Too many concurrent Jobs"
  ]
};
```

---

## 🧪 Advanced Patterns

### Pattern 1: Job Chain (Sequential Jobs)

```yaml
# Use Jobs that wait for previous completion
apiVersion: batch/v1
kind: Job
metadata:
  name: job-step-1
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: step1
        image: busybox
        command: ['sh', '-c', 'echo "Step 1" > /shared/step1.done']
        volumeMounts:
        - name: shared
          mountPath: /shared
      volumes:
      - name: shared
        emptyDir: {}

---
apiVersion: batch/v1
kind: Job
metadata:
  name: job-step-2
spec:
  template:
    spec:
      restartPolicy: Never
      initContainers:
      - name: wait-for-step1
        image: busybox
        command:
        - sh
        - -c
        - |
          while [ ! -f /shared/step1.done ]; do
            echo "Waiting for step 1..."
            sleep 5
          done
        volumeMounts:
        - name: shared
          mountPath: /shared
      containers:
      - name: step2
        image: busybox
        command: ['sh', '-c', 'echo "Step 2 complete"']
        volumeMounts:
        - name: shared
          mountPath: /shared
      volumes:
      - name: shared
        emptyDir: {}
```

### Pattern 2: Dynamic CronJob Schedule

```yaml
# ConfigMap to control schedule
apiVersion: v1
kind: ConfigMap
metadata:
  name: cronjob-schedules
data:
  backup-schedule: "0 2 * * *"
  report-schedule: "0 8 * * 1-5"
  cleanup-schedule: "0 1 * * 0"

# Update CronJob schedule dynamically
# kubectl patch cronjob backup -p \
#   "{\"spec\":{\"schedule\":\"$(kubectl get cm cronjob-schedules -o jsonpath='{.data.backup-schedule}')\"}}"
```

### Pattern 3: Job with Sidecar for Logging

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: job-with-logging
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: main-job
        image: busybox
        command:
        - sh
        - -c
        - |
          for i in 1 2 3 4 5; do
            echo "Processing $i" >> /logs/job.log
            sleep 2
          done
        volumeMounts:
        - name: logs
          mountPath: /logs
      
      - name: log-shipper
        image: busybox
        command:
        - sh
        - -c
        - |
          # Ship logs to external system
          while true; do
            if [ -f /logs/job.log ]; then
              echo "Shipping logs..."
              # curl -X POST logs-service:8080 -d @/logs/job.log
            fi
            sleep 5
          done
        volumeMounts:
        - name: logs
          mountPath: /logs
      
      volumes:
      - name: logs
        emptyDir: {}
```

---

## 📈 Performance Considerations

```javascript
const performanceGuidelines = {
  parallelism: {
    tooLow: "Underutilizes cluster resources",
    tooHigh: "Can overwhelm cluster",
    recommendation: "Start with 1-3x number of nodes",
    monitoring: "Watch for resource contention"
  },
  
  completions: {
    large: "Break into smaller batches",
    example: "Instead of 10000 completions, use 100 batches of 100",
    benefit: "Better observability and failure handling"
  },
  
  resources: {
    requests: "Set based on actual usage",
    limits: "Set slightly higher than requests",
    testing: "Test with production-like data volume",
    monitoring: "Track actual vs requested resources"
  },
  
  cronJob: {
    overlap: "Use Forbid for resource-intensive tasks",
    frequency: "Don't schedule too frequently (causes overhead)",
    startingDeadline: "Set reasonable deadline for missed schedules",
    cleanup: "Keep minimal history (saves etcd space)"
  }
};
```

---

## 🔜 What's Next?

**Day 12 Preview:** Tomorrow we'll dive deeper into **ConfigMaps** with advanced patterns:

- Configuration versioning and rollbacks
- Hot-reloading configurations
- Multi-environment configuration management
- Configuration validation
- Binary data in ConfigMaps
- Immutable ConfigMaps for performance
- ConfigMap generation from files/directories
- Using ConfigMaps with Helm

**Sneak peek:**

```yaml
# Immutable ConfigMap (K8s 1.19+)
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-v2
immutable: true  # Can't be modified, better performance
data:
  app.conf: |
    version: 2.0
    features:
      newUI: true

# ConfigMap with binary data
apiVersion: v1
kind: ConfigMap
metadata:
  name: binary-config
binaryData:
  app.jar: <base64-encoded-binary>
```

---

## 📚 Additional Resources

- [Jobs Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJobs Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Crontab Guru](https://crontab.guru/) - Cron schedule expression tester
- [Job Patterns](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-patterns)

---

## 🎓 Summary

Today you learned:

✅ **Jobs** - Run tasks to completion
  - Single and multiple completions
  - Parallel execution
  - Retry logic with backoff
  - TTL for auto-cleanup

✅ **CronJobs** - Scheduled batch processing
  - Cron schedule syntax
  - Concurrency policies
  - History management
  - Manual triggering

✅ **Real-world patterns** - Database backups, data processing, cleanup tasks, report generation

✅ **Debugging** - Finding failed Jobs, viewing logs, manual triggers, monitoring

