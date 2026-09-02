"""
Custom API sidecar for Open WebUI.

This is a standalone FastAPI service that runs alongside the unmodified
Open WebUI image. It provides custom API endpoints that are routed
through the reverse proxy at /api/custom/*.

It can:
  - Call Open WebUI's API to read/write data
  - Share the same PostgreSQL database (read-only recommended)
  - Validate Open WebUI JWT tokens for authenticated endpoints
  - Expose custom business logic not covered by Functions/Tools

Usage:
  uvicorn main:app --host 0.0.0.0 --port 8000
"""

import os
from contextlib import asynccontextmanager

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel


OPENWEBUI_URL = os.getenv("OPENWEBUI_URL", "http://open-webui:8080")
OPENWEBUI_API_KEY = os.getenv("OPENWEBUI_API_KEY", "")


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient(
        base_url=OPENWEBUI_URL,
        timeout=30.0,
    )
    yield
    await app.state.http_client.aclose()


app = FastAPI(
    title="Custom API Sidecar",
    version="0.1.0",
    lifespan=lifespan,
)


async def verify_token(authorization: str = Header(default="")):
    """Validate the Open WebUI JWT by calling its /api/v1/auths endpoint."""
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")

    token = authorization.removeprefix("Bearer ")
    async with httpx.AsyncClient(base_url=OPENWEBUI_URL, timeout=10.0) as client:
        resp = await client.get(
            "/api/v1/auths",
            headers={"Authorization": f"Bearer {token}"},
        )
        if resp.status_code != 200:
            raise HTTPException(status_code=401, detail="Invalid token")
        return resp.json()


@app.get("/health")
async def health():
    return {"status": "ok", "service": "custom-api-sidecar"}


@app.get("/whoami")
async def whoami(user: dict = Depends(verify_token)):
    """Example authenticated endpoint that returns the current user info."""
    return {
        "custom_api": True,
        "user_id": user.get("id"),
        "email": user.get("email"),
        "name": user.get("name"),
        "role": user.get("role"),
    }


class CustomActionRequest(BaseModel):
    action: str
    data: dict = {}


@app.post("/actions")
async def custom_action(
    request: CustomActionRequest,
    user: dict = Depends(verify_token),
):
    """
    Example custom action endpoint.

    This can be called from:
      - A custom Action Function in Open WebUI
      - A webhook receiver
      - A custom frontend
      - Any external system
    """
    return {
        "action": request.action,
        "result": f"Processed action '{request.action}' for user {user.get('email')}",
        "data": request.data,
    }


@app.get("/models")
async def list_upstream_models(user: dict = Depends(verify_token)):
    """Example: proxy a call to Open WebUI's model list API."""
    client: httpx.AsyncClient = app.state.http_client
    headers = {}
    if OPENWEBUI_API_KEY:
        headers["Authorization"] = f"Bearer {OPENWEBUI_API_KEY}"

    resp = await client.get("/api/models", headers=headers)
    if resp.status_code != 200:
        raise HTTPException(status_code=resp.status_code, detail="Upstream error")
    return resp.json()
