# FaultMaven Self-Hosted - SRE Evaluation Report

**Evaluator:** Site Reliability Engineer
**Date:** November 26, 2025
**Evaluation Type:** First-time setup experience and documentation review

---

## Executive Summary

FaultMaven is an AI-powered troubleshooting platform with a self-hosted deployment option. This report documents my experience attempting to set up FaultMaven following the official documentation, along with feedback and recommendations.

**Overall Impression:** Well-documented, thoughtfully designed, but has some areas for improvement in the onboarding experience.

---

## Setup Experience

### What I Did

1. **Cloned the repository** - ✅ Straightforward
2. **Read README.md** - ✅ Comprehensive and well-structured
3. **Copied `.env.example` to `.env`** - ✅ Easy
4. **Configured required variables** - ✅ Clear instructions
5. **Ran `./faultmaven start`** - ⚠️ Script provided excellent feedback when Docker wasn't available

### Time Estimate
- Reading documentation: ~10 minutes
- Configuration: ~5 minutes
- First startup (with Docker): Estimated 5-10 minutes per documentation

---

## What Works Well

### 1. Documentation Quality: A+

**README.md Highlights:**
- Clear "4 simple steps" quick start - gets users running fast
- Excellent architecture diagram showing all services and their relationships
- Well-organized sections with good hierarchy
- Links to additional resources (QUICKSTART.md, TROUBLESHOOTING.md)
- Honest about limitations ("Not For" section)

**QUICKSTART.md Highlights:**
- Detailed LLM configuration options (7 providers!)
- Clear step-by-step instructions
- Local LLM setup instructions (Ollama, LM Studio)
- API usage examples with curl commands
- FAQ section addresses common questions

### 2. CLI Wrapper Script: A+

The `./faultmaven` script is excellent:

```bash
./faultmaven start   # Pre-flight checks + startup
./faultmaven status  # Health checks
./faultmaven logs    # Aggregated logs
./faultmaven clean   # Data reset
./faultmaven prune   # Docker cleanup
./faultmaven nuke    # Nuclear option
```

**Why it's good:**
- Pre-flight checks validate environment before starting
- Colorized output for readability
- RAM check prevents OOM issues
- Auto-creates resource limits file
- Graceful error messages with actionable next steps
- Tiered cleanup options (clean → prune → nuke)

### 3. Environment Configuration: A

**.env.example is well-commented:**
- Explains each variable's purpose
- Provides links to get API keys
- Documents all 7 LLM providers
- Includes examples for different deployment scenarios

### 4. Architecture: A

**Well-designed microservices:**
- 7 backend services with clear separation of concerns
- API Gateway as single entry point (port 8090)
- Health checks on all services
- Docker Compose with proper `depends_on` conditions
- SQLite for simplicity (portable, zero-config)
- ChromaDB for vector search
- Redis for sessions and job queues

### 5. Resource Management: A

**docker-compose.override.yml approach:**
- Memory limits prevent runaway containers
- CPU limits keep laptop usable
- Example file provided
- Auto-created by wrapper script

---

## Areas for Improvement

### Issue 1: Build Context Requires External Repositories (Critical)

**Problem:** The `docker-compose.yml` references external build contexts:

```yaml
fm-auth-service:
  build:
    context: ../fm-auth-service    # <-- NOT in this repo!
    dockerfile: Dockerfile
```

**Impact:** Users who only clone `faultmaven-deploy` will get build errors:
```
ERROR: build path ../fm-auth-service does not exist
```

**Recommendation:**
1. Add a "Clone All Repositories" section to the documentation
2. Or provide a setup script that clones all required repos:
   ```bash
   #!/bin/bash
   repos=(fm-auth-service fm-session-service fm-case-service ...)
   for repo in "${repos[@]}"; do
     git clone https://github.com/FaultMaven/$repo.git ../$repo
   done
   ```
3. Or use pre-built images from Docker Hub instead of local builds

