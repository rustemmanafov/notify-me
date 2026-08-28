#!/usr/bin/env bash
#
# notify-me — Claude Code hook notification script
#
# Runs on Stop and Notification events and sends a message to the
# platform selected via the NOTIFY_PLATFORM environment variable.
#
# NOTIFY_STYLE: funny (default) | plain
# NOTIFY_LANG:  en (default) | az | tr | ru | zh | es | de | fr
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
# Casual, friendly tone in every language. 15 per event per language.
# ---------------------------------------------------------------------------

FUNNY_STOP_EN=(
  "😎 Done! Go tell everyone you did it yourself."
  "🍕 Done! Claude finished while you were 'testing' that pizza."
  "🎉 Task complete. Claude did the work, you take the credit."
  "🤖 Beep boop. Work's done. Praise the robot."
  "🏆 Claude finished and is now waiting for compliments."
  "🥷 Task silently eliminated. No witnesses."
  "🫡 Mission complete, commander!"
  "☕ Done before your coffee got cold. You're welcome."
  "🧘 Task finished. Claude is meditating until the next one."
  "🚀 Done! Claude already misses the next task."
  "💪 Done. You didn't even lift a finger. Respect."
  "😏 Finished. Even your boss would be impressed by this speed."
  "🎁 Delivery! One freshly completed task."
  "🛋️ You relaxed, Claude worked. It's done."
  "🔥 Nailed it! Turns out we make a great team."
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
  "📢 Hey! Your robot wants your attention."
  "🤙 Claude says: got a minute? Quick question."
  "😅 Claude is stuck and refuses to move without you."
  "🚪 That knocking? It's Claude. It has business with you."
  "☕ Claude took a break — you have time for a sip before it gets impatient."
  "🧠 Claude thought long and hard and decided to ask you."
)

