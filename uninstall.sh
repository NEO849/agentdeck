#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · Rückbau
# Entfernt CHIRURGISCH nur, was install.sh hinzugefügt hat. Legt vor jeder
# Änderung ein .bak-<zeitstempel> an. ~/.claude.json wird nie berührt.
#   ./uninstall.sh          # fragt vor dem Löschen des Plugin-Ordners
#   ./uninstall.sh --yes    # ohne Rückfrage
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PLUG="$HOME/.tmux/plugins/tmux-agent-sidebar"
TMUXCONF="$HOME/.tmux.conf"
SETTINGS="$HOME/.claude/settings.json"
TS="$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_YES=0; [ "${1:-}" = "--yes" ] && ASSUME_YES=1
command -v jq >/dev/null 2>&1 || { echo "FEHLT: jq" >&2; exit 1; }

echo "=== 1/3  Claude-Hooks + Statusline entfernen ==="
if [ -f "$SETTINGS" ]; then
  cp -a "$SETTINGS" "$SETTINGS.bak-$TS"
  TMP="$(mktemp)"
  jq --arg sl "$SCRIPT_DIR/extras/statusline.sh" '
    # Sidebar- und agentdeck-Hook-Kommandos aus allen Event-Arrays werfen
    (.hooks // {}) |= (
      with_entries(
        .value |= ( map( .hooks |= map(select(
              (.command // "") | (contains("tmux-agent-sidebar/hook.sh")
                                   or contains("agentdeck")) | not )))
          | map(select((.hooks | length) > 0)) )
      ) | with_entries(select((.value | length) > 0))
    )
    # unsere Statusline nur zurücknehmen, wenn sie auf UNSER Script zeigt
    | if (.statusLine.command // "") == $sl then del(.statusLine) else . end
  ' "$SETTINGS" > "$TMP"
  jq -e . "$TMP" >/dev/null && mv "$TMP" "$SETTINGS" \
    && echo "  bereinigt (Backup: $SETTINGS.bak-$TS)" \
    || { echo "  FEHLER: settings.json unverändert"; rm -f "$TMP"; exit 1; }
  rest="$(jq -r '.statusLine.command // "—"' "$SETTINGS")"
  echo "  aktuelle Statusline: $rest"
else
  echo "  keine settings.json — übersprungen."
fi

echo "=== 2/3  tmux.conf-Block entfernen ==="
if [ -f "$TMUXCONF" ] && grep -q "tmux-agent-sidebar.tmux" "$TMUXCONF"; then
  cp -a "$TMUXCONF" "$TMUXCONF.bak-$TS"
  # vom agentdeck-Markerkommentar bis zur run-shell-Zeile (inkl.) löschen;
  # fällt der Marker, entferne mindestens die run-shell-Zeile selbst.
  awk '
    /agentdeck · tmux-agent-sidebar/ {skip=1}
    skip && /tmux-agent-sidebar\.tmux/ {skip=0; next}
    skip {next}
    /tmux-agent-sidebar\.tmux/ {next}
    {print}
  ' "$TMUXCONF" > "$TMUXCONF.tmp" && mv "$TMUXCONF.tmp" "$TMUXCONF"
  echo "  entfernt (Backup: $TMUXCONF.bak-$TS)"
else
  echo "  kein Sidebar-Block gefunden — übersprungen."
fi

echo "=== 3/3  Plugin-Ordner ==="
if [ -d "$PLUG" ]; then
  if [ "$ASSUME_YES" = 0 ]; then
    read -r -p "  $PLUG löschen? [y/N] " ans; [ "$ans" = y ] || [ "$ans" = Y ] || { echo "  behalten."; PLUG=""; }
  fi
  [ -n "$PLUG" ] && { rm -rf "$PLUG"; echo "  gelöscht."; }
else
  echo "  nicht vorhanden."
fi

echo
echo "Fertig. Zum Abschluss:  tmux source $TMUXCONF   (und neue Claude-Session starten)."
