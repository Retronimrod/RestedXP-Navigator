# v1.7.23 — Testversion

- Reise-HUD setzt Text und Pfeildrehung nur bei einer tatsächlichen Änderung neu.
- Bereits ermittelte Kontinent-Reiseinformationen werden an Reiseplanung und Reiseauflösung weitergereicht. Andere Aufrufer behalten die bisherige automatische Auflösung.
- Route, Richtung und Entfernung werden weiterhin bei jedem HUD-Update ermittelt; keine Änderung der Aktualisierungsrate.
- Zusätzliche HUD-Detailmessungen für Routenauswahl, Stil, Richtung/Entfernung, Titel, Kontext und Anzeige.
- SPF-Bridge 0.3.8 unverändert. Alle vorhandenen Einstellungen bleiben erhalten.

Validierung: Syntax- und Modul-Ladetests mit simulierten WoW-Funktionen, Cache- und Profiler-Tests sowie Prüfungen zur Weitergabe von Reiseinformationen und zu Textaktualisierungen. Ingame-Vergleich mit /rxpnav perf erforderlich.
