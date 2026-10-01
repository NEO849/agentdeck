# agentdeck · Sidebar-Referenz (Keybinds & Befehle)

**Präfix = `Ctrl+b`** (drücken, loslassen, dann die Taste).

## Ein-/ausblenden (mit Präfix)
| Taste | Wirkung |
|---|---|
| `Ctrl+b` → `e` | Sidebar im aktuellen Fenster an/aus |
| `Ctrl+b` → `E` | Sidebar in **allen** Fenstern an/aus |

## In die Sidebar hinein (fokussieren)
- Maus: reinklicken · oder Tastatur: `Ctrl+b` → `←`

## Drin navigieren (OHNE Präfix, Taste direkt)
| Taste | Wirkung |
|---|---|
| `j` / `k` (↓/↑) | Auswahl rauf/runter |
| `Enter` | zum Pane des Agenten springen |
| `Tab` (oder `h`/`l`) | Status-Filter: all → running → waiting → idle → error |
| `r` | Repo-Filter (Popup) |
| `Shift+Tab` | unteres Panel: Activity ⇄ Git |
| `Esc` | zurück / Popup schließen / Fokus raus |

## Worktrees (in der Sidebar, ohne Präfix)
| Taste | Wirkung |
|---|---|
| `n` | neuer Worktree + Agent (Popup: Name/Agent/Modus · Pfeile ändern · `Enter` erstellen · `Esc` abbrechen) |
| `x` | erzeugtes Pane entfernen (`y` = Fenster+Worktree+Branch weg · `c` = nur Fenster · `Esc` abbrechen) |

## Status-Farben
🟢 running · 🟡 waiting · ⚫ idle · 🔴 error · blaue Akzente = Git-Branch/Titel

## Live-Befehle (tmux)
```bash
tmux set -g @sidebar_width 25%        # Breite ändern …
tmux set -g @sidebar_position right   # … oder Position
# danach einmal  Ctrl+b E  aus/an  → die Sidebar liest die Optionen neu
```

- **Breite** ist mit agentdeck adaptiv: schmaler Client (Handy) → 30 %, Desktop → 22 %
  (`extras/sidebar-adaptive-width.sh` als tmux-Hook).
- **Benachrichtigungen (ntfy):** Push nur wenn Claude **wartet**, bei **Fehler**, oder wenn ein
  **langer Lauf (>2 min) fertig** wird, während du weg warst (`extras/notify-ntfy.sh`).

**Typischer Ablauf:** `Ctrl+b e` → reinklicken/`Ctrl+b ←` → mit `j/k` suchen → `Enter` hin →
arbeiten → `Ctrl+b ←` zurück.

---

> Tipp: Als Claude-Code-Slash-Command `/sidebar` immer griffbereit — lege dafür eine Datei
> `~/.claude/commands/sidebar.md` mit dem Inhalt dieser Referenz an (Dateiname = Command-Name).
