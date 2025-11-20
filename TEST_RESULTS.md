# Self-Hosted Deployment Test Results

**Date:** 2025-11-20
**Status:** 🔴 **Blocked - Build Issues Found**
**Tester:** Claude AI Agent
**Last Updated:** 2025-11-20 21:30 UTC

---

## Executive Summary

Initial deployment testing revealed several critical issues preventing successful build and deployment of the self-hosted version. While 4 out of 9 services built successfully, the remaining services are blocked by dependency and configuration issues in fm-agent-service.

**Overall Result:** ❌ FAILED - Cannot proceed to runtime testing

---

## Test Execution Timeline

### Pre-Test Setup ✅
- [x] All service repositories verified present in `/home/swhouse/product/fm-*-service`
- [x] .env file created from .env.example
- [x] docker-compose.yml reviewed and validated
- [x] Build context paths corrected (`./` → `../`)

### Issues Discovered and Fixed

#### Issue 1: fm-auth-service Dockerfile Misconfiguration
**Status:** ✅ FIXED
**Severity:** Critical (Blocking)

**Problem:**
- Dockerfile configured for Enterprise mode (pulling from Docker Hub base image)
- Expected Enterprise-specific files (alembic/, alembic.ini, requirements.txt)
- Build failed with "file not found" errors

**Root Cause:**
- Wrong Dockerfile committed - should be PUBLIC mode (build from source)

**Fix Applied:**
- Created new PUBLIC Dockerfile following fm-case-service pattern:
  - Multi-stage build with Poetry
  - Uses pyproject.toml instead of requirements.txt
  - Builds from source code
- Renamed old Dockerfile to Dockerfile.enterprise
- File: [fm-auth-service/Dockerfile](../fm-auth-service/Dockerfile)

---

#### Issue 2: Missing Git Dependency
**Status:** ✅ FIXED
**Severity:** Critical (Blocking)

**Problem:**
- fm-knowledge-service build failed: `ERROR: Cannot find command 'git'`
- fm-job-worker build failed with same error
- fm-agent-service build would fail for same reason

**Root Cause:**
- Services depend on fm-core-lib via GitHub URL in pyproject.toml:
  ```toml
  fm-core-lib = {git = "https://github.com/FaultMaven/fm-core-lib.git", branch = "main"}
  ```
- pip requires git command to clone git dependencies
- Dockerfiles didn't install git package

**Fix Applied:**
- Updated Dockerfiles to install git:
  - [fm-knowledge-service/Dockerfile](../fm-knowledge-service/Dockerfile:11): Added git to apt-get install
  - [fm-job-worker/Dockerfile](../fm-job-worker/Dockerfile:7): Added git in builder stage
  - [fm-job-worker/Dockerfile.beat](../fm-job-worker/Dockerfile.beat:7): Added git in builder stage
  - [fm-agent-service/Dockerfile](../fm-agent-service/Dockerfile:7): Added git in both builder and runtime stages

---

#### Issue 3: httpx Version Conflict
**Status:** ✅ FIXED
**Severity:** Critical (Blocking)

**Problem:**
- fm-agent-service Poetry export failed with dependency conflict:
  ```
  Because fm-core-lib (0.2.0) depends on httpx (>=0.28.1)
  and fm-agent-service depends on httpx (>=0.25.0,<0.26.0), fm-core-lib is forbidden.
  ```

**Root Cause:**
- fm-agent-service/pyproject.toml had `httpx = "^0.25.0"` (resolves to >=0.25.0,<0.26.0)
- fm-core-lib requires httpx >=0.28.1
- Poetry cannot resolve conflicting version requirements

**Fix Applied:**
- Updated [fm-agent-service/pyproject.toml](../fm-agent-service/pyproject.toml):
  - Line 14: `httpx = "^0.28.1"` (was ^0.25.0)
  - Line 40: `httpx = "^0.28.1"` in dev dependencies (was ^0.25.0)

---

#### Issue 4: fm-agent-service Poetry Lock Timeout
**Status:** 🔴 **BLOCKING**
**Severity:** Critical (Blocking)

**Problem:**
- After fixing httpx version, Poetry export step hangs indefinitely
- `poetry export -f requirements.txt` runs for >10 minutes without completing
- Build log shows repeated `...` indicating process is stuck

**Observed Behavior:**
```
#67 [fm-agent-service builder 6/6] RUN poetry export -f requirements.txt...
#67 ...
#67 ...
```

**Root Cause (Suspected):**
- Poetry attempting to resolve complex dependency tree from fm-core-lib
- May be hitting dependency conflicts not immediately visible
- Could be network timeouts fetching package metadata
- Missing poetry.lock file forces fresh dependency resolution

**Potential Solutions:**
1. **Pre-generate poetry.lock** - Run `poetry lock` locally and commit the file
2. **Switch to setuptools** - Use setup.py/pyproject.toml with pip (like fm-job-worker)
3. **Pin all transitive dependencies** - Fully specify all dependency versions
4. **Use pre-built fm-core-lib** - Publish fm-core-lib to PyPI instead of git

**Recommendation:** Option 1 (pre-generate poetry.lock) is fastest fix

---

## Build Results

### Successfully Built Services ✅

1. **fm-evidence-service**
   - Build time: ~2 minutes
   - Image: `faultmaven-deploy-fm-evidence-service:latest`
   - Size: 199MB

