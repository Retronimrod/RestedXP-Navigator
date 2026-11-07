# 1.7.0-beta.13

Neue Questmeldungen im Gruppenchat:

- Fortschritte beim Sammeln, Töten und anderen gezählten Questzielen.
- Meldung für erfüllte Teilziele und für vollständig erfüllte, abgabebereite Quests.
- Versand ausschließlich an PARTY, RAID oder INSTANCE_CHAT; solo keine Nachrichten.
- Fortschritt und Abschluss getrennt schaltbar unter Allgemein > Questmeldungen für die Gruppe. Beide sind zunächst eingeschaltet.
- Standardmäßig Quests des aktuellen RestedXP-Schritts. Optional alle Quests im Questlog.
- Meldungen werden in der Clientsprache erstellt; Questtitel und Zieltexte stammen aus dem Client.
- Schnell aufeinanderfolgende Zählerstände werden zusammengefasst. Höchstens eine Nachricht alle drei Sekunden, begrenzte Warteschlange und Verfallszeit.
- Login, Reload, Gruppenwechsel und Einstellungswechsel erzeugen keine nachträglichen Meldungen.
- Veraltete Zählerstände und Meldungen für entfernte Quests werden verworfen. Ein vom Client gemeldeter Chat-Lockdown wird respektiert; keine Ausweichkanäle oder Umgehung bei API-Fehlern.
- Marker-Verankerung und Navigation unverändert gegenüber Beta.12.

Automatisierte Tests: Gruppenkanäle, Solo-Verhalten, Reload-Baseline, Gruppenwechsel, Mehrfach-Events, mehrere Teilziele, Abschluss, einzelne Schalter, Questfilter mit RestedXP-Schrittwechsel, Ratenbegrenzung, sinkende Zähler, UTF-8-Limits, Chat-Lockdown und API-Ablehnung. Bestehende Tests und Sprachprüfungen erfolgreich. Ingame-Prüfung steht aus.

Technische Grundlagen: vom Client generierte Blizzard-Dokumentation für C_QuestLog.GetQuestObjectives, GetInfo, GetLogIndexForQuestID, IsComplete sowie C_ChatInfo.SendChatMessage und InChatMessagingLockdown; geprüft über Gethe/wow-ui-source (live). Blizzard UI Add-On Development Policy: keine übermäßige Chatnutzung.
