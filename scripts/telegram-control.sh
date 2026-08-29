#!/usr/bin/env bash
#
# notify-me — two-way Telegram control (optional, opt-in)
#
#   telegram-control.sh permission   # PermissionRequest hook: approve/deny from Telegram
#   telegram-control.sh stop         # Stop hook: pick up a new instruction from Telegram
#
# Enable with NOTIFY_CONTROL=1. Telegram only.
#
# SECURITY: anyone who can post in your bot's chat can approve tool runs and
# send instructions to Claude on this machine. Keep the bot and its token private.
#
# Like notify.sh, this script never returns a non-zero exit code.

CONFIG_FILE="${NOTIFY_ME_CONFIG:-$HOME/.notify-me.env}"
NOTIFY_VARS="NOTIFY_PLATFORM NOTIFY_LANG NOTIFY_CONTROL NOTIFY_CONTROL_TIMEOUT \
NOTIFY_CONTROL_WAIT TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID"
if [ -f "$CONFIG_FILE" ]; then
  for __v in $NOTIFY_VARS; do eval "__env_$__v=\${$__v:-}"; done
  set -a; . "$CONFIG_FILE" 2>/dev/null || true; set +a
  for __v in $NOTIFY_VARS; do
    eval "__had=\$__env_$__v"
    [ -n "$__had" ] && eval "$__v=\$__had"
  done
fi

MODE="${1:-}"

# Only runs when explicitly enabled, on Telegram, with credentials present.
if [ "${NOTIFY_CONTROL:-}" != "1" ] \
   || [ "${NOTIFY_PLATFORM:-}" != "telegram" ] \
   || [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  exit 0
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
OFFSET_FILE="${NOTIFY_ME_OFFSET:-$HOME/.notify-me.offset}"
LANG_CODE="${NOTIFY_LANG:-en}"

INPUT=""
if [ ! -t 0 ]; then INPUT=$(cat 2>/dev/null || true); fi

# --- JSON helpers (jq preferred, python3 as fallback) ----------------------
json_get() { # json_get <json> <jq-path> <python-expr>
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -r "$2 // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$1" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin); v=$3
    print(v if v is not None else '')
except Exception:
    pass
" 2>/dev/null
  fi
}

send_msg() {
  curl -s --max-time 10 -X POST "${API}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=$1" >/dev/null 2>&1 || true
}

read_offset() { [ -f "$OFFSET_FILE" ] && cat "$OFFSET_FILE" 2>/dev/null || echo 0; }
save_offset() { printf '%s' "$1" > "$OFFSET_FILE" 2>/dev/null || true; }

# Skip past anything already sitting in the queue, so a stale "ok" can never
# approve a new request.
drain() {
  local resp last
  resp=$(curl -s --max-time 15 "${API}/getUpdates?offset=-1" 2>/dev/null || true)
  last=$(json_get "$resp" '.result[-1].update_id' "d['result'][-1]['update_id'] if d.get('result') else None")
  [ -n "$last" ] && save_offset $((last + 1))
}

# Wait up to $1 seconds for a message from the configured chat; echo its text.
wait_for_message() {
  local deadline=$(( $(date +%s) + $1 )) resp text uid offset
  while [ "$(date +%s)" -lt "$deadline" ]; do
    offset=$(read_offset)
    resp=$(curl -s --max-time 30 \
      "${API}/getUpdates?offset=${offset}&timeout=20&allowed_updates=%5B%22message%22%5D" 2>/dev/null || true)
    [ -z "$resp" ] && continue
    uid=$(json_get "$resp" "[.result[] | select(.message.chat.id == ${TELEGRAM_CHAT_ID})][-1].update_id" \
      "([u for u in d.get('result',[]) if str(((u.get('message') or {}).get('chat') or {}).get('id'))=='${TELEGRAM_CHAT_ID}'] or [{}])[-1].get('update_id')")
    if [ -n "$uid" ]; then
      text=$(json_get "$resp" "[.result[] | select(.message.chat.id == ${TELEGRAM_CHAT_ID})][-1].message.text" \
        "([u for u in d.get('result',[]) if str(((u.get('message') or {}).get('chat') or {}).get('id'))=='${TELEGRAM_CHAT_ID}'] or [{}])[-1].get('message',{}).get('text')")
      save_offset $((uid + 1))
      [ -n "$text" ] && { printf '%s' "$text"; return 0; }
    else
      # Advance past updates from other chats so they don't block the queue.
      uid=$(json_get "$resp" '.result[-1].update_id' "d['result'][-1]['update_id'] if d.get('result') else None")
      [ -n "$uid" ] && save_offset $((uid + 1))
    fi
  done
  return 1
}

