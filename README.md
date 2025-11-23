# FaultMaven - Self-Hosted Deployment

**The most powerful AI troubleshooter you can run on your laptop for free.**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/u/faultmaven)

---

## Overview

This repository provides a complete Docker Compose deployment for self-hosting **FaultMaven**, an AI-powered troubleshooting platform with:

- 🤖 **Complete AI Agent** - Full LangGraph agent with milestone-based investigation
- 📚 **3-Tier RAG System** - Personal KB + Global KB + Case Working Memory
- 📊 **8 Data Types** - Logs, traces, profiles, metrics, config, code, text, visual
- 🗄️ **SQLite Database** - Zero configuration, single file, portable
- 🔍 **ChromaDB Vector Search** - Semantic knowledge base retrieval
- ⚙️ **Background Jobs** - Celery + Redis for async processing

**Deploy the entire platform in 2 minutes with a single command.**

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

# 2. Secure: Add your API key
cp .env.example .env
# Edit .env and add: OPENAI_API_KEY=sk-...

# 3. Protect: Resource limits (auto-created by wrapper)
# The ./faultmaven script handles this automatically

# 4. Run: Start everything with one command
./faultmaven start
```

**That's it!** FaultMaven is now running on your laptop.

### Prerequisites

**Required:**
- **Docker** & **Docker Compose** ([Get Docker](https://docs.docker.com/get-docker/))
- **8GB RAM** minimum (16GB recommended)
- **Cloud LLM API Key** - Choose one or more:
  - [OpenAI](https://platform.openai.com/api-keys) (GPT-4, GPT-3.5)
  - [Anthropic](https://console.anthropic.com/) (Claude)
  - [Groq](https://console.groq.com/) (FREE tier - ultra-fast!)
  - [Gemini](https://makersuite.google.com/app/apikey) (Google)
  - [Fireworks AI](https://fireworks.ai/api-keys) (Open source models)
  - [OpenRouter](https://openrouter.ai/keys) (Multi-provider aggregation)

### 🎯 **LLM Provider Options**

FaultMaven self-hosted supports **7 LLM providers** with automatic fallback:

- **6 Cloud providers**: OpenAI, Anthropic, Groq, Gemini, Fireworks, OpenRouter
- **1 Local option**: Ollama, LM Studio, LocalAI, vLLM

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

#### Option 3: Hybrid (Best of both worlds)

- ✅ Cloud LLM for complex diagnostics (quality + speed)
- ✅ Local LLM for knowledge base queries (free + private)
- ✅ Cost optimization: 10x+ savings on high-volume RAG queries

**What runs locally (always):**

- ✅ All 6 microservices (auth, case, evidence, knowledge, agent, session)
- ✅ Dashboard web UI for knowledge base management
- ✅ Background job workers (Celery)
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

# Reset to factory defaults (DANGER: deletes all data)
./faultmaven clean

# Show help
./faultmaven help
```

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
# Edit .env and add: OPENAI_API_KEY=sk-...

# Create resource limits (recommended)
cp docker-compose.override.yml.example docker-compose.override.yml

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# Test health endpoints
curl http://localhost:8001/health  # Auth Service
curl http://localhost:8002/health  # Session Service
curl http://localhost:8003/health  # Case Service
curl http://localhost:8004/health  # Knowledge Service
curl http://localhost:8005/health  # Evidence Service
curl http://localhost:8006/health  # Agent Service

# Access web dashboard
# Replace SERVER_IP with your server's IP address (set in .env as SERVER_HOST)
open http://SERVER_IP:3000  # Knowledge Base Management Dashboard
# Example: http://192.168.0.200:3000
# Login: admin / changeme123 (change password after first login!)
# Note: Works from any device on your network - most servers are headless!
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

**✅ FaultMaven is ready!** See [QUICKSTART.md](QUICKSTART.md) for detailed usage guide.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        USER INTERFACES                        │
├──────────────────────────┬───────────────────────────────────┤
│  Browser Extension (UI)  │    Dashboard Web UI (Port 3000)   │
│  faultmaven-copilot      │    faultmaven-dashboard           │
│  • Real-time chat        │    • Login/Authentication         │
│  • Interactive Q&A       │    • Knowledge Base management    │
│  • Evidence upload       │    • Document upload              │
└────────────┬─────────────┴──────────────┬────────────────────┘
             │                            │
             │           HTTP API         │
             ▼                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Backend Microservices (Ports 8001-8006)         │