### Issue 2: SERVER_HOST Required But Not Obviously Required

**Problem:** The `SERVER_HOST` variable is empty by default:

```bash
SERVER_HOST=                             # REQUIRED: Your server IP
```

**Impact:** Users might skip this, leading to dashboard connection failures.

**Recommendation:**
- Add validation in the wrapper script (already done - good!)
- Consider auto-detecting IP address and suggesting it
- Make the variable name more obvious: `SERVER_IP_ADDRESS`

### Issue 3: Default Credentials in Plain Text

**Problem:** Default credentials are visible in `.env.example`:

```bash
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=changeme123
```

**Recommendation:**
- Generate random password on first run
- Force password change on first login
- Add security warning banner in the CLI output

### Issue 4: No Automated Testing Instructions

**Problem:** No way to verify the installation works correctly beyond health checks.

**Recommendation:** Add a verification script:
```bash
./faultmaven verify
# Creates a test case
# Uploads test evidence
# Queries the AI agent
# Confirms full round-trip works
```

### Issue 5: ChromaDB Has No Health Check

**Problem:** ChromaDB container has no healthcheck:

```yaml
chromadb:
  image: chromadb/chroma:latest
  # No healthcheck: ChromaDB image lacks curl/wget
```

**Impact:** Services depending on ChromaDB might start before it's ready.

**Recommendation:**
- Add a custom healthcheck using Python (already in image)
- Or add retry logic in dependent services (documented in comment)

---

## Security Observations

### Good:
- API keys not committed to repo
- `.gitignore` excludes `/data/` directory
- Resource limits prevent container escape via resource exhaustion
- CORS origins properly configured

### Needs Attention:
- Default credentials (`admin/changeme123`) - should be randomized
- Redis exposed on port 6379 (consider removing port mapping for production)
- No TLS/HTTPS configuration documented
- No secrets management (Vault, etc.)

---

## Comparison to Industry Standards

| Aspect | FaultMaven | Industry Best Practice |
|--------|------------|----------------------|
| Documentation | ★★★★★ | Exceeds expectations |
| Docker Compose | ★★★★☆ | Good, needs multi-repo solution |
| Health Checks | ★★★★☆ | Good, ChromaDB missing |
| Resource Limits | ★★★★★ | Excellent approach |
| CLI Experience | ★★★★★ | Exceptional wrapper script |
| Security Defaults | ★★★☆☆ | Needs stronger defaults |
| Onboarding Time | ★★★★☆ | Good with caveats |

---

## Recommendations Summary

### High Priority
1. **Document multi-repo setup** - Critical for first-time users
2. **Provide pre-built Docker images** - Eliminates build complexity
3. **Auto-generate secure credentials** - Security best practice

### Medium Priority
4. **Add verification command** - Confirms installation works
5. **Add ChromaDB health check** - Prevents race conditions
6. **Document HTTPS setup** - Required for production use

### Low Priority
7. **Auto-detect SERVER_HOST** - Nice-to-have convenience
8. **Add Makefile** - Alternative to bash script for some users
9. **Add docker-compose profiles** - Enable minimal mode for testing

---

## Conclusion

FaultMaven has **excellent documentation and tooling** that makes the self-hosted deployment approachable. The `./faultmaven` CLI wrapper is particularly impressive - it handles pre-flight checks, resource management, and provides clear error messages.

The main barrier to adoption is the **multi-repository build context issue**. First-time users will hit a wall when `docker compose build` fails because the service directories don't exist. This should be addressed by either:
1. Documenting the multi-repo setup clearly
2. Publishing pre-built images to Docker Hub
3. Creating a "super repo" that includes all services as submodules

Once that's resolved, FaultMaven would score **4.5/5 stars** for self-hosted deployment experience.

---

**Report Author:** SRE Evaluator
**Methodology:** Fresh clone, documentation-only setup attempt
**Environment:** Linux (Docker not available during test)