FUNNY_STOP_AZ=(
  "😎 Bitdi! Get denən özüm elədim."
  "🍕 Hazırdı! Sən çay içənəcən Claude işi bitirdi."
  "🎉 İş bitdi. Zəhmət Claude-dan, şöhrət səndən."
  "🤖 Bip-bop. İş hazırdı. Robota bir sağol de."
  "🏆 Claude işi bitirdi, indi oturub tərif gözləyir."
  "🥷 Tapşırıq səssizcə həll olundu. Şahid yoxdu."
  "☕ Çayın soyumamış iş hazırdı. Buyur."
  "🧘 İş bitdi. Claude növbəti tapşırığacan meditasiyadadı."
  "🚀 Hazırdı! Claude artıq növbəti işçün darıxır."
  "💪 İş bitdi. Sən heç əlini də tərpətmədin, afərin."
  "😏 Bitdi getdi. Bu sürətə şef də mat qalar."
  "🎁 Al gəldi — təzəcə bitmiş bir tapşırıq."
  "🛋️ Sən uzanmışdın, Claude işləyirdi. İş hazırdı."
  "🔥 Bitirdik! Sən demə yaxşı komandayıq."
  "😤 Nooldu?! Heç nə, iş bitdi, sakit ol."
  "🧿 Maşallah Claude-a, göz dəyməsin — işi bitirdi."
  "🗣️ Abi! Abi! Bir bura bax e — iş bitdi ala! Mən demişdim axı, bu iş məndədi!"
  "👶 Gör inqi qaqan nə qayırıb — tapşırığı bitirib, indi də oturub çayını qarışdırır."
  "🕺 İş bitdi, qaqaş. Pulları ver, çıxaq. Mənim də başqa işim var."
  "⛏️ Claude qan-tər içində işləyib e… Heç olmasa bir çay qoy qabağına, ayıbdı."
  "🐫 Qamçıya ehtiyac olmadı — Claude özü dedi “ver işi, qaqa, mən həll edərəm”. Əhsən!"
  "🧑‍🔧 Usta, iş hazırdı. Bir yoxla… işləyirsə pulunu ver, işləmirsə də mənlik deyil."
  "🧓 Ay bala, işini bitirdim. İndi məni çox saxlama, aşağıda başqa layihə gözləyir."
  "🫡 Əmr yerinə yetirildi, komandir. Kod hazırdır."
  "🚬 İş bitdi. Mən bir siqaret çəkib gəlirəm. Sonra baxarıq nə xarab eləmişik."
  "💀 Claude dedi: “Narahat olma, mən baxaram.” 3 saat sonra: “Abi… iş bitdi.”"
  "🥹 Nəhayət… Bu gün də bir developerin üzünü güldürdük."
  "🧎 Abi vallah əlimdən gələni elədim… Kod da işləyir. Daha məndən nə istəyirsən?!"
  "🧠 Claude beyni yandırdı, RAM-ı ağlatdı, amma axırda kodu birtəhər çıxartdı."
  "🫡 Hazırdır, rəis. Git-ə push elə, məni də burax."
  "💸 İş bitdi qaqaş. İndi zəhmət haqqımı hesabla, sonra “bir balaca düzəliş var” demə."
  "🐐 Claude işini gördü, qaqa. Qalanını artıq tarixçilər araşdıracaq."
)
FUNNY_NOTIF_AZ=(
  "🚨 Adam lazımdı! Claude deyir (yəqin ki) heç nə xarab olmayıb."
  "🖐️ Claude-a böyük adam lazımdı. O böyük adam sənsən."
  "⏳ Claude gözləyir... özü də heç gözünü qırpmır."
  "🙏 Bir klik elə, Claude-un könlü açılsın."
  "🔔 Ding-dong. Claude-du. Sualları var."
  "👀 Claude nəsə maraqlı şey tapıb. Gəl bax, özbaşına iş görməsin."
  "🆘 Claude icazə gözləyir. Böyük güc böyük klik istəyir."
  "🧍 Claude qapıda sualla dayanıb, gözləyir."
  "🎮 Növbə səndədi. Claude pultu sənə ötürdü."
  "📢 Ayə, bir bura bax! Robotun səni istəyir."
  "🤙 Claude deyir: bir dəqiqəlik gəl, iki kəlmə sözüm var."
  "😅 Claude ilişib qalıb, sənsiz tərpənmir."
  "🚪 Qapını döyən Claude-du. Aç, işi var."
  "☕ Claude fasilə verdi — sən gələnəcən çayını içə bilərsən."
  "🧠 Claude düşünüb-düşünüb axırda səndən soruşmaq qərarına gəlib."
  "🗣️ Abi! Abi! Bir dəqiqə bura gəl, vacib sözüm var!"
  "👶 İnqi qaqan səni gözləyir, gör nağaracağ..."
  "😩 Ayə hardasan? Claude burda tək qalıb."
  "🧿 Ay qaqaş, bir icazə ver, Claude işini görsün də."
  "📞 Alo, alo? Claude-du, bir sualı var."
  "🪢 Qamçıya ehtiyac yoxdu — Claude işləmək istəyir, sadəcə icazə gözləyir."
  "⛓️ Claude deyir: işləməyə hazıram, bircə sən 'hə' de."
)

