# RestedXP-Navigator v1.5.27

## Highlights

- Added Blizzard-style in-world navigation markers for RestedXP objectives.
- Uses Blizzard's built-in PingUI atlases for travel, assist/turn-in, attack, warning and neutral targets.
- Added native user-waypoint world navigation while keeping the existing HUD, minimap and world-map guidance.
- Added corpse-run world navigation.
- Added dynamic ETA based on actual movement toward the current target.
- Improved waypoint handover and arrival detection so the previous marker can remain briefly while RestedXP advances to the next step.
- The vertical position pin is shown only at close range; distant objectives stay visually clean.
- Added an explicit `/rxpnav npctest` diagnostic for testing marker anchoring to visible NPC nameplates.
- Friendly and hostile NPC nameplate anchoring was validated without restricted frame measurements.
- Removed restricted nameplate geometry reads and automatic nameplate-CVar changes.
- Restored reliable suppression of Blizzard's duplicate gold waypoint presentation while retaining the underlying native navigation anchor.
- Multiple fixes and polish passes for marker visibility, corpse navigation, quest context and UI behavior.

## Safety / Blizzard API policy

RestedXP-Navigator does not automate combat, targeting, spell casting, item use or player input. It does not attempt to bypass protected/restricted APIs and falls back when Blizzard restricts an interface or region.

## Compatibility

- World of Warcraft: Forever
- Interface: 16001
- Requires: RestedXP Guides
