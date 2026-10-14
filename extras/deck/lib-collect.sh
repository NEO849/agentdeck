#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · deck · Datenschicht (REIN: liest nur, mutiert nichts).
#
# collect_rows gibt den Deck-Zustand als '|'-getrennte Zeilen auf stdout.
# Trenner ist '|' — bewusst NICHT Tab/Space: bash `read` mit Whitespace-IFS
# verschmilzt aufeinanderfolgende Trenner (häufig, da viele @pane_* leer sind)
# und würde Folgefelder verschieben. '|' ist nicht-Whitespace → Leerfelder bleiben
# exakt erhalten. Steuerzeichen (z. B. \037) scheiden aus, weil tmux sie in der
# Format-Ausgabe zu Text maskiert. hiroppy säubert '|' aus allen @pane_*-Werten
# (es nutzt '|' selbst intern) → kollisionssicher.
#
#   Zeile 1:  #HDR|n_sessions|n_claude|n_action
#   danach je Eintrag (9 Felder):
#     rowtype|session|attached|state|model|agent|cause|cwd|target
#       rowtype  C=Claude-Pane · N=Session ohne Claude · B=Hintergrund-Session
#       state    error | action | running | idle | -
#       target   session:@win.%pane  (nur C; für jump)
#   Ohne tmux-Server: einzige Zeile  #NOTMUX
#
# Quellen (read-only, bereits live): EIN list-panes (-F mit allen @pane_*),
# list-sessions, ~/.claude/sessions/*.json, Transcript-Tail (Modell).
# Join-Key @pane_session_id == .sessionId. Handlungsbedarf:
# @pane_attention=="notification" ODER @pane_status=="waiting".
# ─────────────────────────────────────────────────────────────────────────────
set -u

