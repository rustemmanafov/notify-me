#!/usr/bin/env bash
#
# notify-me — interaktiv quraşdırma skripti
#
# Platformanı seçmənizi istəyir, lazımi token/açarları soruşur və
# onları shell konfiqurasiya faylınıza (~/.zshrc və ya ~/.bashrc)
# export sətirləri kimi əlavə edir.

set -u

echo "======================================"
echo "  notify-me quraşdırma"
echo "======================================"
echo ""

# Shell konfiqurasiya faylını avtomatik müəyyən et
detect_rc_file() {
  local shell_name
  shell_name=$(basename "${SHELL:-/bin/bash}")
  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash)
      # macOS-da login shell-lər çox vaxt .bash_profile oxuyur
      if [ "$(uname)" = "Darwin" ] && [ -f "$HOME/.bash_profile" ]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.bashrc"
      fi
      ;;
    *)    echo "$HOME/.profile" ;;
  esac
}

RC_FILE=$(detect_rc_file)
echo "Aşkarlanan shell konfiqurasiya faylı: $RC_FILE"
echo ""

echo "Hansı platformada bildiriş almaq istəyirsiniz?"
echo "  1) Telegram"
echo "  2) Discord"
echo "  3) Slack"
echo "  4) WhatsApp (CallMeBot)"
echo ""
printf "Seçiminiz (1-4): "
read -r CHOICE

EXPORTS=""

case "$CHOICE" in
  1)
    PLATFORM="telegram"
    echo ""
    echo "Telegram üçün bot token və chat ID lazımdır."
    echo "(Necə əldə edəcəyinizi README.md-də tapa bilərsiniz.)"
    printf "TELEGRAM_BOT_TOKEN: "
    read -r BOT_TOKEN
    printf "TELEGRAM_CHAT_ID: "
    read -r CHAT_ID
    EXPORTS="export TELEGRAM_BOT_TOKEN=\"$BOT_TOKEN\"
export TELEGRAM_CHAT_ID=\"$CHAT_ID\""
    ;;
  2)
    PLATFORM="discord"
    echo ""
    echo "Discord üçün webhook URL lazımdır."
    printf "DISCORD_WEBHOOK_URL: "
    read -r WEBHOOK
    EXPORTS="export DISCORD_WEBHOOK_URL=\"$WEBHOOK\""
    ;;
  3)
    PLATFORM="slack"
    echo ""
    echo "Slack üçün incoming webhook URL lazımdır."
    printf "SLACK_WEBHOOK_URL: "
    read -r WEBHOOK
    EXPORTS="export SLACK_WEBHOOK_URL=\"$WEBHOOK\""
    ;;
  4)
    PLATFORM="whatsapp"
    echo ""
    echo "WhatsApp (CallMeBot) üçün telefon nömrəsi və API key lazımdır."
    echo "(CallMeBot-a necə qoşulacağınızı README.md-də tapa bilərsiniz.)"
    printf "WHATSAPP_PHONE (məs. +994501234567): "
    read -r PHONE
    printf "WHATSAPP_APIKEY: "
    read -r APIKEY
    EXPORTS="export WHATSAPP_PHONE=\"$PHONE\"
export WHATSAPP_APIKEY=\"$APIKEY\""
    ;;
  *)
    echo ""
    echo "Yanlış seçim. Skripti yenidən işə salın."
    exit 1
    ;;
esac

echo ""
echo "Aşağıdakı sətirlər $RC_FILE faylına əlavə olunacaq:"
echo "--------------------------------------"
echo "export NOTIFY_PLATFORM=\"$PLATFORM\""
echo "$EXPORTS"
echo "--------------------------------------"
printf "Davam edilsin? (y/n): "
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Ləğv edildi. Heç bir dəyişiklik edilmədi."
  exit 0
fi

{
  echo ""
  echo "# notify-me plugin ($(date '+%Y-%m-%d %H:%M:%S'))"
  echo "export NOTIFY_PLATFORM=\"$PLATFORM\""
  echo "$EXPORTS"
} >> "$RC_FILE"

echo ""
echo "✅ Hazırdır! Dəyişikliklərin qüvvəyə minməsi üçün:"
echo "   source $RC_FILE"
echo "və ya yeni terminal pəncərəsi açın, sonra Claude Code-u yenidən başladın."
