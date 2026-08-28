#!/usr/bin/env bash
#
# notify-me — Claude Code hook notification script
#
# Runs on Stop and Notification events and sends a message to the
# platform selected via the NOTIFY_PLATFORM environment variable.
#
# This script NEVER returns a non-zero exit code, so it can never
# block a Claude Code session.

# Exit silently if no platform is configured
if [ -z "${NOTIFY_PLATFORM:-}" ]; then
  exit 0
fi

# Read the hook JSON from stdin (single cat, non-blocking when no pipe)
INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat 2>/dev/null || true)
fi

# Extract the event name and working directory from the JSON
# (use jq if available, fall back to sed)
EVENT=""
CWD=""
NOTIF_MSG=""
if [ -n "$INPUT" ]; then
  if command -v jq >/dev/null 2>&1; then
    EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
    CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    NOTIF_MSG=$(printf '%s' "$INPUT" | jq -r '.message // empty' 2>/dev/null)
  else
    EVENT=$(printf '%s' "$INPUT" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    CWD=$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    NOTIF_MSG=$(printf '%s' "$INPUT" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  fi
fi

[ -z "$CWD" ] && CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
PROJECT=$(basename "$CWD")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Build the message text based on the event
if [ "$EVENT" = "Notification" ]; then
  MESSAGE="🔔 Claude Code is waiting for your input
Project: ${PROJECT}
Time: ${TIMESTAMP}"
  if [ -n "$NOTIF_MSG" ]; then
    MESSAGE="${MESSAGE}
Message: ${NOTIF_MSG}"
  fi
else
  MESSAGE="✅ Claude Code finished a task
Project: ${PROJECT}
Time: ${TIMESTAMP}"
fi

# Minimal escaping for JSON strings (needed when jq is unavailable)
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//'
}

case "$NOTIFY_PLATFORM" in

  telegram)
    if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
      curl -s --max-time 10 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${MESSAGE}" \
        >/dev/null 2>&1 || true
    fi
    ;;

  discord)
    if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
      ESCAPED=$(json_escape "$MESSAGE")
      curl -s --max-time 10 \
        -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"${ESCAPED}\"}" \
        >/dev/null 2>&1 || true
    fi
    ;;

  slack)
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
      ESCAPED=$(json_escape "$MESSAGE")
      curl -s --max-time 10 \
        -X POST "$SLACK_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"${ESCAPED}\"}" \
        >/dev/null 2>&1 || true
    fi
    ;;

  whatsapp)
    if [ -n "${WHATSAPP_PHONE:-}" ] && [ -n "${WHATSAPP_APIKEY:-}" ]; then
      curl -s --max-time 10 -G \
        "https://api.callmebot.com/whatsapp.php" \
        --data-urlencode "phone=${WHATSAPP_PHONE}" \
        --data-urlencode "apikey=${WHATSAPP_APIKEY}" \
        --data-urlencode "text=${MESSAGE}" \
        >/dev/null 2>&1 || true
    fi
    ;;

  *)
    # Unknown platform — skip silently
    ;;
esac

exit 0