├─────────┬───────────┬───────────┬──────────┬───────┬────────┤
│  Auth   │  Session  │   Case    │Knowledge │Evidence│ Agent  │
│  :8001  │   :8002   │   :8003   │  :8004   │ :8005  │ :8006  │
│         │           │           │          │        │        │
│ Simple  │ Redis     │ Milestone │ 3-Tier   │ File   │LangGraph│
│ Auth    │ Sessions  │ Tracking  │   RAG    │ Upload │  AI    │
└────┬────┴─────┬─────┴─────┬─────┴────┬─────┴───┬────┴────┬───┘
     │          │           │          │         │         │
     ▼          ▼           ▼          ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐ ┌─────┐ ┌──────┐
│ SQLite │ │ Redis  │ │ SQLite │ │ ChromaDB │ │./data││Cloud │
│/data/  │ │:6379   │ │/data/  │ │  :8007   │ │files││ LLM  │
└────────┘ └────────┘ └────────┘ └──────────┘ └─────┘ └──────┘
                                                         ▲
                            Background Workers           │
                            ┌──────────┬──────────┐      │
                            │Job Worker│Worker Beat│     │
                            │ (Celery) │(Scheduler)│─────┘
                            └──────────┴──────────┘
```

### Services

| Service | Port | Description |
|---------|------|-------------|
| **Auth Service** | 8001 | User authentication (JWT, Redis sessions) |
| **Session Service** | 8002 | Session management with Redis |
| **Case Service** | 8003 | Case lifecycle & milestone tracking |
| **Knowledge Service** | 8004 | 3-tier RAG knowledge base (ChromaDB + BGE-M3) |
| **Evidence Service** | 8005 | File uploads (logs, screenshots, configs) |
| **Agent Service** | 8006 | AI troubleshooting agent (LangGraph + MilestoneEngine) |
| **Dashboard** | 3000 | Web UI for knowledge base management (React + Nginx) |
| **Job Worker** | - | Background tasks (Celery + Redis) |
| **Job Worker Beat** | - | Celery task scheduler |
| **Redis** | 6379 | Session storage & task queue |
| **ChromaDB** | 8007 | Vector database for semantic search |

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

### Create a Case

```bash
curl -X POST http://localhost:8003/api/v1/cases \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Production API latency spike",
    "description": "Users reporting slow response times",
    "user_id": "user_001"
  }'
```

### Upload Evidence

```bash
curl -X POST http://localhost:8005/api/v1/evidence \
  -F "file=@/path/to/error.log" \
  -F "case_id=case_abc123" \
  -F "evidence_type=log"
```

### Query AI Agent

```bash
curl -X POST http://localhost:8006/api/v1/agent/query \
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
- **8001-8007**: Backend services + ChromaDB
- **3000**: Dashboard web UI
- **6379**: Redis

### ChromaDB connection issues

```bash
# Check ChromaDB health
curl http://localhost:8007/api/v1/heartbeat

# Restart ChromaDB
docker-compose restart chromadb
```

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
curl http://localhost:8003/health
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

## Components

This deployment uses microservices from:

- [fm-core-lib](https://github.com/FaultMaven/fm-core-lib) - Shared models & LLM infrastructure
- [fm-auth-service](https://github.com/FaultMaven/fm-auth-service) - Authentication & user management
- [fm-session-service](https://github.com/FaultMaven/fm-session-service) - Session management (Redis)
- [fm-case-service](https://github.com/FaultMaven/fm-case-service) - Milestone-based case lifecycle
- [fm-knowledge-service](https://github.com/FaultMaven/fm-knowledge-service) - 3-tier RAG knowledge base (ChromaDB)
- [fm-evidence-service](https://github.com/FaultMaven/fm-evidence-service) - File upload & storage
- [fm-agent-service](https://github.com/FaultMaven/fm-agent-service) - AI troubleshooting agent (LangGraph + MilestoneEngine)
- [fm-job-worker](https://github.com/FaultMaven/fm-job-worker) - Background task processing (Celery)
- [faultmaven-dashboard](https://github.com/FaultMaven/faultmaven-dashboard) - Web UI for knowledge base management (React + Vite)
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
