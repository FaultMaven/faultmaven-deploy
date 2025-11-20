# FaultMaven Cleanup Guide

Comprehensive guide to cleaning up FaultMaven resources when things go wrong or you need to free disk space.

---

## Quick Reference

```bash
./faultmaven kill    # Emergency: Force-kill misbehaving containers
./faultmaven clean   # Data reset: Delete all cases/evidence (fast restart)
./faultmaven prune   # Disk space: Remove Docker images and cache
./faultmaven nuke    # Nuclear: Delete everything (including system-wide cache)
```

---

## Command Breakdown

### `./faultmaven kill` - Emergency Shutdown

**Use when:**
- A container is stuck and won't respond to `stop`
- Service is misbehaving or consuming too much memory
- Need immediate shutdown (crashes, OOM loops)

**What it does:**
1. Force-kills all FaultMaven containers (`docker kill`)
2. Removes all FaultMaven containers (`docker rm -f`)
3. Runs `docker compose down` as backup
4. Preserves data in `./data` directory
5. Preserves Docker images (fast restart)

**What it preserves:**
- ✅ All data (`./data` directory intact)
- ✅ Docker images (no rebuild needed)
- ✅ Build cache (speeds up future builds)

**Recovery:**
```bash
./faultmaven kill
./faultmaven start  # Restarts in 30-60 seconds (no rebuild)
```

**Example output:**
```
╔════════════════════════════════════════╗
║  FaultMaven Self-Hosted Manager      ║
╚════════════════════════════════════════╝

Force-killing all FaultMaven containers...

ℹ Killing containers...
ℹ Removing containers...
✓ All FaultMaven containers killed and removed

ℹ Data preserved in ./data directory
ℹ Run './faultmaven start' to restart
```

---

### `./faultmaven clean` - Data Reset

**Use when:**
- Want to start with fresh database
- Corrupted data or testing migrations
- Need to clear all cases/evidence for demo

**What it does:**
1. Stops all services gracefully (`docker compose down -v`)
2. Deletes `./data` directory (SQLite + uploads)
3. Preserves Docker images (no rebuild)
4. Removes Docker volumes

**What it deletes:**
- ❌ SQLite database (`./data/faultmaven.db`)
- ❌ All uploaded evidence files (`./data/uploads/`)
- ❌ Docker volumes (if any)

**What it preserves:**
- ✅ Docker images (fast restart)
- ✅ Build cache
- ✅ Configuration files (`.env`, `docker-compose.yml`)

**Confirmation required:** Type `DELETE`

**Recovery:**
```bash
./faultmaven clean
# Type: DELETE
./faultmaven start  # Starts with empty database
```

**Example output:**
```
╔════════════════════════════════════════╗
║  FaultMaven Self-Hosted Manager      ║
╚════════════════════════════════════════╝

⚠ This will PERMANENTLY DELETE all data including:
  - All cases and troubleshooting sessions
  - All uploaded evidence files
  - All knowledge base documents
  - SQLite database

Docker images and containers will be preserved (use 'prune' to remove)

Are you sure? Type 'DELETE' to confirm: DELETE

ℹ Stopping services...
ℹ Removing data directory...
✓ FaultMaven data has been deleted

ℹ Docker images preserved - restart will be fast
ℹ Run './faultmaven start' to start fresh
```

---

### `./faultmaven prune` - Docker Cleanup

**Use when:**
- Low on disk space
- Have old/dangling FaultMaven images
- Want to remove build cache
- Orphaned containers exist

**What it does:**
1. Stops and removes all containers (`docker compose down --remove-orphans`)
2. Removes all FaultMaven images
3. Removes dangling/unused images
4. Removes unused Docker networks
5. Clears build cache
6. Shows disk space reclaimed

**What it deletes:**
- ❌ All FaultMaven Docker images
- ❌ Build cache (layer cache)
- ❌ Dangling images
- ❌ Unused networks
- ❌ Orphaned containers

**What it preserves:**
- ✅ Data directory (`./data` intact)
- ✅ Other Docker projects (only removes FaultMaven images)

**Confirmation required:** Press `y`

**Recovery:**
```bash
./faultmaven prune
# Type: y
./faultmaven start  # Rebuilds images (5-10 minutes)
```

**Example output:**
```
╔════════════════════════════════════════╗
║  FaultMaven Self-Hosted Manager      ║
╚════════════════════════════════════════╝

⚠ This will remove:
  - All stopped FaultMaven containers
  - All orphaned containers (detached from compose)
  - All dangling/unused FaultMaven images
  - All unused Docker networks
  - All build cache (speeds up future builds)

Data in ./data directory will be preserved

Continue? (y/N) y

ℹ Removing containers...
ℹ Removing FaultMaven images...
ℹ Removing dangling images...
ℹ Removing unused networks...
ℹ Removing build cache...
✓ Docker cleanup complete

ℹ Checking disk space...
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          15        3         8.5GB     6.2GB (73%)
Containers      0         0         0B        0B
Local Volumes   2         1         1.2GB     800MB (66%)
Build Cache     45        0         3.1GB     3.1GB (100%)

ℹ Data preserved in ./data directory
ℹ Run './faultmaven start' to rebuild and restart
```

---

### `./faultmaven nuke` - Nuclear Option

**Use when:**
- Total rebuild needed (code changes, corruption)
- Want to free maximum disk space
- Starting completely fresh
- Troubleshooting weird Docker issues

**What it does:**
1. Kills all FaultMaven containers
2. Removes ALL FaultMaven images
3. Deletes `./data` directory
4. Removes `docker-compose.override.yml`
5. Runs `docker system prune -a -f --volumes` (SYSTEM-WIDE!)
6. Shows total disk space reclaimed

