#!/usr/bin/env bash
set -euo pipefail

# OpenAI-compatible endpoint backed by Open WebUI
BASE_URL="${OPENAI_BASE_URL:-https://ai.epetype.org/api/v1}"
MODEL="${OPENAI_MODEL:-qwen3-coder:30b}"
API_KEY="${OPENAI_API_KEY:-}"

if [[ -z "${API_KEY}" ]]; then
  echo "ERROR: OPENAI_API_KEY is not set." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"your prompt\" [model]" >&2
  echo "Example: $0 \"Reply with PRIVATE_AI_OK\" qwen3-coder:30b" >&2
  exit 1
fi

PROMPT="$1"
if [[ $# -ge 2 ]]; then
  MODEL="$2"
fi

# Basic JSON escaping for prompt content.
ESCAPED_PROMPT="${PROMPT//\\/\\\\}"
ESCAPED_PROMPT="${ESCAPED_PROMPT//\"/\\\"}"
ESCAPED_PROMPT="${ESCAPED_PROMPT//$'\n'/\\n}"

curl -sS "${BASE_URL}/chat/completions" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(cat <<JSON
{
  "model": "${MODEL}",
  "messages": [
    { "role": "user", "content": "${ESCAPED_PROMPT}" }
  ]
}
JSON
)" | sed -n 's/.*"content":"\([^"]*\)".*/\1/p' | head -n 1
