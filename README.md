# FaultMaven - Self-Hosted Deployment

**One-command deployment of FaultMaven AI troubleshooting platform**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

## Overview

This repository provides a complete Docker Compose deployment for self-hosting FaultMaven, an AI-powered troubleshooting copilot with milestone-based investigation and 3-tier RAG knowledge base. Deploy the entire platform with a single command.

**New in v2.0**: MilestoneEngine for opportunistic AI investigation, LangGraph stateful agents, and 3-tier RAG architecture (User KB, Global KB, Case Evidence).

## Quick Start

```bash
# Clone repository
git clone https://github.com/FaultMaven/faultmaven-deploy.git
cd faultmaven-deploy

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

FaultMaven will be available at `http://localhost:8090`

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    API Gateway (8090)                    │
│              http://localhost:8090/api/v1                │
└───────────┬─────────────────────────────────────────────┘
            │
            ├──> Auth Service (8001)       - JWT authentication
            ├──> Session Service (8002)    - Redis session storage
            ├──> Case Service (8003)       - Milestone-based case tracking
            ├──> Knowledge Service (8004)  - 3-tier RAG (ChromaDB + BGE-M3)
            ├──> Evidence Service (8005)   - File uploads (local storage)
            ├──> Agent Service (8006)      - AI troubleshooting (MilestoneEngine)
            └──> Job Worker                - Async tasks (Celery + Redis)
                        │
                        ├──> Redis (6379)     - Sessions, cache & task queue
                        └──> ChromaDB (8000)  - Vector embeddings
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| **API Gateway** | 8090 | Central routing and authentication |
| **Auth Service** | 8001 | User authentication with JWT |
| **Session Service** | 8002 | Session management with Redis |
| **Case Service** | 8003 | Case lifecycle with milestone tracking |
| **Knowledge Service** | 8004 | 3-tier RAG knowledge base (User KB, Global KB, Case Evidence) |
| **Evidence Service** | 8005 | File upload/download |
| **Agent Service** | 8006 | AI troubleshooting agent (LangGraph + MilestoneEngine) |
| **Job Worker** | - | Background tasks (document ingestion, case cleanup) |
| **Redis** | 6379 | Session storage & task queue |
| **ChromaDB** | 8000 | Vector database for semantic search |

## Data Persistence

All data is persisted in Docker volumes:

- `redis-data` - Redis session storage & Celery task queue
- `chromadb-data` - Vector embeddings for semantic search
- `auth-data` - User authentication database (SQLite)
- `case-data` - Case management database (SQLite)
- `knowledge-data` - Document metadata
- `evidence-data` - Uploaded files

To backup data:
```bash
docker-compose down
docker run --rm -v faultmaven-deploy_case-data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data
```

To restore data:
```bash
docker run --rm -v faultmaven-deploy_case-data:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /
```

## Configuration

Default configuration works out of the box. To customize, create a `.env` file:

```bash
# LLM Provider API Keys (required for AI agent)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
FIREWORKS_API_KEY=fw_...

# Open Core Configuration
PROFILE=public              # Options: public, enterprise
DB_TYPE=sqlite              # Options: sqlite, postgresql

# Service ports (optional)
AUTH_PORT=8001
SESSION_PORT=8002
CASE_PORT=8003
KNOWLEDGE_PORT=8004
EVIDENCE_PORT=8005
AGENT_PORT=8006
GATEWAY_PORT=8090

# Infrastructure (optional)
REDIS_HOST=redis
REDIS_PORT=6379
CHROMADB_HOST=chromadb
CHROMADB_PORT=8000

# Authentication (optional)
JWT_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# File uploads (optional)
MAX_FILE_SIZE_MB=50
```

## Usage

### 1. Register a User

```bash
curl -X POST http://localhost:8090/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "secure_password",
    "full_name": "John Doe"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:8090/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "secure_password"
  }'
```

Response includes `access_token` and `refresh_token`.

### 3. Create a Case

