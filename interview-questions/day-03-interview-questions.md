# Day 03: Deployments - Interview Questions

## 1. Why do we use Deployments instead of creating Pods directly?

**Answer:**
Deployments provide several critical features that bare Pods lack:

**Problems with bare Pods:**
- No automatic restart if Pod crashes
- No scaling capability
- No rolling updates
- No rollback capability
- Pods are lost if node fails
- Manual management required

**Deployments solve:**
- ✅ **Self-healing**: Automatically replaces failed Pods
- ✅ **Scaling**: Easy horizontal scaling (replicas)
- ✅ **Rolling updates**: Zero-downtime deployments
- ✅ **Rollback**: Revert to previous version easily
- ✅ **Desired state**: Maintains specified number of replicas
- ✅ **Version history**: Tracks rollout history

**Best Practice:** Never create Pods directly in production. Always use Deployments (or other controllers like StatefulSet, DaemonSet).

---

## 2. Explain the hierarchy: Deployment → ReplicaSet → Pod

**Answer:**

```
Deployment (manages)
    ↓
ReplicaSet (ensures N replicas)
    ↓
Pods (actual running containers)
```

**Deployment:**
- Manages ReplicaSets
- Handles rolling updates and rollbacks
- Declares desired state (replicas, image, etc.)

**ReplicaSet:**
- Ensures specified number of Pod replicas are running
- Creates/deletes Pods to match desired count
- Managed by Deployment (you rarely create ReplicaSets directly)

**Pod:**
- Actual running container instance
- Created and managed by ReplicaSet

**Example:**
```yaml
Deployment: node-app (replicas: 3)
    ↓
ReplicaSet: node-app-abc123 (replicas: 3)
    ↓
Pods: node-app-abc123-xyz, node-app-abc123-def, node-app-abc123-ghi
```

---

## 3. Multiple Choice: What command is used to scale a Deployment?

A. `kubectl scale deployment <name> --replicas=5`  
B. `kubectl resize deployment <name> --replicas=5`  
C. `kubectl set replicas deployment <name> 5`  
D. `kubectl update deployment <name> --replicas=5`

**Answer: A**

**Explanation:** `kubectl scale` is the correct command to scale Deployments, ReplicaSets, or StatefulSets.

---

## 4. Explain how rolling updates work in Kubernetes Deployments.

**Answer:**
Rolling update is a strategy that updates Pods incrementally, ensuring zero downtime.

**Process:**
1. **New ReplicaSet created** with updated Pod template
2. **Gradual replacement**: Old Pods terminated, new Pods created
3. **Controlled by parameters**:
   - `maxSurge`: Maximum extra Pods during update (default: 25%)
   - `maxUnavailable`: Maximum Pods down during update (default: 25%)
4. **Health checks**: New Pods must be ready before old ones terminate
5. **Completion**: All Pods running new version

**Example:**
```
Initial: 4 Pods (v1)
Update starts:
  - 5 Pods total (4 v1 + 1 v2) [maxSurge: 1]
  - New Pod becomes Ready
  - Old Pod terminates
  - Repeat until all v2
Final: 4 Pods (v2)
```

**Benefits:**
- Zero downtime
- Automatic rollback if new version fails
- Gradual traffic shift

---

## 5. What is the difference between `maxSurge` and `maxUnavailable` in rolling update strategy?

**Answer:**

**maxSurge:**
- Maximum number of Pods that can be created **above** the desired replica count
- Can be absolute number (e.g., 2) or percentage (e.g., 25%)
- Example: With 4 replicas and maxSurge=1, you can have up to 5 Pods during update

**maxUnavailable:**
- Maximum number of Pods that can be **unavailable** during update
- Can be absolute number or percentage
- Example: With 4 replicas and maxUnavailable=1, at least 3 Pods must be available

**Example:**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # Can have 1 extra Pod
    maxUnavailable: 0  # All Pods must be available (zero downtime)
