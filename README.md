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

## Message styles

By default, every notification comes with a **random funny headline** — because getting pinged by a robot should be fun:

> 🍕 Claude finished. You may now return to your pizza.
> Project: my-app
> Time: 2026-08-28 16:45:12

> 🚨 Human input required. This is not a drill.
> Project: my-app
> Time: 2026-08-28 16:47:03

There are 20+ different headlines per event (34 for Azerbaijani), picked at random each time. If you prefer boring notifications, set:

```bash
export NOTIFY_STYLE="plain"
```

and you'll get the professional versions instead ("✅ Claude Code finished a task" / "🔔 Claude Code is waiting for your input"). The project name and timestamp are always included either way.

## Languages

Notifications are available in 8 languages, selected via `NOTIFY_LANG`:

| Value | Language | Example |
|---|---|---|
| `en` (default) | English | 😎 Done! Go tell everyone you did it yourself. |
| `az` | Azərbaycanca | 😎 Bitdi! Get denən özüm elədim. |
| `tr` | Türkçe | 😎 Bitti! Git 'ben yaptım' de, kimse anlamaz. |
| `ru` | Русский | 😎 Готово! Иди скажи всем, что сам сделал. |
| `zh` | 中文 | 😎 搞定了！去跟别人说是你自己干的吧。 |
| `es` | Español | 😎 ¡Listo! Ve y di que lo hiciste tú. |
| `de` | Deutsch | 😎 Fertig! Geh ruhig sagen, dass du es selbst warst. |
| `fr` | Français | 😎 Terminé ! Va dire que c'est toi qui l'as fait. |

```bash
export NOTIFY_LANG="az"
```

The labels (Project/Time) and plain-style headlines are translated too. Each language has its own set of 20+ casual, friendly headlines per event — not literal translations, but jokes that actually work in that language. The Azerbaijani set comes with bonus lines inspired by local viral memes. 🇦🇿

## Telegram stickers

On Telegram, every notification is followed by a **random Hasbulla sticker** — on by default, because this plugin is about having fun. 🐐 No setup needed: your bot fetches the public pack (`hasbullahasbulla2`) itself and sends a random sticker from it.

Don't want stickers? Turn them off:

```bash
export NOTIFY_STICKER_SET="off"
```

Want a different pack? Point at any public sticker pack by name:

```bash
export NOTIFY_STICKER_SET="your_favorite_pack"
```

To find a pack's name: open the sticker pack in Telegram, tap share/copy link — the link looks like `https://t.me/addstickers/<pack_name>`; use the `<pack_name>` part.

**Alternative: hand-picked stickers.** If you want specific stickers instead of a whole pack:

1. In Telegram, send (or forward) your favorite stickers to **your bot's chat**.
2. Run the helper script — it lists their `file_id`s:
   ```bash
   bash scripts/get-sticker-ids.sh
   ```
3. Add the ones you like to your shell config, comma-separated:
   ```bash
   export NOTIFY_STICKERS="CAACAgIAAxkBAAE...,CAACAgIAAxkBAAF..."
   ```

`NOTIFY_STICKER_SET` takes priority when both are set; leave both unset to disable stickers. Note: `file_id`s are bot-specific (the helper script handles that), while a pack name works for any bot. Stickers work on Telegram only.

## Two-way control from Telegram (optional)

Beyond notifications, the plugin can let you **drive Claude from your Telegram chat** — approve a permission request, or send the next instruction — without touching the computer. Useful when Claude Code runs under a different account than the one on your phone, so the built-in remote control is not an option.

Enable it (Telegram only):

```bash
export NOTIFY_CONTROL="1"
```

Then:

- **Approving actions.** When Claude asks for permission, you get a message like `🔐 Claude is asking for permission — Bash: git push`. Reply `ok` to allow or `no` to deny. Answers work in English, Azerbaijani, Turkish and Russian (`ok`, `hə`, `evet`, `да` / `no`, `yox`, `hayır`, `нет`). If you don't answer within `NOTIFY_CONTROL_TIMEOUT` seconds (default 120), the normal on-screen prompt takes over — nothing is auto-approved.
- **Sending instructions.** Anything you type in the chat while Claude is working — "commit and push", "run the tests" — becomes its next instruction as soon as the current response ends. By default (`NOTIFY_CONTROL_WAIT="0"`) this costs no waiting at all: Claude checks once for an already-waiting message and moves on. Raise it (e.g. `60`) when you step away and want Claude to pause at the end of each response and give you time to type; note that this then delays the end of *every* response by up to that many seconds.

```bash
# Optional tuning
export NOTIFY_CONTROL_TIMEOUT="120"   # seconds to wait for an approval reply
export NOTIFY_CONTROL_WAIT="0"        # extra seconds to wait for an instruction after each response
```

⚠️ **Security.** With this on, anyone who can post in your bot's chat can approve tool executions and send instructions to Claude on your machine. Only the chat ID in `TELEGRAM_CHAT_ID` is accepted, and stale messages are discarded before each approval request so an old "ok" can never approve a new action — but the bot token is the key to all of it. Keep it private, and leave `NOTIFY_CONTROL` off unless you want this.

⚠️ Each session polls the same bot, so running several sessions with control enabled at once means they compete for your replies. Use it in one session at a time.

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

The script will ask you to pick a platform and enter the required tokens/API keys, then write them to `~/.notify-me.env`.

Now restart Claude Code. Done! 🎉

The plugin reads that file directly, so this works the same whether you use the terminal, the desktop app or an IDE extension — see [Where settings live](#where-settings-live).

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

## Where settings live

The plugin reads its settings from two places, in this order:

1. **Environment variables** — anything already exported in the shell that started Claude Code.
2. **`~/.notify-me.env`** — a plain config file (this is what `setup.sh` writes).

The config file matters because the **desktop app and IDE extensions do not read `~/.zshrc`** — they never see variables exported there. Settings in `~/.notify-me.env` work everywhere: terminal, desktop app, IDE. Point `NOTIFY_ME_CONFIG` at another path to use a different file.

## Example environment values

These are the settings themselves. Put them in `~/.notify-me.env` (recommended — works everywhere) or export them from your `~/.zshrc` (terminal only):

```bash
# --- notify-me ---
# Platform choice: telegram | discord | slack | whatsapp
export NOTIFY_PLATFORM="telegram"

# Message style: funny (default) | plain
export NOTIFY_STYLE="funny"

# Message language: en (default) | az | tr | ru | zh | es | de | fr
export NOTIFY_LANG="en"

# Two-way Telegram control: 1 to enable (see "Two-way control" above)
export NOTIFY_CONTROL="0"

# Telegram stickers: a pack name, or "off" to disable
# (defaults to the Hasbulla pack when unset)
export NOTIFY_STICKER_SET="hasbullahasbulla2"

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

You should receive a notification with a random funny headline (or "✅ Claude Code finished a task" in plain mode) on your chosen platform.

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
