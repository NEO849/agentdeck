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

# Optionale Config mit NTFY_URL/NTFY_TOPIC laden, falls nicht schon in der Umgebung gesetzt.
# Reihenfolge: $AGENTDECK_NTFY_ENV → ~/.config/agentdeck/ntfy.env
if [ -z "${NTFY_URL:-}${NTFY_TOPIC:-}" ]; then
  for f in "${AGENTDECK_NTFY_ENV:-}" "$HOME/.config/agentdeck/ntfy.env"; do
    if [ -n "$f" ] && [ -f "$f" ]; then set -a; . "$f"; set +a; break; fi
  done
fi

# Ziel bauen: Basis-URL + Topic (unterstützt NTFY_URL=Basis + NTFY_TOPIC, ODER komplette NTFY_URL)
if [ -n "${NTFY_TOPIC:-}" ]; then
  TARGET="${NTFY_URL:-https://ntfy.sh}/${NTFY_TOPIC}"
else
  TARGET="${NTFY_URL:-}"
fi
[ -z "$TARGET" ] && exit 0                        # nicht konfiguriert → still nichts tun
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
  "$TARGET" >/dev/null 2>&1 || true

exit 0
