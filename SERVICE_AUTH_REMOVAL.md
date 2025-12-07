# Service-to-Service Authentication Removal - Migration Guide

**Date**: 2025-12-07
**Status**: ✅ Complete
**Type**: Breaking Change

---

## Summary

Service-to-service JWT authentication has been **completely removed** from FaultMaven. We've migrated to a **Perimeter Security** model where the API Gateway handles all authentication and backend services trust validated X-User-* headers.

---

## Why This Change?

### Problems with Service-to-Service JWT Auth

1. **Broken Implementation**: Services never received JWT tokens, causing "Missing authentication context" errors
2. **Unnecessary Complexity**: JWT validation on every internal service call added latency and code complexity
3. **Wrong Security Layer**: Application-layer JWT auth doesn't defend against realistic threats in containerized environments
4. **Industry Misalignment**: Modern architectures use infrastructure-layer mTLS (Istio, Linkerd), not app-layer JWT

### Benefits of Perimeter Security

1. **Simpler**: One authentication point instead of two
2. **Faster**: No JWT generation/validation overhead on internal calls
3. **Cleaner**: ~850 lines of auth code removed
4. **Correct**: Aligns with how Kong, Traefik, Envoy, and other API gateways work
5. **Maintainable**: Easier to debug and audit

---

## Architecture Changes

### Before (Broken)

```
Client Request
    ↓
API Gateway (User JWT validation)
    ↓ Adds X-User-* headers
    ↓
Backend Service (Service JWT validation)
    ✗ Expects Authorization: Bearer <service-jwt>
    ✗ Only gets X-User-* headers
    ✗ FAILS: "Missing authentication context"
```

### After (Working)

```
Client Request
    ↓
API Gateway
    ├─ Validates user JWT
    ├─ Strips client X-User-* headers (security!)
    ├─ Adds validated X-User-* headers
    ↓
Backend Services
    ├─ Trust X-User-* headers
    ├─ Extract user context
    ✓ SUCCESS
```

---

## Changes Made

### 1. fm-core-lib v0.3.0 (BREAKING)

**Deleted**:
- `ServiceAuthMiddleware` class
- `ServiceTokenProvider` class
- `ServiceIdentity` class
- `token_provider.py` file
- `service_auth.py` file
- Dependencies: `pyjwt`, `cryptography`

**Added**:
- New simplified `RequestContext` class (header extraction only)
- `request_context.py` file

**Updated**:
- `BaseServiceClient`: No longer requires `token_provider`
- `CaseServiceClient`: Simplified constructor

**Migration**:

```python
# OLD ❌
from fm_core_lib.auth import ServiceTokenProvider, ServiceAuthMiddleware

app.add_middleware(ServiceAuthMiddleware, public_key=key, ...)

token_provider = ServiceTokenProvider(auth_service_url=url, ...)
client = CaseServiceClient(base_url=url, token_provider=token_provider.get_token)

# NEW ✅
# Remove middleware registration entirely

client = CaseServiceClient(base_url=url)
```

### 2. fm-auth-service

**Deleted**:
- `api/routes/service_auth.py` (service token endpoint)
- `domain/services/service_token_manager.py`
- Service token initialization from `main.py`

**No Migration Needed**: Endpoint `/api/v1/service-auth/token` no longer exists.

### 3. fm-case-service

**Changed**:
- Removed `ServiceAuthMiddleware` registration
- Updated `get_user_id()` to extract from X-User-ID header directly

**Migration**: Already complete ✅

### 4. fm-agent-service

**Changed**:
- Removed `ServiceTokenProvider` singleton
- Simplified `get_case_service_client()`

**Migration**: Already complete ✅

### 5. Other Services

**fm-knowledge-service**, **fm-evidence-service**, **fm-session-service**:
- Never used ServiceAuthMiddleware
- **No changes needed** ✅

---

## Security Model

### Critical Security Guardrail

**API Gateway MUST strip client-provided X-User-* headers.**

**Location**: `fm-api-gateway/src/gateway/api/middleware.py:202-228`

```python
def _strip_client_user_headers(self, request: Request) -> None:
    """Remove any client-provided X-User-* headers (security measure)."""
    headers_to_remove = [
        key for key in headers.keys() if key.lower().startswith("x-user-")
    ]
    if headers_to_remove:
        logger.warning(f"Client attempted header injection with: {headers_to_remove}")
```

**This prevents attackers from forging user identity.**

### Security Properties Maintained

✅ **User Authentication**: Gateway validates JWT tokens
✅ **Header Injection Prevention**: Gateway strips client X-User-* headers
✅ **User Isolation**: Database queries scoped to user_id
✅ **Network Isolation**: Services not publicly accessible
✅ **Audit Trail**: All requests logged with user context

### Security Properties Removed

❌ ~~Service-to-service JWT validation~~
❌ ~~Service identity and permissions~~

**Why this is OK**: Services run on private networks (Docker/K8s). External attackers cannot reach services directly. Internal service calls are trusted.

