# Resource Management: FaultMaven Core vs Cloud K8s

This document explains how Docker Compose resource limits work for FaultMaven Core deployment compared to Kubernetes in the cloud, and what happens when resources are exhausted.

---

## Configuration Comparison

### FaultMaven Core Docker Compose

**File:** `docker-compose.override.yml`

```yaml
services:
  fm-agent-service:
    mem_limit: 1536m        # Hard limit: 1.5GB RAM
    mem_reservation: 512m   # Soft limit: 512MB guaranteed
    cpus: 1.0               # Max 1 CPU core
```

**Characteristics:**
- **Hard limits** enforced by Docker runtime (cgroups)
- **Single replica** per service (no horizontal scaling)
- **No auto-scaling** - fixed resource allocation
- **Shared resources** - all services compete for laptop RAM/CPU
- **Total footprint:** ~6-8GB RAM across 9 containers

---

### Cloud Kubernetes

**File:** `kubernetes/deployments/agent-service.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fm-agent-service
spec:
  replicas: 3  # High availability
  template:
    spec:
      containers:
      - name: agent
        resources:
          limits:
            cpu: "2000m"      # 2 full cores
            memory: "4Gi"     # 4GB per pod
          requests:
            cpu: "1000m"      # Guaranteed 1 core
            memory: "2Gi"     # Guaranteed 2GB
```

**Characteristics:**
- **Soft limits** - can burst above requests up to limits
- **Multiple replicas** - 3+ pods per service for HA
- **Horizontal Pod Autoscaling (HPA)** - auto-scales based on load
- **Node affinity** - services spread across dedicated nodes
- **Total footprint:** ~80-100GB RAM across cluster

---

## Resource Footprint Breakdown

### FaultMaven Core (8GB Laptop)

| Service | CPU Limit | Memory Limit | Memory Reserved | Notes |
|---------|-----------|--------------|-----------------|-------|
| **fm-agent-service** | 1.0 | 1.5GB | 512MB | LangGraph agent orchestration |
| **fm-knowledge-service** | 1.0 | 2.0GB | 1GB | ChromaDB + embeddings |
| **chromadb** | 0.5 | 1.0GB | 512MB | Vector database |
| **redis** | 0.25 | 512MB | 256MB | Session store |
| fm-case-service | default | ~256MB | - | Lightweight FastAPI CRUD |
| fm-auth-service | default | ~256MB | - | User authentication |
| fm-session-service | default | ~256MB | - | Session management |
| fm-evidence-service | default | ~256MB | - | File upload handling |
| fm-job-worker | default | ~256MB | - | Celery background jobs |
| **Total** | **~3 CPUs** | **~6-8GB** | **~3GB** | |

**Resource allocation strategy:**
- **Explicit limits** only for AI-intensive services
- **CRUD services** use Docker defaults (~256MB each)
- **Leaves 2-4GB** for host OS, browser, IDE

---

### Cloud K8s (Production Cluster)

| Service | Replicas | CPU/Pod | Memory/Pod | Total Memory | Scaling |
|---------|----------|---------|------------|--------------|---------|
| **fm-agent-service** | 3 | 2 cores | 4GB | **12GB** | HPA 3-10 pods |
| **fm-knowledge-service** | 3 | 2 cores | 4GB | **12GB** | HPA 3-8 pods |
| **chromadb** | 3 | 1 core | 2GB | **6GB** | StatefulSet |
| **redis** (HA) | 3 | 0.5 core | 1GB | **3GB** | Sentinel cluster |
| fm-case-service | 3 | 1 core | 2GB | 6GB | HPA 3-6 pods |
| fm-auth-service | 3 | 1 core | 2GB | 6GB | HPA 3-6 pods |
| fm-session-service | 3 | 0.5 core | 1GB | 3GB | HPA 3-6 pods |
| fm-evidence-service | 3 | 1 core | 2GB | 6GB | HPA 3-6 pods |
| fm-job-worker | 2 | 1 core | 2GB | 4GB | HPA 2-5 pods |
| PostgreSQL (HA) | 3 | 2 cores | 8GB | 24GB | Patroni cluster |
| **Total** | **~30 pods** | **~40 cores** | **~80GB** | |

