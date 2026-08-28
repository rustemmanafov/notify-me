#!/usr/bin/env bash
#
# notify-me — interactive setup script
#
# Asks you to pick a platform, prompts for the required tokens/keys,
# and appends them as export lines to your shell config file
# (~/.zshrc or ~/.bashrc).

set -u

echo "======================================"
echo "  notify-me setup"
echo "======================================"
echo ""

# Detect the shell config file automatically
detect_rc_file() {
  local shell_name
  shell_name=$(basename "${SHELL:-/bin/bash}")
  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash)
      # On macOS, login shells usually read .bash_profile
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
echo "Detected shell config file: $RC_FILE"
echo ""

echo "Which platform do you want to receive notifications on?"
echo "  1) Telegram"
echo "  2) Discord"
echo "  3) Slack"
echo "  4) WhatsApp (CallMeBot)"
echo ""
printf "Your choice (1-4): "
read -r CHOICE

EXPORTS=""

case "$CHOICE" in
  1)
    PLATFORM="telegram"
    echo ""
    echo "Telegram requires a bot token and a chat ID."
    echo "(See README.md for how to get them.)"
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
    echo "Discord requires a webhook URL."
    printf "DISCORD_WEBHOOK_URL: "
    read -r WEBHOOK
    EXPORTS="export DISCORD_WEBHOOK_URL=\"$WEBHOOK\""
    ;;
  3)
    PLATFORM="slack"
    echo ""
    echo "Slack requires an incoming webhook URL."
    printf "SLACK_WEBHOOK_URL: "
    read -r WEBHOOK
    EXPORTS="export SLACK_WEBHOOK_URL=\"$WEBHOOK\""
    ;;
  4)
    PLATFORM="whatsapp"
    echo ""
    echo "WhatsApp (CallMeBot) requires a phone number and an API key."
    echo "(See README.md for how to connect to CallMeBot.)"
    printf "WHATSAPP_PHONE (e.g. +994501234567): "
    read -r PHONE
    printf "WHATSAPP_APIKEY: "
    read -r APIKEY
    EXPORTS="export WHATSAPP_PHONE=\"$PHONE\"
export WHATSAPP_APIKEY=\"$APIKEY\""
    ;;
  *)
    echo ""
    echo "Invalid choice. Please run the script again."
    exit 1
    ;;
esac

echo ""
echo "The following lines will be appended to $RC_FILE:"
echo "--------------------------------------"
echo "export NOTIFY_PLATFORM=\"$PLATFORM\""
echo "$EXPORTS"
echo "--------------------------------------"
printf "Continue? (y/n): "
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Cancelled. No changes were made."
  exit 0
fi

{
  echo ""
  echo "# notify-me plugin ($(date '+%Y-%m-%d %H:%M:%S'))"
  echo "export NOTIFY_PLATFORM=\"$PLATFORM\""
  echo "$EXPORTS"
} >> "$RC_FILE"

echo ""
echo "✅ Done! For the changes to take effect, run:"
echo "   source $RC_FILE"
echo "or open a new terminal window, then restart Claude Code."
