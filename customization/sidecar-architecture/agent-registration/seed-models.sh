#!/bin/sh
#
# seed-models.sh -- Create Open WebUI workspace models with agent_mode
#
# Reads from agents.yaml and creates workspace models in Open WebUI
# for each agent that has agent_mode: true. Idempotent -- skips models
# that already exist.
#
# Designed to run as:
#   - A K8s Job that runs after Open WebUI starts
#   - A sidecar init script
#   - Manually during development
#
# Required env vars:
#   OWUI_URL    -- Open WebUI base URL (e.g., http://open-webui:8080)
#   OWUI_KEY    -- Open WebUI admin API key
#   PREFIX_ID   -- Connection prefix_id used in OPENAI_API_CONFIGS (e.g., "agent")
#
# Usage:
#   OWUI_URL=http://open-webui:8080 OWUI_KEY=sk-key PREFIX_ID=agent ./seed-models.sh /path/to/agents.yaml

set -e

OWUI_URL="${OWUI_URL:?OWUI_URL is required}"
OWUI_KEY="${OWUI_KEY:?OWUI_KEY is required}"
PREFIX_ID="${PREFIX_ID:-agent}"

wait_for_owui() {
    echo "Waiting for Open WebUI at $OWUI_URL..."
    retries=0
    while [ $retries -lt 60 ]; do
        if curl -s --max-time 3 "$OWUI_URL/health" | grep -q '"status":true'; then
            echo "Open WebUI is ready"
            return 0
        fi
        retries=$((retries + 1))
        sleep 5
    done
    echo "ERROR: Open WebUI did not become ready in 5 minutes" >&2
    return 1
}

create_workspace_model() {
    local name="$1" model_id="$2" description="$3" agent_mode="$4"
    local base_model_id="${PREFIX_ID}.${model_id}"

    echo "Creating workspace model: $name (base=$base_model_id, agent_mode=$agent_mode)"

    # Check if model already exists
    check=$(curl -s -o /dev/null -w "%{http_code}" \
        "$OWUI_URL/api/v1/models/$name" \
        -H "Authorization: Bearer $OWUI_KEY")

    if [ "$check" = "200" ]; then
        echo "  Already exists (skipping)"
        return 0
    fi

    # Build capabilities JSON
    if [ "$agent_mode" = "true" ]; then
        caps='{"agent_mode":true,"builtin_tools":false,"memory":false,"web_search":false,"code_interpreter":false,"file_context":false,"status_updates":true}'
    else
        caps='{"status_updates":true}'
    fi

    response=$(curl -s -w "\n%{http_code}" \
        -X POST "$OWUI_URL/api/v1/models/create" \
        -H "Authorization: Bearer $OWUI_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"id\": \"$name\",
            \"name\": \"$(echo "$name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')\",
            \"base_model_id\": \"$base_model_id\",
            \"meta\": {
                \"description\": \"$description\",
                \"capabilities\": $caps
            },
            \"params\": {}
        }")

    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo "  Created ($http_code)"
    else
        echo "  FAILED ($http_code): $body" >&2
        return 1
    fi
}

# Parse agents.yaml
AGENTS_FILE="${1:-/config/agents.yaml}"
if [ ! -f "$AGENTS_FILE" ]; then
    echo "ERROR: agents.yaml not found at $AGENTS_FILE" >&2
    echo "Usage: $0 [path/to/agents.yaml]" >&2
    exit 1
fi

wait_for_owui

echo "Reading agents from $AGENTS_FILE"
echo "Open WebUI URL: $OWUI_URL"
echo "Connection prefix: $PREFIX_ID"
echo "---"

current_name="" current_model="" current_desc="" current_agent_mode=""
while IFS= read -r line; do
    case "$line" in
        *"- name:"*)
            if [ -n "$current_name" ] && [ -n "$current_model" ]; then
                create_workspace_model "$current_name" "$current_model" "$current_desc" "$current_agent_mode" || true
            fi
            current_name=$(echo "$line" | sed 's/.*- name: *//' | tr -d '"' | tr -d "'")
            current_model="" current_desc="" current_agent_mode="false"
            ;;
        *"model_id:"*)
            current_model=$(echo "$line" | sed 's/.*model_id: *//' | tr -d '"' | tr -d "'")
            ;;
        *"description:"*)
            current_desc=$(echo "$line" | sed 's/.*description: *//' | tr -d '"' | tr -d "'")
            ;;
        *"agent_mode:"*)
            current_agent_mode=$(echo "$line" | sed 's/.*agent_mode: *//' | tr -d '"' | tr -d "'" | tr -d ' ')
            ;;
    esac
done < "$AGENTS_FILE"

# Flush last agent
if [ -n "$current_name" ] && [ -n "$current_model" ]; then
    create_workspace_model "$current_name" "$current_model" "$current_desc" "$current_agent_mode" || true
fi

echo "---"
echo "Model seeding complete"
