# Screenshot-Anleitung (für die README)

Die README verweist auf Bilder in diesem Ordner (`docs/readme/`). Bis deine echten Aufnahmen da
sind, sind es Platzhalter. Ideal sind **4 Screenshots aus deinem echten tmux** — die zeigen die
Sidebar mit *deinen* laufenden Agenten und wirken dadurch glaubwürdiger als Upstream-Captures.

## Welche 4 Bilder

| Datei | Motiv | So entsteht es |
|---|---|---|
| `hero.png` | Gesamtansicht: Sidebar links + ein Claude-Pane rechts, mehrere Agenten gelistet | tmux mit 2-3 aktiven Sessions, Sidebar an (`prefix + e`), Terminal breit (≥ 1400 px) |
| `status-filter.png` | Statusfarben (running/waiting/error) + Filterzeile | Filter mit `Tab` durchschalten, Moment mit gemischten Status |
| `git-tab.png` | Bottom-Panel im Git-Tab (Branch/Diff/PR) | `Shift+Tab` auf Git, in einem Repo mit Änderungen |
| `notify.png` | ntfy-Push auf dem Handy (Agent fertig/wartet) | Handy-Screenshot der ntfy-App nach einem `Stop`/`Notification` |

## Aufnahme

- **VPS/headless:** im Terminal-Emulator lokal aufnehmen (die Sidebar ist ja SSH-Text) — macOS
  `Cmd+Shift+4`, dann ins `docs/readme/` legen. Für exakt gleiche Breite hilft ein fixes
  Fenster-Preset.
- **Einheitlichkeit:** gleiches Farbschema (Tokyo Night), gleiche Fensterbreite, keine sensiblen
  Pfade/Tokens im Bild (vorher prüfen!).
- **Größe:** Hero ~ 1600 px breit, dann auf ~ 880 px herunterskalieren (die README setzt `width`).

## Einbinden

Dateiname exakt wie oben — die README referenziert `docs/readme/hero.png` usw. relativ. Kein weiterer
Schritt nötig, sobald die PNGs hier liegen.
