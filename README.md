# FaultMaven - Self-Hosted Deployment

**An AI-powered troubleshooting copilot you can run anywhere for free.**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/u/faultmaven)

---

## Overview

This repository provides a complete Docker Compose deployment for self-hosting **FaultMaven**, an AI-powered troubleshooting copilot that helps you diagnose and resolve technical issues faster.

**📖 For architectural details and contributing:** See the main [FaultMaven](https://github.com/FaultMaven/FaultMaven) repository.

**What you get with self-hosted deployment:**

- 🤖 **AI Troubleshooting Agent** - LangGraph-powered assistant with milestone-based investigation
- 📚 **3-Tier Knowledge Base** - Personal KB + Global KB + Case Working Memory
- 📊 **8 Data Type Support** - Logs, traces, profiles, metrics, config, code, text, visual
- 🗄️ **Portable SQLite Database** - Zero configuration, single file, easy backups
- 🔍 **Vector Search** - ChromaDB for semantic knowledge retrieval
- ⚙️ **Background Processing** - Celery + Redis for async operations

**Deploy everything in 2 minutes with a single command.**

---

## Who Is This For?

**✅ Perfect For:**
- 👨‍💻 **Developers** - Study architecture, contribute code, learn AI troubleshooting
- 🔬 **Tinkerers** - Experiment with LLMs, RAG, and agentic workflows
- 🔐 **Privacy-conscious** - Keep sensitive data on-premises (air-gapped environments)
- 🌍 **Open-source contributors** - Improve the product, add features

**❌ Not For:**
- Production team use (single-user architecture)
- Collaboration workflows (no case/knowledge sharing)
- Enterprise compliance needs (no SSO/RBAC)

---

## Quick Start

**⚡ Four Simple Steps:**

```bash
# 1. Install: Clone the repository
git clone https://github.com/FaultMaven/faultmaven-deploy.git
cd faultmaven-deploy

# 2. Configure: Add your settings
cp .env.example .env
# Edit .env and add:
#   - LLM API key (any provider: OPENAI_API_KEY, ANTHROPIC_API_KEY, GROQ_API_KEY, etc.)
#   - SERVER_HOST (your server IP, e.g., 192.168.0.200)

# 3. Protect: Resource limits (auto-created by wrapper)
# The ./faultmaven script handles this automatically

# 4. Run: Start everything with one command
./faultmaven start
# Docker automatically pulls pre-built images from Docker Hub
```

**That's it!** FaultMaven is now running.

**What happens during deployment:**

- Docker pulls pre-built container images from [Docker Hub](https://hub.docker.com/u/faultmaven)
- No compilation or building required - images are ready to run
- First deployment downloads ~2-3GB of images (one-time)
- Future updates only download changed layers (faster)

> **📝 Note for Early Adopters:** If you encounter "build path does not exist" errors, it means Docker Hub images haven't been published yet. In this case, you'll need to clone all service repositories. See [Development Setup](#development-setup) below for multi-repo cloning instructions.

### Prerequisites

**Required:**

- **Docker** & **Docker Compose** ([Get Docker](https://docs.docker.com/get-docker/))
- **8GB RAM** minimum (16GB recommended)
  - Default resource limits assume 8GB system RAM
  - Allocates ~5GB total: Agent (1.5GB), Knowledge (2GB), ChromaDB (1GB), Redis (512MB)
  - Remaining ~3GB for OS and other applications
  - **16GB+ systems:** Edit `docker-compose.override.yml` to increase limits for better performance
- **LLM API Key** - Choose one or more:
  - [OpenAI](https://platform.openai.com/api-keys) (GPT-4, GPT-3.5)
  - [Anthropic](https://console.anthropic.com/) (Claude)
  - [Groq](https://console.groq.com/) (FREE tier - ultra-fast!)
  - [Gemini](https://makersuite.google.com/app/apikey) (Google)
  - [Fireworks AI](https://fireworks.ai/api-keys) (Open source models)
  - [OpenRouter](https://openrouter.ai/keys) (Multi-provider aggregation)

### 🎯 **LLM Provider Options**

FaultMaven self-hosted uses **one LLM for all tasks** (simplified configuration). Choose from:

- **Cloud providers**: OpenAI, Anthropic, Groq, Gemini, Fireworks, OpenRouter
- **Local option**: Ollama, LM Studio, LocalAI, vLLM

Configure one provider and it handles chat, knowledge base queries, and all AI operations.

**Choose your deployment model:**

#### Option 1: Cloud LLM (Recommended for best performance)

- ✅ Fastest response times (1-2 seconds)
- ✅ Best quality for complex reasoning
- ✅ No local hardware requirements
- 💰 Cost: $0.10-$0.50 per troubleshooting session

#### Option 2: Local LLM (FREE, privacy-first)

- ✅ Zero API costs (runs on your hardware)
- ✅ 100% private (no data leaves your machine)
- ✅ Works offline
- ⚙️ Hardware: 8GB+ RAM for small models, 16GB+ recommended
- ⚙️ GPU acceleration recommended for best performance
- ⏱️ Slower inference (5-15 seconds vs 1-2 seconds)

> **Need task-specific LLM routing?** The [FaultMaven Managed SaaS](https://github.com/FaultMaven/FaultMaven#2-managed-saas) supports hybrid deployment with automatic routing: cloud LLMs for complex diagnostics, local LLMs for knowledge base queries (10x+ cost savings).

**What runs locally (always):**

- ✅ 6 microservices: auth, session, case, knowledge, evidence, agent
- ✅ API Gateway (single entry point)
- ✅ Dashboard web UI for Global KB management
- ✅ 2 background workers: Celery worker + Celery Beat scheduler
- ✅ ChromaDB vector database
- ✅ Redis session store
- ✅ SQLite data storage
- ✅ All your sensitive data stays on your machine

**What varies by LLM choice:**

- ☁️ **Cloud LLM**: Inference via API (only prompts/responses sent, no tracking)
- 🖥️ **Local LLM**: Everything runs locally (zero external calls)
- 🔀 **Hybrid**: Smart routing based on task type

**Your data never leaves your laptop** - only anonymous prompts/responses go to the LLM provider you choose.

---

## Using the CLI Wrapper

The `./faultmaven` script simplifies deployment with pre-flight checks and resource management:

```bash
# Start with full validation
./faultmaven start

# Check service status and health
./faultmaven status

# View logs (all services)
./faultmaven logs

# View logs (specific service)
./faultmaven logs fm-agent-service

# Stop services (preserves data)
./faultmaven stop

# Verify installation (test end-to-end functionality)
./faultmaven verify

# Reset to factory defaults (DANGER: deletes all data)
./faultmaven clean

# Show help
./faultmaven help
```

### Verifying Your Installation

After deployment, verify everything works with the automated test suite:

```bash
./faultmaven verify
```

**What the verification test does:**

1. ✅ Checks all service health endpoints
2. ✅ Creates a test case via API
3. ✅ Uploads test evidence (log file)
4. ✅ Queries the AI agent
5. ✅ Verifies database persistence
6. ✅ Tests knowledge base search
7. ✅ Confirms end-to-end workflow

**Expected output:**

```text
🔍 Running FaultMaven verification tests...
✅ All services healthy
✅ Case created successfully (ID: case_test_123)
✅ Evidence uploaded successfully
✅ AI agent responded (latency: 1.2s)
✅ Database persistence confirmed
✅ Knowledge base operational
🎉 All tests passed! FaultMaven is ready to use.
```

**If verification fails:**

- Run `./faultmaven status` to check service health
- Run `./faultmaven logs <service-name>` to view error logs
- See [Troubleshooting](#troubleshooting) section below

---

**The wrapper automatically:**
- ✅ Checks Docker is running
- ✅ Verifies you have 8GB+ RAM
- ✅ Validates .env file has API key
- ✅ Creates resource limits (docker-compose.override.yml)
- ✅ Tests service health endpoints

---

## Manual Deployment (Advanced)

If you prefer direct Docker Compose commands:

```bash
# Configure environment
cp .env.example .env
# Edit .env and add your LLM API key (see .env.example for all provider options)

# Create resource limits (recommended)
cp docker-compose.override.yml.example docker-compose.override.yml

# Start all services (pulls pre-built images from Docker Hub)
docker-compose up -d

# Check status
docker-compose ps

# Test health endpoints
# Note: Replace <SERVER_HOST> with 'localhost' (if on server) or server IP (if remote)
curl http://<SERVER_HOST>:8001/health  # Auth Service
curl http://<SERVER_HOST>:8002/health  # Session Service
curl http://<SERVER_HOST>:8003/health  # Case Service
curl http://<SERVER_HOST>:8004/health  # Knowledge Service
curl http://<SERVER_HOST>:8005/health  # Evidence Service
curl http://<SERVER_HOST>:8006/health  # Agent Service

# Access web dashboard
# Replace <SERVER_HOST> with your server's IP address (from .env SERVER_HOST)
# Use 'localhost' only if accessing from the server itself
open http://<SERVER_HOST>:3000
# Example: http://192.168.0.200:3000

# ⚠️ SECURITY WARNING: Change default credentials immediately!
# Login: admin / changeme123
```

Expected health response:
```json
{
  "status": "healthy",
  "service": "fm-case-service",
  "version": "1.0.0",
  "database": "sqlite+aiosqlite"
}
```

**✅ FaultMaven is ready!**

---

## Using FaultMaven

### Browser Extension - REQUIRED for AI Chat

**⚠️ IMPORTANT:** The browser extension is **REQUIRED** to interact with the FaultMaven AI agent. The backend server alone does not provide a chat interface.

#### Installation Options

**Option 1: Chrome Web Store** (Recommended)
```bash
# Coming soon - FaultMaven Copilot will be published to the Chrome Web Store
# Search for "FaultMaven Copilot" in Chrome Web Store
```

**Option 2: Install from GitHub** (Available Now)
```bash
# 1. Download the latest release
git clone https://github.com/FaultMaven/faultmaven-copilot.git
cd faultmaven-copilot

# 2. Build the extension
pnpm install
pnpm build

# 3. Load in Chrome
# - Open chrome://extensions/
# - Enable "Developer mode"
# - Click "Load unpacked"
# - Select the faultmaven-copilot/dist directory
```

#### Configure Extension

After installation, configure the extension to connect to your FaultMaven server:

```bash
# 1. Click the FaultMaven extension icon in Chrome
# 2. Go to Settings
# 3. Set API URL to: http://<SERVER_HOST>:8090
#    Example: http://192.168.0.200:8090
# 4. Login with your dashboard credentials (default: admin/changeme123)
```

#### What Each Component Does

| Component | Purpose | Required For |
|-----------|---------|--------------|
| **Browser Extension** | AI chat interface, real-time troubleshooting, evidence upload | ✅ **AI chat** (REQUIRED) |
| **Dashboard** (Port 3000) | Knowledge base management, document upload, user settings | Knowledge base only (optional) |
| **Backend Server** | API services, AI agent, data processing | Everything (REQUIRED) |

**Note:** Without the browser extension, you can only interact with FaultMaven via direct API calls (developer option). The dashboard at port 3000 is for knowledge base management only, NOT for chatting with the AI agent.

---

## Architecture

```mermaid
graph TB
    subgraph "User Interfaces"
        UI1["Browser Extension<br/>faultmaven-copilot<br/>• Real-time chat<br/>• Interactive Q&A<br/>• Evidence upload"]
        UI2["Dashboard Web UI<br/>Port 3000<br/>• Login/Authentication<br/>• Global KB management<br/>• Document upload"]
    end

    subgraph "API Layer"
        GW["API Gateway<br/>Port 8090<br/>Main entry point"]
    end

    subgraph "Microservices (Ports 8001-8006)"
        AUTH["Auth Service<br/>:8001<br/>Simple Auth"]
        SESSION["Session Service<br/>:8002<br/>Redis Sessions"]
        CASE["Case Service<br/>:8003<br/>Milestone Tracking"]
        KNOWLEDGE["Knowledge Service<br/>:8004<br/>3-Tier RAG"]
        EVIDENCE["Evidence Service<br/>:8005<br/>File Upload"]
        AGENT["Agent Service<br/>:8006<br/>LangGraph AI"]
    end

    subgraph "Data Layer"
        DB1[("SQLite<br/>/data/")]
        REDIS[("Redis<br/>:6379")]
        CHROMA[("ChromaDB<br/>:8007")]
        FILES[("File Storage<br/>./data/files")]
    end

    subgraph "Background Processing"
        WORKER["Celery Worker<br/>Job Processing"]
        BEAT["Celery Beat<br/>Scheduler"]
    end

    subgraph "External Services"
        LLM["Cloud LLM<br/>OpenAI/Anthropic/Groq"]
    end

    UI1 -->|HTTP API| GW
    UI2 -->|HTTP API| GW

    GW --> AUTH
    GW --> SESSION
    GW --> CASE
    GW --> KNOWLEDGE
    GW --> EVIDENCE
    GW --> AGENT

    AUTH --> DB1
    SESSION --> REDIS
    CASE --> DB1
    KNOWLEDGE --> CHROMA
    EVIDENCE --> FILES
    AGENT --> LLM

    WORKER --> REDIS
    BEAT --> REDIS
    WORKER --> LLM

    style GW fill:#4A90E2,stroke:#2E5C8A,stroke-width:3px,color:#fff
    style AGENT fill:#E27D60,stroke:#C25A3C,stroke-width:2px,color:#fff
    style LLM fill:#85C88A,stroke:#5A9F5E,stroke-width:2px,color:#fff
    style UI1 fill:#9B59B6,stroke:#6C3483,stroke-width:2px,color:#fff
    style UI2 fill:#9B59B6,stroke:#6C3483,stroke-width:2px,color:#fff
```

### Services

| Service | Port | Description |
|---------|------|-------------|
| **API Gateway** | 8090 | Main entry point for all client requests |
| **Auth Service** | 8001 | User authentication (JWT, Redis sessions) |
| **Session Service** | 8002 | Session management with Redis |
| **Case Service** | 8003 | Case lifecycle & milestone tracking |
| **Knowledge Service** | 8004 | 3-tier RAG knowledge base (ChromaDB + BGE-M3) |
| **Evidence Service** | 8005 | File uploads (logs, screenshots, configs) |
| **Agent Service** | 8006 | AI troubleshooting agent (LangGraph + MilestoneEngine) |
| **Dashboard** | 3000 | Web UI for Global KB management (React + Vite) |
| **Job Worker** | - | Background tasks (Celery + Redis) |
| **Job Worker Beat** | - | Celery task scheduler |
| **Redis** | 6379 | Session storage & task queue |
| **ChromaDB** | 8007 | Vector database for semantic search |

**Note:** Individual service ports (8001-8007) are exposed for health checks and debugging. All API requests should go through the **API Gateway on port 8090**.

---

## Data Persistence

All data is stored in the `./data/` directory:

```
./data/
├── faultmaven.db       # SQLite database (all microservices share this file)
└── uploads/            # Evidence files
    └── case_abc123/
        └── error.log
```

**Benefits:**
- ✅ **Portable** - Zip entire `./data/` folder and move to another laptop
- ✅ **Simple Backup** - `zip -r backup.zip ./data`
- ✅ **Version Control Friendly** - `.gitignore` excludes `/data/`
- ✅ **Survives Restarts** - Data persists across `docker-compose down`

**Backup:**
```bash
# Backup entire FaultMaven state
zip -r faultmaven-backup-$(date +%Y%m%d).zip ./data

# Restore on another machine
unzip faultmaven-backup-20251120.zip
docker-compose up -d
```

---

## What's Included

- ✅ **Complete AI Agent** - Full LangGraph agent with 8 milestones
- ✅ **3-Tier RAG System** - Personal KB + Global KB + Case Working Memory
- ✅ **All 8 Data Types** - Logs, traces, profiles, metrics, config, code, text, visual
- ✅ **SQLite Database** - Zero configuration, single file, portable
- ✅ **ChromaDB Vector Search** - Semantic knowledge base retrieval
- ✅ **Background Jobs** - Celery + Redis for async processing
- ✅ **Local File Storage** - All evidence files stay on your machine

---

## 🚀 Need Production-Ready Infrastructure?

> **Self-hosted is single-user only.** For production use, try **[FaultMaven Managed SaaS](https://github.com/FaultMaven/FaultMaven#2-managed-saas)** — available **for free** for individuals and teams.
>
> Get elastic resource management, optimized performance, and enterprise-grade features. **[Learn More →](https://github.com/FaultMaven/FaultMaven#2-managed-saas)**

---

## API Usage Examples

All API requests should go through the **API Gateway (port 8090)** - the single entry point for all client requests.

**Important:** Replace `<SERVER_HOST>` below with:

- `localhost` if running commands ON the FaultMaven server itself
- Your server IP (e.g., `192.168.0.200`) if running FROM a different machine

### Create a Case

```bash
curl -X POST http://<SERVER_HOST>:8090/api/v1/cases \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Production API latency spike",
    "description": "Users reporting slow response times",
    "user_id": "user_001"
  }'
```

### Upload Evidence

```bash
curl -X POST http://<SERVER_HOST>:8090/api/v1/evidence \
  -F "file=@/path/to/error.log" \
  -F "case_id=case_abc123" \
  -F "evidence_type=log"
```

### Query AI Agent

```bash
curl -X POST http://<SERVER_HOST>:8090/api/v1/agent/query \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "case_abc123",
    "message": "Analyze the error log and suggest root cause"
  }'
```

**See [QUICKSTART.md](QUICKSTART.md) for complete API reference.**

---

## Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs fm-case-service
docker-compose logs fm-agent-service

# Restart specific service
docker-compose restart fm-case-service

# Rebuild all services
docker-compose up -d --build
```

### Database errors

```bash
# Remove old database and restart (WARNING: deletes all data)
rm -rf ./data/
docker-compose down
docker-compose up -d
```

### Port conflicts

If ports are already in use, edit `docker-compose.yml`:

```yaml
ports:
  - "9001:8000"  # Change external port (e.g., 8001 to 9001)
```

**Port ranges used:**
- **8001-8007**: Backend microservices + ChromaDB
- **8090**: API Gateway (main entry point)
- **3000**: Dashboard web UI
- **6379**: Redis

### ChromaDB connection issues

**⚠️ Note:** ChromaDB doesn't have a built-in health check endpoint. Services that depend on it use retry logic to handle startup timing.

```bash
# Check if ChromaDB container is running
docker-compose ps chromadb

# View ChromaDB logs for errors
docker-compose logs chromadb

# Test ChromaDB manually
curl http://localhost:8007/api/v1/heartbeat

# If ChromaDB is slow to start, wait 10-15 seconds then restart dependent services
docker-compose restart fm-knowledge-service
docker-compose restart fm-agent-service

# Full ChromaDB restart
docker-compose restart chromadb
```

**Common ChromaDB issues:**

- **Slow startup:** ChromaDB can take 10-15 seconds to fully initialize. Wait before accessing it.
- **Race conditions:** If knowledge service starts before ChromaDB is ready, it will retry automatically (up to 5 times with exponential backoff).
- **Connection refused:** Check that port 8007 isn't in use by another application.

---

## Updating

To update to the latest version:

```bash
# Pull latest changes
git pull origin main

# Rebuild containers
docker-compose up -d --build

# Verify services are healthy
docker-compose ps
curl http://<SERVER_HOST>:8003/health  # Replace <SERVER_HOST> with 'localhost' or server IP
```

---

## Stopping FaultMaven

```bash
# Stop all services (data persists in ./data/)
docker-compose down

# Stop and remove data (WARNING: deletes everything)
docker-compose down -v
rm -rf ./data/
```

---

## Development Setup

### ⚠️ For Contributors & Early Adopters Only

If Docker Hub images aren't available yet, you'll need to clone all service repositories and build locally:

```bash
# Create a workspace directory
mkdir faultmaven-workspace
cd faultmaven-workspace

# Clone deployment repository
git clone https://github.com/FaultMaven/faultmaven-deploy.git

# Clone all service repositories (required for local builds)
repos=(
  "fm-core-lib"
  "fm-auth-service"
  "fm-session-service"
  "fm-case-service"
  "fm-knowledge-service"
  "fm-evidence-service"
  "fm-agent-service"
  "fm-api-gateway"
  "fm-job-worker"
  "faultmaven-dashboard"
)

for repo in "${repos[@]}"; do
  git clone https://github.com/FaultMaven/$repo.git
done

# Now deploy from the deploy repository
cd faultmaven-deploy
cp .env.example .env
# Edit .env with your settings
./faultmaven start
```

**Directory structure after cloning:**

```text
faultmaven-workspace/
├── faultmaven-deploy/          # This repo
├── fm-auth-service/             # Auth microservice
├── fm-session-service/          # Session microservice
├── fm-case-service/             # Case microservice
├── fm-knowledge-service/        # Knowledge microservice
├── fm-evidence-service/         # Evidence microservice
├── fm-agent-service/            # Agent microservice
├── fm-api-gateway/              # API Gateway
├── fm-job-worker/               # Background jobs
├── faultmaven-dashboard/        # Web UI
└── fm-core-lib/                 # Shared library
```

---

## Components

This deployment uses microservices from:

- [fm-core-lib](https://github.com/FaultMaven/fm-core-lib) - Shared models & LLM infrastructure
- [fm-auth-service](https://github.com/FaultMaven/fm-auth-service) - Authentication & user management
- [fm-session-service](https://github.com/FaultMaven/fm-session-service) - Session management (Redis)
- [fm-case-service](https://github.com/FaultMaven/fm-case-service) - Milestone-based case lifecycle
- [fm-knowledge-service](https://github.com/FaultMaven/fm-knowledge-service) - 3-tier RAG knowledge base (ChromaDB)
- [fm-evidence-service](https://github.com/FaultMaven/fm-evidence-service) - File upload & storage
- [fm-agent-service](https://github.com/FaultMaven/fm-agent-service) - AI troubleshooting agent (LangGraph + MilestoneEngine)
- [fm-api-gateway](https://github.com/FaultMaven/fm-api-gateway) - API Gateway (main entry point for all requests)
- [fm-job-worker](https://github.com/FaultMaven/fm-job-worker) - Background task processing (Celery)
- [faultmaven-dashboard](https://github.com/FaultMaven/faultmaven-dashboard) - Web UI for Global KB management (React + Vite)
- [faultmaven-copilot](https://github.com/FaultMaven/faultmaven-copilot) - Browser extension for interactive troubleshooting

---

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Detailed setup and usage guide
- **[Architecture Overview](https://github.com/FaultMaven/FaultMaven/blob/main/docs/ARCHITECTURE.md)** - System design
- **[Deployment Guide](https://github.com/FaultMaven/FaultMaven/blob/main/docs/DEPLOYMENT.md)** - Advanced deployment options and configurations
- **[API Reference](https://github.com/FaultMaven/FaultMaven/blob/main/docs/API.md)** - Complete endpoint documentation

---

## License

**Apache 2.0 License** - See [LICENSE](LICENSE) for details.

**Why Apache 2.0?**
- ✅ Use commercially without restrictions
- ✅ Fork, modify, commercialize freely
- ✅ Patent grant protection
- ✅ Enterprise-friendly (same license as Kubernetes, Android)

**TL;DR:** You can use FaultMaven for anything, including building commercial products. No strings attached.

---

## Support

- **GitHub Issues**: [Report bugs](https://github.com/FaultMaven/faultmaven-deploy/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/FaultMaven/faultmaven-deploy/discussions)
- **Main Project**: [FaultMaven](https://github.com/FaultMaven/FaultMaven)

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](https://github.com/FaultMaven/FaultMaven/blob/main/CONTRIBUTING.md) for guidelines.

**Quick start:**
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test locally
4. Commit (`git commit -m 'Add amazing feature'`)
5. Push (`git push origin feature/amazing-feature`)
6. Open Pull Request

---

**FaultMaven** - Making troubleshooting faster, smarter, and more collaborative.