```

**Common configurations:**
- **Fast update**: `maxSurge: 3, maxUnavailable: 1` (faster but more resource usage)
- **Slow update**: `maxSurge: 1, maxUnavailable: 0` (safer, zero downtime)
- **Default**: `maxSurge: 25%, maxUnavailable: 25%`

---

## 6. Multiple Choice: How do you rollback a Deployment to the previous version?

A. `kubectl rollback deployment <name>`  
B. `kubectl rollout undo deployment <name>`  
C. `kubectl revert deployment <name>`  
D. `kubectl undo deployment <name>`

**Answer: B**

**Explanation:** `kubectl rollout undo` rolls back a Deployment to the previous revision. You can also use `--to-revision=<number>` to rollback to a specific revision.

---

## 7. Explain the concept of Deployment revision history.

**Answer:**
Kubernetes maintains a history of Deployment revisions (rollouts) to enable rollbacks.

**How it works:**
- Each update creates a new revision
- Revisions are stored in ReplicaSets
- Default history limit: 10 revisions
- Can be configured with `revisionHistoryLimit`

**Commands:**
```bash
# View rollout history
kubectl rollout history deployment <name>

# View specific revision
kubectl rollout history deployment <name> --revision=2

# Rollback to previous
kubectl rollout undo deployment <name>

# Rollback to specific revision
kubectl rollout undo deployment <name> --to-revision=3
```

**Best Practice:** Keep revision history for easy rollbacks, but limit it to avoid excessive storage.

---

## 8. Scenario: You need to update your Deployment's image from v1 to v2. Show two methods to do this.

**Answer:**

**Method 1: Using kubectl set image (Imperative)**
```bash
kubectl set image deployment/<name> <container-name>=<new-image>:v2

# Example
kubectl set image deployment/node-app node-app=myapp:v2

# Watch the rollout
kubectl rollout status deployment/node-app
```

**Method 2: Edit YAML and apply (Declarative)**
```bash
# Edit the deployment YAML
kubectl edit deployment <name>
# Change: image: myapp:v1 → image: myapp:v2

# Or edit file and apply
vim deployment.yaml  # Change image
kubectl apply -f deployment.yaml
```

**Method 3: Patch command**
```bash
kubectl patch deployment <name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","image":"<new-image>"}]}}}}'
```

**Best Practice:** Use declarative approach (Method 2) for production. Method 1 is fine for quick updates.

---

## 9. Multiple Choice: What happens when you delete a Pod that is managed by a Deployment?

A. The Pod is permanently deleted  
B. The Pod is recreated automatically to maintain desired replicas  
C. The Deployment is also deleted  
D. Nothing happens

**Answer: B**

**Explanation:** Deployments maintain desired state. If a Pod is deleted, the ReplicaSet (managed by Deployment) detects the mismatch and creates a new Pod to restore the desired replica count.

---

## 10. What is the purpose of `kubectl rollout pause` and `kubectl rollout resume`?

**Answer:**
These commands allow you to pause and resume a Deployment rollout.

**Use case:**
- **Pause**: Make multiple changes without triggering multiple rollouts
- **Resume**: Apply all changes at once in a single rollout

**Example:**
```bash
# Pause the rollout
kubectl rollout pause deployment/myapp

# Make multiple changes (no rollout yet)
kubectl set image deployment/myapp app=myapp:v2
kubectl set resources deployment/myapp -c app --limits=cpu=500m,memory=512Mi
kubectl set env deployment/myapp ENV=production

# Resume - all changes applied in one rollout
kubectl rollout resume deployment/myapp