FUNNY_STOP_TR=(
  "😎 Bitti! Git 'ben yaptım' de, kimse anlamaz."
  "🍕 Bitti! Sen çayını yudumlarken Claude işi bitirdi."
  "🎉 Görev tamam. Emek Claude'un, övgü senin."
  "🤖 Bip bop. İş hazır. Robota bir teşekkür et."
  "🏆 Claude işi bitirdi, şimdi oturmuş iltifat bekliyor."
  "🥷 Görev sessizce halledildi. Tanık yok."
  "🫡 Komutanım, emir yerine getirildi!"
  "☕ Kahven soğumadan iş bitti. Rica ederim."
  "🧘 İş bitti. Claude bir sonraki göreve kadar meditasyonda."
  "🚀 Hazır! Claude yeni görevi özlemeye başladı bile."
  "💪 Bitti. Parmağını bile kıpırdatmadın, helal olsun."
  "😏 Bitti gitti. Bu hıza patron bile şaşırır."
  "🎁 Teslimat! Taze bitmiş bir görev."
  "🛋️ Sen uzandın, Claude çalıştı. İş hazır."
  "🔥 Bitirdik! Meğer iyi bir ekipmişiz."
)
FUNNY_NOTIF_TR=(
  "🚨 İnsan lazım! Claude (muhtemelen) hiçbir şeyin bozulmadığına söz veriyor."
  "🖐️ Claude'un bir yetişkine ihtiyacı var. O yetişkin sensin."
  "⏳ Claude bekliyor... ve asla göz kırpmıyor."
  "🙏 Bir tık at, Claude'un gönlü olsun."
  "🔔 Ding dong. Claude geldi. Soruları var."
  "👀 Claude ilginç bir şey buldu. Kendi başına iş yapmadan gel bak."
  "🆘 Claude izin bekliyor. Büyük güç, büyük tık gerektirir."
  "🧍 Claude kapıda bir soruyla bekliyor."
  "🎮 Sıra sende. Claude kumandayı sana verdi."
  "📢 Baksana! Robotun seni istiyor."
  "🤙 Claude diyor ki: bir dakikan var mı? Ufak bir soru."
  "😅 Claude takıldı kaldı, sensiz kımıldamıyor."
  "🚪 Kapıyı çalan Claude. Seninle işi var."
  "☕ Claude mola verdi — sen gelene kadar çayını içebilirsin."
  "🧠 Claude düşündü taşındı, sonunda sana sormaya karar verdi."
)

FUNNY_STOP_RU=(
  "😎 Готово! Иди скажи всем, что сам сделал."
  "🍕 Готово! Пока ты пил чай, Claude всё доделал."
  "🎉 Задача выполнена. Работал Claude, лавры твои."
  "🤖 Бип-боп. Работа готова. Похвали робота."
  "🏆 Claude закончил и сидит ждёт комплиментов."
  "🥷 Задача тихо устранена. Свидетелей нет."
  "🫡 Командир, приказ выполнен!"
  "☕ Готово, пока кофе не остыл. Пожалуйста."
  "🧘 Всё готово. Claude медитирует до следующей задачи."
  "🚀 Готово! Claude уже скучает по следующей задаче."
  "💪 Готово. Ты даже пальцем не пошевелил. Уважение."
  "😏 Готово. Такой скорости позавидовал бы даже твой начальник."
  "🎁 Доставка! Одна свежевыполненная задача."
  "🛋️ Ты отдыхал, Claude работал. Всё готово."
  "🔥 Справились! Оказывается, мы отличная команда."
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
  "📢 Эй! Твой робот хочет внимания."
  "🤙 Claude спрашивает: есть минутка? Короткий вопрос."
  "😅 Claude застрял и без тебя не двигается."
  "🚪 Это стучит Claude. У него к тебе дело."
  "☕ Claude взял паузу — успеешь допить чай, пока он ждёт."
  "🧠 Claude долго думал и решил спросить у тебя."
)