**What it deletes:**
- ❌ **All FaultMaven containers**
- ❌ **All FaultMaven images**
- ❌ **All FaultMaven data (`./data`)**
- ❌ **Resource limit overrides**
- ❌ **ALL Docker build cache (system-wide)**
- ❌ **ALL unused Docker resources (affects other projects!)**

**What it preserves:**
- ✅ Configuration files (`.env`, `docker-compose.yml`)
- ✅ Source code in repositories

**⚠️ WARNING:** This affects your **entire Docker installation**, not just FaultMaven!

**Confirmation required:** Type `NUKE`

**Recovery:**
```bash
./faultmaven nuke
# Type: NUKE
./faultmaven start  # Complete rebuild (10-15 minutes, no cache)
```

**Example output:**
```
╔════════════════════════════════════════╗
║  FaultMaven Self-Hosted Manager      ║
╚════════════════════════════════════════╝

⚠️  NUCLEAR OPTION - This will:
  - Kill all FaultMaven containers
  - Remove all FaultMaven images and volumes
  - Remove ALL Docker build cache (affects other projects!)
  - Remove ALL unused Docker resources system-wide
  - DELETE ./data directory (all cases, evidence, knowledge base)

✗ This is destructive and affects your entire Docker installation!

Are you ABSOLUTELY sure? Type 'NUKE' to confirm: NUKE

ℹ Killing all FaultMaven containers...
ℹ Removing all FaultMaven images...
ℹ Removing data directory...
ℹ Removing docker-compose.override.yml...
⚠ Running system-wide Docker cleanup...
✓ Nuclear cleanup complete - FaultMaven obliterated

ℹ Disk space reclaimed:
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          2         0         150MB     150MB (100%)
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B

⚠ You'll need to rebuild everything with './faultmaven start'
⚠ First build will take 10-15 minutes (no cache)
```

---

## Decision Tree

```
Is a service misbehaving or stuck?
├─ Yes → ./faultmaven kill
└─ No
    │
    Want to reset data only?
    ├─ Yes → ./faultmaven clean
    └─ No
        │
        Running low on disk space?
        ├─ Yes → ./faultmaven prune
        └─ No
            │
            Need complete fresh start?
            └─ Yes → ./faultmaven nuke
```

---

## Comparison Table

| Command | Containers | Images | Data | Build Cache | Restart Time | Disk Freed |
|---------|------------|--------|------|-------------|--------------|------------|
| **kill** | Killed | ✅ Kept | ✅ Kept | ✅ Kept | 30-60s | 0 MB |
| **clean** | Stopped | ✅ Kept | ❌ Deleted | ✅ Kept | 30-60s | ~1 GB |
| **prune** | Removed | ❌ Deleted | ✅ Kept | ❌ Deleted | 5-10 min | ~5-10 GB |
| **nuke** | Removed | ❌ Deleted | ❌ Deleted | ❌ Deleted (all!) | 10-15 min | ~15-20 GB |

---

## Advanced: Manual Cleanup

If the wrapper script fails or you need more control:

### Find all FaultMaven containers
```bash
docker ps -a --filter "name=faultmaven"
```

### Kill specific container
```bash
docker kill <container-id>
docker rm -f <container-id>
```

### Remove all FaultMaven images
```bash
docker images --filter "reference=faultmaven*" -q | xargs docker rmi -f
```

### Check orphaned containers
```bash
docker ps -a --filter "status=exited"
docker ps -a --filter "status=dead"
```

### Remove orphaned containers
```bash
docker container prune -f
```

### Check disk usage
```bash
docker system df
docker system df -v  # Verbose
```

### Nuclear Docker cleanup (use with caution!)
```bash
docker system prune -a -f --volumes
```

---

## Troubleshooting

### "Container won't stop"
```bash
# Force kill the specific container
docker kill <container-id>

# If still stuck, restart Docker daemon
# macOS/Windows: Restart Docker Desktop
# Linux: sudo systemctl restart docker
```

### "Image removal failed"
```bash
# Check if containers are using the image
docker ps -a --filter "ancestor=<image-id>"

# Stop and remove containers first
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

# Then remove image
docker rmi -f <image-id>
```

### "Cannot remove volume"
```bash
# Check what's using the volume
docker ps -a --filter "volume=<volume-name>"

# Stop containers using it
docker compose down -v

# Force remove
docker volume rm -f <volume-name>
```

### "Disk still full after cleanup"
```bash
# Check Docker disk usage
docker system df -v

# Nuclear cleanup
docker system prune -a -f --volumes

# On Linux, also clear journal logs
journalctl --vacuum-time=1d
```

---

## Best Practices

1. **Use `kill` for emergency stops**
   - Fast recovery (30s)
   - Data preserved
   - Safe to run repeatedly

2. **Use `clean` for data resets**
   - Testing database migrations
   - Demo resets
   - Corrupted data recovery

3. **Use `prune` for disk space**
   - Run monthly to reclaim space
   - Before major updates
   - When Docker feels slow

4. **Avoid `nuke` unless necessary**
   - Affects other Docker projects
   - Long rebuild time (10-15 min)
   - Only for complete fresh start

5. **Always backup before cleanup**
   ```bash
   # Backup data before clean/nuke
   zip -r faultmaven-backup-$(date +%Y%m%d).zip ./data

   # Restore if needed
   unzip faultmaven-backup-20250120.zip
   ```

---

## Summary

- **Quick fix:** `./faultmaven kill` (30s restart)
- **Fresh start:** `./faultmaven clean` (1 min restart)
- **Free space:** `./faultmaven prune` (10 min rebuild)
- **Nuclear:** `./faultmaven nuke` (15 min rebuild + system impact)

All commands are **safe** and **reversible** (except data deletion in `clean`/`nuke`).

Always check `./faultmaven help` for the latest options!
