# agentdeck · Runbook

Betriebswissen für den Alltag mit der Sidebar — inkl. der ehrlichen Fallstricke.

## Bedienung (Prefix = `Ctrl+b`)

| Taste | Wirkung |
|---|---|
| `prefix + e` | Sidebar im aktuellen Fenster an/aus |
| `prefix + E` | Sidebar in **allen** Fenstern an/aus |

In fokussierter Sidebar (ohne Prefix — Fokus per Maus oder `Ctrl+b ←`):

| Taste | Wirkung |
|---|---|
| `j` / `k` | Auswahl hoch/runter |
| `Enter` | zum Pane des Agenten springen |
| `h` / `l` · `Tab` | Statusfilter (all/running/waiting/idle/error/background) |
| `r` | Repo-Filter-Popup |
| `Shift+Tab` | Bottom-Panel umschalten (Activity ⇄ Git) |
| `n` / `x` | Worktree neu anlegen / entfernen |
| `Esc` | Fokus zurück / Popup schließen |

## Live-Umkonfigurieren (ohne Neustart)

```bash
tmux set -g @sidebar_width 30%
tmux set -g @sidebar_position right
# dann Sidebar einmal aus- und wieder einschalten:  prefix + E  ,  prefix + E
```

## Headless-Realität (wichtig, ehrlich)

- **Desktop-Notifications der Sidebar feuern auf einem reinen SSH-/VPS-Host NICHT.** Das Plugin nutzt
  auf Linux `notify-send`; fehlt ein Notification-Daemon/DBus, schaltet es die Funktion **still ab**
  (kein Fehler, aber auch kein Ton). → Dafür ist das **ntfy-Add-on** da (`extras/notify-ntfy.sh`):
  Push aufs Handy per ausgehendem HTTPS, ganz ohne Desktop.
- **Speicherwachstum (offener Upstream-Bug #85):** Bei sehr lang laufendem tmux-Server kann der
  Server-Speicher mit aktiver Sidebar über Tage anwachsen. Workaround bis zum Upstream-Fix: den
  tmux-Server periodisch neu starten (`tmux kill-server`, danach neu attachen). Beobachten, nicht
  ignorieren. Quelle: github.com/hiroppy/tmux-agent-sidebar/issues/85

## Zusammenspiel mit tmux-resurrect / tmux-continuum

`@sidebar_auto_create off` ist Absicht: mit `@continuum-restore on` baut tmux beim Serverstart viele
Fenster deklarativ neu auf — bei `auto_create on` würde in **jedem** davon sofort eine Sidebar
aufgehen. Mit `off` blendest du sie bewusst per `prefix + e` ein, wo du sie brauchst.
(Nicht upstream-dokumentiert — eigene Betriebserfahrung.)

## Voraussetzungen

- tmux **3.0+**, `git`, `jq`. Zum Bauen aus Quelle: Rust/`cargo` (sonst holt die Sidebar beim ersten
  Load ein Prebuilt-Binary). `gh` optional — nur für PR-Nummern im Git-Tab.
- Volle Feature-Tiefe (Subagent-Tree, Task-Progress, Wait-Reason, Permission-Badge) nur mit
  **Claude Code**; Codex/OpenCode werden eingeschränkter unterstützt.
