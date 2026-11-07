# 1.7.0-beta.11

Grundlage: unveränderte Beta.10 mit gezielten Fehlerkorrekturen.

- Ruhestein-Binden (.home/.bindlocation) als Interaktion statt Teleport erkannt; Text-Fallback verlangt eine Benutzen-Anweisung.
- Persönliche Raid-Symbole und Zielkopf-Schalter im Control Center ergänzt.
- Wirkungslose automatische NPC-Einstellungen entfernt.
- Vorschau verwendet denselben Renderer wie der Weltmarker, ohne Navigation zu verändern.
- Reglergrenzen mit Darstellung abgeglichen; alte Werte beim Laden und Profilwechsel angepasst.
- Ältere Profile erhalten fehlende Standardwerte. Explizite false-Werte bleiben erhalten.
- Löschen eines inaktiven Profils wechselt nicht mehr das aktive Profil.
- Änderungsinformationen aktualisiert.

Prüfung: Alle Lua-Dateien unter Lua 5.1 kompiliert; bestehende Tests sowie neue Regressionstests erfolgreich. Kein Ingame-Test möglich. Die Verankerung der Beta.10 wurde nicht geändert.
