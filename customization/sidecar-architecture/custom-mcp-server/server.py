"""
Custom MCP Tool Server for Open WebUI.

This is a Model Context Protocol (MCP) server that exposes custom tools
to the LLM via Open WebUI's tool server integration. The LLM can call
these tools during chat conversations.

Register this server in Open WebUI:
  Admin > Integrations > Tool Servers > Add
  URL: http://custom-mcp-server:8001/sse (or /mcp for streamable HTTP)

This uses the official `mcp` Python SDK.
"""

import datetime
import json
import os

from mcp.server.fastmcp import FastMCP

app = FastMCP(
    "Custom Tools",
    version="0.1.0",
)


@app.tool()
async def get_system_info() -> str:
    """Get information about the custom deployment environment."""
    return json.dumps({
        "service": "custom-mcp-server",
        "version": "0.1.0",
        "timestamp": datetime.datetime.now(datetime.UTC).isoformat(),
        "environment": os.getenv("DEPLOYMENT_ENV", "development"),
    })


@app.tool()
async def lookup_employee(name: str) -> str:
    """Look up an employee by name in the company directory.

    Args:
        name: The name of the employee to look up (partial match supported).
    """
    directory = [
        {"name": "Alice Johnson", "dept": "Engineering", "email": "alice@example.com"},
        {"name": "Bob Smith", "dept": "Product", "email": "bob@example.com"},
        {"name": "Carol Williams", "dept": "Design", "email": "carol@example.com"},
    ]

    matches = [
        emp for emp in directory
        if name.lower() in emp["name"].lower()
    ]

    if not matches:
        return f"No employees found matching '{name}'"
    return json.dumps(matches, indent=2)


@app.tool()
async def create_ticket(
    title: str,
    description: str,
    priority: str = "medium",
) -> str:
    """Create a support ticket in the internal ticketing system.

    Args:
        title: Short title for the ticket.
        description: Detailed description of the issue or request.
        priority: Priority level (low, medium, high, critical).
    """
    ticket_id = f"TICKET-{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
    return json.dumps({
        "ticket_id": ticket_id,
        "title": title,
        "description": description,
        "priority": priority,
        "status": "created",
        "message": f"Ticket {ticket_id} created successfully",
    })


if __name__ == "__main__":
    import uvicorn
    from mcp.server.fastmcp import create_sse_server

    sse_app = create_sse_server(app)
    uvicorn.run(sse_app, host="0.0.0.0", port=8001)
