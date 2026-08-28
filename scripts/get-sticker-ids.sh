#!/usr/bin/env bash
#
# notify-me — helper: list sticker file_ids sent to your Telegram bot.
#
# Usage:
#   1. In Telegram, send (or forward) the stickers you want to YOUR bot's chat.
#   2. Run this script — it prints each sticker's file_id.
#   3. Add them to your shell config, comma-separated:
#        export NOTIFY_STICKERS="<file_id1>,<file_id2>,..."
#
# Note: file_ids are bot-specific. They must come from YOUR bot
# (this script uses TELEGRAM_BOT_TOKEN), not from someone else's.

set -u

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "Error: TELEGRAM_BOT_TOKEN is not set. Run setup.sh first or export it." >&2
  exit 1
fi

RESP=$(curl -s --max-time 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" || true)

if [ -z "$RESP" ]; then
  echo "Error: could not reach the Telegram API." >&2
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  IDS=$(printf '%s' "$RESP" | jq -r '.result[].message.sticker | select(. != null) | (.emoji // "🙂") + "  " + .file_id' | sort -u)
else
  IDS=$(printf '%s' "$RESP" | python3 -c '
import json, sys
data = json.load(sys.stdin)
seen = set()
for u in data.get("result", []):
    st = (u.get("message") or {}).get("sticker")
    if st and st["file_id"] not in seen:
        seen.add(st["file_id"])
        emoji = st.get("emoji") or ":)"
        print(emoji + "  " + st["file_id"])
')
fi

if [ -z "$IDS" ]; then
  echo "No stickers found. Send a few stickers to your bot's chat and run this again."
  echo "(Telegram only keeps recent updates — send them freshly before running.)"
  exit 0
fi

echo "Stickers recently sent to your bot:"
echo ""
echo "$IDS"
echo ""
echo "Add the ones you like to your shell config, e.g.:"
echo '  export NOTIFY_STICKERS="<file_id1>,<file_id2>"'
