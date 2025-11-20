# Self-Hosted Testing Procedure

**Date:** 2025-11-20
**Status:** 🟡 **Ready for Testing (API Key Required)**

---

## Prerequisites Completed ✅

1. ✅ **docker-compose.yml** updated to reference `../fm-*-service` repos
2. ✅ **.env** file created from `.env.example`
3. ✅ All service repositories exist in parent directory
4. ✅ Shared `./data` directory will be created on first run

---

## Testing Steps

### Step 1: Add API Key

**REQUIRED:** Edit `.env` file and add your real API key:

```bash
# Edit this line in .env:
OPENAI_API_KEY=sk-your-actual-key-here
```

**Get keys from:**
- OpenAI: https://platform.openai.com/api-keys
- Anthropic: https://console.anthropic.com/
- Fireworks: https://fireworks.ai/api-keys

---

### Step 2: Start Docker Compose

```bash
cd /home/swhouse/product/faultmaven-deploy
docker-compose up -d
```

**Expected output:**
```
Creating network "faultmaven-network" with the default driver
Creating volume "faultmaven-deploy_redis-data" with default driver
Creating volume "faultmaven-deploy_chromadb-data" with default driver
Building fm-auth-service...
Building fm-session-service...
...
Creating faultmaven-redis ... done
Creating faultmaven-chromadb ... done
Creating fm-auth-service ... done
Creating fm-session-service ... done
Creating fm-case-service ... done
Creating fm-knowledge-service ... done
Creating fm-evidence-service ... done
Creating fm-agent-service ... done
Creating fm-job-worker ... done
Creating fm-job-worker-beat ... done
```

---

### Step 3: Verify All Containers Started

```bash
docker-compose ps
```

**Expected output (all "Up"):**
```
Name                  State    Ports
-----------------------------------------------------
fm-agent-service      Up       0.0.0.0:8006->8000/tcp
fm-auth-service       Up       0.0.0.0:8001->8000/tcp
fm-case-service       Up       0.0.0.0:8003->8000/tcp
fm-evidence-service   Up       0.0.0.0:8005->8000/tcp
fm-job-worker         Up
fm-job-worker-beat    Up
fm-knowledge-service  Up       0.0.0.0:8004->8000/tcp
fm-session-service    Up       0.0.0.0:8002->8000/tcp
faultmaven-chromadb   Up       0.0.0.0:8000->8000/tcp
faultmaven-redis      Up       0.0.0.0:6379->6379/tcp
```

**If any service is not "Up":**
```bash
# Check logs for specific service
docker-compose logs fm-case-service
docker-compose logs fm-agent-service
```

---

### Step 4: Verify Data Directory Created

```bash
ls -la ./data/
```

**Expected output:**
```
drwxr-xr-x  3 user user 4096 Nov 20 12:00 .
drwxr-xr-x  5 user user 4096 Nov 20 12:00 ..
-rw-r--r--  1 user user 8192 Nov 20 12:00 faultmaven.db
drwxr-xr-x  2 user user 4096 Nov 20 12:00 uploads
```

**Verify SQLite database:**
```bash
sqlite3 ./data/faultmaven.db ".tables"
```

**Expected output (database tables from fm-case-service):**
```
cases
evidence
hypotheses
solutions
case_messages
uploaded_files
case_status_transitions
case_tags
agent_tool_calls
```

---

### Step 5: Test Health Endpoints

```bash
# Test each service health endpoint
curl http://localhost:8001/health  # Auth Service
curl http://localhost:8002/health  # Session Service
curl http://localhost:8003/health  # Case Service
curl http://localhost:8004/health  # Knowledge Service
curl http://localhost:8005/health  # Evidence Service
curl http://localhost:8006/health  # Agent Service

# Test infrastructure
redis-cli -h localhost ping  # Should return "PONG"
curl http://localhost:8000/api/v1/heartbeat  # ChromaDB
```

**Expected response (example from case service):**
```json
{
  "status": "healthy",
  "service": "fm-case-service",
  "version": "1.0.0",
  "database": "sqlite+aiosqlite"
}
```

---

### Step 6: Test Basic API Calls

#### 6.1: Create a Case

```bash
curl -X POST http://localhost:8003/api/v1/cases \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test case for deployment verification",
    "description": "Testing self-hosted deployment",
    "user_id": "test_user_001"
  }'
```

**Expected response:**
```json
{
  "case_id": "case_abc123...",
  "title": "Test case for deployment verification",
  "status": "consulting",
  "created_at": "2025-11-20T12:00:00Z",
  ...
}
```

**Save the `case_id` for next steps.**

