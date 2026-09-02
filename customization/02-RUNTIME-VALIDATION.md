# Runtime Customization Validation Guide

This document validates that all runtime customization surfaces work with the
unmodified upstream Open WebUI image.

## Test Setup

```bash
cd customization/
docker compose -f docker-compose.runtime-test.yaml up -d
```

This starts:
- **PostgreSQL 16** (production database)
- **Redis 7** (websocket manager for multi-instance)
- **Open WebUI** (unmodified upstream `ghcr.io/open-webui/open-webui:main`)

## Validation Checklist

### 1. Volume-Mounted custom.css

**What**: Mount `custom-assets/custom.css` at `/app/backend/open_webui/static/custom.css`

**How to verify**:
1. Open `http://localhost:3000` in browser
2. Open DevTools > Network > filter `custom.css`
3. Confirm the file is loaded with your custom rules
4. Inspect sidebar -- should have custom background color

**Known caveat**: The upstream `config.py` copies `FRONTEND_BUILD_DIR/static/**` into
`open_webui/static` on import. However, Docker volume mounts take precedence over
the container filesystem, so a bind-mount at the target path survives the copy.
The copy writes to the mount point, but since we mount read-only (`:ro`), the
container's copy attempt for `custom.css` will silently fail, and our file persists.

**Risk level**: LOW -- this is a documented customization surface.

### 2. Volume-Mounted loader.js

**What**: Mount `custom-assets/loader.js` at `/app/backend/open_webui/static/loader.js`

**How to verify**:
1. Open browser DevTools > Console
2. Switch themes (Settings > General > Theme)
3. Confirm `window.applyTheme()` fires and custom CSS variable is set
4. Check: `getComputedStyle(document.documentElement).getPropertyValue('--custom-header-bg')`

**Risk level**: LOW -- same mechanism as custom.css.

### 3. Environment-Based Configuration

**What**: All `ENABLE_*`, `DATABASE_URL`, `REDIS_URL`, `WEBUI_NAME`, etc.

**How to verify**:
1. Open `http://localhost:3000`
2. Confirm page title shows "My Custom Platform (Open WebUI)"
3. Log in with admin@example.com / admin
4. Go to Settings (Admin) > General -- confirm feature flags match env vars
5. Go to Admin > Connections -- confirm Ollama is disabled
6. Check database: `docker compose exec postgres psql -U openwebui -c "SELECT count(*) FROM config;"`

**Risk level**: VERY LOW -- this is the primary configuration mechanism.

### 4. DB-Stored Functions (Plugin System)

**What**: Create a Filter Function via Admin UI, stored in database.

**How to verify**:
1. Log in as admin
2. Go to Workspace > Functions > Create
3. Paste this example filter function:

```python
"""
title: Example Greeting Filter
description: Prepends a greeting to all assistant responses
version: 0.1.0
"""

class Filter:
    def __init__(self):
        pass

    async def inlet(self, body, __user__=None):
        # Modify incoming request
        return body

    async def outlet(self, body, __user__=None):
        # Modify outgoing response
        for message in body.get("messages", []):
            if message.get("role") == "assistant":
                content = message.get("content", "")
                if not content.startswith("[Custom]"):
                    message["content"] = f"[Custom] {content}"
        return body
```

4. Enable the function and assign it as a global filter
5. Send a chat message -- response should be prefixed with "[Custom]"
6. Restart the container: `docker compose restart open-webui`
7. Verify the function persists (stored in PostgreSQL)

**Risk level**: LOW -- this is the official plugin mechanism.

### 5. DB-Stored Tools

**What**: Create a Tool via Workspace > Tools.

**How to verify**:
1. Go to Workspace > Tools > Create
2. Paste this example tool:

```python
"""
title: Current Time Tool
description: Returns the current server time
version: 0.1.0
"""

import datetime

class Tools:
    def __init__(self):
        pass

    async def get_current_time(self) -> str:
        """Get the current server date and time."""
        return datetime.datetime.now().isoformat()
```

3. Enable the tool
4. In a chat, enable the tool and ask "What time is it?"
5. The LLM should call the tool and return the current time

**Risk level**: LOW -- official plugin mechanism.

### 6. PostgreSQL Persistence

**What**: All data persists in external PostgreSQL, not SQLite.

**How to verify**:
```bash
docker compose exec postgres psql -U openwebui -c "\dt"
```
Should show all Open WebUI tables (auth, user, chat, config, function, tool, etc.)

**Risk level**: VERY LOW -- PostgreSQL is a first-class supported backend.

### 7. Redis WebSocket Manager

**What**: WebSocket events routed through Redis for multi-instance support.

**How to verify**:
```bash
docker compose exec redis redis-cli keys "*open-webui*"
```
Should show session/presence keys after a user logs in.

**Risk level**: LOW -- documented multi-instance setup.

## What This Validates

- The upstream image works as a black box with zero code changes
- CSS/JS customization via volume mounts works
- Environment variables configure all major subsystems
- Plugin system (Functions, Tools) stores code in the database
- External data backends (PostgreSQL, Redis) work out of the box
- All customizations survive container restarts (persisted in DB/volumes)