# Watch the combined rollout
kubectl rollout status deployment/myapp
```

**Benefits:**
- Efficient: Single rollout instead of multiple
- Atomic: All changes applied together
- Faster: Less downtime

---

## 11. Explain the difference between Deployment update strategies: RollingUpdate vs Recreate.

**Answer:**

**RollingUpdate (Default):**
- Updates Pods incrementally
- Zero downtime
- New Pods created before old ones terminate
- Gradual traffic shift
- Use for: Production applications requiring availability

**Recreate:**
- Terminates all old Pods first
- Then creates new Pods
- Downtime during update
- Simpler, faster update
- Use for: Development, or when app can't run multiple versions

**Example:**
```yaml
strategy:
  type: Recreate  # or RollingUpdate
```

**When to use Recreate:**
- Application doesn't support multiple versions
- Database migrations that require downtime
- Quick updates in development
- Stateful applications that can't run in parallel

---

## 12. Multiple Choice: Which command shows the status of an ongoing rollout?

A. `kubectl rollout status deployment <name>`  
B. `kubectl get rollout deployment <name>`  
C. `kubectl describe rollout deployment <name>`  
D. `kubectl show rollout deployment <name>`

**Answer: A**

**Explanation:** `kubectl rollout status` shows the current status of a Deployment rollout and waits until it completes.

---

## 13. How does self-healing work in Deployments?

**Answer:**
Self-healing is the automatic recovery of failed Pods to maintain desired state.

**Process:**
1. **Desired state**: Deployment specifies 3 replicas
2. **Current state**: Only 2 Pods running (one crashed)
3. **Reconciliation**: ReplicaSet detects mismatch
4. **Action**: Creates new Pod to restore desired count
5. **Continuous**: Monitors and maintains desired state

**Example:**
```bash
# Deployment with 3 replicas
kubectl get pods
# Shows 3 Pods running

# Delete one Pod
kubectl delete pod <pod-name>

# Immediately check again
kubectl get pods
# Shows 3 Pods again (new one created automatically)
```

**Also works for:**
- Node failures (Pods rescheduled to other nodes)
- Container crashes (Pod recreated)
- Resource eviction (new Pod created)

---

## 14. Scenario: Your Deployment rollout is stuck. How would you troubleshoot it?

**Answer:**

**Step 1: Check rollout status**
```bash
kubectl rollout status deployment/<name>
# Shows current status and any errors
```

**Step 2: Check Pod status**
```bash
kubectl get pods -l app=<app-label>
# Look for Pods in Pending, CrashLoopBackOff, etc.
```

**Step 3: Check ReplicaSets**
```bash
kubectl get replicasets
# See if new ReplicaSet is created and Pods are being created
```

**Step 4: Describe Deployment**
```bash
kubectl describe deployment <name>
# Check Events section for errors
```

**Step 5: Check Pod events and logs**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Common issues:**
- **ImagePullBackOff**: Cannot pull image
- **CrashLoopBackOff**: New Pods keep crashing
- **Pending**: Insufficient resources
- **Readiness probe failing**: Pods not becoming ready

**Step 6: Rollback if needed**
```bash
kubectl rollout undo deployment/<name>
```

---

## 15. What is the relationship between Deployment selector and Pod labels?

**Answer:**
The Deployment's selector must match the Pod labels in the template.

**How it works:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp        # Selector
  template:
    metadata:
      labels:
        app: myapp      # Must match selector!
    spec:
      containers: [...]
```

**Rules:**
- Selector labels must match Pod template labels
- Selector is immutable (cannot change after creation)
- Pods created must have matching labels
- Service uses same labels to find Pods

**Why important:**
- ReplicaSet uses selector to find Pods it manages
- Service uses selector to route traffic
- Ensures correct Pods are managed

**Common mistake:**
```yaml
# ❌ WRONG - selector doesn't match labels
selector:
  matchLabels:
    app: myapp
template:
  metadata:
    labels:
      app: different-app  # Mismatch!
```

---

## 16. Multiple Choice: What is the default update strategy for Deployments?

A. Recreate  
B. RollingUpdate  
C. BlueGreen  
D. Canary

**Answer: B**

**Explanation:** RollingUpdate is the default strategy. It updates Pods incrementally with zero downtime.

