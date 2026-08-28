# 🔔 notify-me

A notification plugin for Claude Code. It sends you a message on your platform of choice when Claude Code **finishes a task** (Stop event) or **needs your input** (Notification event):

- 📨 **Telegram**
- 🎮 **Discord**
- 💬 **Slack**
- 📱 **WhatsApp** (via CallMeBot)

Kick off a long-running task, walk away from your computer, and stop watching the screen — you'll get a message on your phone when it's done.

## How it works

The plugin hooks into Claude Code's hook system:

| Event | When it fires | Message |
|---|---|---|
| `Stop` | When Claude finishes responding | ✅ Task finished (project name + time) |
| `Notification` | When Claude is waiting for permission/input | 🔔 Your input is needed (project name + time) |

The platform is selected via the `NOTIFY_PLATFORM` environment variable. If this variable is not set, the plugin **does nothing and produces no errors** — it is completely harmless when unconfigured.

## Installation

### 1. Add the marketplace

```
/plugin marketplace add rustemmanafov/notify-me
```

### 2. Install the plugin

```
/plugin install notify-me@notify-me-marketplace
```

### 3. Run the setup script

After installing the plugin, run in your terminal:

```bash
bash ~/.claude/plugins/marketplaces/notify-me-marketplace/scripts/setup.sh
```

The script will ask you to pick a platform and enter the required tokens/API keys, then automatically add them to your shell config file (`~/.zshrc` or `~/.bashrc` — it detects which shell you use).

Finally:

```bash
source ~/.zshrc
```

and restart Claude Code. Done! 🎉

> Note: the path to setup.sh may vary depending on how the plugin was installed. To find the exact path: `find ~/.claude/plugins -name setup.sh -path "*notify-me*"`

## How to get tokens / API keys

### 📨 Telegram

1. Message [@BotFather](https://t.me/BotFather) on Telegram and create a new bot with the `/newbot` command.
2. BotFather will give you a **bot token** (format: `123456789:ABCdef...`). This is your `TELEGRAM_BOT_TOKEN`.
3. Send any message to your new bot (you must message the bot before it can message you).
4. To find your **Chat ID**, open this in your browser:
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
   The `"chat":{"id":123456789}` value in the response is your `TELEGRAM_CHAT_ID`.
   (Alternative: message [@userinfobot](https://t.me/userinfobot) and it will show you your ID.)

### 🎮 Discord

1. In your Discord server, open the settings of the channel you want: **Edit Channel → Integrations → Webhooks**.
2. Click **New Webhook** and give it a name.
3. Copy the link with **Copy Webhook URL** — this is your `DISCORD_WEBHOOK_URL`.
   (Format: `https://discord.com/api/webhooks/...`)

### 💬 Slack

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and create a new app via **Create New App → From scratch**.
2. Open the **Incoming Webhooks** section in the left menu and enable it (**Activate Incoming Webhooks**).
3. Click **Add New Webhook to Workspace** and choose a channel.
4. Copy the generated **Webhook URL** — this is your `SLACK_WEBHOOK_URL`.
   (Format: `https://hooks.slack.com/services/...`)

### 📱 WhatsApp (CallMeBot)

CallMeBot is a simple free service that requires no registration:

1. Add this number to your phone contacts: **+34 644 84 71 89** (CallMeBot).
2. Send this message to that number on WhatsApp:
   ```
   I allow callmebot to send me messages
   ```
3. The bot will reply with an **API key** — this is your `WHATSAPP_APIKEY`.
4. `WHATSAPP_PHONE` is your own number in international format (e.g. `+994501234567`).

> For the latest instructions: [callmebot.com/blog/free-api-whatsapp-messages](https://www.callmebot.com/blog/free-api-whatsapp-messages/)

## Example environment values

If you prefer not to use the setup script, you can add these lines to your `~/.zshrc` (or `~/.bashrc`) yourself:

```bash
# --- notify-me ---
# Platform choice: telegram | discord | slack | whatsapp
export NOTIFY_PLATFORM="telegram"

# Telegram
export TELEGRAM_BOT_TOKEN="123456789:ABCdefGhIJKlmNoPQRstuVWxyz"
export TELEGRAM_CHAT_ID="987654321"

# Discord
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1234567890/abcdef..."

# Slack
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX"

# WhatsApp (CallMeBot)
export WHATSAPP_PHONE="+994501234567"
export WHATSAPP_APIKEY="123456"
```

You only need to fill in the values for the platform you chose.

## Testing

After setup, you can call the script manually to verify notifications work:

```bash
echo '{"hook_event_name":"Stop","cwd":"'$PWD'"}' | bash scripts/notify.sh
```

You should receive a "✅ Claude Code finished a task" message on your chosen platform.

## File structure

```
notify-me/
├── .claude-plugin/
│   ├── plugin.json        # Plugin manifest
│   └── marketplace.json   # Marketplace definition
├── hooks/
│   └── hooks.json         # Stop and Notification hooks
├── scripts/
│   ├── notify.sh          # Notification sender script
│   └── setup.sh           # Interactive setup script
└── README.md
```

## Security note

Tokens and API keys are stored only in your local shell config file and are never sent to any third party. Notification messages contain only the project folder name and a timestamp — no code or session content is ever sent.

## License

MIT
