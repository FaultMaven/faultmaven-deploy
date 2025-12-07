# Make GHCR Packages Public - Web UI Instructions

The GitHub API for changing org-level package visibility requires special permissions. The simplest approach is to use the GitHub web UI.

## Quick Links - Click to Open Each Package

1. [fm-auth-service](https://github.com/orgs/FaultMaven/packages/container/package/fm-auth-service)
2. [fm-session-service](https://github.com/orgs/FaultMaven/packages/container/package/fm-session-service)
3. [fm-case-service](https://github.com/orgs/FaultMaven/packages/container/package/fm-case-service)
4. [fm-knowledge-service](https://github.com/orgs/FaultMaven/packages/container/package/fm-knowledge-service)
5. [fm-evidence-service](https://github.com/orgs/FaultMaven/packages/container/package/fm-evidence-service)
6. [fm-agent-service](https://github.com/orgs/FaultMaven/packages/container/package/fm-agent-service)
7. [fm-api-gateway](https://github.com/orgs/FaultMaven/packages/container/package/fm-api-gateway)
8. [fm-job-worker](https://github.com/orgs/FaultMaven/packages/container/package/fm-job-worker)
9. [faultmaven-dashboard](https://github.com/orgs/FaultMaven/packages/container/package/faultmaven-dashboard) *(if exists)*

## Steps for Each Package

1. **Click the link above** to open the package page
2. **Click "Package settings"** (gear icon on the right side)
3. **Scroll down to "Danger Zone"**
4. **Click "Change package visibility"**
5. **Select "Public"**
6. **Type the package name** to confirm (e.g., `fm-auth-service`)
7. **Click "I understand, change package visibility"**

## Checklist

Mark each as you complete:

- [ ] fm-auth-service
- [ ] fm-session-service
- [ ] fm-case-service
- [ ] fm-knowledge-service
- [ ] fm-evidence-service
- [ ] fm-agent-service
- [ ] fm-api-gateway
- [ ] fm-job-worker
- [ ] faultmaven-dashboard

## Verification

After making all packages public, verify:

```bash
# Should work without authentication:
docker logout ghcr.io
docker pull ghcr.io/faultmaven/fm-case-service:latest

# Check all are public:
gh api /orgs/FaultMaven/packages?package_type=container | \
  jq -r '.[] | "\(.name): \(.visibility)"'
```

Expected output:
```
fm-auth-service: public
fm-session-service: public
fm-case-service: public
...
```

## After Completion

Test the full user flow:

```bash
cd /tmp
git clone https://github.com/FaultMaven/faultmaven-deploy.git
cd faultmaven-deploy
cp .env.example .env
# Add OPENAI_API_KEY=sk-...
./faultmaven start
```

Should complete without authentication errors!
