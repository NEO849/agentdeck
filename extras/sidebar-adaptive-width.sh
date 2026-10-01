#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · adaptive Sidebar-Breite
# Setzt @sidebar_width je nach Bildschirmbreite des aktuellen tmux-Clients:
# schmaler Client (Handy) → breiter, breiter Client (Desktop) → normal.
# Gedacht als tmux-Hook auf client-attached / client-resized.
#
# Stellschrauben (per Env überschreibbar):
#   SIDEBAR_NARROW_COLS  Schwelle in Spalten, ab der ein Client als "Handy" gilt (Default 100)
#   SIDEBAR_WIDTH_PHONE  Breite auf schmalen Clients (Default 30%)
#   SIDEBAR_WIDTH_DESK   Breite auf breiten Clients  (Default 22%)
#
# Hinweis: Die Sidebar liest die Breite beim Öffnen/Toggle. Läuft sie schon,
# wird sie nach einer Breitenänderung erst beim nächsten Toggle (prefix+E) neu gezogen.
# ─────────────────────────────────────────────────────────────────────────────
set -u
command -v tmux >/dev/null 2>&1 || exit 0

THRESHOLD="${SIDEBAR_NARROW_COLS:-100}"
PHONE="${SIDEBAR_WIDTH_PHONE:-30%}"
DESK="${SIDEBAR_WIDTH_DESK:-22%}"

w="$(tmux display -p '#{client_width}' 2>/dev/null)"
case "$w" in ''|*[!0-9]*) exit 0 ;; esac    # keine gültige Zahl → nichts tun

if [ "$w" -le "$THRESHOLD" ]; then want="$PHONE"; else want="$DESK"; fi
cur="$(tmux show -gv @sidebar_width 2>/dev/null || true)"
[ "$cur" = "$want" ] && exit 0              # schon korrekt → keine unnötige Änderung
tmux set -g @sidebar_width "$want"