# Transcript-Tail → rohe Modell-ID (leer wenn nicht ermittelbar). Gebremst + still.
_deck_model_id() {
  local sid="$1" f
  [ -n "$sid" ] || return 0
  # shellcheck disable=SC2012  # Dateinamen sind UUIDs (safe); ls -t = jüngstes Transcript
  f=$(ls -t "$HOME"/.claude/projects/*/"$sid".jsonl 2>/dev/null | head -1)
  [ -n "$f" ] && [ -f "$f" ] || return 0
  tail -c 262144 "$f" 2>/dev/null | tac 2>/dev/null \
    | grep -m1 -o '"model":"[^"]*"' 2>/dev/null \
    | head -1 | sed 's/.*"model":"\([^"]*\)".*/\1/'
}

collect_rows() {
  command -v tmux >/dev/null 2>&1 || { printf '#NOTMUX\n'; return 0; }

  local D='|'
  local fmt="#{session_name}${D}#{window_id}${D}#{pane_id}${D}#{pane_current_command}${D}#{@pane_agent}${D}#{@pane_session_id}${D}#{@pane_status}${D}#{@pane_attention}${D}#{@pane_wait_reason}${D}#{@pane_subagents}${D}#{@pane_cwd}${D}#{@deck_pane}"
  local panes sessions
  panes=$(tmux list-panes -a -F "$fmt" 2>/dev/null) || { printf '#NOTMUX\n'; return 0; }
  sessions=$(tmux list-sessions -F "#{session_name}${D}#{session_attached}" 2>/dev/null) || true

  # --- Sessions-Index (Reihenfolge + attached) ---
  declare -A attached_of
  local n_sessions=0 sname satt
  while IFS=$D read -r sname satt; do
    [ -n "$sname" ] || continue
    attached_of[$sname]="${satt:-0}"
    n_sessions=$(( n_sessions + 1 ))
  done <<< "$sessions"

  # --- sessions/*.json → Metadaten je sessionId (optional) ---
  declare -A j_name j_kind j_tmux
  local files=()
  shopt -s nullglob
  files=("$HOME"/.claude/sessions/*.json)
  shopt -u nullglob
  if [ "${#files[@]}" -gt 0 ] && command -v jq >/dev/null 2>&1; then
    local jsid jnm jkd jtm
    while IFS=$D read -r jsid jnm jkd jtm; do
      [ -n "$jsid" ] || continue
      j_name[$jsid]="$jnm"; j_kind[$jsid]="$jkd"; j_tmux[$jsid]="$jtm"
    done < <(jq -rs '.[] | [.sessionId,(.name//""),(.kind//""),(.tmux//"")] | join("|")' "${files[@]}" 2>/dev/null)
  fi

  # --- Panes scannen ---
  declare -A has_claude sess_pc sess_cmd model_cache
  local claude_rows=()
  local n_claude=0 n_action=0
  local session win pane cmd agent sid st att wr sub pcwd deck
  while IFS=$D read -r session win pane cmd agent sid st att wr sub pcwd deck; do
    [ -n "$session" ] || continue
    [ "${deck:-}" = "1" ] && continue                 # eigenen Deck-Pane nie listen
    sess_pc[$session]=$(( ${sess_pc[$session]:-0} + 1 ))
    [ -z "${sess_cmd[$session]:-}" ] && sess_cmd[$session]="$cmd"
    [ "$agent" = "claude" ] || continue

    has_claude[$session]=1
    n_claude=$(( n_claude + 1 ))

    local state cause
    if [ "$st" = "error" ]; then
      state=error; cause="${wr:-Fehler}"
    elif [ "$att" = "notification" ] || [ "$st" = "waiting" ]; then
      state=action; cause="${wr:-wartet auf Eingabe}"
    elif [ "$st" = "running" ]; then
      state=running; cause=""
    else
      state=idle; cause=""
    fi
    if [ "$state" = action ] || [ "$state" = error ]; then
      n_action=$(( n_action + 1 ))
    fi

    local mid
    if [ -n "${model_cache[$sid]:-}" ]; then
      mid="${model_cache[$sid]}"
    else
      mid="$(_deck_model_id "$sid")"; model_cache[$sid]="$mid"
    fi
    local model; model="$(model_name "$mid")"

    local agentlabel="${sub:-}"; [ -z "$agentlabel" ] && agentlabel="-"
    local target="${session}:${win}.${pane}"
    local sk=2; case "$state" in error|action) sk=0 ;; running) sk=1 ;; esac

    claude_rows+=( "$(printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s' \
      "$sk" "C" "$session" "${attached_of[$session]:-0}" "$state" "$model" \
      "$agentlabel" "$cause" "${pcwd:-}" "$target")" )
  done <<< "$panes"

  # --- Sessions ohne Claude ---
  local noclaude_rows=()
  while IFS=$D read -r sname satt; do
    [ -n "$sname" ] || continue
    [ -n "${has_claude[$sname]:-}" ] && continue
    noclaude_rows+=( "$(printf '3|N|%s|%s|-||%s|%s pane||' \
      "$sname" "${satt:-0}" "${sess_cmd[$sname]:-?}" "${sess_pc[$sname]:-0}")" )
  done <<< "$sessions"

  # --- Hintergrund-/Daemon-Sessions (tmux:null) ---
  local bg_rows=() bsid
  for bsid in "${!j_kind[@]}"; do
    if [ "${j_kind[$bsid]}" = "bg" ] || [ -z "${j_tmux[$bsid]}" ]; then
      bg_rows+=( "$(printf '4|B|%s|0|-|||||' "${j_name[$bsid]:-bg}")" )
    fi
  done

  # --- Ausgabe: Header + sortierte Zeilen (Handlungsbedarf zuerst) ---
  printf '#HDR|%s|%s|%s\n' "$n_sessions" "$n_claude" "$n_action"
  {
    [ "${#claude_rows[@]}"   -gt 0 ] && printf '%s\n' "${claude_rows[@]}"
    [ "${#noclaude_rows[@]}" -gt 0 ] && printf '%s\n' "${noclaude_rows[@]}"
    [ "${#bg_rows[@]}"       -gt 0 ] && printf '%s\n' "${bg_rows[@]}"
  } | sort -t'|' -k1,1n -k3,3 | cut -d'|' -f2-
}
