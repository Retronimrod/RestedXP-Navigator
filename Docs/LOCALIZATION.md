# Localization

`Localization/Locale.lua` is loaded before Core and owns all UI translations. English source strings are stable lookup keys; Core maps legacy setting keys through SOURCE_KEYS. Use `Navigator.API:Localize(source)` for new UI text and `API:Translate(key)` for existing keyed settings. Never translate player profile names or guide-provided data.

Locale aliases: enGB uses enUS; esMX uses the neutral Spanish esES catalog. Unknown locale codes fall back to English. Keep format placeholders unchanged. Client font objects provide the fonts; do not force a Latin font.

Run `python tests/localization.py` and `python tests/beta11_regressions.py` with lupa installed. The localization suite checks complete catalogs, core keys, format placeholders, popup newlines, UTF-8 title truncation and Control Center construction with stubs for all locale codes. Visual layout must also be checked in the game client. Diagnostic exports keep technical field names stable for support.