---

## Testing Results

### Before Removal

```bash
$ ./faultmaven verify
✗ Failed to create test case
Error: "Missing authentication context (middleware not configured?)"
```

### After Removal

```bash
$ ./faultmaven verify
✓ Auth Service
✓ Session Service
✓ Case Service
✓ Knowledge Service
✓ Evidence Service
✓ Agent Service
✓ API Gateway
✓ Dashboard
✓ Case created (ID: case_44b45303c6bf)
✓ Evidence uploaded
✓ Knowledge base endpoint operational
```

**All services working correctly** ✅

---

## For Enterprise/Production Deployments

If you need service-to-service security (zero-trust between services), use **infrastructure-layer tools**, not application code:

### Option 1: Istio Service Mesh

```bash
# Install Istio
istioctl install --set profile=default

# Enable mTLS globally
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: faultmaven
spec:
  mtls:
    mode: STRICT
EOF
```

**Benefits**:
- Automatic mTLS between all services
- Certificate rotation handled by Istio
- No code changes required
- Industry-standard approach

### Option 2: Kubernetes NetworkPolicy

```yaml
# Only allow API Gateway to call backend services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-direct-backend-access
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: fm-api-gateway
```

### Option 3: Linkerd Service Mesh

```bash
# Install Linkerd
linkerd install | kubectl apply -f -

# Inject Linkerd proxy
kubectl annotate namespace faultmaven linkerd.io/inject=enabled
```

**DO NOT** re-implement service JWT auth in application code. Use infrastructure.

---

## Rollback Instructions

If you need to rollback (not recommended):

### 1. Revert fm-core-lib

```bash
cd fm-core-lib
git revert caced5f  # Revert v0.3.0 breaking changes
git push origin main
```

### 2. Revert fm-auth-service

```bash
cd fm-auth-service
git revert fdfd85d  # Restore service token manager
git push origin main
```

### 3. Revert fm-case-service

```bash
cd fm-case-service
git revert d20248d  # Restore ServiceAuthMiddleware
git push origin main
```

### 4. Revert fm-agent-service

```bash
cd fm-agent-service
git revert 200aa14  # Restore ServiceTokenProvider
git push origin main
```

**Note**: Rollback will restore broken state. Fix requires implementing gateway to generate service JWTs.

---

## FAQ

### Q: Is this less secure than before?

**A**: No. The previous implementation was broken (services never received tokens). The new model is **more secure** because:
1. Gateway properly sanitizes headers (prevents injection)
2. Simpler code = fewer bugs
3. Single auth point = easier to audit
4. Network isolation already prevents external access

### Q: What about zero-trust security?

**A**: Zero-trust for microservices uses **mTLS at the infrastructure layer** (Istio/Linkerd), not application-layer JWT. Application-layer JWT is the wrong tool for service-to-service auth.

### Q: Can services call each other without going through the gateway?

**A**: Yes. Services can call each other directly on the internal Docker/Kubernetes network. They propagate X-User-* headers from the original request. This is **intentional** and aligns with industry best practices.

### Q: What if someone deploys a rogue service on the network?

**A**:
1. If an attacker has access to deploy services on your internal network, you have bigger problems (compromised infrastructure)
2. Use Kubernetes NetworkPolicy to restrict which pods can communicate
3. Use service mesh (Istio/Linkerd) for mTLS if paranoid
4. Application-layer JWT doesn't help if attacker controls infrastructure

### Q: How do we prevent one service from impersonating another?

**A**: Services don't have separate identities in this model. All services are part of the trusted backend. If you need service identity/permissions:
1. Use service mesh with mTLS (infrastructure layer)
2. NOT application-layer JWT (wrong approach)

### Q: What about audit logs showing which service made the call?

**A**:
- All requests are logged with user context (user_id from headers)
- Service-to-service calls are internal implementation details
- Audit what the **user** did, not which service called which
- If you need service-level audit, add correlation IDs, not JWT auth

---

## Commits

| Repository | Commit | Description |
|------------|--------|-------------|
| fm-core-lib | `caced5f` | BREAKING: Remove service-to-service JWT authentication (v0.3.0) |
| fm-auth-service | `fdfd85d` | Remove service-to-service JWT token generation |
| fm-case-service | `d20248d` | Remove service-to-service JWT authentication |
| fm-agent-service | `200aa14` | Remove ServiceTokenProvider from agent service |

---

## Related Documents

- [GHCR_DECISION.md](GHCR_DECISION.md) - Why we made GHCR packages public
- [README.md](README.md#security-architecture) - Updated security architecture
- [QUICKSTART.md](QUICKSTART.md) - Deployment guide (no auth config needed)

---

## Support

If you have questions or issues:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review this migration guide
3. Check GitHub Issues: https://github.com/FaultMaven/faultmaven-deploy/issues

---

**Status**: Migration complete ✅
**Date**: 2025-12-07
**Impact**: All services updated and tested
