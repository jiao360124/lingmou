#!/bin/bash
# Environment Variable Loader for OpenClaw (Bash version - Workspace root)
# Load ports and other configuration from .env files

load_env_file() {
    local file_path="${1:-.env}"

    if [ -f "$file_path" ]; then
        # Load variables from file
        while IFS='=' read -r key value; do
            # Skip empty lines and comments
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            # Remove quotes if present
            value="${value%\"}"
            value="${value#\"}"
            export "$key=$value"
        done < "$file_path"
        echo "✅ Environment variables loaded from $file_path"
    else
        echo "⚠️  Environment file not found: $file_path"
    fi
}

# Load from .ports.env
load_env_file ".ports.env"

# Set defaults if not already set
export GATEWAY_PORT=${GATEWAY_PORT:-18789}
export CANVAS_PORT=${CANVAS_PORT:-18789}
export HEARTBEAT_PORT=${HEARTBEAT_PORT:-18789}
export WS_PORT=${WS_PORT:-18789}
