# FaultMaven Self-Hosted - Troubleshooting Guide

## Dashboard Login Issues

### ❌ Error: "Refused to connect - violates Content Security Policy"

**Symptoms:**
```
Connecting to 'http://localhost:8004/v1/dev/login' violates the following 
Content Security Policy directive: "connect-src 'self' https://api.faultmaven.ai 
http://localhost:8000"
```

**Root Cause:** Dashboard was built with wrong API URL (Knowledge Service port 8004 instead of Auth Service port 8001)

**Solution:**
```bash
# Rebuild dashboard with correct API URL
docker compose down
docker compose build --no-cache fm-dashboard
docker compose up -d
```

The fix is already in the latest docker-compose.yml (commit 7b60cd9).

---

## Port Reference

| Service | Port | Purpose |
|---------|------|---------|
| Auth Service | 8001 | **Login/Authentication** |
| Session Service | 8002 | Session management |
| Case Service | 8003 | Case operations |
| Knowledge Service | 8004 | KB document operations |
| Evidence Service | 8005 | File uploads |
| Agent Service | 8006 | AI troubleshooting |
| ChromaDB | 8007 | Vector database |
| Dashboard | 3000 | **Web UI** |
| Redis | 6379 | Cache/sessions |

**Dashboard connects to:** Auth Service (8001) for login, then other services for operations.

---

## Common Issues

### Services Won't Start

```bash
# Check Docker is running
docker ps

# View service logs
docker compose logs fm-auth-service
docker compose logs fm-dashboard

# Restart all services
docker compose down
docker compose up -d
```

### Port Already in Use

**Error:** `bind: address already in use`

**Solution:**
```bash
# Find what's using the port
lsof -i :8001  # or whatever port

# Kill the process or change port in docker-compose.yml
```

### Dashboard Shows Blank Page

```bash
# Check dashboard logs
docker compose logs fm-dashboard

# Verify it's running
curl http://localhost:3000

# Rebuild if needed
docker compose build --no-cache fm-dashboard
docker compose up -d fm-dashboard
```

### Auth Service Not Responding

```bash
# Check health
curl http://localhost:8001/health

# View logs
docker compose logs fm-auth-service

# Restart
docker compose restart fm-auth-service
```

---

## Reset Everything

**⚠️ WARNING: This deletes all data!**

```bash
# Stop all services
docker compose down

# Remove data
rm -rf ./data/

# Remove Docker volumes
docker compose down -v

# Start fresh
docker compose up -d --build
```

---

## Getting Help

1. Check logs: `docker compose logs [service-name]`
2. Check GitHub Issues: https://github.com/FaultMaven/faultmaven-deploy/issues
3. Read QUICKSTART.md for setup steps
4. Check service health endpoints: `curl http://localhost:8001/health`
