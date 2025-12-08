# Deployment Neutrality - Phase 1 & 2 Implementation

> **Status:** ✅ Complete (Phase 1 & Phase 2)
> **Last Updated:** December 8, 2025

## Overview

FaultMaven's deployment neutrality initiative enables **zero-code changes** when deploying across different environments: laptop development, Docker Compose, or Kubernetes production. This is achieved through provider patterns and environment-based configuration across four infrastructure layers.

## Architecture Philosophy

**Principle:** Infrastructure choices should be deployment-time decisions, not code-time decisions.

**Implementation:** Provider pattern with environment-based selection:
- Abstract interfaces define contracts
- Multiple implementations for different deployment targets
- Factory pattern selects provider based on environment variables
- Services use providers without knowing implementation details

## Four Infrastructure Layers

### 1. Identity Layer (Redis)

**Challenge:** Session storage and distributed caching

**Solution:** Redis client with mode support

| Deployment | Mode | Configuration |
|------------|------|---------------|
| **Laptop/Dev** | Standalone | Single Redis instance |
| **Production** | Sentinel | High availability with automatic failover |

**Environment Variables:**
```bash
REDIS_MODE=standalone              # or "sentinel"
REDIS_HOST=localhost               # Standalone mode
REDIS_PORT=6379

# Sentinel mode
REDIS_SENTINEL_HOSTS=host1:26379,host2:26379,host3:26379
REDIS_MASTER_SET=mymaster
```

**Affected Services:**
- ✅ [fm-auth-service](../fm-auth-service) - User sessions
- ✅ [fm-session-service](../fm-session-service) - Conversation sessions
- ✅ [fm-api-gateway](../fm-api-gateway) - Rate limiting, circuit breakers
- ✅ [fm-job-worker](../fm-job-worker) - Celery task queue

### 2. Data Layer (Database)

**Challenge:** Development simplicity vs production scalability

**Solution:** SQLAlchemy with async support for both SQLite and PostgreSQL

| Deployment | Database | Configuration |
|------------|----------|---------------|
| **Laptop/Dev** | SQLite | Single file, zero setup |
| **Production** | PostgreSQL | Scalable, concurrent, production-ready |

**Environment Variables:**
```bash
DATABASE_URL=sqlite+aiosqlite:///./data/faultmaven.db
# or
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/faultmaven
```

**Migration System:**
- Alembic migrations in each service
- Automatic schema creation on startup (dev mode)
- Manual migration control (production)

**Affected Services:**
- ✅ [fm-auth-service](../fm-auth-service)
- ✅ [fm-case-service](../fm-case-service)
- ✅ [fm-evidence-service](../fm-evidence-service)
- ✅ [fm-knowledge-service](../fm-knowledge-service)

### 3. Files Layer (Storage)

**Challenge:** Local development vs cloud object storage

**Solution:** Storage provider abstraction

| Deployment | Provider | Configuration |
|------------|----------|---------------|
| **Laptop/Dev** | Local filesystem | `./data/uploads/` directory |
| **Production** | AWS S3 | Scalable cloud object storage |

**Environment Variables:**
```bash
STORAGE_PROVIDER=local            # or "s3"

# S3 configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
S3_BUCKET_NAME=faultmaven-evidence
```

**Provider Interface:**
```python
class StorageProvider(ABC):
    @abstractmethod
    async def upload_file(self, file: UploadFile, key: str) -> str

    @abstractmethod
    async def download_file(self, key: str) -> bytes

    @abstractmethod
    async def delete_file(self, key: str) -> None
```

**Affected Services:**
- ✅ [fm-evidence-service](../fm-evidence-service) - Logs, screenshots, configs

### 4. Vector Layer (Knowledge Base)

**Challenge:** Embedded dev database vs enterprise-scale vector search

**Solution:** Vector database provider abstraction

| Deployment | Provider | Scale | Configuration |
|------------|----------|-------|---------------|
| **Laptop/Dev** | ChromaDB Local | ~100K docs | Embedded SQLite |
| **Production** | Pinecone | Billions of docs | Managed cloud service |

**Environment Variables:**
```bash
VECTOR_DB_PROVIDER=chroma          # or "pinecone"

# ChromaDB (default)
CHROMA_HOST=localhost
CHROMA_PORT=8007

# Pinecone
PINECONE_API_KEY=xxx
PINECONE_ENVIRONMENT=us-east-1
PINECONE_INDEX_NAME=faultmaven-knowledge
```

