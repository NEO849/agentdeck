#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# agentdeck · deck · Modell-ID → Klarname
# Reine Funktion (kein Seiteneffekt). Unbekannte IDs werden roh durchgereicht,
# leere → "—". Bewusst tolerant: neue Modell-Generationen fallen auf die
# Familien-Kurzform zurück statt zu brechen.
# ─────────────────────────────────────────────────────────────────────────────

model_name() {
  case "${1:-}" in
    "" )                         printf '—' ;;
    *opus-4-8*|*opus-4.8*)       printf 'Opus 4.8' ;;
    *opus-4-5*|*opus-4.5*)       printf 'Opus 4.5' ;;
    *sonnet-4-5*|*sonnet-4.5*)   printf 'Sonnet 4.5' ;;
    *haiku-4-5*|*haiku-4.5*)     printf 'Haiku 4.5' ;;
    *opus-5*)                    printf 'Opus 5' ;;
    *sonnet-5*)                  printf 'Sonnet 5' ;;
    *haiku-5*)                   printf 'Haiku 5' ;;
    *fable-5*)                   printf 'Fable 5' ;;
    *opus-4*)                    printf 'Opus 4' ;;
    *sonnet-4*)                  printf 'Sonnet 4' ;;
    *haiku-4*)                   printf 'Haiku 4' ;;
    *opus*)                      printf 'Opus' ;;
    *sonnet*)                    printf 'Sonnet' ;;
    *haiku*)                     printf 'Haiku' ;;
    *)                           printf '%s' "$1" ;;
  esac
}
