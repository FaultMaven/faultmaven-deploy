# GHCR Image Distribution Strategy - Decision Required

## Current Situation

We changed docker-compose.yml to pull images from `ghcr.io/faultmaven/` but **all packages are currently private**, requiring GitHub authentication.

## The Problem

External users running `./faultmaven start` will immediately hit:
```
Error: Head "https://ghcr.io/v2/faultmaven/fm-agent-service/manifests/latest": unauthorized
```

## Three Options

### Option A: Make GHCR Packages Public ✅ RECOMMENDED

**Implementation:**
1. Change package visibility to public for all 10 services (via GitHub UI or API)
2. Update QUICKSTART.md to remove build time estimate, change to "downloads images"
3. Remove authentication logic from faultmaven script (not needed)

**Pros:**
- ✅ Zero-friction user experience
- ✅ No authentication needed
- ✅ Users get tested CI/CD images
- ✅ Fast first start (pull vs build)
- ✅ Aligns with open-source principles
- ✅ Consistent images across dev/test/prod

**Cons:**
- ⚠️ Images publicly accessible (but source code is already public anyway)
- ⚠️ Need to ensure no secrets in images (already verified - no secrets)

**Steps to implement:**
```bash
# For each package, make it public via GitHub API:
for pkg in fm-auth-service fm-session-service fm-case-service fm-knowledge-service \
           fm-evidence-service fm-agent-service fm-api-gateway fm-job-worker \
           faultmaven-dashboard; do
  gh api \
    --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "/orgs/FaultMaven/packages/container/$pkg" \
    -f visibility=public
done
```

Or via GitHub UI:
https://github.com/orgs/FaultMaven/packages?repo_name=fm-case-service → Package settings → Change visibility

---

### Option B: Revert to Local Builds

**Implementation:**
1. Revert docker-compose.yml images back to `faultmaven/` (no registry prefix)
2. Re-add `--build` flag to faultmaven script
3. Copy Dockerfiles from each service repo to faultmaven-deploy/dockerfiles/
4. Set up build contexts in docker-compose.yml

**Pros:**
- ✅ No GHCR dependency
- ✅ Works offline
- ✅ No authentication needed

**Cons:**
- ❌ Slower first start (5-10 min build vs 1-2 min pull)
- ❌ Local Dockerfiles can drift from service repos
- ❌ Users get untested local builds, not CI/CD-tested images
- ❌ Need to maintain duplicate Dockerfiles
- ❌ Build cache issues on fresh clones

---

### Option C: Hybrid (Build by Default, Pull Optional)

**Implementation:**
1. Keep local Dockerfiles + build contexts
2. Add `--use-ghcr` flag to faultmaven script
3. Document both paths in QUICKSTART.md

**Pros:**
- ✅ Works without authentication (default)
- ✅ Power users can opt into tested images

**Cons:**
- ❌ Complex configuration
- ❌ Most users get untested local builds
- ❌ Confusing documentation ("two ways to run")
- ❌ Duplicate maintenance burden

---

## Security Considerations

### Are there secrets in the images?
**NO** - Verified:
- ✅ No hardcoded credentials
- ✅ All secrets passed via environment variables
- ✅ .env files not copied into images
- ✅ Build-time secrets (GitHub tokens) only for git clone, not persisted

### What's in the images?
- Python code (already public in GitHub repos)
- Dependencies from public PyPI/npm
- fm-core-lib installed from public GitHub repo
- Empty /data directories
- No configuration files

### Can we make them public safely?
**YES** - The images contain nothing that isn't already public.

---

## Recommendation

**Go with Option A: Make GHCR Packages Public**

### Why?
1. **Best user experience** - Download and run in 2 minutes, no auth, no friction
2. **Better quality** - Users get CI/CD-tested images with all fixes
3. **Simpler maintenance** - Single source of truth (service repos)
4. **Aligns with open-source** - Code is public, images should be too
5. **Standard practice** - Most open-source projects publish public images

### What about private/proprietary features?
- Self-hosted version is **open-source by design**
- Enterprise-only features are in **separate private repos** (not in these services)
- These 8 services are the **public core** - making images public is consistent

---

## Implementation Checklist (Option A)

- [ ] Make all 10 GHCR packages public
  - [ ] fm-auth-service
  - [ ] fm-session-service
  - [ ] fm-case-service
  - [ ] fm-knowledge-service
  - [ ] fm-evidence-service
  - [ ] fm-agent-service
  - [ ] fm-api-gateway
  - [ ] fm-job-worker
  - [ ] faultmaven-dashboard
  - [ ] fm-job-worker-beat (if exists)

- [ ] Update faultmaven script:
  - [ ] Remove GHCR authentication logic (lines 276-304)
  - [ ] Update message to say "Pulling images from GHCR (no auth needed)"

- [ ] Update QUICKSTART.md:
  - [ ] Change "5-10 minutes (builds images)" to "2-3 minutes (downloads images)"
  - [ ] Remove any mention of build time
  - [ ] Add note about public images

- [ ] Update README.md:
  - [ ] Add note that pre-built images are available
  - [ ] Remove any build-related instructions

- [ ] Test flow:
  - [ ] Fresh clone of faultmaven-deploy
  - [ ] Run `./faultmaven start` without authentication
  - [ ] Verify all images pull successfully
  - [ ] Verify services start and pass health checks

---

## Alternative: If We Must Keep Packages Private

If there's a business reason to keep packages private, then we must:

1. **Revert to Option B (local builds)**
2. Copy all Dockerfiles to faultmaven-deploy
3. Accept slower first-run experience
4. Accept maintenance burden of duplicate Dockerfiles

But I strongly recommend against this unless there's a compelling reason.

---

## Decision

**Please choose:**
- [ ] Option A: Make packages public (recommended)
- [ ] Option B: Revert to local builds
- [ ] Option C: Hybrid approach
- [ ] Other: _________________________________

**If Option A, who should execute the package visibility changes?**
- [ ] Me (need admin access to GitHub org)
- [ ] You (will do manually)

---

**Date:** 2025-12-07
**Author:** Claude (AI Assistant)
**Status:** PENDING DECISION
