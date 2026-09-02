#!/usr/bin/env bash
set -euo pipefail

# Custom entrypoint wrapper for derived Open WebUI image.
# Runs custom initialization before delegating to the upstream start.sh.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

echo "=== Custom Init: Starting ==="

# -- Example: Wait for external dependencies --
# Uncomment to wait for a custom sidecar service:
# until curl -sf http://custom-api:8000/health > /dev/null 2>&1; do
#   echo "Waiting for custom API service..."
#   sleep 2
# done

# -- Example: Pre-seed configuration --
# Write custom config or download assets at startup:
# if [ -n "${CUSTOM_BRANDING_URL:-}" ]; then
#   echo "Downloading custom branding..."
#   curl -sf "${CUSTOM_BRANDING_URL}/favicon.png" -o /app/backend/open_webui/static/favicon.png || true
#   curl -sf "${CUSTOM_BRANDING_URL}/logo.png" -o /app/backend/open_webui/static/logo.png || true
# fi

# -- Example: Run custom database migrations --
# If you have a sidecar DB with custom tables:
# python -c "from custom_module import run_migrations; run_migrations()" || true

echo "=== Custom Init: Complete ==="

# Delegate to upstream start.sh (handles secret key, Ollama, CUDA, uvicorn)
exec bash "${SCRIPT_DIR}/start.sh" "$@"
