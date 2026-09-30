#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · Installer für hiroppys tmux-agent-sidebar + Claude Code
#
# Prinzip: ADDITIV + RÜCKBAUBAR. Überschreibt nichts. Legt vor jeder Änderung an
# ~/.tmux.conf und ~/.claude/settings.json ein .bak-<zeitstempel> an. ~/.claude.json
# wird NIE angefasst. Kein `curl | bash`. Mehrfaches Ausführen ist sicher (idempotent).
#
# Nutzung:
#   ./install.sh                     # Sidebar + tmux-Config + die 14 Sidebar-Hooks
#   ./install.sh --with-statusline   # zusätzlich die agentdeck-Statusline (mit Backup)
#   ./install.sh --with-ntfy         # zusätzlich Remote-Push (Notification+Stop → ntfy)
#   Flags sind kombinierbar.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUG="$HOME/.tmux/plugins/tmux-agent-sidebar"
TMUXCONF="$HOME/.tmux.conf"
SETTINGS="$HOME/.claude/settings.json"
TS="$(date +%Y%m%d-%H%M%S)"
WITH_STATUSLINE=0; WITH_NTFY=0

for a in "$@"; do case "$a" in
  --with-statusline) WITH_STATUSLINE=1 ;;
  --with-ntfy)       WITH_NTFY=1 ;;
  -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "Unbekanntes Flag: $a" >&2; exit 2 ;;
esac; done

need() { command -v "$1" >/dev/null 2>&1 || { echo "FEHLT: $1 — bitte installieren." >&2; exit 1; }; }
need git; need tmux; need jq

echo "=== 1/4  Sidebar-Plugin ==="
if [ -d "$PLUG" ]; then
  echo "  $PLUG existiert bereits — überspringe Clone."
else
  git clone --depth 1 https://github.com/hiroppy/tmux-agent-sidebar "$PLUG"
fi
if [ ! -x "$PLUG/bin/tmux-agent-sidebar" ]; then
  if command -v cargo >/dev/null 2>&1; then
    echo "  Baue aus Quelle (cargo) — vertrauenswürdiger als Prebuilt…"
    cargo build --release --manifest-path "$PLUG/Cargo.toml"
    mkdir -p "$PLUG/bin"; cp "$PLUG/target/release/tmux-agent-sidebar" "$PLUG/bin/"
  else
    echo "  cargo nicht gefunden — das Plugin lädt beim ersten tmux-Load automatisch ein"
    echo "  Prebuilt-Binary via install-wizard.sh (hiroppy). Alternativ Rust installieren und erneut ausführen."
  fi
fi

echo "=== 2/4  tmux.conf (additiv) ==="
if grep -q "tmux-agent-sidebar.tmux" "$TMUXCONF" 2>/dev/null; then
  echo "  Sidebar-Zeile schon vorhanden — überspringe."
else
  [ -f "$TMUXCONF" ] && cp -a "$TMUXCONF" "$TMUXCONF.bak-$TS"
  printf '\n' >> "$TMUXCONF"
  cat "$SCRIPT_DIR/config/tmux.conf.snippet" >> "$TMUXCONF"
  echo "  angehängt (Backup: $TMUXCONF.bak-$TS)"
fi

echo "=== 3/4  Claude-Sidebar-Hooks mergen ==="
if [ ! -f "$SETTINGS" ]; then echo '{}' > "$SETTINGS"; fi
if grep -q "tmux-agent-sidebar/hook.sh" "$SETTINGS"; then
  echo "  Sidebar-Hooks schon vorhanden — überspringe."
else
  cp -a "$SETTINGS" "$SETTINGS.bak-$TS"
  TMP="$(mktemp)"
  jq -s --arg root "$PLUG" '
    .[0] as $cur | .[1] as $sid |
    ($sid.hooks | with_entries(.value |= (map(.hooks |= map(
        .command |= gsub("\\$\\{CLAUDE_PLUGIN_ROOT\\}"; $root)))))) as $add |
    $cur | .hooks = (($cur.hooks // {}) as $ch |
      reduce ($add | keys[]) as $k ($ch; .[$k] = (($ch[$k] // []) + $add[$k])))
  ' "$SETTINGS" "$SCRIPT_DIR/config/claude-hooks.snippet.json" > "$TMP"
  jq -e . "$TMP" >/dev/null && mv "$TMP" "$SETTINGS" \
    && echo "  gemergt (Backup: $SETTINGS.bak-$TS)" \
    || { echo "  FEHLER: ungültiges JSON — settings.json UNVERÄNDERT"; rm -f "$TMP"; exit 1; }
fi

if [ "$WITH_STATUSLINE" = 1 ]; then
  echo "=== +  Statusline ==="
  cp -a "$SETTINGS" "$SETTINGS.bak-statusline-$TS"
  cur_sl="$(jq -r '.statusLine.command // empty' "$SETTINGS")"
  [ -n "$cur_sl" ] && echo "  Hinweis: vorhandene Statusline gesichert ($cur_sl → Backup $SETTINGS.bak-statusline-$TS)"
  chmod +x "$SCRIPT_DIR/extras/statusline.sh"
  TMP="$(mktemp)"
  jq --arg cmd "$SCRIPT_DIR/extras/statusline.sh" \
     '.statusLine = {type:"command", command:$cmd, padding:0}' "$SETTINGS" > "$TMP"
  jq -e . "$TMP" >/dev/null && mv "$TMP" "$SETTINGS" && echo "  Statusline gesetzt." || { rm -f "$TMP"; exit 1; }
fi

if [ "$WITH_NTFY" = 1 ]; then
  echo "=== +  Remote-Notifications (ntfy) ==="
  chmod +x "$SCRIPT_DIR/extras/notify-ntfy.sh"
  cp -a "$SETTINGS" "$SETTINGS.bak-ntfy-$TS"
  TMP="$(mktemp)"
  jq --arg cmd "bash \"$SCRIPT_DIR/extras/notify-ntfy.sh\"" '
    def add($ev; $arg): .hooks[$ev] = ((.hooks[$ev] // []) +
      [{matcher:"", hooks:[{type:"command", command:($cmd + " " + $arg)}]}]);
    add("Notification";"notification") | add("Stop";"stop")
  ' "$SETTINGS" > "$TMP"
  jq -e . "$TMP" >/dev/null && mv "$TMP" "$SETTINGS" \
    && echo "  Hooks ergänzt. NTFY_TOPIC in ~/.bashrc setzen (siehe extras/NOTIFY_BACKENDS.md)." \
    || { rm -f "$TMP"; exit 1; }
fi

echo
echo "=== 4/4  Fertig ==="
echo "  Sidebar-Hooks aktiv: $(grep -o 'tmux-agent-sidebar/hook.sh' "$SETTINGS" | wc -l | tr -d ' ')"
echo
echo "NÄCHSTE SCHRITTE:"
echo "  1) tmux source $TMUXCONF"
echo "  2) Sidebar einblenden: prefix + e   (alle Fenster: prefix + E)"
echo "  3) NEUE Claude-Session starten (Hooks greifen erst für neue Sessions)."
echo
echo "Rückbau jederzeit:  $SCRIPT_DIR/uninstall.sh"
