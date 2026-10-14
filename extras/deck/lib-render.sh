#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · deck · Renderschicht (REIN: Zeilen stdin → Frame stdout).
# Keine tmux-Aufrufe, keine Datei-Reads. Feld-Trenner '|' (wie collect).
# Enterprise/No-Emoji: geometrische Glyphen (■ ▲ ● ○) + dezente ANSI-Farbe.
# Ehrt NO_COLOR und Nicht-TTY → reiner Text ohne Escape-Sequenzen.
# Glyph/Farbe = Funktion, nicht Deko: Status auf einen Blick.
# ─────────────────────────────────────────────────────────────────────────────
set -u

render_frame() {
  local D='|'

  # --- Breite ---
  local cols="${COLUMNS:-}"
  [ -z "$cols" ] && cols="$( (tput cols) 2>/dev/null || echo 40 )"
  case "$cols" in ''|*[!0-9]*) cols=40 ;; esac

  # --- Farben (additiv; aus bei NO_COLOR / Nicht-TTY) ---
  local R BOLD DIM A G M AM RD
  if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
    R=''; BOLD=''; DIM=''; A=''; G=''; M=''; AM=''; RD=''
  else
    R=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
    A=$'\033[38;5;111m'       # Akzent (Blau)  — Header/Session
    G=$'\033[38;5;114m'       # läuft  (Grün)
    M=$'\033[38;5;245m'       # idle/muted
    AM=$'\033[38;5;221m'      # wartet (Amber) — Handlungsbedarf
    RD=$'\033[38;5;167m'      # Fehler (Rot)
  fi

  # --- alles einlesen (winzig) ---
  local ROWS=(); mapfile -t ROWS
  local hdr_n=0 hdr_c=0 hdr_a=0 notmux=0 r
  for r in "${ROWS[@]:-}"; do
    case "$r" in
      '#NOTMUX'*) notmux=1 ;;
      '#HDR'*)    IFS=$D read -r _ hdr_n hdr_c hdr_a <<< "$r" ;;
    esac
  done
  if [ "$notmux" = 1 ]; then
    printf ' %sagentdeck%s  kein tmux-Server erreichbar\n' "$DIM" "$R"; return 0
  fi

  # --- Separator + Header ---
  local w=$(( cols < 62 ? cols : 62 )); [ "$w" -lt 20 ] && w=20
  local sep; sep="$(printf '%*s' "$w" '' | tr ' ' '-')"
  local now; now="$(date +%H:%M)"
  local actcol="$M"; [ "${hdr_a:-0}" -gt 0 ] && actcol="$AM$BOLD"
  printf ' %sagentdeck%s   %s Sessions   %s%sx Claude%s   %s%s braucht Aktion%s   %s%s%s\n' \
    "$BOLD$A" "$R" "$hdr_n" "$BOLD" "$hdr_c" "$R" "$actcol" "$hdr_a" "$R" "$DIM" "$now" "$R"
  printf '%s%s%s\n' "$DIM" "$sep" "$R"

  # --- Zeilen ---
  local idx=0 noclaude="" bg=""
  local rt session attached state model agent cause cwd _t
  for r in "${ROWS[@]:-}"; do
    case "$r" in '#'*) continue ;; '') continue ;; esac
    IFS=$D read -r rt session attached state model agent cause cwd _t <<< "$r"
    case "$rt" in
      C)
        idx=$(( idx + 1 ))
        local glyph col label amark sub info shortcwd
        case "$state" in
          error)   glyph='■'; col="$RD"; label='FEHLER' ;;
          action)  glyph='▲'; col="$AM"; label='WARTET' ;;
          running) glyph='●'; col="$G";  label='aktiv'  ;;
          *)       glyph='○'; col="$M";  label='idle'   ;;
        esac
        amark=''; [ "$attached" = "1" ] && amark='*'
        [ ${#session} -gt 18 ] && session="${session:0:18}"
        printf ' %s[%d]%s %s%s%s %s%-19s%s %s%-9s%s %s%-6s%s\n' \
          "$DIM" "$idx" "$R" "$col" "$glyph" "$R" \
          "$A$BOLD" "$session$amark" "$R" "$DIM" "$model" "$R" "$col$BOLD" "$label" "$R"
        sub="Agent: ${agent:--}"
        shortcwd="${cwd/#$HOME/~}"
        [ ${#shortcwd} -gt 30 ] && shortcwd="…${shortcwd: -29}"
        info="$shortcwd"; [ -n "$cause" ] && info="$cause"
        [ -n "$info" ] && info="   $info"
        printf '     %s%s%s%s%s%s\n' "$M" "$sub" "$R" "$DIM" "$info" "$R"
        ;;
      N) noclaude+="  $session" ;;
      B) bg+="  $session" ;;
    esac
  done

  printf '%s%s%s\n' "$DIM" "$sep" "$R"
  [ -n "$noclaude" ] && printf ' %s%s   (kein Claude)%s\n' "$DIM" "$noclaude" "$R"
  [ -n "$bg" ]       && printf ' %s(bg)%s%s\n' "$DIM" "$bg" "$R"
  return 0
}