**Additional infrastructure:**
- NGINX Ingress: 2GB
- Prometheus/Grafana: 5GB
- Logging (ELK): 8GB
- **Grand Total:** ~95GB+ RAM

---

## What Happens When Resources Are Exhausted?

### Memory Limit Exceeded (FaultMaven Core)

#### Stage 1: Soft Pressure (90-95% usage)

```bash
$ docker stats fm-agent-service
CONTAINER           MEM USAGE / LIMIT     MEM %
fm-agent-service    1.40GiB / 1.50GiB    93.33%
```

**Symptoms:**
- Python garbage collector runs more frequently
- Response times increase (200ms → 500ms)
- Container remains healthy

**Impact:**
- ⚠️ Degraded performance
- ✅ No failures yet
- ⚠️ Warning logs in container

#### Stage 2: Hard Limit (100% usage)

```bash
$ docker stats fm-agent-service
CONTAINER           MEM USAGE / LIMIT     MEM %
fm-agent-service    1.50GiB / 1.50GiB    100.00%
```

**What happens:**
1. **Docker OOM Killer** activates
2. **Container killed** immediately
3. **Auto-restart** triggered (unless `restart: "no"`)
4. **Other containers unaffected** (cgroup isolation)

**User experience:**
```bash
$ ./faultmaven logs fm-agent-service
2025-11-20 22:15:42 ERROR Process killed by OOM
2025-11-20 22:15:43 INFO Restarting fm-agent-service (attempt 1/3)
2025-11-20 22:15:50 INFO Agent service started successfully
```

**Impact:**
- ❌ **Current request fails** (500 Internal Server Error)
- ❌ **In-flight state lost** (unless persisted to database)
- ⏱️ **10-30 second downtime** for restart
- ✅ **Other services continue** working normally

**Detection:**
```bash
$ ./faultmaven status
...
✗ Agent Service (port 8006) - Not responding

$ docker inspect fm-agent-service | grep OOMKilled
"OOMKilled": true
```

---

### CPU Limit Exceeded (FaultMaven Core)

#### When CPU hits limit:

```bash
$ docker stats fm-knowledge-service
CONTAINER               CPU %
fm-knowledge-service    99.80%  # Throttled at 100% of 1 core
```

**What happens:**
1. **CFS (Completely Fair Scheduler)** enforces quota
2. **Process throttled** - paused periodically to stay under limit
3. **No crash** - service stays running
4. **Slower execution** - tasks take longer

**User experience:**
```python
# Normal performance
embeddings = generate_embeddings(docs)  # 2 seconds

# CPU throttled
embeddings = generate_embeddings(docs)  # 10 seconds (5x slower)
```

**Impact:**
- ⚠️ **Slow response times** (not failures)
- ⚠️ **Request queue buildup** if load exceeds capacity
- ⚠️ **Timeout risk** if requests take >30s
- ✅ **Eventually consistent** - requests complete

---

### System-Wide Memory Exhaustion (FaultMaven Core)

#### Cascade failure scenario:

```bash
$ free -h
              total   used   free   shared  buff/cache
Mem:          8.0Gi  7.9Gi  100Mi   50Mi    200Mi  ← System RAM exhausted!
Swap:         2.0Gi  2.0Gi    0Gi  ← Swap fully used!
```

**What happens without resource limits:**
1. fm-knowledge-service grows to 3GB (no limit)
2. fm-agent-service grows to 2.5GB (no limit)
3. chromadb grows to 2GB (no limit)
4. **Total:** 7.5GB + host OS = 9GB+ needed
5. **System swap thrashes** - disk I/O saturates
6. **OS OOM Killer** activates at kernel level
7. **Kills largest process** - could be Docker, Chrome, IDE!
8. **Laptop freezes** - requires hard reboot

