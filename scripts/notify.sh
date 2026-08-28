#!/usr/bin/env bash
#
# notify-me — Claude Code hook notification script
#
# Runs on Stop and Notification events and sends a message to the
# platform selected via the NOTIFY_PLATFORM environment variable.
#
# NOTIFY_STYLE: funny (default) | plain
# NOTIFY_LANG:  en (default) | az | tr | ru
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

STYLE="${NOTIFY_STYLE:-funny}"
LANG_CODE="${NOTIFY_LANG:-en}"

# ---------------------------------------------------------------------------
# Funny headlines — one is picked at random for each notification.
# ---------------------------------------------------------------------------

FUNNY_STOP_EN=(
  "🍕 Done! Claude finished while you were 'testing' that pizza."
  "🎉 Task complete. Claude did in minutes what you'd postpone till Friday."
  "🤖 Beep boop. Work's done. Praise the robot."
  "😴 Claude finished. You may now pretend you did it."
  "🏆 Done! Claude would like this mentioned in your next standup."
  "🥷 Task silently eliminated. No witnesses."
  "🫡 Mission complete, commander. Claude awaits new orders."
  "☕ Done before your coffee got cold. You're welcome."
  "🧘 Task finished. Claude is meditating until the next one."
  "🚀 Task complete. Claude accepts payment in GPU time."
)
FUNNY_NOTIF_EN=(
  "🚨 Human needed! Claude promises it's (probably) not broken."
  "🖐️ Claude needs an adult. You're the adult."
  "⏳ Claude is waiting... and it never blinks."
  "🙏 One click from you and Claude will stop sulking."
  "🔔 Ding dong. It's Claude. It brought questions."
  "👀 Claude found something interesting. Come look before it acts on its own."
  "🆘 Claude needs permission. With great power comes great clicking."
  "🧍 Claude is standing at the door with a question."
  "🎮 Player 1, your turn. Claude passed the controller."
  "📢 Attention human: your robot requires supervision."
)

FUNNY_STOP_AZ=(
  "🍕 Hazırdır! Sən çay içənə kimi Claude işi bitirdi."
  "🎉 Tapşırıq bitdi. Zəhmət Claude-un, kredit sənin."
  "🤖 Bip-bop. İş hazırdır. Robota bir təşəkkür düşür."
  "😎 Bitdi! Gedib deyə bilərsən ki, özün elədin."
  "🏆 Claude işi bitirdi və indi tərif gözləyir."
  "🥷 Tapşırıq səssizcə yox edildi. Şahid yoxdur."
  "🫡 Əmr yerinə yetirildi, komandir!"
  "☕ Çayın soyumamış iş bitdi. Buyur."
  "🧘 İş bitdi. Claude növbəti tapşırığa qədər meditasiyadadır."
  "🚀 Hazırdır! Claude növbəti tapşırıq üçün darıxır."
)
FUNNY_NOTIF_AZ=(
  "🚨 İnsan lazımdır! Claude söz verir ki, (yəqin) heç nə xarab olmayıb."
  "🖐️ Claude-a böyük adam lazımdır. O böyük adam sənsən."
  "⏳ Claude gözləyir... və o heç vaxt gözünü qırpmır."
  "🙏 Bir kliklə Claude-un könlünü ala bilərsən."
  "🔔 Ding-dong. Claude-dur. Sualları var."
  "👀 Claude maraqlı bir şey tapıb. Gəl bax, özbaşına iş görməsin."
  "🆘 Claude icazə gözləyir. Böyük güc böyük klik tələb edir."
  "🧍 Claude qapıda sualla dayanıb."
  "🎮 Növbə səndədir. Claude pultu sənə ötürdü."
  "📢 Diqqət! Robotunuz nəzarət tələb edir."
)

FUNNY_STOP_TR=(
  "🍕 Bitti! Sen çayını yudumlarken Claude işi bitirdi."
  "🎉 Görev tamamlandı. Emek Claude'un, övgü senin."
  "🤖 Bip bop. İş hazır. Robota bir teşekkür borçlusun."
  "😎 Bitti! Gidip 'ben yaptım' diyebilirsin."
  "🏆 Claude işi bitirdi, şimdi iltifat bekliyor."
  "🥷 Görev sessizce halledildi. Tanık yok."
  "🫡 Emir yerine getirildi, komutanım!"
  "☕ Kahven soğumadan iş bitti. Rica ederim."
  "🧘 İş bitti. Claude bir sonraki göreve kadar meditasyonda."
  "🚀 Hazır! Claude yeni görev için sabırsızlanıyor."
)
FUNNY_NOTIF_TR=(
  "🚨 İnsan lazım! Claude (muhtemelen) hiçbir şeyin bozulmadığına söz veriyor."
  "🖐️ Claude'un bir yetişkine ihtiyacı var. O yetişkin sensin."
  "⏳ Claude bekliyor... ve asla göz kırpmıyor."
  "🙏 Tek tıkla Claude'un gönlünü alabilirsin."
  "🔔 Ding dong. Claude geldi. Soruları var."
  "👀 Claude ilginç bir şey buldu. Kendi başına iş yapmadan gel bak."
  "🆘 Claude izin bekliyor. Büyük güç, büyük tık gerektirir."
  "🧍 Claude kapıda bir soruyla bekliyor."
  "🎮 Sıra sende. Claude kumandayı sana verdi."
  "📢 Dikkat! Robotunuz denetim istiyor."
)

