#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · Smart-Notifications → ntfy  (v2: Signal statt Lärm)
#
# Prinzip (SRE-Regel „jede Meldung muss handlungs-wert sein"):
#   • wartet auf dich  (Notification)   → IMMER pingen  · high/bell
#   • Fehler/Abbruch   (StopFailure)    → IMMER pingen  · urgent
#   • fertig           (Stop)           → NUR wenn Lauf lang (> LONGRUN) UND du
#                                          nicht aktiv dran warst (away) · low
#   • Routine-Stop beim Mitlesen        → STILL
#
# Hook-Events (je als eigener Hook in settings.json verdrahten, Arg = Event):
#   UserPromptSubmit → "turnstart"   (merkt sich Startzeit; pingt nicht)
#   Notification     → "notification"
#   Stop             → "stop"
#   StopFailure      → "stopfailure"
#
# Config (Werte nie ins Repo): NTFY_URL/NTFY_TOPIC via $AGENTDECK_NTFY_ENV oder
#   ~/.config/agentdeck/ntfy.env. Stellschrauben:
#     AGENTDECK_LONGRUN_SECS   ab wann ein Lauf "lang" ist (Default 120)
#     AGENTDECK_AWAY_IDLE_SECS ab wann du als "weg" giltst (Default 60; 0 = away-Check aus)
# Blockiert Claude Code nie: endet immer mit exit 0.
# ─────────────────────────────────────────────────────────────────────────────
set -u

# --- Config laden (falls Vars nicht schon gesetzt) ---------------------------
if [ -z "${NTFY_URL:-}${NTFY_TOPIC:-}" ]; then
  for f in "${AGENTDECK_NTFY_ENV:-}" "$HOME/.config/agentdeck/ntfy.env"; do
    if [ -n "$f" ] && [ -f "$f" ]; then set -a; . "$f"; set +a; break; fi
  done
fi
if [ -n "${NTFY_TOPIC:-}" ]; then TARGET="${NTFY_URL:-https://ntfy.sh}/${NTFY_TOPIC}"; else TARGET="${NTFY_URL:-}"; fi

event="${1:-}"
input="$(cat 2>/dev/null)"
jqf(){ command -v jq >/dev/null 2>&1 && printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }
[ -z "$event" ] && event="$(jqf '.hook_event_name')"

sid="$(jqf '.session_id')"; [ -z "$sid" ] && sid="default"
msg="$(jqf '.message')"
cwd="$(jqf '.cwd')"; [ -z "$cwd" ] && cwd="$(jqf '.workspace.current_dir')"
proj="${cwd##*/}"; [ -z "$proj" ] && proj="claude"

STATE="$HOME/.cache/agentdeck"; mkdir -p "$STATE" 2>/dev/null || true
startf="$STATE/turn-${sid//[^A-Za-z0-9_-]/_}.start"

# --- turnstart: nur Startzeit merken, nichts senden --------------------------
if [ "$event" = "turnstart" ] || [ "$event" = "UserPromptSubmit" ]; then
  date +%s > "$startf" 2>/dev/null || true
  exit 0
fi

# ab hier wird ggf. gesendet → ohne Ziel/curl raus
[ -z "$TARGET" ] && exit 0
command -v curl >/dev/null 2>&1 || exit 0
send(){ curl -fsS --max-time 6 -H "Title: $1" -H "Priority: $2" -H "Tags: $3" -d "$4" "$TARGET" >/dev/null 2>&1 || true; }

# away = du warst nicht aktiv dran. Heuristik über jüngste tmux-Client-Aktivität.
# Unklar/ohne tmux → als "weg" behandeln (lieber einmal pingen als verpassen).
is_away(){
  local idle_max="${AGENTDECK_AWAY_IDLE_SECS:-60}"
  [ "$idle_max" -le 0 ] 2>/dev/null && return 0        # away-Check deaktiviert
  command -v tmux >/dev/null 2>&1 || return 0
  local acts newest now idle
  acts="$(tmux list-clients -F '#{client_activity}' 2>/dev/null)"
  [ -z "$acts" ] && return 0                           # kein Client dran → weg
  newest="$(printf '%s\n' "$acts" | sort -n | tail -1)"
  now="$(date +%s)"; idle=$(( now - newest ))
  [ "$idle" -ge "$idle_max" ]                          # lange keine Aktivität → weg
}

case "$event" in
  notification|Notification)
    send "⏳ Claude wartet · ${proj}" high bell "${msg:-Eingabe oder Freigabe nötig}" ;;

  stopfailure|StopFailure)
    send "⛔ Claude abgebrochen · ${proj}" urgent rotating_light "${msg:-Lauf fehlgeschlagen/gestoppt}" ;;

  stop|Stop)
    start="$(cat "$startf" 2>/dev/null || true)"; rm -f "$startf" 2>/dev/null || true
    [ -z "$start" ] && exit 0
    now="$(date +%s)"; elapsed=$(( now - start ))
    [ "$elapsed" -lt "${AGENTDECK_LONGRUN_SECS:-120}" ] && exit 0   # kurzer Turn → still
    is_away || exit 0                                               # du warst präsent → still
    mins=$(( elapsed / 60 ))
    send "✅ Claude fertig · ${proj}" low white_check_mark "Langer Lauf (~${mins} min) fertig – du warst weg." ;;
esac
exit 0