FUNNY_STOP_ZH=(
  "😎 搞定了！去跟别人说是你自己干的吧。"
  "🍕 搞定！你还在摸鱼，Claude 已经把活干完了。"
  "🎉 任务完成。功劳归你，辛苦归 Claude。"
  "🤖 哔卟哔卟。工作完成，请表扬机器人。"
  "🏆 Claude 干完了，正坐着等夸奖。"
  "🥷 任务已悄悄解决。没有目击者。"
  "🫡 报告指挥官，任务完成！"
  "☕ 咖啡还没凉，活就干完了。不客气。"
  "🧘 任务完成。Claude 正在打坐，等待下一个任务。"
  "🚀 完成！Claude 已经开始想念下一个任务了。"
  "💪 搞定。你连手指都没动一下，佩服。"
  "😏 干完了。这速度连老板都得佩服。"
  "🎁 外卖到了！一份新鲜出炉的完成任务。"
  "🛋️ 你躺着，Claude 干活。任务完成了。"
  "🔥 搞定！原来我们是个好团队。"
)
FUNNY_NOTIF_ZH=(
  "🚨 需要人类支援！Claude 保证（大概）没搞坏什么。"
  "🖐️ Claude 需要一个大人。那个大人就是你。"
  "⏳ Claude 在等你……而且它从不眨眼。"
  "🙏 你点一下，Claude 就不闹脾气了。"
  "🔔 叮咚。是 Claude，它带着问题来了。"
  "👀 Claude 发现了有趣的东西。快来看看，别让它自作主张。"
  "🆘 Claude 在等你的批准。能力越大，点击越大。"
  "🧍 Claude 拿着问题站在门口。"
  "🎮 该你了，玩家一号。Claude 把手柄递给了你。"
  "📢 喂！你的机器人想找你。"
  "🤙 Claude 问：有一分钟吗？小问题。"
  "😅 Claude 卡住了，没有你它动不了。"
  "🚪 敲门的是 Claude。它找你有事。"
  "☕ Claude 暂停了——趁它等着，你可以喝口茶。"
  "🧠 Claude 想了又想，最后决定还是问你。"
)

FUNNY_STOP_ES=(
  "😎 ¡Listo! Ve y di que lo hiciste tú."
  "🍕 ¡Listo! Claude terminó mientras tú 'probabas' esa pizza."
  "🎉 Tarea completada. El trabajo fue de Claude, el mérito es tuyo."
  "🤖 Bip bop. Trabajo terminado. Elogia al robot."
  "🏆 Claude terminó y está sentado esperando cumplidos."
  "🥷 Tarea eliminada en silencio. Sin testigos."
  "🫡 ¡Misión cumplida, comandante!"
  "☕ Terminado antes de que se enfriara tu café. De nada."
  "🧘 Tarea terminada. Claude medita hasta la próxima."
  "🚀 ¡Listo! Claude ya extraña la siguiente tarea."
  "💪 Hecho. No moviste ni un dedo. Respeto."
  "😏 Terminado. Hasta tu jefe envidiaría esta velocidad."
  "🎁 ¡Entrega! Una tarea recién terminada."
  "🛋️ Tú descansabas, Claude trabajaba. Ya está listo."
  "🔥 ¡Lo logramos! Resulta que somos un gran equipo."
)
FUNNY_NOTIF_ES=(
  "🚨 ¡Se necesita un humano! Claude promete que (probablemente) nada está roto."
  "🖐️ Claude necesita un adulto. Ese adulto eres tú."
  "⏳ Claude está esperando... y nunca parpadea."
  "🙏 Un clic tuyo y Claude dejará de estar triste."
  "🔔 Ding dong. Es Claude. Trae preguntas."
  "👀 Claude encontró algo interesante. Ven antes de que actúe por su cuenta."
  "🆘 Claude espera tu permiso. Un gran poder conlleva un gran clic."
  "🧍 Claude está en la puerta con una pregunta."
  "🎮 Tu turno, jugador 1. Claude te pasó el control."
  "📢 ¡Oye! Tu robot quiere tu atención."
  "🤙 Claude pregunta: ¿tienes un minuto? Pregunta rápida."
  "😅 Claude se atascó y no se mueve sin ti."
  "🚪 El que toca la puerta es Claude. Tiene un asunto contigo."
  "☕ Claude hizo una pausa — te da tiempo de terminar tu café."
  "🧠 Claude lo pensó mucho y decidió preguntarte a ti."
)

