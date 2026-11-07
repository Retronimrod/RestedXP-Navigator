# 1.7.0-beta.12

- Automatische Sprache nach WoW-Client: Englisch (US/GB), Deutsch, Französisch, Spanisch (ES/MX), Italienisch, Portugiesisch (BR), Russisch, Koreanisch, Chinesisch (vereinfacht/traditionell).
- Zentrale UTF-8-Sprachdatei mit 298 Einträgen pro Sprache, inklusive vorhandener und neuer Einstellungen.
- Control Center, Minimap- und Gruppen-Tooltips, Reisehinweise, Schritttypen, Profilmeldungen, Dialoge und Neuerungen lokalisiert.
- Addon-Beschreibungen im Client lokalisiert.
- Eigene Profilnamen, RestedXP-Inhalte und technische Diagnosefelder werden unverändert übernommen.
- UTF-8-sicheres Kürzen von Markertiteln; längere Schaltflächen-Texte werden angepasst.
- Produktionspfad der Marker-Verankerung unverändert zur getesteten Beta.11.

Prüfung: Sprachabdeckung für alle 12 Sprachcodes, 115 Control-Center-Texte pro Code mit UI-Stubs, Formatplatzhalter, Core-Schlüssel, englischer Fallback und mehrbyteige Markertitel geprüft. Bestehende Gruppenmarker-, Weltmarker- und Regressionstests erfolgreich. Alle Lua-Dateien unter Lua 5.1 geprüft. Keine visuelle Ingame-Prüfung der Sprachclients durchgeführt.
