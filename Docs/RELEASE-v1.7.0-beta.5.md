# RestedXP-Navigator v1.7.0-beta.5 — ground-height experiment

This is a client experiment, not a confirmed terrain-anchoring implementation.

## Height comparison

Stand still on dry, solid ground, preferably on an open slope. Enable Blizzard in-game navigation. Run `/rxpnav groundtest here` to sample your map X/Y and UnitPosition Z. Move 10–20 steps away from the stored point, then compare:

- `/rxpnav groundtest auto`: same X/Y, no explicit Z.
- `/rxpnav groundtest z 0`: same X/Y, sampled player Z.
- `/rxpnav groundtest z 10`: sampled Z + 10.
- `/rxpnav groundtest z -10`: sampled Z - 10.
- `/rxpnav groundtest status`: requested and readback Z, plus waypoint ownership.
- `/rxpnav groundtest off`: end test and restore previous display settings / resume guide navigation.

Rotate/tilt the camera and compare where the lower edge of the marker appears relative to the original standing spot. Keep the character at the same observation position when changing Z. A readback Z alone does not prove visual placement support; the marker must visibly move with Z while X/Y stay fixed. Player-origin Z is an experimental height reference, not a verified terrain sample or automatic remote terrain query.

Test automatically stops after 180 seconds, on zone changes or logout. Starting requires an enabled Navigator, readable position and a waypoint-capable map. Moving, flying, falling and swimming starts are rejected. No heights are learned or saved automatically. RestedXP waypoint generation remains unchanged outside the experiment. Externally replaced waypoints are respected.

## Compact precision appearance

Precision mode is on by default (General settings can restore the old style). It uses a fixed 24-pixel stem, a smaller 22-pixel icon, no nameplate snapping, no decorative glow layers and no simulated ground ring without terrain height. The world marker changes directly to the new guide target instead of holding the previous point for up to 30 seconds. The native navigation anchor is reused and invalid screen positions are hidden. Legacy NPC anchoring also fixes an incorrect bottom-vs-center attachment that added half the large marker frame height above the nameplate.

## Validation

Lua 5.1 syntax parsing and LuaJIT 2.1 / Lua 5.1-compatible mocked tests cover sampling, offsets, no-Z comparison, Z-only waypoint updates, absent Z on readback, timeout, setting restoration, external waypoint ownership, precision appearance and existing hearth/raid-symbol behavior. Visual behavior and actual client interpretation of Z must still be verified in WoW Forever.