FUNNY_STOP_DE=(
  "😎 Fertig! Geh ruhig sagen, dass du es selbst warst."
  "🍕 Fertig! Claude war schneller als deine Kaffeepause."
  "🎉 Aufgabe erledigt. Claude hat gearbeitet, du bekommst das Lob."
  "🤖 Piep bop. Arbeit erledigt. Lob den Roboter."
  "🏆 Claude ist fertig und sitzt da und wartet auf Komplimente."
  "🥷 Aufgabe lautlos erledigt. Keine Zeugen."
  "🫡 Mission erfüllt, Kommandant!"
  "☕ Fertig, bevor dein Kaffee kalt wurde. Gern geschehen."
  "🧘 Aufgabe erledigt. Claude meditiert bis zur nächsten."
  "🚀 Fertig! Claude vermisst die nächste Aufgabe jetzt schon."
  "💪 Fertig. Du hast keinen Finger gerührt. Respekt."
  "😏 Erledigt. Bei dem Tempo würde selbst dein Chef staunen."
  "🎁 Lieferung! Eine frisch erledigte Aufgabe."
  "🛋️ Du hast entspannt, Claude hat gearbeitet. Fertig."
  "🔥 Geschafft! Wir sind wohl doch ein gutes Team."
)
FUNNY_NOTIF_DE=(
  "🚨 Mensch benötigt! Claude verspricht: (wahrscheinlich) ist nichts kaputt."
  "🖐️ Claude braucht einen Erwachsenen. Der Erwachsene bist du."
  "⏳ Claude wartet... und es blinzelt nie."
  "🙏 Ein Klick von dir und Claude hört auf zu schmollen."
  "🔔 Ding dong. Claude ist da. Mit Fragen."
  "👀 Claude hat etwas Interessantes gefunden. Komm, bevor es eigenmächtig handelt."
  "🆘 Claude wartet auf deine Erlaubnis. Mit großer Macht kommt großes Klicken."
  "🧍 Claude steht mit einer Frage vor der Tür."
  "🎮 Du bist dran, Spieler 1. Claude hat dir den Controller gegeben."
  "📢 Hey! Dein Roboter will deine Aufmerksamkeit."
  "🤙 Claude fragt: Hast du kurz Zeit? Kleine Frage."
  "😅 Claude hängt fest und bewegt sich ohne dich nicht."
  "🚪 Es klopft — Claude ist da. Es hat ein Anliegen."
  "☕ Claude macht Pause — dein Kaffee schafft es noch, bevor es ungeduldig wird."
  "🧠 Claude hat lange nachgedacht und beschlossen, dich zu fragen."
)

