# v1.7.25 — Testversion

- Nicht unterstütztes Ereignis NEW_TAXI_PATH aus der HUD-Reiseplanung entfernt.
- Zusätzliche Reiseereignisse werden geschützt registriert. Ein unbekanntes Ereignis unterbricht das Laden nicht mehr.
- Reiseplanung weiterhin maximal 0,25 Sekunden zwischengespeichert; Ziel-/Schrittwechsel und unterstützte Ereignisse verwerfen den Cache. Richtung und Entfernung bleiben aktuell.
- SPF-Bridge unverändert 0.3.8.

Validierung: Lua-Syntax, Modul-Ladereihenfolge, bisherige Cache-Tests und gezielter Ladetest mit abgewiesenen optionalen Ereignissen.
