# v1.7.22 — Testversion

- HUD-Kontexthinweise werden bei unverändertem Zustand kurz zwischengespeichert (maximal 0,25 Sekunden).
- Ruhestein-Reisehinweise werden maximal 0,10 Sekunden zwischengespeichert; Abschluss und übersprungene Schritte werden weiterhin geprüft.
- Erfolgreiche moderne Spielerkartenabfragen werden innerhalb desselben Frames auch bei unterschiedlichen Zielkarten wiederverwendet. Rückfallkarten bleiben getrennt.
- Bereits ermitteltes Navigationsziel und Spielerkarte werden im HUD weitergereicht. Richtung, Entfernung und Friedhofentfernung bleiben aktuell.
- Der Performanceexport enthält getrennte Messungen der HUD-Arbeitsschritte. Diese Detailmessungen überschneiden sich mit dem HUD-Gesamtwert.
- Neue Versionshinweise in allen zwölf unterstützten Client-Sprachvarianten.
- SPF-Bridge 0.3.8 unverändert. Minikarte weiterhin nur aktueller Schritt, ohne Routenanimation bei aktivierter Bridge.

Validierung: Lua-Syntaxprüfung, vollständiger Modul-Ladetest mit simulierten WoW-Funktionen, gezielte Tests für Cache-Gültigkeit und Profiler-Abschluss. Keine Ingame-Leistungszusage; Vergleichsmessung mit /rxpnav perf erforderlich.