```bash
curl -X POST http://localhost:8090/api/v1/cases \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Database connection timeout",
    "description": "Users experiencing intermittent timeouts"
  }'
```

### 4. Upload Evidence

```bash
curl -X POST http://localhost:8090/api/v1/evidence \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "file=@application.log" \
  -F "case_id=case_abc123" \
  -F "evidence_type=log"
```

### 5. Search Knowledge Base

```bash
curl -X POST http://localhost:8090/api/v1/knowledge/search \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How to fix database timeouts?",
    "limit": 5
  }'
```

### 6. Get AI Troubleshooting Help

```bash
curl -X POST http://localhost:8090/api/v1/agent/investigate \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "case_abc123",
    "message": "The database is timing out intermittently during peak hours"
  }'
```

The AI agent uses MilestoneEngine to opportunistically complete investigation milestones and provide adaptive troubleshooting guidance.

## Health Checks

Check service health:

```bash
# Overall gateway health
curl http://localhost:8090/health

# Individual services
curl http://localhost:8001/health  # Auth
curl http://localhost:8002/health  # Session
curl http://localhost:8003/health  # Case
curl http://localhost:8004/health  # Knowledge
curl http://localhost:8005/health  # Evidence
curl http://localhost:8006/health  # Agent (AI troubleshooting)

# Infrastructure
curl http://localhost:6379         # Redis (session & task queue)
curl http://localhost:8000/api/v1/heartbeat  # ChromaDB (vector database)
```

## Scaling

To scale individual services:

```bash
# Scale session service to 3 replicas
docker-compose up -d --scale session-service=3

# Scale knowledge service for heavy RAG workloads
docker-compose up -d --scale knowledge-service=2

# Scale agent service for concurrent AI investigations
docker-compose up -d --scale agent-service=3

# Scale job workers for heavy background processing
docker-compose up -d --scale job-worker=4
```

## Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Rebuild images
docker-compose up -d --build
```

### Database issues

```bash
# Reset all data (CAUTION: destroys all data)
docker-compose down -v
docker-compose up -d
```

### Performance tuning

For better performance with large knowledge bases:

```bash
# Allocate more memory to knowledge service
docker-compose up -d --scale knowledge-service=1 --memory 4g
```

## Monitoring

View real-time logs:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f auth-service

# Last 100 lines
docker-compose logs --tail=100
```

## Updating

To update to the latest version:

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

## Development

To develop against the deployment:

```bash
# Run services in development mode
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

## Production Deployment

For production, use:

1. **Reverse Proxy**: Add nginx/traefik for SSL termination
2. **External Database**: Replace SQLite with PostgreSQL
3. **Object Storage**: Replace local storage with S3/MinIO
4. **Monitoring**: Add Prometheus + Grafana
5. **Backup**: Implement automated backup strategy

## Components

This deployment uses:

- [fm-core-lib](https://github.com/FaultMaven/fm-core-lib) - Shared models & LLM infrastructure
- [fm-auth-service](https://github.com/FaultMaven/fm-auth-service) - Authentication & authorization
- [fm-session-service](https://github.com/FaultMaven/fm-session-service) - Session management (Redis)
- [fm-case-service](https://github.com/FaultMaven/fm-case-service) - Milestone-based case lifecycle
- [fm-knowledge-service](https://github.com/FaultMaven/fm-knowledge-service) - 3-tier RAG knowledge base
- [fm-evidence-service](https://github.com/FaultMaven/fm-evidence-service) - File management
- [fm-agent-service](https://github.com/FaultMaven/fm-agent-service) - AI troubleshooting agent (MilestoneEngine + LangGraph)
- [fm-job-worker](https://github.com/FaultMaven/fm-job-worker) - Background task processing (Celery)
- [fm-api-gateway](https://github.com/FaultMaven/fm-api-gateway) - API routing (optional)

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/FaultMaven/faultmaven-deploy/issues)
- **Discussions**: [GitHub Discussions](https://github.com/FaultMaven/faultmaven-deploy/discussions)
- **Documentation**: [docs.faultmaven.com](https://docs.faultmaven.com)

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
