# OIDC/SAML Authentication Setup Guide

This guide explains how to configure FaultMaven for enterprise Single Sign-On (SSO) using OpenID Connect (OIDC) or SAML 2.0.

## Table of Contents

- [Overview](#overview)
- [Deployment Neutrality](#deployment-neutrality)
- [OIDC Setup](#oidc-setup)
  - [Google Workspace](#google-workspace)
  - [Microsoft Azure AD / Entra ID](#microsoft-azure-ad--entra-id)
  - [Okta](#okta)
  - [Auth0](#auth0)
- [SAML Setup](#saml-setup)
- [Browser Extension Configuration](#browser-extension-configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

FaultMaven supports three authentication modes:

| Mode | Use Case | Configuration |
|------|----------|--------------|
| **local** | Self-hosted, single-user | Username/password with JWT tokens |
| **oidc** | Enterprise SSO (Google, Azure, Okta) | OpenID Connect |
| **saml** | Enterprise SSO (SAML-only providers) | SAML 2.0 |

Authentication mode is controlled by the `AUTH_PROVIDER` environment variable in `.env`:

```bash
# Self-hosted (default)
AUTH_PROVIDER=local

# Enterprise SSO via OIDC
AUTH_PROVIDER=oidc

# Enterprise SSO via SAML
AUTH_PROVIDER=saml
```

---

## Deployment Neutrality

FaultMaven uses **deployment-neutral authentication** — the same codebase supports both self-hosted (Docker Compose) and enterprise cloud (Kubernetes) environments.

### How It Works

1. **Backend**: `fm-auth-service` selects authentication provider via `AUTH_PROVIDER` environment variable
2. **Extension**: Queries `GET /api/v1/auth/config` on startup to determine auth mode
3. **UI**: Dynamically renders:
   - **Local**: Username/password form → redirects to dashboard login
   - **OIDC/SAML**: "Sign in with Organization" button → opens SSO flow

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Browser Extension                                           │
│                                                             │
│  ┌──────────────────┐                                      │
│  │ GET /auth/config │ ─────> Determines auth mode          │
│  └──────────────────┘                                      │
│         │                                                   │
│         ├─> local:  Show "Sign In" → dashboard login       │
│         ├─> oidc:   Show "Sign in with Organization" → SSO │
│         └─> saml:   Show "Sign in with Organization" → SSO │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ fm-auth-service                                             │
│                                                             │
│  ┌──────────────────────────────────────────┐              │
│  │ AuthProvider Factory (factory.py)        │              │
│  │                                          │              │
│  │  ENV: AUTH_PROVIDER                      │              │
│  │                                          │              │
│  │  ├─> local  → LocalAuthProvider          │              │
│  │  ├─> oidc   → OIDCAuthProvider           │              │
│  │  └─> saml   → SAMLAuthProvider           │              │
│  └──────────────────────────────────────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Principle**: No hardcoded authentication logic in clients. All authentication decisions are driven by backend configuration.

---

## OIDC Setup

### Prerequisites

- OIDC-compatible identity provider (Google, Azure AD, Okta, Auth0)
- Admin access to configure OAuth2 applications
- FaultMaven deployment URL (e.g., `https://api.faultmaven.ai` or `http://localhost:8090`)

---

### Google Workspace

**1. Create OAuth2 Credentials**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Choose **Web application**
6. Configure:
   - **Name**: FaultMaven
   - **Authorized redirect URIs**:
     ```
     https://api.faultmaven.ai/api/v1/auth/callback
     chrome-extension://[EXTENSION_ID]/oidc-callback.html
     ```
     (Replace `[EXTENSION_ID]` with your Chrome extension ID)
7. Save and note down:
   - **Client ID**: `123456789.apps.googleusercontent.com`
   - **Client Secret**: `GOCSPX-xxx`

**2. Configure FaultMaven**

Edit `.env` in `faultmaven-deploy`:

```bash
# Authentication provider
AUTH_PROVIDER=oidc

# Google Workspace OIDC
OIDC_ISSUER_URL=https://accounts.google.com
OIDC_CLIENT_ID=123456789.apps.googleusercontent.com
OIDC_CLIENT_SECRET=GOCSPX-xxx
OIDC_SCOPES="openid email profile"
```

**3. Restart Services**

```bash
docker compose down
docker compose up -d
```

**4. Test**

1. Open browser extension
2. You should see **"Sign in with Organization"** button
3. Click button → redirects to Google login
4. Complete Google authentication
5. Extension receives auth tokens and starts session

---

### Microsoft Azure AD / Entra ID

**1. Register Application**

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to **Microsoft Entra ID** → **App registrations**
3. Click **New registration**
4. Configure:
   - **Name**: FaultMaven
   - **Supported account types**: Accounts in this organizational directory only
   - **Redirect URIs**:
     - Type: Web
     - URI: `https://api.faultmaven.ai/api/v1/auth/callback`
5. Click **Register**
6. Note down:
   - **Application (client) ID**: `xxx`
   - **Directory (tenant) ID**: `xxx`

**2. Create Client Secret**

1. Go to **Certificates & secrets**
2. Click **New client secret**
3. Description: FaultMaven
4. Expiration: Choose duration (24 months recommended)
5. Click **Add**
6. Note down **Value** (not Secret ID)

**3. Configure API Permissions**

1. Go to **API permissions**
2. Click **Add a permission** → **Microsoft Graph**
3. Choose **Delegated permissions**
4. Add:
   - `openid`
   - `email`
   - `profile`
5. Click **Grant admin consent** (requires admin)

**4. Configure FaultMaven**

Edit `.env` in `faultmaven-deploy`:

```bash
# Authentication provider
AUTH_PROVIDER=oidc

# Azure AD OIDC
OIDC_ISSUER_URL=https://login.microsoftonline.com/{TENANT_ID}/v2.0
OIDC_CLIENT_ID={CLIENT_ID}
OIDC_CLIENT_SECRET={CLIENT_SECRET}
OIDC_SCOPES="openid email profile"
```

Replace `{TENANT_ID}`, `{CLIENT_ID}`, and `{CLIENT_SECRET}` with values from Azure Portal.

**5. Restart Services**

```bash
docker compose down
docker compose up -d
```

---

### Okta

**1. Create OIDC Application**

1. Go to [Okta Admin Console](https://admin.okta.com/)
2. Navigate to **Applications** → **Applications**
3. Click **Create App Integration**
4. Choose:
   - **Sign-in method**: OIDC - OpenID Connect
   - **Application type**: Web Application
5. Configure:
   - **App integration name**: FaultMaven
   - **Grant type**: Authorization Code
   - **Sign-in redirect URIs**:
     ```
     https://api.faultmaven.ai/api/v1/auth/callback
     chrome-extension://[EXTENSION_ID]/oidc-callback.html
     ```
   - **Sign-out redirect URIs**: (leave empty)
   - **Controlled access**: Choose who can use this application
6. Click **Save**
7. Note down:
   - **Client ID**: `xxx`
   - **Client secret**: `xxx`

**2. Get Issuer URL**

1. Navigate to **Security** → **API**
2. Find your **Authorization Server**:
   - **Default**: `https://{domain}.okta.com/oauth2/default`
   - **Custom**: `https://{domain}.okta.com/oauth2/{authorizationServerId}`
3. Note down **Issuer URI**

**3. Configure FaultMaven**

Edit `.env` in `faultmaven-deploy`:

```bash
# Authentication provider
AUTH_PROVIDER=oidc

# Okta OIDC
OIDC_ISSUER_URL=https://{domain}.okta.com/oauth2/default
OIDC_CLIENT_ID={CLIENT_ID}
OIDC_CLIENT_SECRET={CLIENT_SECRET}
OIDC_SCOPES="openid email profile"
```

**4. Restart Services**

```bash
docker compose down
docker compose up -d
```

---

### Auth0

**1. Create Application**

1. Go to [Auth0 Dashboard](https://manage.auth0.com/)
2. Navigate to **Applications** → **Applications**
3. Click **Create Application**
4. Choose:
   - **Name**: FaultMaven
   - **Application Type**: Regular Web Applications
5. Click **Create**

**2. Configure Application**

1. Go to **Settings** tab
2. Configure:
   - **Allowed Callback URLs**:
     ```
     https://api.faultmaven.ai/api/v1/auth/callback,
     chrome-extension://[EXTENSION_ID]/oidc-callback.html
     ```
   - **Allowed Logout URLs**: (leave empty)
   - **Allowed Web Origins**: `https://api.faultmaven.ai`
3. Scroll down and click **Save Changes**
4. Note down:
   - **Domain**: `{tenant}.auth0.com`
   - **Client ID**: `xxx`
   - **Client Secret**: `xxx`

**3. Configure FaultMaven**

Edit `.env` in `faultmaven-deploy`:

```bash
# Authentication provider
AUTH_PROVIDER=oidc

# Auth0 OIDC
OIDC_ISSUER_URL=https://{tenant}.auth0.com
OIDC_CLIENT_ID={CLIENT_ID}
OIDC_CLIENT_SECRET={CLIENT_SECRET}
OIDC_SCOPES="openid email profile"
```

**4. Restart Services**

```bash
docker compose down
docker compose up -d
```

---

## SAML Setup

SAML 2.0 configuration is similar to OIDC but uses different environment variables.

### Prerequisites

- SAML 2.0 identity provider (e.g., Okta, OneLogin, Azure AD SAML)
- IdP metadata URL or XML file
- FaultMaven Assertion Consumer Service (ACS) URL

### Configuration

1. **Get IdP Metadata URL** from your SAML provider
2. **Configure FaultMaven** (`.env`):

```bash
# Authentication provider
AUTH_PROVIDER=saml

# SAML Configuration
SAML_IDP_METADATA_URL=https://idp.example.com/metadata
SAML_SP_ENTITY_ID=faultmaven
SAML_SP_ACS_URL=https://api.faultmaven.ai/api/v1/auth/saml/acs
```

3. **Register Service Provider (SP) in IdP**:
   - **Entity ID**: `faultmaven`
   - **ACS URL**: `https://api.faultmaven.ai/api/v1/auth/saml/acs`
   - **Name ID Format**: `urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress`

4. **Restart Services**:

```bash
docker compose down
docker compose up -d
```

---

## Browser Extension Configuration

The browser extension automatically detects authentication mode by querying `GET /api/v1/auth/config`.

### Extension Callback URL

For OIDC/SAML to work with the browser extension, you must register the callback URL:

```
chrome-extension://[EXTENSION_ID]/oidc-callback.html
```

**How to find Extension ID**:

1. Open Chrome → **Extensions** → **Manage Extensions**
2. Enable **Developer mode** (top-right)
3. Find **FaultMaven Copilot**
4. Copy **ID** (e.g., `abcdefghijklmnopqrstuvwxyz`)

**Register in IdP**:

- **Google**: Add to "Authorized redirect URIs"
- **Azure AD**: Add to "Redirect URIs"
- **Okta**: Add to "Sign-in redirect URIs"
- **Auth0**: Add to "Allowed Callback URLs"

---

## Troubleshooting

### Extension shows "Sign In" instead of "Sign in with Organization"

**Cause**: Extension is not detecting OIDC/SAML mode.

**Fix**:

1. Check backend configuration:
   ```bash
   curl http://localhost:8090/api/v1/auth/config
   ```
   Expected response (OIDC):
   ```json
   {
     "provider": "oidc",
     "features": {
       "supports_registration": false,
       "requires_redirect": true
     }
   }
   ```

2. If response shows `"provider": "local"`, check `.env`:
   ```bash
   grep AUTH_PROVIDER .env
   # Should show: AUTH_PROVIDER=oidc
   ```

3. Restart services:
   ```bash
   docker compose restart fm-auth-service fm-api-gateway
   ```

---

### OIDC login fails with "redirect_uri_mismatch"

**Cause**: Redirect URI not registered in OAuth2 application.

**Fix**:

1. Get exact redirect URI from error message
2. Add to OAuth2 application configuration:
   - Backend: `https://api.faultmaven.ai/api/v1/auth/callback`
   - Extension: `chrome-extension://[EXTENSION_ID]/oidc-callback.html`
3. Save changes in IdP console
4. Retry authentication

---

### OIDC login succeeds but extension doesn't authenticate

**Cause**: PKCE code verifier mismatch or callback handler issue.

**Fix**:

1. Check browser console for errors:
   - Open extension popup
   - Right-click → Inspect → Console tab
   - Look for `[OIDC Callback]` errors

2. Check backend logs:
   ```bash
   docker compose logs fm-auth-service | grep OIDC
   ```

3. Verify PKCE support in IdP:
   - Google: ✅ Supported
   - Azure AD: ✅ Supported
   - Okta: ✅ Supported
   - Auth0: ✅ Supported

---

### "Failed to get auth config" error

**Cause**: Backend not reachable or auth service down.

**Fix**:

1. Check backend health:
   ```bash
   curl http://localhost:8090/health
   ```

2. Check auth service status:
   ```bash
   docker compose ps fm-auth-service
   ```

3. Check logs:
   ```bash
   docker compose logs fm-auth-service
   ```

4. Restart if needed:
   ```bash
   docker compose restart fm-auth-service
   ```

---

### Azure AD login fails with "invalid_client"

**Cause**: Client secret expired or incorrect.

**Fix**:

1. Go to Azure Portal → **App registrations** → **FaultMaven**
2. Navigate to **Certificates & secrets**
3. Check if secret is expired
4. Create new secret if needed
5. Update `.env` with new secret:
   ```bash
   OIDC_CLIENT_SECRET={NEW_SECRET}
   ```
6. Restart services:
   ```bash
   docker compose restart fm-auth-service
   ```

---

### Okta login fails with "access_denied"

**Cause**: User not assigned to application.

**Fix**:

1. Go to Okta Admin Console → **Applications** → **FaultMaven**
2. Navigate to **Assignments** tab
3. Click **Assign** → **Assign to People** or **Assign to Groups**
4. Add users who should have access
5. Retry authentication

---

## Security Best Practices

### 1. Use HTTPS in Production

OIDC/SAML require HTTPS for redirect URIs in production. Use:

- Reverse proxy (nginx, Caddy) with SSL certificates
- Cloud load balancer with TLS termination
- Self-signed certificates for testing only

### 2. Rotate Client Secrets

- Google: No expiration (manual rotation recommended)
- Azure AD: Expires after 24 months (configure reminder)
- Okta: No expiration (manual rotation recommended)
- Auth0: No expiration (manual rotation recommended)

### 3. Limit OAuth Scopes

Only request necessary scopes:

```bash
# Minimal scopes (recommended)
OIDC_SCOPES="openid email profile"

# ❌ Avoid requesting unnecessary scopes
# OIDC_SCOPES="openid email profile https://www.googleapis.com/auth/drive"
```

### 4. Monitor Authentication Logs

```bash
# Check auth service logs
docker compose logs -f fm-auth-service | grep -E "Login|Auth|OIDC"

# Look for:
# - Failed login attempts
# - Token validation failures
# - Suspicious activity patterns
```

### 5. Enable Admin Consent (Azure AD)

For Azure AD, always enable "Grant admin consent" to avoid per-user prompts.

---

## Next Steps

- [Deploy to Kubernetes](./KUBERNETES_DEPLOYMENT.md) for enterprise cloud
- [Configure Redis Sentinel](./REDIS_HA.md) for high availability
- [Set up S3 storage](./S3_STORAGE.md) for stateless pods
- [Enable observability](./OBSERVABILITY.md) for monitoring

---

## Support

For issues or questions:

- GitHub Issues: https://github.com/FaultMaven/faultmaven/issues
- GitHub Discussions: https://github.com/FaultMaven/faultmaven/discussions
- Documentation: https://github.com/FaultMaven/faultmaven