#### 6.2: Get Case Details

```bash
curl http://localhost:8003/api/v1/cases/{case_id}
```

**Expected:** Full case details returned.

#### 6.3: Upload Evidence File

```bash
# Create a test log file
echo "Error: Connection timeout at 2025-11-20 12:00:00" > test_error.log

# Upload to case
curl -X POST http://localhost:8005/api/v1/evidence \
  -F "file=@test_error.log" \
  -F "case_id={case_id}" \
  -F "evidence_type=log"
```

**Expected:** Evidence file uploaded to `./data/uploads/case_{case_id}/`

**Verify:**
```bash
ls -la ./data/uploads/case_{case_id}/
```

#### 6.4: Test Knowledge Service (ChromaDB)

```bash
# Upload a document to knowledge base
curl -X POST http://localhost:8004/api/v1/knowledge/documents \
  -H "Content-Type: application/json" \
  -d '{
    "content": "How to troubleshoot connection timeouts: Check network latency, verify firewall rules, increase timeout values.",
    "metadata": {
      "user_id": "test_user_001",
      "title": "Connection Timeout Troubleshooting",
      "type": "runbook"
    }
  }'
```

**Expected:** Document ID returned.

**Search knowledge base:**
```bash
curl -X POST http://localhost:8004/api/v1/knowledge/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "connection timeout",
    "user_id": "test_user_001",
    "limit": 5
  }'
```

**Expected:** Search results with similarity scores.

#### 6.5: Test Agent Service (AI Troubleshooting)

**⚠️ This requires a valid API key in .env**

```bash
curl -X POST http://localhost:8006/api/v1/agent/query \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "{case_id}",
    "message": "The application is experiencing connection timeouts. What could be the root cause?"
  }'
```

**Expected:** AI-generated troubleshooting response from LangGraph agent.

---

### Step 7: Verify Background Job Worker

```bash
# Check job worker logs
docker-compose logs fm-job-worker

# Expected output should show Celery worker started:
# [timestamp] INFO/MainProcess] Connected to redis://redis:6379/0
# [timestamp] INFO/MainProcess] celery@hostname ready.
```

---

### Step 8: Test Data Persistence

```bash
# Stop all services
docker-compose down

# Verify data directory still exists
ls -la ./data/

# Restart services
docker-compose up -d

# Verify same case still exists
curl http://localhost:8003/api/v1/cases/{case_id}
```

**Expected:** All data persists across restarts.

---

## Known Issues to Watch For

### Issue 1: Port Conflicts
**Symptom:** Container fails to start with "port already allocated"
**Fix:** Edit docker-compose.yml and change port mappings:
```yaml
ports:
  - "9001:8000"  # Change 8001 to 9001
```

### Issue 2: Build Failures
**Symptom:** "ERROR [internal] load build context"
**Cause:** Service repos not found in parent directory
**Fix:** Verify repos exist:
```bash
ls -d ../fm-*-service
```

### Issue 3: ChromaDB Connection Errors
**Symptom:** fm-knowledge-service logs show "Connection refused to chromadb:8000"
**Fix:** Wait for ChromaDB health check to pass:
```bash
docker-compose logs chromadb
# Wait until you see: "Application startup complete"
```

### Issue 4: SQLite Database Not Created
**Symptom:** Health checks fail with "database not found"
**Cause:** Database initialization may not have run
**Fix:** Check service logs:
```bash
docker-compose logs fm-case-service | grep "Database initialized"
docker-compose logs fm-evidence-service | grep "Database initialized"
```

### Issue 5: Missing API Key
**Symptom:** fm-agent-service fails or AI queries return errors
**Cause:** .env file has placeholder `OPENAI_API_KEY=sk-...`
**Fix:** Add real API key to .env and restart:
```bash
docker-compose restart fm-agent-service
```

---

## Success Criteria

✅ All 9 containers running (docker-compose ps shows "Up")
✅ ./data/faultmaven.db created with tables
✅ All health endpoints return 200 OK
✅ Can create a case via API
✅ Can upload evidence file
✅ Can search knowledge base
✅ AI agent responds (requires valid API key)
✅ Data persists across restarts

---

## Cleanup (After Testing)

```bash
# Stop all services
docker-compose down

# Remove all data (optional - if starting fresh)
rm -rf ./data/

# Remove Docker volumes (optional)
docker-compose down -v
```

---

## Next Steps After Successful Test

1. Document any issues found
2. Update README.md if procedures differ
3. Create GitHub issue for any bugs
4. Test with real frontend (faultmaven-copilot)
5. Add to CI/CD pipeline
