# RestedXP-Navigator v1.7.0-beta.1

Based on the latest published GitHub / CurseForge release, v1.6.11.

- Adds a compact group toolbar below the native navigation header.
- Share target sends the currently owned navigation waypoint as a clickable map link to party, raid or instance chat, only after a click. Repeated clicks are limited to one message every three seconds.
- Eight raid world-marker buttons: left-click opens Blizzard ground targeting; right-click clears that specific marker.
- A user-replaced waypoint is never shared as a RestedXP destination.
- The toolbar requires enabled native world navigation, a visible-header setting, a current shareable target and a group. It follows the header's default screen position.
- Protected toolbar visibility is frozen during combat and refreshed when combat ends. Click actions still use the current target and group.

## Limits and in-game verification

Raid world markers are placed manually on the ground. This build cannot place them at arbitrary remote RestedXP coordinates. Group permissions, placement range and client restrictions remain enforced by WoW. These markers are separate from the existing local navigation visuals.

Lua parsing and mocked behavior checks cover waypoint ownership, chat routing, click throttling, secure marker attributes and combat visibility guards. The build has not been tested in the WoW client. Verify left/right clicks, group permissions, target changes, combat entry/exit, instance chat and waypoint links in WoW Forever 1.60.1 before publishing.
