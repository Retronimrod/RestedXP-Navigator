# Einrichtung

Neue Installation: Der Einrichtungsassistent öffnet sich nach dem ersten Login. Bei einer vorhandenen Konfiguration bleibt diese bestehen. Zum Starten den Button Einrichtung im Control Center oder /rxpnav setup verwenden.

Der Assistent führt durch sechs Schritte. Zurück und Weiter behalten die Auswahl als Entwurf; Einrichtung abschließen übernimmt die Optionen ins gewählte Addon-Profil. Überspringen oder Schließen verändert diese Optionen nicht und beendet die automatische Ersteinrichtung. Über das Menü kann sie später erneut geöffnet werden.

Im Schritt Layout bearbeiten können die Bildschirm-Anzeigen positioniert werden. Positionen speichert der Layout-Editor separat über seinen Speichern-Button. Anschließend kehrt die Ansicht zum Assistenten zurück. Ein späteres Überspringen des Assistenten nimmt ausdrücklich im Layout-Editor gespeicherte Positionen nicht zurück.

Die Oberfläche folgt der Clientsprache. Deaktivierte Blizzard-Navigation wird im Weltmarker-Schritt erläutert; die Client-Einstellung wird vom Assistenten nicht automatisch verändert.

Technik: setupVersion/setupStatus sind installationsbezogene Metadaten in RXPNavigatorDB und gehören nicht zum Profil-Snapshot. Profilwechsel setzen den Einrichtungsstatus nicht zurück. Ein als pending gespeicherter Erststart wird nach erneutem Login angeboten. UI/Theme.lua stellt gemeinsame Bedienelemente bereit; UI/SetupWizard.lua verwaltet Entwurf und Abschluss. Die Assistentenseiten verwenden wiederverwendete UI-Objekte statt fortlaufend neue Rahmen anzulegen.

## Speichern im letzten Schritt (Beta.16)

Allgemeines Profil speichert im gemeinsamen Standardprofil (intern Default). Persönliches Profil bietet einen eigenen Namen und ist zunächst dem aktuellen Charakter zugeordnet. Über Ein Profil für alle Charaktere kann auch ein benanntes Profil gemeinsam genutzt werden. Ein vorhandener Zielname erfordert Vorhandenes Profil ersetzen. Ohne Bestätigung werden vorhandene Daten nicht verändert; der Assistent bleibt geöffnet. Namenslimit: 32 Zeichen. Auch Marker-Darstellung und bereits gespeicherte Layout-Positionen gehören zum Profil.

Im Weltmarker-Schritt und im Weltmarker-Menü kann die Darstellung unabhängig vom Aufgabentyp festgelegt werden. Automatisch nach Aufgabe behält den bisherigen Wechsel der Symbole bei. Raid-Symbole sind persönliche Grafiken; diese Auswahl setzt keine Gruppen-Weltmarkierung.
