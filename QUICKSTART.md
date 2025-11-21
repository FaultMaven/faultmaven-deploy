# FaultMaven Self-Hosted - Quick Start Guide

**Get FaultMaven running on your laptop in under 5 minutes.**

---

## ⚡ TL;DR - Four Simple Steps

```bash
# 1. Install: Clone the repository
git clone https://github.com/FaultMaven/faultmaven-deploy.git
cd faultmaven-deploy

# 2. Secure: Add your API key
cp .env.example .env
# Edit .env and add: OPENAI_API_KEY=sk-...

# 3. Protect: Resource limits (auto-created)
# The ./faultmaven script will create docker-compose.override.yml

# 4. Run: Start everything
./faultmaven start
```

That's it! FaultMaven is now running on your laptop.

---

## Prerequisites

### Required
- **Docker** & **Docker Compose** installed ([Get Docker](https://docs.docker.com/get-docker/))
- **8GB RAM** minimum (16GB recommended)
- **Cloud LLM API Key** - Choose one:
  - [OpenAI](https://platform.openai.com/api-keys) (GPT-4)
  - [Anthropic](https://console.anthropic.com/) (Claude)
  - [Fireworks AI](https://fireworks.ai/api-keys) (Multiple models)

### ⚠️ Important: Cloud LLM Required

FaultMaven self-hosted uses **your choice of cloud AI providers** via API.

**Why not a local LLM like Ollama?**
- Local LLM (Llama 70B+) requires **32GB+ RAM** and a **dedicated GPU**
- Inference speed would be too slow for interactive troubleshooting
- Cloud APIs provide **better quality** and **faster responses**
- Agentic complexity typically fails on smaller local models

**Cost estimate:** $0.10-$0.50 per troubleshooting session (using GPT-4) - cheaper than running GPU hardware.

**What runs locally:**
- ✅ All services (case management, evidence storage, etc.)
- ✅ ChromaDB vector database
- ✅ Redis session store
- ✅ SQLite data storage

**What uses cloud:**
- ☁️ LLM inference only (via your API key)
- ☁️ No FaultMaven tracking or data collection

---

## Installation Steps

### Step 1: Install - Clone Repository

```bash
git clone https://github.com/FaultMaven/faultmaven-deploy.git
cd faultmaven-deploy
```

### Step 2: Secure - Add Your API Key

```bash
cp .env.example .env
```

Edit `.env` and configure:

```bash
# Required: Add at least one API key
OPENAI_API_KEY=sk-your-actual-key-here

# Optional: Add more providers for fallback
# ANTHROPIC_API_KEY=sk-ant-...
# FIREWORKS_API_KEY=fw_...

# Simple Authentication (Self-Hosted)
# IMPORTANT: Change these default credentials!
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=changeme123

# Optional: Headless mode for browser extension
# DEFAULT_USER_TOKEN=my-secret-token
```

**Get API keys:**
- OpenAI: https://platform.openai.com/api-keys
- Anthropic: https://console.anthropic.com/
- Fireworks: https://fireworks.ai/api-keys

**⚠️ Security Note:** The default credentials (`admin`/`changeme123`) are for initial setup only. Change them before deploying anywhere accessible beyond localhost!

**Development Mode:** The auth service runs in simplified "development mode" for self-hosted deployments. While the login page may show "any username works", you should still use the configured `admin` account for consistency and to prepare for future security updates.

### Step 3: Protect - Resource Limits

**This step is automatic!** The `./faultmaven start` command will create `docker-compose.override.yml` with sensible resource limits to keep your laptop usable.

**What it does:**
- Limits AI services to 2GB RAM each
- Prevents ChromaDB from consuming all CPU
- Ensures you can still use other apps

**Customize (optional):**
```bash
# Edit resource limits if you have 16GB+ RAM
nano docker-compose.override.yml
```

### Step 4: Run - Start FaultMaven

```bash
./faultmaven start
```

The wrapper script will:
1. ✅ Check Docker is running
2. ✅ Verify you have enough RAM
3. ✅ Validate your .env file
4. ✅ Create resource limits file
5. ✅ Build and start all services

**First run takes 5-10 minutes** (downloads and builds Docker images).

### Step 5: Access the Dashboard

Once services are running, open your browser:

**Dashboard Login:** http://localhost:3000

```
Username: admin
Password: changeme123
```

**⚠️ IMPORTANT:** Change your password immediately after first login! The default credentials are only for initial setup.

**Port Architecture Note:** The Dashboard (port 3000) is your web UI. It connects internally to backend API services (ports 8001-8007) which you don't need to access directly. Everything goes through the dashboard.

From the dashboard you can:
- 📚 **Upload knowledge base documents** (runbooks, post-mortems, documentation)
- 🔍 **Search your knowledge base** with semantic search
- 📊 **Manage your documentation** organized by categories
- 👤 **Change your password** (do this first!)

**Browser Extension:** For real-time chat troubleshooting, install the browser extension:
- **Chrome/Edge**: Clone [faultmaven-copilot](https://github.com/FaultMaven/faultmaven-copilot) and load as unpacked extension ([instructions](https://github.com/FaultMaven/faultmaven-copilot#installation))
- **Firefox**: Build instructions in the repository README
- The extension connects to the same backend services (localhost:8001-8006)

---

## Using the `./faultmaven` CLI

The wrapper script simplifies all operations:

```bash
# Start all services (with pre-flight checks)
./faultmaven start

# Check service status and health
./faultmaven status

# View logs from all services
./faultmaven logs

# View logs from specific service
./faultmaven logs fm-agent-service

# Stop all services (preserves data)
./faultmaven stop

# DANGER: Delete all data and reset
./faultmaven clean

# Show help
./faultmaven help
```

---

## Verifying Installation

### Check Service Status

```bash
./faultmaven status
```

Expected output:
```
╔════════════════════════════════════════╗
║  FaultMaven Self-Hosted Manager      ║
╚════════════════════════════════════════╝

Service Status:
NAME                    STATUS              PORTS
fm-auth-service         Up (healthy)        0.0.0.0:8001->8001/tcp
fm-case-service         Up (healthy)        0.0.0.0:8003->8003/tcp
fm-knowledge-service    Up (healthy)        0.0.0.0:8004->8004/tcp
fm-agent-service        Up (healthy)        0.0.0.0:8006->8006/tcp
...

Health Checks:
✓ Auth Service (port 8001)
✓ Session Service (port 8002)
✓ Case Service (port 8003)
✓ Knowledge Service (port 8004)
✓ Evidence Service (port 8005)
✓ Agent Service (port 8006)
✓ API Gateway (port 8090)
```

### Access API Documentation

| Service | Swagger UI |
|---------|-----------|
| **Agent Service** | http://localhost:8006/docs |
| **Case Service** | http://localhost:8003/docs |
| **Knowledge Service** | http://localhost:8004/docs |
| **Auth Service** | http://localhost:8001/docs |
| **Evidence Service** | http://localhost:8005/docs |

---

## Using FaultMaven

### Option 1: Browser Extension (Recommended)

**Coming Soon:** Install `faultmaven-copilot` from Chrome Web Store or Firefox Add-ons.

Configure extension settings:
- API Endpoint: `http://localhost:8006`

### Option 2: Direct API Calls

#### Create a troubleshooting case:

```bash
curl -X POST http://localhost:8003/api/v1/cases \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Production API latency spike",
    "description": "Users reporting slow response times",
    "user_id": "user_001"
  }'
```

#### Upload evidence:

```bash
curl -X POST http://localhost:8005/api/v1/evidence \
  -F "file=@/path/to/error.log" \
  -F "case_id=case_abc123" \
  -F "evidence_type=log"
```

#### Query AI agent:

```bash
curl -X POST http://localhost:8006/api/v1/agent/query \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "case_abc123",
    "message": "Analyze the error log and suggest root cause"
  }'
```

---

## Data Management

### Where Your Data Lives

All data is stored in the `./data/` directory:

```
./data/
├── faultmaven.db       # SQLite database (all tables)
└── uploads/            # Evidence files
    └── case_abc123/
        └── error.log
```

### Backup & Restore

```bash
# Backup entire FaultMaven state
zip -r faultmaven-backup-$(date +%Y%m%d).zip ./data

# Restore on another machine
unzip faultmaven-backup-20250120.zip
./faultmaven start
```

**The SQLite database is portable** - move it to another laptop and everything works!

### Reset to Factory Defaults

```bash
./faultmaven clean
# Type 'DELETE' to confirm
```

**⚠️ WARNING:** This permanently deletes all cases, evidence, and knowledge base documents.

---

## Troubleshooting

### Services won't start

```bash
# Check what's failing
./faultmaven status

# View detailed logs
./faultmaven logs

# View logs for specific service
./faultmaven logs fm-agent-service

# Restart all services
./faultmaven stop
./faultmaven start
```

### "Insufficient RAM" warning

You have less than 8GB available. Options:

1. **Close other applications** to free RAM
2. **Reduce resource limits** in `docker-compose.override.yml`
3. **Disable heavy services** (comment out fm-knowledge-service in docker-compose.yml)

### Port conflicts

If ports 8001-8006 are already in use, edit `docker-compose.yml`:

```yaml
ports:
  - "9001:8001"  # Change external port to 9001
```

### Docker daemon not running

```bash
# macOS/Windows: Start Docker Desktop
# Linux: sudo systemctl start docker
```

---

## What's Included vs. What's Not

### ✅ Self-Hosted Includes

- **Complete AI Agent** - Full LangGraph agent with 8 milestones
- **3-Tier RAG System** - Personal KB + Global KB + Case Working Memory
- **All 8 Data Types** - Logs, traces, profiles, metrics, config, code, text, visual
- **SQLite Database** - Zero configuration, single file, portable
- **ChromaDB Vector Search** - Semantic knowledge base retrieval
- **Background Jobs** - Celery + Redis for async processing
- **Local File Storage** - All evidence files stay on your machine
- **Full API Access** - All endpoints available

### ❌ Enterprise-Only Features

- Team collaboration & case sharing
- SSO/SAML authentication
- Multi-tenant organizations
- S3 cloud storage integration
- Advanced analytics dashboards
- Audit logs & compliance reports
- Auto-scaling resources based on demand
- Built-in curated knowledge base
- Professional support & SLA
- Managed hosting with 99.9% uptime

**Need Enterprise features?** [https://faultmaven.ai/signup](https://faultmaven.ai/signup) *(free tier available for individuals & teams)*

---

## Performance Expectations

### On 8GB RAM Laptop
- **Startup time:** 5-10 minutes (first run)
- **Response time:** 2-5 seconds (AI agent queries)
- **Concurrent cases:** 1-2 active investigations
- **Storage limit:** ~10GB (SQLite + uploads)

### On 16GB+ RAM Desktop
- **Startup time:** 2-3 minutes (first run)
- **Response time:** 1-2 seconds (AI agent queries)
- **Concurrent cases:** 5-10 active investigations
- **Storage limit:** ~50GB+ (depends on evidence uploads)

---

## Next Steps

1. **Explore the API:** Open http://localhost:8006/docs and try the interactive API
2. **Read architecture docs:** Understand how FaultMaven works ([ARCHITECTURE.md](./ARCHITECTURE.md))
3. **Join community:** [GitHub Discussions](https://github.com/FaultMaven/faultmaven-deploy/discussions)
4. **Report issues:** [GitHub Issues](https://github.com/FaultMaven/faultmaven-deploy/issues)

---

## FAQ

**Q: Can I use Ollama or other local LLMs?**
A: Not recommended. Agentic workflows require large models (70B+ parameters) that need 32GB+ RAM and GPU. Cloud APIs are faster and cheaper.

**Q: Is my data sent to FaultMaven servers?**
A: No. All data stays on your laptop. Only LLM API calls go to your chosen provider (OpenAI/Anthropic/Fireworks).

**Q: Can I run this in production?**
A: Self-hosted is for **single-user development/testing only**. For production (individuals or teams), use [Enterprise SaaS](https://faultmaven.ai/signup) with auto-scaling, built-in knowledge base, HA PostgreSQL, S3 storage, and 99.9% SLA.

**Q: How do I update to the latest version?**
A: `git pull origin main && ./faultmaven stop && ./faultmaven start --build`

**Q: Can I contribute code?**
A: Yes! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

**FaultMaven** - The most powerful AI troubleshooter you can run on your laptop for free.

**Questions?** Open an issue at https://github.com/FaultMaven/faultmaven-deploy/issues