**Why docker-compose.override.yml prevents this:**
```yaml
# WITHOUT override:
# fm-knowledge-service can use unlimited RAM → 3GB
# fm-agent-service can use unlimited RAM → 2.5GB
# chromadb can use unlimited RAM → 2GB
# Total: 7.5GB+ → System OOM!

# WITH override:
# fm-knowledge-service capped at 2GB → OOM killed if exceeds
# fm-agent-service capped at 1.5GB → OOM killed if exceeds
# chromadb capped at 1GB → OOM killed if exceeds
# Total: Never exceeds 5GB → System stays responsive!
```

**Impact:**
- ✅ **Individual container killed** (isolated failure)
- ✅ **System remains usable** (no freeze)
- ✅ **Other apps unaffected** (Chrome, IDE, etc.)
- ⏱️ **10-30 second recovery** per container

---

### Memory Limit Exceeded (Cloud K8s)

#### Pod-level OOM:

```bash
$ kubectl top pods
NAME                          CPU    MEMORY
fm-agent-service-abc123       950m   3900Mi  # Approaching 4Gi limit
fm-agent-service-def456       500m   2100Mi
fm-agent-service-ghi789       600m   2300Mi
```

**What happens:**
1. **Pod OOMKilled** by kubelet
2. **Restart policy** creates new pod
3. **Load balancer stops routing** to killed pod
4. **Other replicas continue** serving traffic
5. **HPA may scale up** if CPU/memory average high

**User experience:**
- ✅ **Zero downtime** - other replicas healthy
- ✅ **Transparent failover** - users don't notice
- ⚠️ **Temporary reduced capacity** (3 pods → 2 pods)
- ✅ **Auto-recovery** in 30-60s (new pod scheduled)

#### Node-level exhaustion:

```bash
$ kubectl top nodes
NAME           CPU    MEMORY
worker-1       85%    95%    ← Node under memory pressure!
worker-2       45%    60%
worker-3       40%    55%
```

**Kubernetes behavior:**
1. **Node taint** applied: `node.kubernetes.io/memory-pressure`
2. **Evict low-priority pods** (BestEffort QoS first)
3. **Reschedule pods** to other nodes
4. **Cluster Autoscaler** adds new node (if enabled)

**Impact:**
- ✅ **Graceful pod migration** (drains connections)
- ✅ **No data loss** (persistent volumes reattach)
- ⚠️ **Brief capacity reduction** during migration
- ✅ **Self-healing** within 2-3 minutes

---

## Failure Mode Comparison

| Scenario | FaultMaven Core (Docker) | Cloud K8s |
|----------|--------------------------|-----------|
| **Single container OOM** | ❌ 10-30s downtime, request fails | ✅ Zero downtime, other replicas serve |
| **CPU throttling** | ⚠️ Slow but functional | ⚠️ Slow but functional |
| **Node/host failure** | ❌ Total outage | ✅ Pods migrate to other nodes |
| **Recovery time** | 10-30 seconds | 30-90 seconds |
| **Data loss** | ⚠️ In-flight requests lost | ✅ Load balancer retries |
| **Blast radius** | Single user affected | Isolated to single user's request |
| **Manual intervention** | `./faultmaven start` | Auto-recovery, ops alerted only |

---

## Monitoring Resource Usage

### FaultMaven Core

**Check real-time usage:**
```bash
$ docker stats

CONTAINER           CPU %   MEM USAGE / LIMIT     MEM %
fm-agent-service    45%     890MiB / 1.5GiB      58%
fm-knowledge-svc    80%     1.8GiB / 2GiB        90%  ← High!
chromadb            25%     512MiB / 1GiB        50%
redis               5%      128MiB / 512MiB      25%
```

