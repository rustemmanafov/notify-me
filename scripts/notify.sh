#!/usr/bin/env bash
#
# notify-me — Claude Code hook bildiriş skripti
#
# Stop və Notification event-lərində işə düşür və NOTIFY_PLATFORM
# environment variable-ına əsasən seçilmiş platformaya mesaj göndərir.
#
# Bu skript HEÇ VAXT sıfırdan fərqli exit code qaytarmır ki,
# Claude Code sessiyasını bloklamasın.

# Platforma seçilməyibsə səssizcə çıx
if [ -z "${NOTIFY_PLATFORM:-}" ]; then
  exit 0
fi

# Hook-dan gələn JSON-u stdin-dən oxu (bloklanmamaq üçün timeout-suz, tək cat)
INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat 2>/dev/null || true)
fi

# Event adını və işçi qovluğu JSON-dan çıxar (jq varsa onu, yoxdursa sed işlət)
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

# Event-ə görə mesaj mətnini qur
if [ "$EVENT" = "Notification" ]; then
  MESSAGE="🔔 Claude Code sizin cavabınızı gözləyir
Layihə: ${PROJECT}
Vaxt: ${TIMESTAMP}"
  if [ -n "$NOTIF_MSG" ]; then
    MESSAGE="${MESSAGE}
Mesaj: ${NOTIF_MSG}"
  fi
else
  MESSAGE="✅ Claude Code tapşırığı bitirdi
Layihə: ${PROJECT}
Vaxt: ${TIMESTAMP}"
fi

# JSON string-lər üçün sadə escape (jq yoxdursa lazım olur)
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
    # Tanınmayan platforma — səssizcə keç
    ;;
esac

exit 0
