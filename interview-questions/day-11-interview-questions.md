# Day 11: Jobs & CronJobs - Interview Questions

## Descriptive Questions

### 1. Explain the fundamental difference between a Kubernetes Job and a Deployment. When would you use each?

**Answer:**
- **Deployment**: Designed for long-running applications that should stay running indefinitely. It maintains a desired number of pod replicas and automatically restarts pods if they fail. Deployments are ideal for web servers, APIs, databases, and other services that need to be always available.

- **Job**: Designed for tasks that run to completion. A Job creates pods and ensures they complete successfully, then marks the job as complete. Jobs are ideal for:
  - Database migrations
  - Batch data processing
  - One-time tasks
  - Scheduled tasks (via CronJob)

**Key difference**: Deployments keep pods running forever, while Jobs run until completion and stop.

---

### 2. What is the significance of `restartPolicy` in a Job? What are the valid values and when should you use each?

**Answer:**
`restartPolicy` determines what happens when a container exits:

- **Never**: If the container exits (success or failure), the pod is not restarted. A new pod is created for retries. This is the most common choice for Jobs.
- **OnFailure**: If the container exits with a non-zero status, it's restarted in the same pod. If it exits with 0, the pod completes.
- **Always**: Pod is always restarted (default for Deployments, but **should never be used for Jobs**).

**Best Practice**: Always use `Never` or `OnFailure` for Jobs. Using `Always` would cause the Job to never complete, as Kubernetes would keep restarting completed containers.

---

### 3. Explain the relationship between `completions` and `parallelism` in a Job. Provide examples of different use cases.

**Answer:**
- **`completions`**: Total number of successful pod completions required for the Job to be considered complete.
- **`parallelism`**: Maximum number of pods that can run simultaneously.

**Use Cases:**

1. **Sequential Processing** (`completions: 5, parallelism: 1`):
   - Process 5 items one at a time
   - Useful when order matters or resources are limited

2. **Parallel Processing** (`completions: 10, parallelism: 3`):
   - Process 10 items with up to 3 running at once
   - Faster processing while controlling resource usage

3. **Work Queue Pattern** (`parallelism: 5`, no `completions`):
   - 5 workers pulling from a queue
   - Job completes when all workers finish and queue is empty

---

### 4. What is `backoffLimit` in a Job? How does Kubernetes handle retries when a Job fails?

**Answer:**
`backoffLimit` specifies the maximum number of retries before marking the Job as failed. Default is 6.

**Retry Behavior:**
- When a pod fails (exits with non-zero status), Kubernetes waits before creating a new pod
- Backoff delays: 10s, 20s, 40s, 80s, 160s, 320s (exponential backoff)
- After `backoffLimit` retries, the Job is marked as failed
- Each retry creates a new pod (if `restartPolicy: Never`) or restarts the container (if `restartPolicy: OnFailure`)

**Example:**
```yaml
spec:
  backoffLimit: 3  # Retry up to 3 times
```

If all 3 retries fail, the Job status becomes `Failed`.

---

### 5. Explain what a CronJob is and how it differs from a regular Job. What are the key configuration options for CronJobs?

**Answer:**
A **CronJob** is a Job that runs on a schedule (like Unix cron). It automatically creates Jobs at specified times.

**Key Differences:**
- **Job**: Runs once (or multiple times based on completions)
- **CronJob**: Creates Jobs on a schedule repeatedly

**Key Configuration Options:**

1. **`schedule`**: Cron expression (e.g., `"0 2 * * *"` for daily at 2 AM)
2. **`concurrencyPolicy`**:
   - `Allow` (default): Multiple jobs can run concurrently
   - `Forbid`: Skip new run if previous still running
   - `Replace`: Cancel previous and start new
3. **`successfulJobsHistoryLimit`**: Keep last N successful jobs (default: 3)
4. **`failedJobsHistoryLimit`**: Keep last N failed jobs (default: 1)
5. **`startingDeadlineSeconds`**: Max delay for missed schedule
6. **`suspend`**: Pause CronJob execution

---

### 6. What are the three `concurrencyPolicy` options for CronJobs? Explain when you would use each.

**Answer:**

