# Remote-Notifications — Backends

Ziel: ein Signal aufs Handy, wenn Claude Code **auf Eingabe wartet** (`Notification`) oder eine
**Runde beendet** (`Stop`). Auf einem headless-VPS ist das der einzige zuverlässige Weg — die
Desktop-Notifications der Sidebar nutzen auf Linux `notify-send`; fehlt der Daemon (typisch bei
reinem SSH), schalten sie sich **still ab**.

Alle drei Backends nutzen dieselbe Hook-Logik (`extras/notify-ntfy.sh` als Vorlage), nur ein anderer
Kanal. **ntfy ist der Default** (kostenlos, kein Account nötig).

---

## Hook registrieren (`~/.claude/settings.json`)

Zwei Events genügen. `<AGENTDECK>` durch den absoluten Pfad zu diesem Repo ersetzen:

```json
{
  "hooks": {
    "Notification": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash \"<AGENTDECK>/extras/notify-ntfy.sh\" notification" } ] } ],
    "Stop": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash \"<AGENTDECK>/extras/notify-ntfy.sh\" stop" } ] } ]
  }
}
```

> Läuft die hiroppy-Sidebar schon, hängst du diese zwei Einträge **zusätzlich** in die bestehenden
> `Notification`/`Stop`-Arrays — nicht ersetzen. `install.sh --with-ntfy` macht das additiv + mit Backup.

---

## 1. ntfy.sh (Default)

```bash
# 1) ntfy-App (iOS/Android) installieren, Topic abonnieren (frei wählbar, aber RATEN-sicher)
# 2) in ~/.bashrc:
export NTFY_TOPIC="cc-<name>-<zufall>"        # z.B. cc-michi-7f3a9c  (gilt als Geheimnis!)
# selbst-gehostet stattdessen:
# export NTFY_URL="https://ntfy.deine-domain.tld/cc-topic"
```

- ✅ kostenlos, kein Account · nur ausgehendes HTTPS · self-host möglich.
- ⚠️ Das Topic ist ein Passwort-Äquivalent: Wer es kennt, sieht deine Notifications. Nicht committen.

## 2. Pushover (sehr zuverlässig)

Einmalig ~5 $/Plattform. `notify-ntfy.sh` als Vorlage nehmen und den `curl`-Block ersetzen:

```bash
curl -fsS --max-time 5 \
  --form-string "token=$PUSHOVER_APP_TOKEN" \
  --form-string "user=$PUSHOVER_USER_KEY" \
  --form-string "title=$title" \
  --form-string "message=$body" \
  https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true
```

## 3. Telegram-Bot (kostenlos)

Bot via @BotFather anlegen, `chat_id` ermitteln. `curl`-Block:

```bash
curl -fsS --max-time 5 \
  --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" \
  --data-urlencode "text=$title — $body" \
  "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" >/dev/null 2>&1 || true
```

---

**Tokens/Keys** gehören in `~/.bashrc` oder einen Secret-Store, **nie ins Repo**. Der Hook ist so
gebaut, dass er ohne gesetzte Variablen einfach nichts tut (kein Fehler, blockiert Claude Code nie).
