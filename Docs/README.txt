RestedXP-Navigator 1.6.11

A visual navigation companion for RestedXP Guides on WoW Forever.

RestedXP-Navigator adds a dedicated navigation layer to RXPGuides without replacing or redistributing RestedXP guide content. It provides minimap and world-map routing, HUD guidance, future-goal previews, travel assistance, route overlays and corpse-run navigation.


WHAT'S NEW IN 1.4.0

Quest object markers
- RestedXP object-location loops can be shown as individual collectible/object nodes instead of connected lines.
- Supported visual classes include crystals, chests, herbs, mushrooms, eggs, containers, remains and a generic quest-object fallback.
- The nearest visible object is highlighted for orientation.

Grind XP HUD
- Dedicated XP progress display for active RestedXP grind steps.
- Shows current/target XP, percentage progress and grind instruction text.
- ETA is hidden during grind steps so the HUD remains focused on XP progress.
- Grind progress hides automatically when the threshold is reached or the guide leaves the grind step.

FEATURES

Native In-World Marker
- Optional Blizzard-native world-space navigation marker for the current RestedXP target
- Uses the built-in Forever navigation diamond and distance presentation
- Preserves/restores existing user waypoint or quest super-tracking where possible
- Optional compact target header with RestedXP target name, distance and approximate ETA

Navigation
- Direct navigation to the active RestedXP destination
- Minimap route line with directional indicators
- World and zone map route display
- Smoothed route rendering and target markers
- Same-continent zone/submap transitions remain normal navigation
- Cross-continent travel is handled separately through travel routing

Future Goals
- Preview upcoming RestedXP targets from +1 up to +6 steps ahead
- Future targets can be shown on the world map and minimap
- Off-screen minimap future targets are clamped to the minimap edge instead of disappearing
- Nearby future goals can be grouped to reduce map clutter

Travel Routing
- Detects Hearthstone, flight, Zeppelin, ship, portal and generic travel steps
- Travel Resolver normalizes transport metadata
- Travel Network exposes verified transport connections and RestedXP-provided travel points
- Smart Travel Planner can guide to the local departure point before the transport leg
- Travel HUD shows the immediate action, destination and platform information when available
- Normal navigation resumes after the transport/continent transition

HUD Navigation
- Three selectable HUD arrow styles
- Distance and ETA display
- Adjustable arrow and text size
- Movable and lockable HUD position
- Clear travel instructions for transport steps
- Dedicated Hearthstone presentation

World Map Overlays
- Farm/loop routes
- Patrol routes
- Search areas
- Mouseover tooltips for overlay paths and normal navigation routes
- Stable tooltip ownership at route crossings

Minimap Overlays
- Farm and patrol routes
- Main navigation route
- Current target marker
- Off-screen target indicator
- Future-step markers up to +6

Target & Tooltip System
- Central Target Resolver for current and future RestedXP targets
- Unified Tooltip Engine across navigation and overlays
- Quest, kill, loot/collect, talk, travel and other step types are normalized where supported by RestedXP data
- Objective text and progress can be shown when matching data is available

Corpse Run
- Automatic corpse navigation while ghosted
- Blood-red route styling
- Corpse distance and proximity feedback
- Optional Spirit Healer hint when the client exposes the required data
- Normal RestedXP navigation returns after resurrection

Settings
- Dedicated tabs for General, Minimap, World Map, HUD, Overlays, Corpse Run and Advanced
- Independent controls for route visibility, future goals, marker sizes and HUD presentation
- Presets were intentionally removed; settings are now controlled directly
- Restoring Defaults requires confirmation

Diagnostics
- /rxpnav maptest
- /rxpnav bugreport
- /rxpnav status
- Copyable diagnostics for compatibility reports

REQUIREMENTS
- WoW Forever
- RestedXP Guides / RXPGuides

QUICK COMMANDS
/rxpnav options
/rxpnav toggle
/rxpnav goals 0|1|2|3|4|5|6
/rxpnav maptest
/rxpnav bugreport
/rxpnav status
/rxpnav reset