1. **`Allow`** (default):
   - Multiple jobs can run concurrently
   - Use when: Jobs are idempotent, can safely overlap, or are lightweight

2. **`Forbid`**:
   - Skips new run if previous job is still running
   - Use when: Jobs must not overlap (e.g., database backups, resource-intensive tasks)
   - Most common for production CronJobs

3. **`Replace`**:
   - Cancels previous job and starts new one
   - Use when: Only the latest run matters, previous runs can be interrupted

**Example:**
```yaml
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid  # Don't start backup if previous still running
```

---

### 7. How would you manually trigger a CronJob without waiting for its schedule? Explain the command and use case.

**Answer:**
Use `kubectl create job --from=cronjob/<name> <job-name>` to create a Job immediately from a CronJob template.

**Command:**
```bash
kubectl create job --from=cronjob/backup-cronjob manual-backup-1
```

**Use Cases:**
- Testing CronJob configuration before schedule triggers
- Running ad-hoc backups or maintenance tasks
- Debugging CronJob issues
- Emergency execution outside schedule

**Note**: This creates a regular Job, not a CronJob, so it runs once and completes.

---

### 8. What is `ttlSecondsAfterFinished` in a Job? Why is it important?

**Answer:**
`ttlSecondsAfterFinished` automatically deletes a completed Job after the specified number of seconds.

**Why it's important:**
- Prevents accumulation of completed Jobs in the cluster
- Saves etcd storage space
- Reduces clutter in `kubectl get jobs` output
- Automatic cleanup without manual intervention

**Example:**
```yaml
spec:
  ttlSecondsAfterFinished: 3600  # Delete 1 hour after completion
```

**Note**: Only works for completed Jobs (succeeded or failed). Requires TTL controller to be enabled (default in K8s 1.21+).

---

### 9. Explain the cron schedule format in Kubernetes. Provide examples of common schedules.