**Check if OOM killed:**
```bash
$ docker inspect fm-agent-service | grep -A 5 State
"State": {
    "Status": "running",
    "Running": true,
    "Paused": false,
    "Restarting": false,
    "OOMKilled": false,  ← Check this!
    "Dead": false
}
```

**Check restart count:**
```bash
$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES                   STATUS
fm-agent-service        Up 2 minutes (healthy)
fm-knowledge-service    Up 10 seconds (starting) ← Recently restarted!
```

---

### Cloud K8s

**Check pod resource usage:**
```bash
$ kubectl top pods -n production
NAME                          CPU    MEMORY
fm-agent-service-abc123       950m   3200Mi
fm-agent-service-def456       1200m  2800Mi  ← CPU spike
fm-agent-service-ghi789       800m   2100Mi
```

**Check node capacity:**
```bash
$ kubectl describe node worker-1
Allocated resources:
  CPU:     14000m (87%)
  Memory:  28Gi (90%)  ← High utilization!
```

**Check HPA status:**
```bash
$ kubectl get hpa
NAME               REFERENCE                 TARGETS   MINPODS   MAXPODS   REPLICAS
fm-agent-service   Deployment/fm-agent-svc   75%/70%   3         10        5  ← Scaled up!
```

**View events:**
```bash
$ kubectl get events --sort-by='.lastTimestamp'
...
5m   Warning   OOMKilled   Pod/fm-agent-service-abc123   Container killed: OOM
5m   Normal    Started     Pod/fm-agent-service-xyz987   New pod created
```

---

## Best Practices

### FaultMaven Core

1. **Always use resource limits**
   - Copy `docker-compose.override.yml.example`
   - Adjust limits based on your laptop specs

2. **Monitor with docker stats**
   ```bash
   watch -n 2 docker stats
   ```

3. **Set alerts for high usage**
   ```bash
   # Simple monitoring script
   while true; do
     MEM_PERCENT=$(docker stats --no-stream --format "{{.MemPerc}}" fm-knowledge-service | sed 's/%//')
     if (( $(echo "$MEM_PERCENT > 85" | bc -l) )); then
       echo "WARNING: fm-knowledge-service at ${MEM_PERCENT}% memory"
     fi
     sleep 30
   done
   ```

4. **Plan for OOM failures**
   - LLM calls should be idempotent
   - Database transactions should be atomic
   - Use retry logic in client code

### Cloud K8s

1. **Set both requests and limits**
   ```yaml
   resources:
     requests:   # Scheduling + HPA decisions
       cpu: "1000m"
       memory: "2Gi"
     limits:     # OOM kill threshold
       cpu: "2000m"
       memory: "4Gi"
   ```

2. **Configure HPA**
   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   spec:
     minReplicas: 3
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```

3. **Use Pod Disruption Budgets**
   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   spec:
     minAvailable: 2  # Always keep 2 pods running
     selector:
       matchLabels:
         app: fm-agent-service
   ```

4. **Enable Cluster Autoscaler**
   - Automatically add nodes when pods are pending
   - Scale down nodes when underutilized

---

## Summary

**FaultMaven Core:**
- **Footprint:** 6-8GB RAM, designed for 8GB+ laptops
- **Limits:** Hard caps prevent system OOM
- **Failure mode:** Container restart, 10-30s recovery
- **Scaling:** None (single replica per service)

**Cloud K8s:**
- **Footprint:** 80-100GB RAM across cluster
- **Limits:** Soft limits with burst capacity
- **Failure mode:** Pod migration, zero downtime
- **Scaling:** HPA + Cluster Autoscaler

**Key Takeaway:**
- FaultMaven Core prioritizes **resource efficiency** and **predictability**
- Cloud K8s prioritizes **high availability** and **scalability**
- Resource limits are **critical** for FaultMaven Core to prevent laptop freeze
- Cloud handles failures **gracefully** with redundancy and auto-healing
