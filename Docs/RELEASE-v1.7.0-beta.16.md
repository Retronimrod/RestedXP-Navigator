# 1.7.0-beta.16

Setup-Profile

- Letzter Einrichtungsschritt mit Auswahl Allgemeines Profil oder Persönliches Profil.
- Allgemeines Profil: gemeinsames Default-Profil für alle Charaktere.
- Persönliches Profil: eigener Name, standardmäßig für den aktuellen Charakter; optional gemeinsame Nutzung für alle Charaktere.
- Vorhandene Profile werden nur nach ausdrücklicher Bestätigung ersetzt. Eine erstmalige Einrichtung darf das neu angelegte Standardprofil direkt konfigurieren.
- Leere Namen, Steuer-/Formatzeichen und Namen über 32 UTF-8-Zeichen werden abgewiesen. Default ist für das allgemeine Profil reserviert.
- Validierung vor Änderung der aktiven Konfiguration und Profilauswahl. Andere Profile bleiben erhalten. Layout, Farben und nicht im Assistenten bearbeitete Einstellungen bleiben im gespeicherten Profil enthalten.

Weltmarker

- Gemeinsame Auswahl im Weltmarker-Menü und im Assistenten: Automatisch nach Aufgabe, Diamant, Pfeil, Schwert, Interaktion, Warnung und Raid-Symbole.
- Raid-Symbole weiterhin mit acht auswählbaren Symbolen. Symbolauswahl aktiviert die Raid-Symbol-Darstellung direkt.
- Vorschau und tatsächlicher Weltmarker verwenden dieselbe Stilauflösung. Nicht verfügbare Blizzard-Atlanten nutzen den bestehenden Diamant-Fallback.
- Ausschließlich vorhandene Blizzard-Grafiken und der bestehende Bodenring. Keine EasyFind-Abhängigkeit.
- Marker-Stil wird im Profil gespeichert. Zielkoordinaten, Verankerung und Navigationsberechnung unverändert.

Prüfung

Produktive Profil-API mit tatsächlichem Assistenten unter UI-Mocks geprüft: gemeinsame/charakterbezogene Profile, Namensprüfung, explizites Ersetzen, unveränderte Konfiguration bei Ablehnung, unabhängige Snapshots sowie Erhalt von Layout und Marker-Stil. Alle Marker-Stile gegen den produktiven Renderer geprüft. Vorhandene Lua-5.1-, Gruppenchat-, Layout- und Sprachtests erfolgreich. Echte Ingame-Prüfung steht aus.