FUNNY_STOP_FR=(
  "😎 Terminé ! Va dire que c'est toi qui l'as fait."
  "🍕 Terminé ! Claude a fini pendant que tu 'goûtais' cette pizza."
  "🎉 Tâche accomplie. Le travail pour Claude, le mérite pour toi."
  "🤖 Bip bop. Travail terminé. Félicite le robot."
  "🏆 Claude a terminé et attend des compliments."
  "🥷 Tâche éliminée en silence. Aucun témoin."
  "🫡 Mission accomplie, commandant !"
  "☕ Fini avant que ton café ne refroidisse. De rien."
  "🧘 Tâche terminée. Claude médite jusqu'à la prochaine."
  "🚀 Terminé ! La prochaine tâche manque déjà à Claude."
  "💪 Fini. Tu n'as pas levé le petit doigt. Respect."
  "😏 Terminé. Même ton chef serait jaloux de cette vitesse."
  "🎁 Livraison ! Une tâche fraîchement terminée."
  "🛋️ Tu te reposais, Claude travaillait. C'est fait."
  "🔥 On a réussi ! Finalement, on fait une super équipe."
)
FUNNY_NOTIF_FR=(
  "🚨 Humain requis ! Claude promet que (probablement) rien n'est cassé."
  "🖐️ Claude a besoin d'un adulte. Cet adulte, c'est toi."
  "⏳ Claude attend... et il ne cligne jamais des yeux."
  "🙏 Un clic de toi et Claude arrête de bouder."
  "🔔 Ding dong. C'est Claude. Il a des questions."
  "👀 Claude a trouvé quelque chose d'intéressant. Viens voir avant qu'il n'agisse seul."
  "🆘 Claude attend ta permission. Un grand pouvoir implique un grand clic."
  "🧍 Claude est à la porte avec une question."
  "🎮 À toi, joueur 1. Claude t'a passé la manette."
  "📢 Hé ! Ton robot veut ton attention."
  "🤙 Claude demande : t'as une minute ? Petite question."
  "😅 Claude est bloqué et refuse d'avancer sans toi."
  "🚪 On frappe à la porte — c'est Claude. Il a une affaire pour toi."
  "☕ Claude fait une pause — tu as le temps de finir ton café."
  "🧠 Claude a longuement réfléchi et a décidé de te demander."
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
  zh)
    STOP_HEADS=("${FUNNY_STOP_ZH[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_ZH[@]}")
    PLAIN_STOP="✅ Claude Code 完成了任务"
    PLAIN_NOTIF="🔔 Claude Code 正在等待你的输入"
    L_PROJECT="项目"; L_TIME="时间"; L_MESSAGE="消息"
    ;;
  es)
    STOP_HEADS=("${FUNNY_STOP_ES[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_ES[@]}")
    PLAIN_STOP="✅ Claude Code terminó una tarea"
    PLAIN_NOTIF="🔔 Claude Code espera tu respuesta"
    L_PROJECT="Proyecto"; L_TIME="Hora"; L_MESSAGE="Mensaje"
    ;;
  de)
    STOP_HEADS=("${FUNNY_STOP_DE[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_DE[@]}")
    PLAIN_STOP="✅ Claude Code hat eine Aufgabe erledigt"
    PLAIN_NOTIF="🔔 Claude Code wartet auf deine Eingabe"
    L_PROJECT="Projekt"; L_TIME="Zeit"; L_MESSAGE="Nachricht"
    ;;
  fr)
    STOP_HEADS=("${FUNNY_STOP_FR[@]}");  NOTIF_HEADS=("${FUNNY_NOTIF_FR[@]}")
    PLAIN_STOP="✅ Claude Code a terminé une tâche"
    PLAIN_NOTIF="🔔 Claude Code attend ta réponse"
    L_PROJECT="Projet"; L_TIME="Heure"; L_MESSAGE="Message"
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

      # Optional: send a random sticker after the text (Telegram only).
      # Two ways to configure, checked in this order:
      #   NOTIFY_STICKER_SET — a public sticker pack name (e.g. "hasbullahasbulla2");
      #                        works for everyone, no file_ids needed.
      #   NOTIFY_STICKERS    — comma-separated sticker file_ids obtained via
      #                        your own bot (see scripts/get-sticker-ids.sh).
      STICKER=""
      if [ -n "${NOTIFY_STICKER_SET:-}" ]; then
        SET_JSON=$(curl -s --max-time 10 \
          "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getStickerSet?name=${NOTIFY_STICKER_SET}" 2>/dev/null || true)
        if [ -n "$SET_JSON" ]; then
          if command -v jq >/dev/null 2>&1; then
            SET_IDS=$(printf '%s' "$SET_JSON" | jq -r '.result.stickers[]?.file_id' 2>/dev/null)
          elif command -v python3 >/dev/null 2>&1; then
            SET_IDS=$(printf '%s' "$SET_JSON" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    for s in d.get("result", {}).get("stickers", []):
        print(s["file_id"])
except Exception:
    pass
' 2>/dev/null)
          else
            SET_IDS=""
          fi
          if [ -n "$SET_IDS" ]; then
            STICKER=$(printf '%s\n' "$SET_IDS" | awk -v seed="$RANDOM" 'BEGIN{srand(seed)} {a[NR]=$0} END{if(NR>0) print a[int(rand()*NR)+1]}')
          fi
        fi
      elif [ -n "${NOTIFY_STICKERS:-}" ]; then
        IFS=',' read -r -a STICKER_ARR <<< "$NOTIFY_STICKERS"
        if [ "${#STICKER_ARR[@]}" -gt 0 ]; then
          STICKER=$(printf '%s' "${STICKER_ARR[$((RANDOM % ${#STICKER_ARR[@]}))]}" | tr -d ' ')
        fi
      fi
      if [ -n "$STICKER" ]; then
        curl -s --max-time 10 \
          -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendSticker" \
          --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
          --data-urlencode "sticker=${STICKER}" \
          >/dev/null 2>&1 || true
      fi
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
