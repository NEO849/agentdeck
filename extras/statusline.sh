#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · Statusline für Claude Code
# Zeigt EINE Zeile: Modell · Verzeichnis · Git-Branch · Kontext-% · Kosten.
#
# Claude Code reicht ein JSON-Objekt auf stdin. Feldpfade laut offizieller Doku
# (code.claude.com/docs/en/statusline). GRUNDPRINZIP: fehlt ein Feld (ältere/
# neuere CC-Version), wird das Segment still weggelassen — nie falsche Zahlen,
# nie Absturz. Der Kontext-Balken kommt aus echten Daten (used_percentage) oder
# gar nicht — kein gefakter Fortschritt.
#
# Voraussetzung: jq. Einbau: siehe extras/ in der README (mit Backup!).
# ─────────────────────────────────────────────────────────────────────────────
set -u

input="$(cat 2>/dev/null)"

# jq fehlt → minimaler, ehrlicher Fallback
if ! command -v jq >/dev/null 2>&1; then
  printf 'agentdeck (jq fehlt — bitte installieren)'
  exit 0
fi

# Felder defensiv lesen (// empty = weglassen, wenn nicht vorhanden)
model="$(printf '%s' "$input"   | jq -r '.model.display_name // empty' 2>/dev/null)"
cwd="$(printf '%s' "$input"     | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)"
cost="$(printf '%s' "$input"    | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)"
ctx="$(printf '%s' "$input"     | jq -r '.context_window.used_percentage // empty' 2>/dev/null)"

# ── Farben (ANSI, dezent) ────────────────────────────────────────────────────
DIM=$'\033[2m'; RST=$'\033[0m'
BLUE=$'\033[38;5;111m'; GREEN=$'\033[38;5;114m'
AMBER=$'\033[38;5;221m'; RED=$'\033[38;5;167m'; MUTED=$'\033[38;5;245m'

seg=()

# Modell (gedämpft)
[ -n "$model" ] && seg+=("${DIM}${model}${RST}")

# Verzeichnis (~ gekürzt, blau)
if [ -n "$cwd" ]; then
  short="${cwd/#$HOME/\~}"
  [ ${#short} -gt 34 ] && short=".../${short##*/}"
  seg+=("${BLUE}${short}${RST}")
fi

# Git-Branch: robust direkt aus git (unabhängig vom JSON-Schema)
if [ -n "$cwd" ] && command -v git >/dev/null 2>&1; then
  br="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ -n "$br" ]; then
    short_br="${br%%-*}"                       # bis zum ersten '-' kürzen: feat/gallery-indexeddb-fetch → feat/gallery
    [ ${#short_br} -gt 22 ] && short_br="${short_br:0:21}…"
    seg+=("${GREEN}⎇ ${short_br}${RST}")
  fi
fi

# Kontext-Auslastung: echter Mini-Balken aus used_percentage, farbcodiert
if [ -n "$ctx" ]; then
  pct="${ctx%.*}"; [ -z "$pct" ] && pct=0
  filled=$(( pct / 10 )); [ "$filled" -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  bar="$(printf '%0.s█' $(seq 1 $filled 2>/dev/null))$(printf '%0.s░' $(seq 1 $empty 2>/dev/null))"
  if   [ "$pct" -ge 85 ]; then c="$RED"; elif [ "$pct" -ge 60 ]; then c="$AMBER"; else c="$MUTED"; fi
  seg+=("${c}${bar} ${pct}%${RST}")
fi

# Kosten (amber, 2 Nachkommastellen)
if [ -n "$cost" ]; then
  seg+=("$(printf '%s$%.2f%s' "$AMBER" "$cost" "$RST" 2>/dev/null)")
fi

# Mit " │ " verbinden
out=""; for s in "${seg[@]}"; do [ -n "$out" ] && out+="${MUTED} │ ${RST}"; out+="$s"; done
printf '%s' "$out"
