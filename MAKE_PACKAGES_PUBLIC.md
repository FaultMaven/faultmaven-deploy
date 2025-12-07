# Making GHCR Packages Public - Instructions

## Why This Is Needed

The FaultMaven self-hosted deployment now pulls pre-built Docker images from GitHub Container Registry (GHCR). To provide a zero-friction user experience, these packages need to be public so users don't need to authenticate.

## Option 1: Automated Script (Recommended)

### Prerequisites
- GitHub Personal Access Token with `write:packages` scope
- Organization admin/owner permissions

### Steps

1. **Create GitHub PAT:**
   - Go to: https://github.com/settings/tokens/new
   - Name: `GHCR Package Admin`
   - Expiration: Choose appropriate duration
   - Scopes: Select `write:packages`, `read:packages`
   - Click "Generate token"
   - Copy the token (starts with `ghp_`)

2. **Export token:**
   ```bash
   export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxx
   ```

3. **Run script:**
   ```bash
   cd /home/swhouse/product/faultmaven-deploy
   ./make-packages-public.sh
   ```

The script will:
- Check for GITHUB_TOKEN
- List all packages to be updated
- Ask for confirmation
- Update visibility for all packages
- Report success/failure for each

---

## Option 2: Manual via GitHub UI

If you prefer to update manually or the script fails:

### For Each Package:

1. **Navigate to package:**
   - Go to: https://github.com/orgs/FaultMaven/packages
   - Click on the package name (e.g., `fm-case-service`)

2. **Change visibility:**
   - Click "Package settings" (right sidebar)
   - Scroll to "Danger Zone"
   - Click "Change visibility"
   - Select "Public"
   - Type package name to confirm
   - Click "I understand, change package visibility"

### Packages to Update:

- [ ] fm-auth-service
- [ ] fm-session-service
- [ ] fm-case-service
- [ ] fm-knowledge-service
- [ ] fm-evidence-service
- [ ] fm-agent-service
- [ ] fm-api-gateway
- [ ] fm-job-worker
- [ ] faultmaven-dashboard

**Quick Links:**
- [fm-auth-service](https://github.com/FaultMaven/fm-auth-service/pkgs/container/fm-auth-service/settings)
- [fm-session-service](https://github.com/FaultMaven/fm-session-service/pkgs/container/fm-session-service/settings)
- [fm-case-service](https://github.com/FaultMaven/fm-case-service/pkgs/container/fm-case-service/settings)
- [fm-knowledge-service](https://github.com/FaultMaven/fm-knowledge-service/pkgs/container/fm-knowledge-service/settings)
- [fm-evidence-service](https://github.com/FaultMaven/fm-evidence-service/pkgs/container/fm-evidence-service/settings)
- [fm-agent-service](https://github.com/FaultMaven/fm-agent-service/pkgs/container/fm-agent-service/settings)
- [fm-api-gateway](https://github.com/FaultMaven/fm-api-gateway/pkgs/container/fm-api-gateway/settings)
- [fm-job-worker](https://github.com/FaultMaven/fm-job-worker/pkgs/container/fm-job-worker/settings)
- [faultmaven-dashboard](https://github.com/FaultMaven/faultmaven-dashboard/pkgs/container/faultmaven-dashboard/settings)

---

## Option 3: GitHub CLI (Alternative)

If you have organization admin access:

```bash
# Requires gh CLI v2.40.0+ and write:packages scope
for pkg in fm-auth-service fm-session-service fm-case-service \
           fm-knowledge-service fm-evidence-service fm-agent-service \
           fm-api-gateway fm-job-worker faultmaven-dashboard; do
  gh api \
    --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "/orgs/FaultMaven/packages/container/$pkg" \
    -f visibility=public
done
```

---

## Verification

After making packages public, verify:

```bash
# Should succeed without authentication:
docker pull ghcr.io/faultmaven/fm-case-service:latest

# Check all packages are public:
gh api /orgs/FaultMaven/packages?package_type=container | \
  jq -r '.[] | "\(.name): \(.visibility)"'
```

Expected output:
```
fm-case-service: public
fm-auth-service: public
...
```

---

## Security Check

Before making packages public, ensure:
- [ ] No hardcoded secrets in images
- [ ] No .env files copied into images
- [ ] All sensitive config passed via environment variables
- [ ] Build-time secrets (like GitHub tokens) not persisted in layers

**Status:** ✅ All checks passed - images contain only public code and dependencies

---

## Next Steps

After packages are public:

1. Remove GHCR authentication logic from `faultmaven` script
2. Update QUICKSTART.md to reflect public images
3. Test fresh installation without authentication
4. Update README.md to mention pre-built images

---

**Last Updated:** 2025-12-07
**Status:** Pending execution