**Provider Interface:**
```python
class VectorDBProvider(ABC):
    @abstractmethod
    async def upsert_vectors(self, collection: str, vectors: List[Dict]) -> None

    @abstractmethod
    async def search(self, collection: str, query_vector: List[float], limit: int) -> List[SearchResult]
```

**Similarity Score Normalization:**
- ChromaDB returns L2 distance (lower = better)
- Pinecone returns cosine similarity (higher = better)
- Provider normalizes to 0-1 score (higher = better)

**Affected Services:**
- ✅ [fm-knowledge-service](../fm-knowledge-service) - RAG knowledge base

## Phase 2: Service Discovery & Gateway Protection

### Service Discovery (Phase 2.2)

**Challenge:** Service URLs differ across Docker, Kubernetes, and local development

**Solution:** ServiceRegistry in fm-core-lib with deployment mode detection

**Deployment Modes:**

| Mode | Service URL Pattern | Example |
|------|---------------------|---------|
| **Docker** | `http://fm-{service}-service:{port}` | `http://fm-auth-service:8000` |
| **Kubernetes** | `http://fm-{service}-service.{namespace}.svc.cluster.local:{port}` | `http://fm-auth-service.faultmaven.svc.cluster.local:8000` |
| **Local** | `http://localhost:{port}` | `http://localhost:8000` |

**Environment Variables:**
```bash
DEPLOYMENT_MODE=docker             # or "kubernetes", "local"
K8S_NAMESPACE=faultmaven          # Only used in kubernetes mode
```

**Implementation:**
```python
from fm_core_lib.discovery import get_service_registry

registry = get_service_registry()
auth_url = registry.get_url("auth")  # Returns correct URL for deployment mode
```

**Affected Services:**
- ✅ [fm-core-lib](../fm-core-lib) - ServiceRegistry implementation
- ✅ [fm-api-gateway](../fm-api-gateway) - All proxy routes updated

### Rate Limiting (Phase 2.3)

**Challenge:** Protect against DDoS and resource exhaustion

**Solution:** Token bucket rate limiter with Redis-backed distributed tracking

**Features:**
- Per-IP rate limiting (default: 60 requests/minute)
- Redis-backed for distributed enforcement across gateway pods
- In-memory fallback if Redis unavailable
- Graceful degradation (fails open on errors)
- Standard HTTP headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

**Environment Variables:**
```bash
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS_PER_MINUTE=60
```

**Response on Limit Exceeded:**
```json
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1701234567

{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Please try again later."
}
```

**Affected Services:**
- ✅ [fm-api-gateway](../fm-api-gateway) - RateLimitMiddleware

### Circuit Breakers (Phase 2.3)

**Challenge:** Prevent cascading failures when backend services are unhealthy

**Solution:** Per-service circuit breaker with state machine

**States:**

| State | Behavior | Transition Condition |
|-------|----------|---------------------|
| **CLOSED** (normal) | All requests pass through | After `FAIL_THRESHOLD` consecutive 5xx/timeouts → OPEN |
| **OPEN** (failing) | Reject immediately with 503 | After `RESET_TIMEOUT` seconds → HALF_OPEN |
| **HALF_OPEN** (testing) | Allow 1 test request | Success → CLOSED, Failure → OPEN |

**Environment Variables:**
```bash
CIRCUIT_BREAKER_ENABLED=true
CIRCUIT_BREAKER_FAIL_THRESHOLD=5      # Failures before opening
CIRCUIT_BREAKER_RESET_TIMEOUT=30      # Seconds before attempting recovery
```

**What Counts as Failure:**
- ✅ 5xx responses from backend
- ✅ Network timeouts
- ✅ Connection errors
- ❌ 4xx responses (client error, service is healthy)

**Response When Circuit Open:**
```json
HTTP/1.1 503 Service Unavailable

{
  "error": "service_unavailable",
  "message": "fm-knowledge-service temporarily unavailable"
}
```

**Affected Services:**
- ✅ [fm-api-gateway](../fm-api-gateway) - Circuit breaker integration in `proxy_request()`

## Configuration Migration Guide

### From Laptop Dev → Docker Compose

**No changes needed!** Default `.env` settings work for both.

### From Docker Compose → Kubernetes

Update your `.env` or ConfigMap:

```bash
# Service Discovery
DEPLOYMENT_MODE=kubernetes
K8S_NAMESPACE=faultmaven

# Redis (upgrade to Sentinel for HA)
REDIS_MODE=sentinel
REDIS_SENTINEL_HOSTS=redis-sentinel-1:26379,redis-sentinel-2:26379,redis-sentinel-3:26379
REDIS_MASTER_SET=mymaster

# Database (upgrade to PostgreSQL)
DATABASE_URL=postgresql+asyncpg://faultmaven:${DB_PASSWORD}@postgres.faultmaven.svc.cluster.local:5432/faultmaven

# Storage (upgrade to S3)
STORAGE_PROVIDER=s3
S3_BUCKET_NAME=faultmaven-production-evidence

# Vector DB (upgrade to Pinecone for scale)
VECTOR_DB_PROVIDER=pinecone
PINECONE_API_KEY=${PINECONE_API_KEY}
PINECONE_INDEX_NAME=faultmaven-production-kb
```

**Result:** Same Docker images, different environment = different infrastructure.

## Testing Strategy

### Local Development
```bash
# Use defaults (SQLite, local files, ChromaDB, standalone Redis)
docker-compose up -d
```

### Staging (Docker Compose with Production-Like Infrastructure)
```bash
# Test with PostgreSQL, S3, Pinecone, Redis Sentinel
DEPLOYMENT_MODE=docker \
REDIS_MODE=sentinel \
DATABASE_URL=postgresql+asyncpg://... \
STORAGE_PROVIDER=s3 \
VECTOR_DB_PROVIDER=pinecone \
docker-compose up -d
```

### Production (Kubernetes)
```bash
# Deploy with production settings
DEPLOYMENT_MODE=kubernetes \
K8S_NAMESPACE=faultmaven \
# ... (full production config)
kubectl apply -f k8s/
```

## Performance Characteristics

### SQLite vs PostgreSQL

| Metric | SQLite | PostgreSQL |
|--------|--------|------------|
| **Concurrent Writes** | 1 writer at a time | Unlimited concurrent |
| **Max Size** | ~281 TB | Unlimited |
| **Setup** | Zero config | Requires server |
| **Backup** | Copy single file | `pg_dump` + restore |

**Recommendation:** SQLite for dev/single-user, PostgreSQL for production.

### ChromaDB vs Pinecone

| Metric | ChromaDB Local | Pinecone |
|--------|----------------|----------|
| **Max Documents** | ~100K (performance degrades) | Billions |
| **Query Latency** | 10-50ms | 20-100ms |
| **Setup** | Zero config | API key required |
| **Cost** | Free | $70/month for starter index |

**Recommendation:** ChromaDB for dev/testing, Pinecone for production scale.

### Local Storage vs S3

| Metric | Local Files | AWS S3 |
|--------|-------------|---------|
| **Max Size** | Disk limit | Unlimited |
| **Availability** | Single server | 99.99% SLA |
| **Durability** | RAID dependent | 99.999999999% (11 nines) |
| **Cost** | Disk cost | $0.023/GB/month |

**Recommendation:** Local for dev, S3 for production.

## Implementation Timeline

### Phase 1: Infrastructure Provider Patterns ✅

**Completed:** December 7, 2025

- ✅ PostgreSQL support (SQLite → PostgreSQL)
- ✅ Redis Sentinel support (Standalone → Sentinel)
- ✅ S3 storage abstraction (Local → S3)
- ✅ Vector database abstraction (ChromaDB → Pinecone)
- ✅ Alembic migrations for all services

### Phase 2: Service Discovery & Gateway Protection ✅

**Completed:** December 8, 2025

- ✅ **Phase 2.1:** Vector database abstraction (fm-knowledge-service)
- ✅ **Phase 2.2:** ServiceRegistry for deployment-neutral URLs (fm-core-lib, fm-api-gateway)
- ✅ **Phase 2.3:** Rate limiting & circuit breakers (fm-api-gateway)

## Related Documentation

- **[README.md](README.md)** - Main deployment guide
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start for self-hosted deployment
- **[fm-api-gateway/README.md](../fm-api-gateway/README.md)** - Gateway configuration reference
- **[fm-core-lib README](../fm-core-lib/README.md)** - ServiceRegistry usage

## Version Compatibility

All changes are **backward compatible**:

- ✅ Existing `.env` files continue to work (defaults to dev mode)
- ✅ SQLite databases migrate automatically to PostgreSQL via Alembic
- ✅ Local files can be bulk-uploaded to S3 with migration script
- ✅ ChromaDB collections can be exported and imported to Pinecone

**No breaking changes.** Upgrading is opt-in via environment variables.
