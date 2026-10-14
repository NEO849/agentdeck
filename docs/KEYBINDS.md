# agentdeck · Sidebar-Referenz (Keybinds & Befehle)

**Präfix = `Ctrl+b`** (drücken, loslassen, dann die Taste).

## Ein-/ausblenden (mit Präfix)
| Taste | Wirkung |
|---|---|
| `Ctrl+b` → `e` | **agentdeck-Deck** (Session-Überblick, Handlungsbedarf zuerst) an/aus |
| `Ctrl+b` → `E` | **hiroppy-Detail-Sidebar** (Subagent-Tree/Git/Worktrees) an/aus |
| `Ctrl+b` → `Alt+e` | hiroppy-Sidebar in **allen** Fenstern an/aus |

## Der agentdeck-Deck (prefix + e)
Ein nach **tmux-Session** gruppierter Überblick, der beim Aufklappen links erscheint und sich alle
2 s aktualisiert: pro Session die Claude-Instanz mit Modell, aktivem Agent, Status — Sessions mit
**Handlungsbedarf zuerst**. Sessions ohne Claude stehen gedimmt unten, Hintergrund-Sessions als `(bg)`.
Zum Pane einer Session springen: `agentdeck jump <nummer|session>` (z. B. `agentdeck jump 2`).

## In die hiroppy-Sidebar hinein (prefix + E, dann fokussieren)
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

## Status-Marker (emoji-frei)
`●` aktiv (grün) · `▲` wartet / Handlungsbedarf (amber) · `○` idle · `■` Fehler (rot)
· `*` = aktiver Client · blaue Akzente = Session/Header

## Live-Befehle (tmux)
```bash
tmux set -g @sidebar_width 25%        # Breite ändern …
tmux set -g @sidebar_position right   # … oder Position
# danach einmal  Ctrl+b E  aus/an  → die Sidebar liest die Optionen neu
```

- **Breite** ist adaptiv: schmaler Client (Handy) → 30 %, Desktop → 27 % (Deck via `@deck_width`,
  hiroppy via `extras/sidebar-adaptive-width.sh` als tmux-Hook).
- **Benachrichtigungen (ntfy):** Push nur wenn Claude **wartet**, bei **Fehler**, oder wenn ein
  **langer Lauf (>2 min) fertig** wird, während du weg warst (`extras/notify-ntfy.sh`).

**Typischer Ablauf:** `Ctrl+b e` (Deck) → sehen, welche Session Handlungsbedarf hat → dort
weiterarbeiten. Tiefer rein: `Ctrl+b E` (hiroppy) → reinklicken/`Ctrl+b ←` → `j/k` → `Enter` hin.

---

> Tipp: Als Claude-Code-Slash-Command `/sidebar` immer griffbereit — lege dafür eine Datei
> `~/.claude/commands/sidebar.md` mit dem Inhalt dieser Referenz an (Dateiname = Command-Name).