**Answer:**
Cron format: `minute hour day-of-month month day-of-week`

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, Sunday=0)
│ │ │ │ │
* * * * *
```

**Common Examples:**
- `"0 2 * * *"` - Daily at 2:00 AM
- `"*/15 * * * *"` - Every 15 minutes
- `"0 */6 * * *"` - Every 6 hours
- `"0 9 * * 1"` - Every Monday at 9:00 AM
- `"0 0 1 * *"` - First day of month at midnight
- `"0 0 * * 1-5"` - Weekdays at midnight
- `"*/5 9-17 * * *"` - Every 5 minutes, 9 AM to 5 PM

---

### 10. How do you debug a failed Job in Kubernetes? List the steps and commands.

**Answer:**

**Steps to Debug:**

1. **Check Job Status:**
   ```bash
   kubectl get job <job-name>
   kubectl describe job <job-name>
   ```

2. **Find Failed Pods:**
   ```bash
   kubectl get pods -l job-name=<job-name>
   kubectl get pods --field-selector=status.phase=Failed
   ```

3. **View Pod Logs:**
   ```bash
   kubectl logs <failed-pod-name>
   kubectl logs -l job-name=<job-name>
   ```

4. **Check Events:**
   ```bash
   kubectl get events | grep <job-name>
   kubectl describe pod <failed-pod-name>
   ```

5. **Check Resource Constraints:**
   ```bash
   kubectl describe job <job-name> | grep -A 10 "Events"
   ```

6. **Common Issues:**
   - Missing or incorrect `restartPolicy`
   - Resource limits too low
   - Image pull errors
   - Application errors (check logs)
   - Exceeded `backoffLimit`

---

## Multiple Choice Questions (MCQ)

### 11. What is the default `restartPolicy` for a Job in Kubernetes?

A. `Never`  
B. `OnFailure`  
C. `Always`  
D. There is no default

**Answer: C. `Always`**

**Explanation:** The default `restartPolicy` is `Always`, but this is **wrong for Jobs**. You should always explicitly set it to `Never` or `OnFailure` for Jobs, otherwise the Job will never complete as Kubernetes keeps restarting completed containers.

---

### 12. A Job has `completions: 10` and `parallelism: 3`. How many pods will run simultaneously?

A. 1  
B. 3  
C. 10  
D. Depends on cluster resources

**Answer: B. 3**

**Explanation:** `parallelism: 3` means up to 3 pods can run at the same time. The Job will create pods until 10 successful completions are achieved, but never more than 3 at once.

---

### 13. What happens if a CronJob's schedule is `"0 2 * * *"` and the previous job is still running when the next schedule time arrives, with `concurrencyPolicy: Forbid`?

A. The new job starts anyway  
B. The previous job is cancelled  
C. The new job is skipped  
D. Both jobs run concurrently

**Answer: C. The new job is skipped**

**Explanation:** With `concurrencyPolicy: Forbid`, if a previous job is still running when the schedule triggers, the new job is skipped. This prevents overlapping executions.

---

### 14. Which command correctly creates a Job manually from a CronJob named `backup-cron`?

A. `kubectl run job --from=cronjob/backup-cron manual-1`  
B. `kubectl create job --from=cronjob/backup-cron manual-1`  
C. `kubectl apply job --from=cronjob/backup-cron manual-1`  
D. `kubectl exec cronjob/backup-cron -- create job manual-1`

**Answer: B. `kubectl create job --from=cronjob/backup-cron manual-1`**

**Explanation:** The correct command is `kubectl create job --from=cronjob/<name> <job-name>`. This creates a one-time Job from the CronJob's jobTemplate.

---

### 15. What is the default value of `backoffLimit` for a Job?

A. 0  
B. 3  
C. 6  
D. Unlimited

**Answer: C. 6**

**Explanation:** The default `backoffLimit` is 6, meaning Kubernetes will retry up to 6 times before marking the Job as failed.

---

### 16. A Job has `restartPolicy: Never` and a pod fails. What happens?

A. The container restarts in the same pod  
B. A new pod is created for retry  
C. The Job immediately fails  
D. The pod is deleted and recreated

**Answer: B. A new pod is created for retry**

**Explanation:** With `restartPolicy: Never`, if a pod fails, Kubernetes creates a new pod for the retry (subject to `backoffLimit`). The failed pod is not restarted.

---

### 17. What does `ttlSecondsAfterFinished: 3600` do in a Job?

A. Sets a timeout of 1 hour for the job  
B. Deletes the job 1 hour after completion  
C. Retries the job after 1 hour if it fails  
D. Suspends the job for 1 hour after completion

**Answer: B. Deletes the job 1 hour after completion**

**Explanation:** `ttlSecondsAfterFinished` automatically deletes the Job (and its pods) after the specified number of seconds following completion, helping with cleanup.

---

### 18. Which cron expression runs every weekday at 9 AM?

A. `"0 9 * * 1-5"`  
B. `"0 9 1-5 * *"`  
C. `"9 0 * * 1-5"`  
D. `"* 9 * * 1-5"`

**Answer: A. `"0 9 * * 1-5"``

**Explanation:** The format is `minute hour day-of-month month day-of-week`. `"0 9 * * 1-5"` means minute 0, hour 9, any day of month, any month, Monday-Friday (1-5).

---

### 19. What is the purpose of `activeDeadlineSeconds` in a Job?

A. Maximum time between retries  
B. Maximum total time for the entire job  
C. Time to wait before starting the job  
D. Time to wait after job completion before cleanup

**Answer: B. Maximum total time for the entire job**

**Explanation:** `activeDeadlineSeconds` sets the maximum duration (in seconds) that a Job can be active. If exceeded, the Job is terminated and marked as failed, regardless of retries.

---

### 20. A CronJob has `successfulJobsHistoryLimit: 3` and `failedJobsHistoryLimit: 1`. After 10 successful runs, how many Jobs will remain?

A. 1  
B. 3  
C. 4  
D. 10

**Answer: B. 3**

**Explanation:** `successfulJobsHistoryLimit: 3` means only the last 3 successful Jobs are kept. Older successful Jobs are automatically deleted. Failed Jobs are kept separately (up to 1 in this case).

---

### 21. What happens when you set `suspend: true` on a CronJob?

A. The current running job is paused  
B. No new jobs are created, but existing jobs continue  
C. All jobs are immediately deleted  
D. The CronJob is deleted

