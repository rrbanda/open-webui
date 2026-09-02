#!/bin/sh
#
# register.sh -- Register agents with LiteLLM gateway
#
# Reads from agents.yaml and registers each agent as a model in LiteLLM.
# Designed to run as:
#   - A K8s init container alongside each agent deployment
#   - A standalone Job after LiteLLM starts
#   - Manually during development
#
# Required env vars:
#   LITELLM_URL   -- LiteLLM proxy base URL (e.g., http://litellm:4000)
#   LITELLM_KEY   -- LiteLLM master API key
#
# Optional env vars (for single-agent init container mode):
#   AGENT_NAME      -- Agent name (skips agents.yaml, registers this one agent)
#   AGENT_MODEL_ID  -- Model ID on the agent endpoint
#   AGENT_URL       -- Agent endpoint URL
#
# Usage:
#   # From agents.yaml (all agents):
#   LITELLM_URL=http://litellm:4000 LITELLM_KEY=sk-key ./register.sh /path/to/agents.yaml
#
#   # Single agent (init container mode):
#   AGENT_NAME=my-agent AGENT_MODEL_ID=app AGENT_URL=http://agent:8080 ./register.sh

set -e

LITELLM_URL="${LITELLM_URL:?LITELLM_URL is required}"
LITELLM_KEY="${LITELLM_KEY:?LITELLM_KEY is required}"

register_agent() {
    local name="$1" model_id="$2" url="$3"
    echo "Registering agent: $name (model=$model_id, url=$url)"

    response=$(curl -s -w "\n%{http_code}" -X POST "$LITELLM_URL/model/new" \
        -H "Authorization: Bearer $LITELLM_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model_name\": \"$name\",
            \"litellm_params\": {
                \"model\": \"openai/$model_id\",
                \"api_base\": \"$url\"
            }
        }")

    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo "  OK ($http_code)"
    elif echo "$body" | grep -q "already exists"; then
        echo "  Already registered (skipping)"
    else
        echo "  FAILED ($http_code): $body" >&2
        return 1
    fi
}

# Single-agent mode (init container)
if [ -n "$AGENT_NAME" ] && [ -n "$AGENT_MODEL_ID" ] && [ -n "$AGENT_URL" ]; then
    register_agent "$AGENT_NAME" "$AGENT_MODEL_ID" "$AGENT_URL"
    exit $?
fi

# Multi-agent mode (from agents.yaml)
AGENTS_FILE="${1:-/config/agents.yaml}"
if [ ! -f "$AGENTS_FILE" ]; then
    echo "ERROR: agents.yaml not found at $AGENTS_FILE" >&2
    echo "Usage: $0 [path/to/agents.yaml]" >&2
    exit 1
fi

echo "Reading agents from $AGENTS_FILE"
echo "LiteLLM URL: $LITELLM_URL"
echo "---"

# Parse YAML with basic shell (no python dependency in curlimages/curl)
# Extracts name, model_id, url from each agent block
current_name="" current_model="" current_url=""
while IFS= read -r line; do
    case "$line" in
        *"- name:"*)
            # Flush previous agent
            if [ -n "$current_name" ] && [ -n "$current_model" ] && [ -n "$current_url" ]; then
                register_agent "$current_name" "$current_model" "$current_url" || true
            fi
            current_name=$(echo "$line" | sed 's/.*- name: *//' | tr -d '"' | tr -d "'")
            current_model="" current_url=""
            ;;
        *"model_id:"*)
            current_model=$(echo "$line" | sed 's/.*model_id: *//' | tr -d '"' | tr -d "'")
            ;;
        *"url:"*)
            current_url=$(echo "$line" | sed 's/.*url: *//' | tr -d '"' | tr -d "'")
            ;;
    esac
done < "$AGENTS_FILE"

# Flush last agent
if [ -n "$current_name" ] && [ -n "$current_model" ] && [ -n "$current_url" ]; then
    register_agent "$current_name" "$current_model" "$current_url" || true
fi

echo "---"
echo "Registration complete"
