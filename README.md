# 🔔 notify-me

Claude Code üçün bildiriş plugini. Claude Code **bir tapşırığı bitirəndə** (Stop event) və ya **sizin cavabınızı gözləyəndə** (Notification event) seçdiyiniz platformada sizə mesaj göndərir:

- 📨 **Telegram**
- 🎮 **Discord**
- 💬 **Slack**
- 📱 **WhatsApp** (CallMeBot vasitəsilə)

Uzun çəkən tapşırıqları başladıb kompüterdən uzaqlaşanda artıq ekranı izləməyə ehtiyac yoxdur — bitəndə telefonunuza mesaj gəlir.

## Necə işləyir

Plugin Claude Code-un hook sisteminə qoşulur:

| Event | Nə vaxt işə düşür | Mesaj |
|---|---|---|
| `Stop` | Claude cavabını tamamlayanda | ✅ Tapşırıq bitdi (layihə adı + vaxt) |
| `Notification` | Claude icazə/giriş gözləyəndə | 🔔 Cavabınız gözlənilir (layihə adı + vaxt) |

Platforma `NOTIFY_PLATFORM` environment variable-ı ilə seçilir. Bu variable təyin olunmayıbsa, plugin **heç nə etmir və heç bir xəta vermir** — yəni quraşdırılmamış vəziyyətdə tamamilə zərərsizdir.

## Quraşdırma

### 1. Marketplace-i əlavə edin

```
/plugin marketplace add rustemmanafov/notify-me
```

### 2. Plugini quraşdırın

```
/plugin install notify-me@notify-me-marketplace
```

### 3. Setup skriptini işə salın

Plugin quraşdırıldıqdan sonra terminalda:

```bash
bash ~/.claude/plugins/marketplaces/notify-me-marketplace/scripts/setup.sh
```

Skript sizdən platformanı seçməyi və lazımi token/açarları daxil etməyi istəyəcək, sonra onları avtomatik olaraq shell konfiqurasiya faylınıza (`~/.zshrc` və ya `~/.bashrc` — hansı shell işlətdiyinizi özü müəyyən edir) əlavə edəcək.

Sonda:

```bash
source ~/.zshrc
```

və Claude Code-u yenidən başladın. Hazırdır! 🎉

> Qeyd: setup.sh-in yolu quraşdırma üsulundan asılı olaraq dəyişə bilər. Dəqiq yolu tapmaq üçün: `find ~/.claude/plugins -name setup.sh -path "*notify-me*"`

## Token / API key-ləri necə əldə etmək olar

### 📨 Telegram

1. Telegram-da [@BotFather](https://t.me/BotFather)-ə yazın və `/newbot` əmri ilə yeni bot yaradın.
2. BotFather sizə **bot token** verəcək (formatı: `123456789:ABCdef...`). Bu, `TELEGRAM_BOT_TOKEN`-dir.
3. Yaratdığınız bota istənilən mesaj göndərin (bot sizə yazmazdan əvvəl siz ona yazmalısınız).
4. **Chat ID**-nizi öyrənmək üçün brauzerdə açın:
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
   Cavabdakı `"chat":{"id":123456789}` dəyəri sizin `TELEGRAM_CHAT_ID`-nizdir.
   (Alternativ: [@userinfobot](https://t.me/userinfobot)-a yazın, o sizə ID-nizi göstərəcək.)

### 🎮 Discord

1. Discord serverinizdə istədiyiniz kanalın parametrlərini açın: **Edit Channel → Integrations → Webhooks**.
2. **New Webhook** düyməsinə basın, ad verin.
3. **Copy Webhook URL** ilə linki kopyalayın — bu, `DISCORD_WEBHOOK_URL`-dir.
   (Formatı: `https://discord.com/api/webhooks/...`)

### 💬 Slack

1. [api.slack.com/apps](https://api.slack.com/apps) səhifəsində **Create New App → From scratch** ilə yeni app yaradın.
2. Sol menyudan **Incoming Webhooks** bölməsinə keçin və onu aktivləşdirin (**Activate Incoming Webhooks**).
3. **Add New Webhook to Workspace** düyməsinə basıb kanal seçin.
4. Yaranan **Webhook URL**-i kopyalayın — bu, `SLACK_WEBHOOK_URL`-dir.
   (Formatı: `https://hooks.slack.com/services/...`)

### 📱 WhatsApp (CallMeBot)

CallMeBot pulsuz və qeydiyyatsız işləyən sadə bir servisdir:

1. Telefonunuzda bu nömrəni kontaktlara əlavə edin: **+34 644 84 71 89** (CallMeBot).
2. Həmin nömrəyə WhatsApp-dan bu mesajı göndərin:
   ```
   I allow callmebot to send me messages
   ```
3. Bot sizə cavab olaraq **API key** göndərəcək — bu, `WHATSAPP_APIKEY`-dir.
4. `WHATSAPP_PHONE` — öz nömrənizdir, beynəlxalq formatda (məs. `+994501234567`).

> Ən son təlimat üçün: [callmebot.com/blog/free-api-whatsapp-messages](https://www.callmebot.com/blog/free-api-whatsapp-messages/)

## Nümunə environment dəyərləri

Setup skriptini istəməsəniz, bu sətirləri özünüz `~/.zshrc` (və ya `~/.bashrc`) faylına əlavə edə bilərsiniz:

```bash
# --- notify-me ---
# Platforma seçimi: telegram | discord | slack | whatsapp
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

Yalnız seçdiyiniz platformanın dəyərlərini doldurmaq kifayətdir.

## Test

Quraşdırmadan sonra bildirişin işlədiyini yoxlamaq üçün skripti əl ilə çağıra bilərsiniz:

```bash
echo '{"hook_event_name":"Stop","cwd":"'$PWD'"}' | bash scripts/notify.sh
```

Seçdiyiniz platformada "✅ Claude Code tapşırığı bitirdi" mesajı gəlməlidir.

## Fayl strukturu

```
notify-me/
├── .claude-plugin/
│   ├── plugin.json        # Plugin manifesti
│   └── marketplace.json   # Marketplace tərifi
├── hooks/
│   └── hooks.json         # Stop və Notification hook-ları
├── scripts/
│   ├── notify.sh          # Bildiriş göndərən skript
│   └── setup.sh           # İnteraktiv quraşdırma skripti
└── README.md
```

## Təhlükəsizlik qeydi

Token və API key-lər yalnız sizin lokal shell konfiqurasiya faylınızda saxlanılır və heç vaxt üçüncü tərəfə göndərilmir. Bildiriş mesajları yalnız layihə qovluğunun adını və vaxtı ehtiva edir — kod və ya sessiya məzmunu göndərilmir.

## Lisenziya

MIT
