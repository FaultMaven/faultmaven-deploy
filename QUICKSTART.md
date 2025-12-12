# FaultMaven Self-Hosted - Quick Start Guide

**Get FaultMaven running on your laptop in under 5 minutes.**

---

## ⚡ TL;DR - Four Simple Steps

```bash
# 1. Install: Clone the repository
git clone https://github.com/FaultMaven/faultmaven-deploy.git
cd faultmaven-deploy

# 2. Configure: Set required values
cp .env.example .env
# Edit .env and set:
#   SERVER_HOST=192.168.x.x   # Your server's IP (required!)
#   OPENAI_API_KEY=sk-...     # Or another LLM provider key

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
- **jq** & **curl** (for CLI health checks)
  ```bash
  # Ubuntu/Debian
  sudo apt install jq curl
  # macOS (via Homebrew)
  brew install jq curl
  ```
- **8GB RAM** minimum (16GB recommended for local LLM)
- **LLM Provider** - Choose one option:

  **Option 1: Cloud LLM (Recommended for best performance)**
  - [OpenAI](https://platform.openai.com/api-keys) (GPT-4, GPT-3.5)
  - [Anthropic](https://console.anthropic.com/) (Claude)
  - [Groq](https://console.groq.com/) (FREE tier - ultra-fast Llama/Mixtral)
  - [Gemini](https://makersuite.google.com/app/apikey) (Google)
  - [Fireworks AI](https://fireworks.ai/api-keys) (Open source models)
  - [OpenRouter](https://openrouter.ai/keys) (Aggregated access to multiple providers)

  **Option 2: Local LLM (FREE, private, runs on your machine)**
  - [Ollama](https://ollama.ai/) (easiest setup)
  - [LM Studio](https://lmstudio.ai/) (GUI interface)
  - [LocalAI](https://localai.io/) (advanced users)
  - [vLLM](https://github.com/vllm-project/vllm) (production-grade)

### 🎯 LLM Configuration Guide

FaultMaven gives you **full flexibility** in LLM choice - cloud, local, or hybrid.

**Cloud LLM (Best Performance):**

- Fastest response times (1-2 seconds)
- Best quality for complex reasoning
- Pay per use ($0.10-$0.50 per session with GPT-4)
- No local GPU required

**Local LLM (FREE & Private):**

- Zero API costs (runs on your hardware)
- 100% private (no data leaves your machine)
- Works offline
- Slower inference (5-15 seconds depending on hardware)
- Best with 16GB+ RAM and GPU acceleration

**Hybrid Setup (Best of Both Worlds):**

- Cloud LLM for complex diagnostics (quality + speed)
- Local LLM for knowledge base queries (free + private)
- See Advanced Configuration below

**What runs locally (always):**

- ✅ All services (case management, evidence storage, etc.)
- ✅ ChromaDB vector database
- ✅ Redis session store
- ✅ SQLite data storage

**What varies:**

- ☁️ **Cloud LLM:** Inference via API (only prompts/responses sent)
- 🖥️ **Local LLM:** Everything runs on your machine
- 🔐 **No FaultMaven tracking or data collection in either case**

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
# IMPORTANT: Set your server's IP address or hostname
# This is used by the dashboard to connect to backend services
# Replace with your actual server IP (NOT localhost - that won't work from other devices!)
SERVER_HOST=192.168.0.200  # Change this to your server's IP

# =============================================================================
# LLM Provider Configuration - Choose ONE option below
# =============================================================================

# Option 1: Cloud LLM (recommended for best performance)
OPENAI_API_KEY=sk-your-actual-key-here

# Option 2: Local LLM (FREE, private, runs locally)
# Requires Ollama installed and running (see setup below)
# LOCAL_LLM_API_KEY=not-needed
# LOCAL_LLM_URL=http://localhost:11434/v1
# LOCAL_LLM_MODEL=llama3.1

# Optional: Add more cloud providers for fallback
# ANTHROPIC_API_KEY=sk-ant-...
# GROQ_API_KEY=gsk_...
# FIREWORKS_API_KEY=fw_...

# =============================================================================
# Authentication (Self-Hosted)
# =============================================================================
# IMPORTANT: Change these default credentials!
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=changeme123

# Optional: Headless mode for browser extension
# DEFAULT_USER_TOKEN=my-secret-token
```

**Cloud LLM Setup - Get API keys:**

- OpenAI: <https://platform.openai.com/api-keys>
- Anthropic: <https://console.anthropic.com/>
- Groq: <https://console.groq.com/> (FREE tier available!)
- Gemini: <https://makersuite.google.com/app/apikey>
- Fireworks: <https://fireworks.ai/api-keys>
- OpenRouter: <https://openrouter.ai/keys>

