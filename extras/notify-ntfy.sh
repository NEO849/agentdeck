#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · Remote-Notification-Hook → ntfy.sh
# Schickt einen Push aufs Handy, wenn Claude Code auf Eingabe wartet (Notification)
# oder eine Runde beendet (Stop). Löst das headless-VPS-Problem: dort feuern die
# Desktop-Notifications der Sidebar mangels notify-send/DBus nicht.
#
# EINRICHTUNG:
#   1) ntfy-App installieren (iOS/Android) und ein Topic abonnieren, z.B. "cc-mustermann-7f3a".
#   2) export NTFY_TOPIC="cc-mustermann-7f3a"   (in ~/.bashrc; selbst-gehostet: NTFY_URL setzen)
#   3) Diesen Hook für die Events Notification + Stop in settings.json registrieren
#      (siehe extras/NOTIFY_BACKENDS.md).
#
# SICHERHEIT: Das Topic ist ein Geheimnis (wer es kennt, liest/schreibt mit).
# Nur ausgehendes HTTPS, kein offener Port. Ohne Topic/URL tut der Hook NICHTS.
# Blockiert Claude Code nie: bricht immer mit exit 0 ab.
# ─────────────────────────────────────────────────────────────────────────────
set -u

NTFY_URL="${NTFY_URL:-${NTFY_TOPIC:+https://ntfy.sh/$NTFY_TOPIC}}"
[ -z "${NTFY_URL:-}" ] && exit 0                 # nicht konfiguriert → still nichts tun
command -v curl >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null)"
event="$1"                                        # von der Hook-Definition übergeben (notification|stop)
[ -z "${event:-}" ] && event="$(printf '%s' "$input" | { command -v jq >/dev/null 2>&1 && jq -r '.hook_event_name // empty' 2>/dev/null; })"

# Optionaler Kontext aus dem Hook-JSON
msg=""; cwd=""
if command -v jq >/dev/null 2>&1; then
  msg="$(printf '%s' "$input"  | jq -r '.message // empty' 2>/dev/null)"
  cwd="$(printf '%s' "$input"  | jq -r '.cwd // .workspace.current_dir // empty' 2>/dev/null)"
fi
proj="${cwd##*/}"; [ -z "$proj" ] && proj="claude"

case "$event" in
  notification|Notification)
    title="⏳ Claude wartet — ${proj}"
    body="${msg:-Eingabe oder Freigabe nötig}"
    prio="high"; tags="bell" ;;
  stop|Stop)
    title="✅ Claude fertig — ${proj}"
    body="${msg:-Runde abgeschlossen}"
    prio="default"; tags="white_check_mark" ;;
  *)
    title="Claude — ${proj}"
    body="${msg:-${event:-event}}"
    prio="default"; tags="robot" ;;
esac

curl -fsS --max-time 5 \
  -H "Title: ${title}" \
  -H "Priority: ${prio}" \
  -H "Tags: ${tags}" \
  -d "${body}" \
  "$NTFY_URL" >/dev/null 2>&1 || true

exit 0
