# 1.7.0-beta.15

Menüs und Einrichtung

- Gemeinsame dunkle Oberfläche mit klaren Karten, blauem Akzent, konsistenten Schaltflächen, Auswahlfeldern, Schiebereglern und Eingabefeldern.
- Control Center, Layout-Editor und Diagnoseexport nutzen gemeinsame Fensterstile. Die vorhandene Blizzard-Einstellungsseite und die Teilen-Schaltfläche verwenden ebenfalls gemeinsame Bedienelemente.
- Fenster passen sich beim Öffnen und bei Änderungen von Auflösung/UI-Skalierung an den verfügbaren Platz an.
- Neue Einrichtung mit sechs Schritten: Willkommen und Profilmodus, Navigationsanzeigen, Weltmarker mit persönlichem Raid-Symbol und Vorschau, Gruppenmeldungen, Layout-Editor, Zusammenfassung.
- Automatischer Start bei neuen Installationen nach Login. Im Kampf wird der Start verschoben. Eine beim Logout unvollständige Ersteinrichtung bleibt als ausstehend markiert.
- Vorhandene Installationen behalten ihre Einstellungen und werden nicht automatisch unterbrochen. Der Assistent ist über Einrichtung im Menü bzw. /rxpnav setup jederzeit verfügbar.
- Optionen bleiben bis zum Abschluss im Entwurf. Überspringen oder Schließen verwirft sie und verhindert erneutes automatisches Öffnen. Layout-Positionen werden ausdrücklich separat im Layout-Editor gespeichert.
- Der Layout-Editor führt zurück zum laufenden Assistenten, ohne den Optionsentwurf zu verlieren.
- Während der Einrichtung keine Gruppen-Questmeldungen oder Nachlieferung alter Fortschritte.
- Markervorschauen können eigene Entwurfswerte erhalten; ihre Zeichenebene folgt dem Menüfenster. Der Produktionspfad und die Verankerung des Weltmarkers bleiben unverändert.
- Alle neuen Texte in allen unterstützten Clientsprachen.

Qualitätssicherung

Lua-5.1-Kompilierung und bestehende Regressionstests erfolgreich. Neue Tests für Erststart/Upgrade, Überspringen und Wiederöffnung, isolierte Entwürfe, Abschluss, Kampf, Rückkehr aus dem Layout-Editor, Wiederverwendung von UI-Objekten und Fensteranpassung. Alle Control-Center-Seiten und Assistentenschritte mit dem tatsächlichen Theme-Code unter UI-Mocks in allen Sprachcodes aufgebaut. Sprachabdeckung, Platzhalter und UTF-8-Prüfungen erfolgreich. Zusätzliche interne Layout-Ansichten aus den UI-Mocks geprüft; diese ersetzen keinen Test im WoW-Client. Die tatsächliche Darstellung und Bedienung im Spiel sind noch zu prüfen.