**💡 Tip:** Groq offers a generous FREE tier with ultra-fast inference! Great for testing.

**Local LLM Setup - Using Ollama (easiest method):**

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama server (in separate terminal)
ollama serve

# Pull a model (choose one)
ollama pull llama3.1      # Recommended: balanced quality/speed (4.7GB)
ollama pull llama3.1:70b  # Better quality, slower (40GB, requires 32GB+ RAM)
ollama pull mistral       # Faster, smaller (4.1GB)

# Configure FaultMaven to use Ollama
# In your .env file, uncomment and set:
# LOCAL_LLM_API_KEY=not-needed
# LOCAL_LLM_URL=http://localhost:11434/v1
# LOCAL_LLM_MODEL=llama3.1
```

**Local LLM Setup - Using LM Studio (GUI alternative):**

1. Download LM Studio from <https://lmstudio.ai/>
2. Launch LM Studio and download a model (e.g., "Llama 3.1 8B")
3. Click "Start Server" (default port 1234)
4. Configure FaultMaven:

   ```bash
   LOCAL_LLM_API_KEY=not-needed
   LOCAL_LLM_URL=http://localhost:1234/v1
   LOCAL_LLM_MODEL=llama-3.1-8b-instruct
   ```

**Advanced: Hybrid Setup (Mix Cloud + Local)**

Use cloud LLM for chat, local LLM for knowledge base queries (cost optimization):

```bash
# Cloud provider for complex diagnostics
OPENAI_API_KEY=sk-...

# Local LLM for knowledge base (free!)
LOCAL_LLM_API_KEY=not-needed
LOCAL_LLM_URL=http://localhost:11434/v1
LOCAL_LLM_MODEL=llama3.1

# Task-specific routing
CHAT_PROVIDER=openai
CHAT_MODEL=gpt-4o

SYNTHESIS_PROVIDER=local
SYNTHESIS_MODEL=llama3.1
```

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

**First run takes 2-3 minutes** (downloads pre-built Docker images from GitHub Container Registry).

### Step 5: Access the Dashboard

Once services are running, open your browser:

**Dashboard URL:** http://YOUR_SERVER_IP:3000

Replace `YOUR_SERVER_IP` with the IP address you set in `SERVER_HOST`:
- Example: http://192.168.0.200:3000
- If accessing from the server itself: http://localhost:3000

```
Username: admin
Password: changeme123
```

**⚠️ IMPORTANT:** Change your password immediately after first login! The default credentials are only for initial setup.

**Network Access Note:**
- Most self-hosted servers run **headless** (no GUI browser)
- Access the dashboard from **any device** on your network
- The SERVER_HOST in .env tells the dashboard where to find the backend services
- Works across your local network, VPN, or firewall zone

**Port Architecture Note:** The Dashboard (port 3000) is your web UI. It connects internally to backend API services (ports 8001-8007) which you don't need to access directly. Everything goes through the dashboard.

From the dashboard you can:
- 📚 **Upload knowledge base documents** (runbooks, post-mortems, documentation)
- 🔍 **Search your knowledge base** with semantic search
- 📊 **Manage your documentation** organized by categories
- 👤 **Change your password** (do this first!)

**Browser Extension:** For real-time chat troubleshooting, install the browser extension:
- **Chrome/Edge**: Clone [faultmaven-copilot](https://github.com/FaultMaven/faultmaven-copilot) and load as unpacked extension ([instructions](https://github.com/FaultMaven/faultmaven-copilot#installation))
- **Firefox**: Build instructions in the repository README
- The extension connects to the API Gateway (localhost:8090)

---

## Using the `./faultmaven` CLI

The wrapper script simplifies all operations:

```bash
# Start all services (with pre-flight checks)
./faultmaven start

# Check service status and health
./faultmaven status

# Restart all services or a specific one
./faultmaven restart
./faultmaven restart fm-agent-service

# View logs from all services
./faultmaven logs

# View logs from specific service (last 50 lines)
./faultmaven logs fm-agent-service --tail 50

# Stop all services (preserves data)
./faultmaven stop

# DANGER: Delete all data and reset
./faultmaven clean

# Show version and help
./faultmaven version
./faultmaven help