FUNNY_STOP_RU=(
  "🍕 Готово! Пока ты пил чай, Claude всё доделал."
  "🎉 Задача выполнена. Работал Claude, лавры твои."
  "🤖 Бип-боп. Работа готова. Роботу полагается похвала."
  "😎 Готово! Можешь сказать, что сделал сам."
  "🏆 Claude закончил и ждёт комплиментов."
  "🥷 Задача тихо устранена. Свидетелей нет."
  "🫡 Приказ выполнен, командир!"
  "☕ Работа закончена, пока кофе не остыл. Пожалуйста."
  "🧘 Всё готово. Claude медитирует до следующей задачи."
  "🚀 Готово! Claude уже скучает по следующей задаче."
)
FUNNY_NOTIF_RU=(
  "🚨 Нужен человек! Claude обещает, что (наверное) ничего не сломано."
  "🖐️ Claude нужен взрослый. Этот взрослый — ты."
  "⏳ Claude ждёт... и он никогда не моргает."
  "🙏 Один клик — и Claude перестанет грустить."
  "🔔 Динь-дон. Это Claude. У него вопросы."
  "👀 Claude нашёл кое-что интересное. Зайди, пока он не начал действовать сам."
  "🆘 Claude ждёт разрешения. Большая сила требует большого клика."
  "🧍 Claude стоит у двери с вопросом."
  "🎮 Твой ход. Claude передал тебе геймпад."
  "📢 Внимание! Ваш робот требует присмотра."
)

# Language-specific labels and plain headlines
case "$LANG_CODE" in
  az)
    STOP_HEADS=("${FUNNY_STOP_AZ[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_AZ[@]}")
    PLAIN_STOP="✅ Claude Code tapşırığı bitirdi"
    PLAIN_NOTIF="🔔 Claude Code cavabınızı gözləyir"
    L_PROJECT="Layihə"; L_TIME="Vaxt"; L_MESSAGE="Mesaj"
    ;;
  tr)
    STOP_HEADS=("${FUNNY_STOP_TR[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_TR[@]}")
    PLAIN_STOP="✅ Claude Code görevi tamamladı"
    PLAIN_NOTIF="🔔 Claude Code girişinizi bekliyor"
    L_PROJECT="Proje"; L_TIME="Zaman"; L_MESSAGE="Mesaj"
    ;;
  ru)
    STOP_HEADS=("${FUNNY_STOP_RU[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_RU[@]}")
    PLAIN_STOP="✅ Claude Code завершил задачу"
    PLAIN_NOTIF="🔔 Claude Code ждёт вашего ответа"
    L_PROJECT="Проект"; L_TIME="Время"; L_MESSAGE="Сообщение"
    ;;
  *)
    STOP_HEADS=("${FUNNY_STOP_EN[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_EN[@]}")
    PLAIN_STOP="✅ Claude Code finished a task"
    PLAIN_NOTIF="🔔 Claude Code is waiting for your input"
    L_PROJECT="Project"; L_TIME="Time"; L_MESSAGE="Message"
    ;;
esac

# Build the message text based on the event
if [ "$EVENT" = "Notification" ]; then
  if [ "$STYLE" = "plain" ]; then
    HEADLINE="$PLAIN_NOTIF"
  else
    HEADLINE="${NOTIF_HEADS[$((RANDOM % ${#NOTIF_HEADS[@]}))]}"
  fi
  MESSAGE="${HEADLINE}
${L_PROJECT}: ${PROJECT}
${L_TIME}: ${TIMESTAMP}"
  if [ -n "$NOTIF_MSG" ]; then
    MESSAGE="${MESSAGE}
${L_MESSAGE}: ${NOTIF_MSG}"
  fi
else
  if [ "$STYLE" = "plain" ]; then
    HEADLINE="$PLAIN_STOP"
  else
    HEADLINE="${STOP_HEADS[$((RANDOM % ${#STOP_HEADS[@]}))]}"
  fi
  MESSAGE="${HEADLINE}
${L_PROJECT}: ${PROJECT}
${L_TIME}: ${TIMESTAMP}"
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
