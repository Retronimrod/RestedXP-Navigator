RestedXP-Navigator 1.4.0

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

