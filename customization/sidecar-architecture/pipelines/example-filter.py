"""
Example Pipeline Filter for Open WebUI Pipelines service.

This file should be placed in the Pipelines service's /app/pipelines/ directory
(via volume mount or the Pipelines upload API).

It intercepts chat messages before they reach the LLM (inlet) and after
the LLM responds (outlet), allowing custom processing without modifying
the Open WebUI codebase.

Pipelines repo: https://github.com/open-webui/pipelines
"""

from typing import Optional
from pydantic import BaseModel, Field


class Pipeline:
    class Valves(BaseModel):
        """Admin-configurable settings for this pipeline."""
        disclaimer_text: str = Field(
            default="[AI-Generated] ",
            description="Text prepended to all AI responses",
        )
        blocked_words: str = Field(
            default="",
            description="Comma-separated list of words to filter from prompts",
        )
        enable_logging: bool = Field(
            default=True,
            description="Log all prompts and responses",
        )

    def __init__(self):
        self.name = "Custom Filter Pipeline"
        self.valves = self.Valves()

    async def on_startup(self):
        print(f"Pipeline '{self.name}' started")

    async def on_shutdown(self):
        print(f"Pipeline '{self.name}' stopped")

    async def inlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Process incoming chat request before it reaches the LLM."""
        messages = body.get("messages", [])

        if self.valves.blocked_words:
            blocked = [w.strip().lower() for w in self.valves.blocked_words.split(",")]
            for msg in messages:
                if msg.get("role") == "user":
                    content = msg.get("content", "")
                    if isinstance(content, str):
                        for word in blocked:
                            if word and word in content.lower():
                                msg["content"] = content.replace(word, "[REDACTED]")

        if self.valves.enable_logging and user:
            last_msg = messages[-1] if messages else {}
            print(f"[inlet] user={user.get('email', 'unknown')} msg={last_msg.get('content', '')[:100]}")

        return body

    async def outlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """Process outgoing chat response after the LLM responds."""
        messages = body.get("messages", [])

        if self.valves.disclaimer_text:
            for msg in messages:
                if msg.get("role") == "assistant":
                    content = msg.get("content", "")
                    if isinstance(content, str) and not content.startswith(self.valves.disclaimer_text):
                        msg["content"] = f"{self.valves.disclaimer_text}{content}"

        if self.valves.enable_logging and user:
            last_msg = messages[-1] if messages else {}
            print(f"[outlet] user={user.get('email', 'unknown')} response={last_msg.get('content', '')[:100]}")

        return body
