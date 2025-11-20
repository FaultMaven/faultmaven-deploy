# FaultMaven Self-Hosted - Quick Start Guide

**Get FaultMaven running on your laptop in 2 minutes.**

---

## Prerequisites

- **Docker** & **Docker Compose** installed
- **8GB RAM** minimum
- **LLM API Key** (OpenAI, Anthropic, or Fireworks AI)

---

## Setup Steps

### 1. Clone Repository

```bash
git clone https://github.com/FaultMaven/product.git faultmaven
cd faultmaven
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and add your LLM API key:

```bash
# Required: Add at least one API key
OPENAI_API_KEY=sk-your-key-here
```

**Get API keys:**
- OpenAI: https://platform.openai.com/api-keys
- Anthropic: https://console.anthropic.com/
- Fireworks: https://fireworks.ai/api-keys

### 3. Start FaultMaven

```bash
docker-compose up -d
```

This will:
- Pull/build 9 Docker containers (7 services + Redis + ChromaDB)
- Create SQLite database at `./data/faultmaven.db`
- Initialize all tables automatically
- Start background job worker

### 4. Verify Health

```bash
# Check all services are running
docker-compose ps

# Test health endpoints
curl http://localhost:8001/health  # Auth Service
curl http://localhost:8003/health  # Case Service
curl http://localhost:8004/health  # Knowledge Service
curl http://localhost:8006/health  # Agent Service
```

Expected response:
```json
{
  "status": "healthy",
  "service": "fm-case-service",
  "version": "1.0.0",
  "database": "sqlite+aiosqlite"
}
```

### 5. Access Services

| Service | URL | Description |
|---------|-----|-------------|
| **Agent Service** | http://localhost:8006 | AI troubleshooting agent |
| **Case Service** | http://localhost:8003 | Case management API |
| **Knowledge Service** | http://localhost:8004 | Knowledge base & semantic search |
| **Auth Service** | http://localhost:8001 | User authentication |
| **Evidence Service** | http://localhost:8005 | File upload & storage |

**API Documentation:**
- http://localhost:8006/docs (Agent Service Swagger UI)
- http://localhost:8003/docs (Case Service Swagger UI)
- http://localhost:8004/docs (Knowledge Service Swagger UI)

---

## Using FaultMaven

### Option 1: Browser Extension (Recommended)

**Coming Soon:** Install `faultmaven-copilot` from Chrome Web Store or Firefox Add-ons.

Configure extension settings:
- API Endpoint: `http://localhost:8006`

### Option 2: Direct API Calls

Create a troubleshooting case:

```bash
curl -X POST http://localhost:8003/api/v1/cases \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Production API latency spike",
    "description": "Users reporting slow response times",
    "user_id": "user_001"
  }'
```

Upload evidence:

```bash
curl -X POST http://localhost:8005/api/v1/evidence \
  -F "file=@/path/to/error.log" \
  -F "case_id=case_abc123" \
  -F "evidence_type=log"
```

Query AI agent:

```bash
curl -X POST http://localhost:8006/api/v1/agent/query \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "case_abc123",
    "message": "Analyze the error log and suggest root cause"
  }'
```

---

## Data Persistence

All your data is stored in the `./data/` directory:

```
./data/
├── faultmaven.db       # SQLite database (all tables)
└── uploads/            # Evidence files
    └── case_abc123/
        └── error.log
```

**Backup:**
```bash
# Backup entire FaultMaven state
zip -r faultmaven-backup.zip ./data

# Restore on another machine
unzip faultmaven-backup.zip
docker-compose up -d
```

**The SQLite database is portable** - you can move it to another laptop and everything works!

---

## Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs fm-case-service
docker-compose logs fm-agent-service

# Restart specific service
docker-compose restart fm-case-service
```

### Database errors

```bash
# Remove old database and restart (WARNING: deletes all data)
rm -rf ./data/
docker-compose down
docker-compose up -d
```

### Port conflicts

If ports 8001-8006 are already in use, edit `docker-compose.yml`:

```yaml
ports:
  - "9001:8000"  # Change 8001 to 9001
```

---

## Stopping FaultMaven

```bash
# Stop all services (data persists)
docker-compose down

# Stop and remove data (WARNING: deletes everything)
docker-compose down -v
rm -rf ./data/
```

---

## What's Included

✅ **Complete AI Agent** - Full LangGraph agent with 8 milestones
✅ **3-Tier RAG System** - Personal KB + Global KB + Case Working Memory
✅ **All 8 Data Types** - Logs, traces, profiles, metrics, config, code, text, visual
✅ **SQLite Database** - Zero configuration, single file, portable
✅ **ChromaDB Vector Search** - Semantic knowledge base retrieval
✅ **Background Jobs** - Celery + Redis for async processing
✅ **Local File Storage** - All evidence files stay on your machine

---

## What's NOT Included (Enterprise Only)

❌ Team collaboration & case sharing
❌ SSO/SAML authentication
❌ Multi-tenant organizations
❌ S3 cloud storage
❌ Advanced analytics dashboards
❌ Professional support & SLA

**Upgrade to Enterprise:** https://faultmaven.ai/signup *(coming soon)*

---

## Next Steps

1. **Read the docs:** [Architecture Overview](./docs/ARCHITECTURE.md)
2. **Contribute:** [Contributing Guide](./CONTRIBUTING.md)
3. **Get help:** [GitHub Discussions](https://github.com/FaultMaven/FaultMaven/discussions)

---

**Questions?** Open an issue at https://github.com/FaultMaven/FaultMaven/issues

**FaultMaven** - The most powerful AI troubleshooter you can run on your laptop for free.