2. **fm-job-worker**
   - Build time: ~3 minutes
   - Image: `faultmaven-deploy-fm-job-worker:latest`
   - Uses setuptools (no Poetry)

3. **fm-job-worker-beat**
   - Build time: ~3 minutes
   - Image: `faultmaven-deploy-fm-job-worker-beat:latest`
   - Uses setuptools (no Poetry)

4. **fm-knowledge-service**
   - Build time: ~4.5 minutes
   - Image: `faultmaven-deploy-fm-knowledge-service:latest`
   - Successfully installed fm-core-lib from git
   - Largest dependency set (chromadb, sentence-transformers, etc.)

### Failed/Blocked Services ❌

5. **fm-agent-service** 🔴
   - Status: Stuck in Poetry dependency resolution
   - Build time: >10 minutes (timeout)
   - Blocks: All remaining services (parallel build failure)

6. **fm-auth-service** ⚠️
   - Status: Not reached
   - Reason: Blocked by fm-agent-service failure

7. **fm-case-service** ⚠️
   - Status: Not reached
   - Reason: Blocked by fm-agent-service failure

8. **fm-session-service** ⚠️
   - Status: Not reached
   - Reason: Blocked by fm-agent-service failure

9. **chromadb** ⚠️
   - Status: Not attempted (Docker Hub image)
   - Should pull automatically once services build

10. **redis** ⚠️
    - Status: Not attempted (Docker Hub image)
    - Should pull automatically once services build

---

## Runtime Testing

**Status:** ⚠️ NOT PERFORMED

Cannot proceed to runtime testing (health checks, API calls, data persistence) until all services build successfully.

**Pending Tests:**
- [ ] Step 3: Verify all containers started
- [ ] Step 4: Check ./data directory and SQLite database created
- [ ] Step 5: Test health endpoints for all services
- [ ] Step 6: Test basic API operations
- [ ] Step 7: Verify background job worker
- [ ] Step 8: Test data persistence across restarts

---

## Files Modified During Testing

### Dockerfiles Fixed

1. `/home/swhouse/product/fm-auth-service/Dockerfile`
   - Complete rewrite for PUBLIC mode
   - Multi-stage Poetry build

2. `/home/swhouse/product/fm-job-worker/Dockerfile`
   - Added git installation (line 7)

3. `/home/swhouse/product/fm-job-worker/Dockerfile.beat`
   - Added git installation (line 7)

4. `/home/swhouse/product/fm-knowledge-service/Dockerfile`
   - Added git to apt-get install (line 11)

5. `/home/swhouse/product/fm-agent-service/Dockerfile`
   - Added git in builder stage (line 7)
   - Added git in runtime stage (line 22)

### Dependency Files Fixed

6. `/home/swhouse/product/fm-agent-service/pyproject.toml`
   - Updated httpx from ^0.25.0 to ^0.28.1 (line 14)
   - Updated httpx in dev deps (line 40)

---

## Recommendations

### Immediate Actions Required

1. **Fix fm-agent-service Poetry lock**
   ```bash
   cd /home/swhouse/product/fm-agent-service
   poetry lock
   git add poetry.lock
   git commit -m "Add poetry.lock for reproducible builds"
   ```

2. **Generate poetry.lock for all Poetry services**
   - fm-case-service
   - fm-session-service
   - fm-auth-service (if using new Poetry Dockerfile)

3. **Re-test complete build**
   ```bash
   cd /home/swhouse/product/faultmaven-deploy
   docker compose down -v
   docker compose up -d --build
   ```

### Long-Term Improvements

4. **Publish fm-core-lib to PyPI**
   - Avoids git dependency in Docker builds
   - Faster, more reliable builds
   - Better versioning control

5. **Add build timeouts to docker-compose.yml**
   - Fail fast instead of hanging indefinitely
   - Makes CI/CD more predictable

6. **Consider hybrid approach**
   - Use pre-built images for complex services (agent, knowledge)
   - Build simpler services from source
   - Best of both worlds for self-hosted

7. **Add poetry.lock to version control**
   - Ensures reproducible builds
   - Prevents dependency drift
   - Faster resolution (no need to solve)

---

## Conclusion

The self-hosted deployment is **NOT READY** for public release. While the infrastructure (docker-compose, .env, documentation) is well-designed, critical build issues prevent successful deployment.

**Estimated Fix Time:** 2-4 hours
1. Generate poetry.lock files (30 min)
2. Test complete build (30 min)
3. Runtime testing if build succeeds (1-2 hours)
4. Documentation updates (30 min)

**Blocker Resolution Required Before:**
- Public repository announcement
- User testing
- Documentation publishing
- Integration with faultmaven-copilot frontend

---

## Appendix: Build Commands Used

```bash
# Initial attempt
cd /home/swhouse/product/faultmaven-deploy
docker compose up -d --build

# After each fix
docker compose down -v
docker compose up -d --build

# Check status
docker compose ps
docker images | grep faultmaven-deploy

# View logs
docker compose logs fm-agent-service
tail -f /tmp/docker-compose-build.log
```

---

## Appendix: Environment Details

- **Host OS:** Linux 6.14.0-29-generic
- **Docker Version:** (using docker compose v2 syntax)
- **Working Directory:** /home/swhouse/product/faultmaven-deploy
- **Service Repositories:** /home/swhouse/product/fm-*-service
- **Build Tool:** docker compose (Buildx bake)
- **Python Version:** 3.11-slim (base image)
