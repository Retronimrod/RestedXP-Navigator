# v1.7.24 — Testversion

- Reiseinformationen und Routenauswahl des HUD werden höchstens alle 0,25 Sekunden neu berechnet. Auch negative Ergebnisse werden kurz gespeichert.
- Sofortige Invalidierung bei Ziel-/Schrittänderungen, Quest-/Guide-Revisionen, Karten-/Zonenwechseln sowie gemeldeten Änderungen an Steuerung, Reittier, Flugpunkten, Ruhesteinbindung und Zaubern.
- Zielkoordinaten, Schrittstatus und Zieltext werden auf Änderungen geprüft. Fehlende Spielerkarten werden erneut abgefragt.
- Richtung und Entfernung bleiben bei jedem HUD-Update aktuell. Andere Verbraucher der Reiseplanung bleiben unverändert.
- Detailmessung aus v1.7.23 bleibt erhalten; SPF-Bridge weiterhin unverändert 0.3.8.
- Versionshinweis in allen zwölf unterstützten Client-Sprachvarianten.

Validierung: Lua-Syntaxprüfung, Modul-Ladetest mit simulierten WoW-Funktionen und gezielte Prüfungen für Cache-Ablauf, Invalidierung, negative Ergebnisse und Rückfallrouten. Der tatsächliche Leistungsgewinn muss mit /rxpnav perf im Spiel gemessen werden.