**Answer: B. No new jobs are created, but existing jobs continue**

**Explanation:** `suspend: true` prevents the CronJob from creating new Jobs, but any Jobs already created will continue to run. This is useful for temporarily pausing scheduled tasks.

---

### 22. In a Job with `completions: 5` and `parallelism: 2`, if one pod fails, what happens?

A. The entire Job fails immediately  
B. A new pod is created to replace it (subject to backoffLimit)  
C. The Job waits indefinitely  
D. The remaining pods are cancelled

**Answer: B. A new pod is created to replace it (subject to backoffLimit)**

**Explanation:** When a pod fails, Kubernetes creates a new pod to retry (subject to `backoffLimit`). The Job continues until 5 successful completions are achieved.

---

### 23. What is the correct way to view logs from all pods created by a Job named `data-processor`?

A. `kubectl logs job/data-processor`  
B. `kubectl logs -l job-name=data-processor`  
C. `kubectl logs data-processor --all`  
D. `kubectl get logs -j data-processor`

**Answer: B. `kubectl logs -l job-name=data-processor`**

**Explanation:** Jobs automatically label pods with `job-name=<job-name>`. Using `-l job-name=data-processor` selects all pods with that label and shows their logs.

---

### 24. Which of the following is NOT a valid use case for a Kubernetes Job?

A. Database migration  
B. Batch data processing  
C. Running a web server  
D. One-time cleanup task

**Answer: C. Running a web server**

**Explanation:** A web server should use a Deployment, not a Job, because it needs to run continuously. Jobs are for tasks that run to completion.

---

### 25. What does `startingDeadlineSeconds: 60` mean in a CronJob?

A. The job must start within 60 seconds of schedule  
B. The job must complete within 60 seconds  
C. The job will be retried every 60 seconds  
D. The job will be deleted 60 seconds after completion

**Answer: A. The job must start within 60 seconds of schedule**

**Explanation:** If a CronJob misses its schedule (e.g., cluster was down), it can still start if it's within `startingDeadlineSeconds` of the scheduled time. After that, it's skipped.

---

## Scenario-Based Questions

### 26. You need to process 1000 files, and each file takes approximately 2 minutes to process. You want to complete the task as quickly as possible without overwhelming the cluster. How would you configure the Job?

**Answer:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: file-processor
spec:
  completions: 1000
  parallelism: 10  # Adjust based on cluster capacity
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: processor
        image: file-processor:latest
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
```

**Reasoning:**
- `completions: 1000` for 1000 files
- `parallelism: 10` balances speed and cluster load (adjust based on node count and resources)
- Set resource limits to prevent overwhelming the cluster
- Use `OnFailure` restartPolicy for automatic retries on transient failures

---

### 27. You have a critical database backup CronJob that must run daily at 2 AM. The backup takes 30-60 minutes. How would you configure it to prevent issues?

**Answer:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid  # Prevent overlapping backups
  successfulJobsHistoryLimit: 7  # Keep a week of history
  failedJobsHistoryLimit: 3  # Keep failed jobs for debugging
  startingDeadlineSeconds: 300  # Allow 5 min grace period
  jobTemplate:
    spec:
      backoffLimit: 2
      activeDeadlineSeconds: 7200  # 2 hour max (safety limit)
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: postgres:15-alpine
            command: ['pg_dump', ...]
            resources:
              requests:
                memory: "1Gi"
                cpu: "500m"
              limits:
                memory: "2Gi"
                cpu: "1000m"
```

**Key Points:**
- `concurrencyPolicy: Forbid` prevents overlapping backups
- `activeDeadlineSeconds` ensures backup doesn't run forever
- Resource limits prevent resource exhaustion
- History limits for monitoring and debugging

---

## Summary

These questions cover:
- ✅ Fundamental concepts (Jobs vs Deployments)
- ✅ Configuration options (restartPolicy, completions, parallelism)
- ✅ CronJobs and scheduling
- ✅ Debugging and troubleshooting
- ✅ Best practices and real-world scenarios
- ✅ kubectl commands
- ✅ Common patterns and use cases

Perfect for preparing for Kubernetes/DevOps interviews!