IMPORTANT
RestedXP-Navigator is an unofficial companion addon. It does not include or redistribute RestedXP guide content.

The addon provides visual navigation only. It does not automate movement, combat, interactions or gameplay input.

No TomTom or RestedXP-TomTom dependency is required.


NPC ANCHOR TEST
---------------
Select a visible NPC and use:
/rxpnav npctest

The Blizzard-style marker will try to anchor directly to that NPC's visible
nameplate for 120 seconds. The marker turns into the green Assist style and
shows "NPC TEST: <name>" so the test state is obvious.

Status:
/rxpnav npctest status

Stop:
/rxpnav npctest off

If no nameplate is found, keep the NPC visible and enable friendly nameplates.


NPC TEST NOTE (1.5.19)
----------------------
The diagnostic temporarily enables the relevant Blizzard friendly/enemy
nameplate CVar for the selected NPC. The previous setting is restored when the
test stops, expires, or the UI session ends. An overhead NPC name by itself is
not necessarily a C_NamePlate frame; the actual Blizzard nameplate frame is
required for reliable screen-space anchoring.


FRIENDLY NPC NAMEPLATES (1.5.21)
--------------------------------
Friendly NPCs require the dedicated `nameplateShowFriendlyNpcs` CVar in
addition to the general friendly-nameplate setting. The NPC test enables both
temporarily and restores the previous values afterwards.


SAFETY / BLIZZARD API POLICY (1.5.23)
------------------------------------
RestedXP-Navigator deliberately stays inside Blizzard's supported addon model.

- No automatic combat actions, targeting, spell casting, item use or macro execution.
- No automatic ping sending.
- No attempts to measure restricted nameplate/world-frame geometry.
- No automatic changes to player nameplate CVars or other UI preferences.
- No manipulation of Blizzard's native SuperTrackedFrame alpha/state.
- The NPC anchor test is explicit diagnostic functionality only and works only
  with nameplates Blizzard already exposes under the player's own UI settings.
- If Blizzard marks an API/region as protected, restricted or secret, the addon
  falls back instead of trying to bypass that restriction.



NATIVE WAYPOINT VISUALS (1.5.24)
--------------------------------
The duplicate Blizzard SuperTrackedFrame visuals are hidden cosmetically only
while RestedXP-Navigator owns the waypoint. The addon uses post-update
`hooksecurefunc` hooks and hides only visible child regions. It does not alter
Blizzard's navigation-state alpha table or native navigation logic. If a region
is forbidden, the addon leaves it untouched.


NATIVE WAYPOINT VISUALS (1.5.25)
--------------------------------
When RestedXP-Navigator owns the user waypoint, Blizzard's visible
`SuperTrackedFrame` is hidden as a whole. The underlying `C_Navigation` frame
is not disabled or altered and remains the anchor for the custom marker.


NATIVE WAYPOINT VISUALS (1.5.26)
--------------------------------
The visible Blizzard SuperTrackedFrame child regions are suppressed with alpha
only while RestedXP-Navigator owns the waypoint. A cosmetic OnUpdate hook runs
after Blizzard's own frame update so the native distance text cannot reappear.
The underlying navigation frame and navigation state are not modified.


NATIVE WAYPOINT VISUALS (1.5.27)
--------------------------------
The native Blizzard SuperTrackedFrame is visually suppressed with the same
state-based mechanism that was validated in v1.5.15. The underlying user
waypoint and C_Navigation frame remain active; only the duplicate Blizzard
presentation is hidden while RestedXP-Navigator owns the waypoint.

WORLD MARKER INTELLIGENCE (1.6.0)
---------------------------------
For interactive RestedXP objectives, the navigator can attach its own marker to
an exact visible Blizzard NPC nameplate. The addon never reads restricted
nameplate geometry and never changes nameplate CVars. When no exact nameplate is
available, the existing user-waypoint/C_Navigation path remains the fallback.

CONTROL CENTER (1.6.0)
----------------------
The default options experience is now a standalone RestedXP-Navigator Control
Center with a sidebar, cards and a live Blizzard-style world-marker preview.
The implementation is original to RestedXP-Navigator and uses no third-party
code or assets.
