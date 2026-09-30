# agentdeck · Rollback

Der Installer ist additiv und legt vor jeder Änderung Backups an. Es gibt zwei Wege zurück.

## Weg 1 — das Uninstall-Skript (empfohlen)

```bash
./uninstall.sh          # entfernt chirurgisch nur agentdeck-Einträge, fragt vor dem Löschen
./uninstall.sh --yes    # ohne Rückfrage
```

Es macht: Sidebar-/agentdeck-Hooks aus `~/.claude/settings.json` entfernen · unsere Statusline nur
dann zurücknehmen, wenn sie auf unser Script zeigt · den tmux.conf-Block entfernen · den Plugin-Ordner
löschen (nach Rückfrage). Vorher wird jeweils ein `.bak-<zeitstempel>` angelegt.

## Weg 2 — Backups von Hand zurückspielen

```bash
# jeweils das jüngste Backup nehmen:
ls -t ~/.tmux.conf.bak-*            ~/.claude/settings.json.bak-*
cp ~/.tmux.conf.bak-<TS>            ~/.tmux.conf
cp ~/.claude/settings.json.bak-<TS> ~/.claude/settings.json
rm -rf ~/.tmux/plugins/tmux-agent-sidebar
tmux source ~/.tmux.conf
```

## Danach

```bash
tmux source ~/.tmux.conf
```

Und eine **neue** Claude-Session starten — Hook-Änderungen greifen erst für neue Sessions.

> `~/.claude.json` wird von agentdeck nie verändert (das ist der Live-State von Claude Code) — dort
> ist also nichts zurückzurollen.
