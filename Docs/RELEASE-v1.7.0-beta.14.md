# 1.7.0-beta.14

Layout-Editor für die Bildschirm-Anzeigen des Navigators:

- Navigationspfeil mit Distanz, Ankunftszeit und Reise-/Ruhestein-/Grind-Inhalten, oberer Zielkopf sowie Gruppenmarkierungsleiste frei verschiebbar.
- Einstieg über Layout bearbeiten im Control Center bzw. Blizzard-Addon-Einstellungen oder /rxpnav layout.
- Beim öffentlichen Blizzard-Ereignis EditMode.Enter werden eigene Verschiebegriffe eingeblendet. Keine Registrierung in Blizzards interner Systemliste. Einträge in Blizzards Element-Checkbox-Liste werden nicht hinzugefügt.
- Ausgeblendete Anzeigen erhalten unabhängige Beispielrahmen. Die tatsächlichen Bildschirm-Anzeigen sind während des Bearbeitens ausgeblendet, damit keine doppelten Anzeigen entstehen. Der eigentliche Weltmarker bleibt am Navigationsziel.
- Elemente per Ziehen oder X-/Y-Koordinaten in UI-Pixeln (Ursprung unten links) positionieren; Größe 60–160 Prozent; Position und Größe des gewählten Elements zurücksetzen.
- Speichern übernimmt ausschließlich das Navigator-Layout ins aktuelle Addon-Profil. Abbrechen, Escape und Kampfstart verwerfen ungespeicherte Änderungen. Außerhalb des Editors sind die Verschiebegriffe ausgeblendet.
- Positionswerte relativ zur Bildschirmgröße gespeichert und beim Anwenden an Bildschirmgrenzen begrenzt. Vorhandene HUD-Positionen werden übernommen.
- Native EditMode.SavedLayouts übernimmt Navigator-Änderungen ebenfalls; RevertAllChanges verwirft noch ungespeicherte Navigator-Änderungen. Ist Blizzards Speicherbutton mangels Änderungen an Blizzard-Elementen deaktiviert, den eigenen Navigator-Speichern-Button nutzen.
- Navigator-Positionen gehören zum Navigator-Profil, nicht zum separat ausgewählten Blizzard-Layout. Auf Clients ohne passende EditMode-Ereignisse steht der eigene Editor zur Verfügung.
- Im Kampf keine Verschiebung oder Skalierung der geschützten Gruppenleiste. Ausstehende Positionskorrekturen nach Kampfende.
- Neue Texte in allen unterstützten Clientsprachen.

Validierung: Lua-5.1-Syntax, Layout-Transaktionen, erste Öffnung, Profil-Speicherung, relative Positionen, Skalierung, Bildschirmgrenzen, Zurücksetzen, native Events, Verwerfen, Kampfschutz und bisheriges HUD-Ziehen mit UI-Mocks geprüft. Bestehende Marker-, Chat- und Sprachtests erfolgreich. Keine Ingame-Prüfung oder visuelle Prüfung des tatsächlichen Clients durchgeführt.