case "$LANG_CODE" in
  az) T_ASK="🔐 Claude icazə istəyir"; T_REPLY="Cavab: ok / yox"; T_OK="✅ İcazə verildi"
      T_NO="🚫 İmtina edildi"; T_GOT="👌 Başa düşdüm, işə başlayıram:" ;;
  tr) T_ASK="🔐 Claude izin istiyor"; T_REPLY="Cevap: ok / hayır"; T_OK="✅ İzin verildi"
      T_NO="🚫 Reddedildi"; T_GOT="👌 Anlaşıldı, başlıyorum:" ;;
  ru) T_ASK="🔐 Claude просит разрешение"; T_REPLY="Ответ: ok / нет"; T_OK="✅ Разрешено"
      T_NO="🚫 Отклонено"; T_GOT="👌 Понял, приступаю:" ;;
  *)  T_ASK="🔐 Claude is asking for permission"; T_REPLY="Reply: ok / no"; T_OK="✅ Approved"
      T_NO="🚫 Denied"; T_GOT="👌 Got it, working on:" ;;
esac

case "$MODE" in

  permission)
    TOOL=$(json_get "$INPUT" '.tool_name' "d.get('tool_name')")
    CMD=$(json_get "$INPUT" '.tool_input.command // .tool_input.file_path // .tool_input.url' \
      "(d.get('tool_input') or {}).get('command') or (d.get('tool_input') or {}).get('file_path') or (d.get('tool_input') or {}).get('url')")
    CWD=$(json_get "$INPUT" '.cwd' "d.get('cwd')")
    [ -z "$CWD" ] && CWD="${CLAUDE_PROJECT_DIR:-$PWD}"

    drain
    send_msg "${T_ASK}

${TOOL}${CMD:+: $CMD}
$(basename "$CWD")

${T_REPLY}"

    ANSWER=$(wait_for_message "${NOTIFY_CONTROL_TIMEOUT:-120}")
    case "$(printf '%s' "$ANSWER" | tr '[:upper:]' '[:lower:]' | tr -d ' ')" in
      ok|okay|hə|he|bəli|beli|yes|y|allow|evet|да|давай)
        send_msg "$T_OK"
        printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","permissionDecision":"allow","permissionDecisionReason":"Approved from Telegram"}}'
        ;;
      yox|no|n|xeyr|hayır|hayir|deny|нет)
        send_msg "$T_NO"
        printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","permissionDecision":"deny","permissionDecisionReason":"Denied from Telegram"}}'
        ;;
      *)
        # No answer (or something else) — fall through to the normal prompt.
        ;;
    esac
    ;;

  stop)
    # Pick up an instruction typed in Telegram while Claude was working, or
    # within the wait window, and feed it back as the next thing to do.
    WAIT="${NOTIFY_CONTROL_WAIT:-60}"
    [ "$WAIT" -le 0 ] 2>/dev/null && exit 0
    MSG=$(wait_for_message "$WAIT")
    if [ -n "$MSG" ]; then
      send_msg "${T_GOT}
${MSG}"
      ESCAPED=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
      printf '{"decision":"block","reason":"The user sent a new instruction from Telegram: %s"}' "$ESCAPED"
    fi
    ;;

  *)
    ;;
esac

exit 0
