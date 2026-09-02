# Derived image: thin layer on top of the unmodified upstream Open WebUI image.
#
# This approach works for:
#   - Overriding static branding assets (logos, favicons, splash screens)
#   - Adding Python packages for custom Functions/Tools
#   - Wrapping the entrypoint with custom init logic
#
# This approach does NOT work for:
#   - Adding new Svelte components or routes (frontend is pre-built)
#   - Modifying the FastAPI app structure (routers, middleware)
#   - Changing Tailwind theme or i18n (compiled into the SPA)
#
# BUILD:
#   docker build -t my-org/open-webui-custom:latest -f customization/derived-image/Dockerfile .
#
# The build context should be the repo root (or at least include customization/derived-image/).

ARG UPSTREAM_TAG=main
FROM ghcr.io/open-webui/open-webui:${UPSTREAM_TAG}

# --------------------------------------------------------------------------
# 1. Override branding assets
# --------------------------------------------------------------------------
# These files are copied from /app/build/static/ into /app/backend/open_webui/static/
# by config.py at startup. We replace them at the source so the copy picks them up.
#
# NOTE: This is license-restricted. The Open WebUI LICENSE requires attribution.
# Only replace these if your license permits it (enterprise license or compliance
# with the branding requirements in BRANDING.md).

# Uncomment and provide your own files:
# COPY customization/derived-image/branding/favicon.png /app/build/static/favicon.png
# COPY customization/derived-image/branding/logo.png /app/build/static/logo.png
# COPY customization/derived-image/branding/splash.png /app/build/static/splash.png
# COPY customization/derived-image/branding/splash-dark.png /app/build/static/splash-dark.png

# --------------------------------------------------------------------------
# 2. Custom CSS and loader.js (alternative to volume mount)
# --------------------------------------------------------------------------
# If you prefer baking these into the image instead of volume-mounting:

COPY customization/custom-assets/custom.css /app/build/static/custom.css
COPY customization/custom-assets/loader.js /app/build/static/loader.js

# --------------------------------------------------------------------------
# 3. Additional Python packages
# --------------------------------------------------------------------------
# For custom Functions/Tools that need extra dependencies not in the base image.

COPY customization/derived-image/requirements-custom.txt /tmp/requirements-custom.txt
RUN pip install --no-cache-dir -r /tmp/requirements-custom.txt && \
    rm /tmp/requirements-custom.txt

# --------------------------------------------------------------------------
# 4. Custom entrypoint wrapper
# --------------------------------------------------------------------------
# Wraps the upstream start.sh to run custom init logic before the main app.
# The wrapper calls the original start.sh at the end, preserving all upstream
# behavior (secret key generation, Ollama startup, CUDA paths, etc.).

COPY customization/derived-image/custom-start.sh /app/backend/custom-start.sh
RUN chmod +x /app/backend/custom-start.sh

CMD ["bash", "custom-start.sh"]