# Disable colors (useful for CI/scripts)
./faultmaven --no-color status
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
fm-api-gateway          Up (healthy)        0.0.0.0:8090->8090/tcp
fm-auth-service         Up (healthy)        0.0.0.0:8001->8000/tcp
fm-case-service         Up (healthy)        0.0.0.0:8003->8000/tcp
fm-knowledge-service    Up (healthy)        0.0.0.0:8004->8000/tcp
fm-agent-service        Up (healthy)        0.0.0.0:8006->8000/tcp
...

Health Checks:
✓ API Gateway (port 8090)
✓ Auth Service (port 8001)
✓ Session Service (port 8002)
✓ Case Service (port 8003)
✓ Knowledge Service (port 8004)
✓ Evidence Service (port 8005)
✓ Agent Service (port 8006)
```

### Access API Documentation

All APIs are accessible through the API Gateway:

| Service | Swagger UI |
|---------|-----------|
| **API Gateway** | http://localhost:8090/docs |

For direct service access (debugging only):
- Auth Service: http://localhost:8001/docs
- Case Service: http://localhost:8003/docs
- Knowledge Service: http://localhost:8004/docs
- Agent Service: http://localhost:8006/docs
- Evidence Service: http://localhost:8005/docs

---

## Using FaultMaven

### Option 1: Browser Extension (Recommended)

**Coming Soon:** Install `faultmaven-copilot` from Chrome Web Store or Firefox Add-ons.

Configure extension settings:
- API Endpoint: `http://localhost:8090` (API Gateway)

### Option 2: Direct API Calls

All API calls go through the API Gateway on port 8090:

#### Create a troubleshooting case:

```bash
curl -X POST http://localhost:8090/api/v1/cases \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Production API latency spike",
    "description": "Users reporting slow response times",
    "user_id": "user_001"
  }'
```

#### Upload evidence:

```bash
curl -X POST http://localhost:8090/api/v1/evidence \
  -F "file=@/path/to/error.log" \
  -F "case_id=case_abc123" \
  -F "evidence_type=log"
```

#### Query AI agent:

```bash
curl -X POST http://localhost:8090/api/v1/agent/query \
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

If ports 8001-8007 or 8090 are already in use, edit `docker-compose.yml`:

```yaml
ports:
  - "9090:8090"  # Change API Gateway external port
  - "9001:8000"  # Change service external port (internal stays 8000)
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

1. **Explore the API:** Open http://localhost:8090/docs and try the interactive API Gateway
2. **Read architecture docs:** Understand how FaultMaven works ([ARCHITECTURE.md](./ARCHITECTURE.md))
3. **Join community:** [GitHub Discussions](https://github.com/FaultMaven/faultmaven-deploy/discussions)
4. **Report issues:** [GitHub Issues](https://github.com/FaultMaven/faultmaven-deploy/issues)

---

## FAQ

**Q: Can I use Ollama or other local LLMs?**
A: **Yes!** FaultMaven now supports local LLMs (Ollama, LM Studio, LocalAI, vLLM) as a first-class option. Local LLMs are FREE, private, and work offline. They're slower than cloud APIs but perfect for tinkering, privacy-first deployments, or hybrid setups where you use local LLM for knowledge base queries and cloud for complex diagnostics.

**Q: Which is better - cloud or local LLM?**
A: **Cloud LLM** for best performance (1-2s response, highest quality). **Local LLM** for zero cost and privacy (5-15s response, good quality). **Hybrid** for best of both worlds (cloud for chat, local for knowledge base).

**Q: What are the hardware requirements for local LLM?**
A: Minimum 8GB RAM for small models (Llama 3.1 8B, Mistral). Recommended 16GB+ RAM for better performance. GPU acceleration (NVIDIA/AMD/Apple Silicon) significantly speeds up inference. 70B+ parameter models need 32GB+ RAM.

**Q: Is my data sent to FaultMaven servers?**
A: No. All data stays on your laptop. With **cloud LLM**, only prompts/responses go to your chosen provider (OpenAI/Anthropic/etc). With **local LLM**, everything runs on your machine - zero external calls.

**Q: Can I run this in production?**
A: Self-hosted is for **single-user development/testing only**. For production (individuals or teams), use [Enterprise SaaS](https://faultmaven.ai/signup) with auto-scaling, built-in knowledge base, HA PostgreSQL, S3 storage, and 99.9% SLA.

**Q: How do I update to the latest version?**
A: `git pull origin main && ./faultmaven stop && ./faultmaven start --build`

**Q: Can I contribute code?**
A: Yes! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

**FaultMaven** - The most powerful AI troubleshooter you can run on your laptop for free.

**Questions?** Open an issue at https://github.com/FaultMaven/faultmaven-deploy/issues
