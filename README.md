# RestedXP-Navigator

**RestedXP-Navigator** is a visual navigation companion for RestedXP Guides on WoW Forever. It adds minimap, world-map and HUD navigation without replacing or redistributing RestedXP guide content.

## Highlights

- Direct navigation to the active RestedXP destination
- Minimap and world-map route rendering
- HUD guidance with selectable arrow styles
- Future-goal preview from +1 to +6 steps
- Smart travel routing for Hearthstone, flights, Zeppelins, ships and portals
- Quest-object / collectible markers
- Grind XP HUD with progress and percentage display
- Corpse-run navigation
- Farm, patrol and search-area overlays
- Integrated diagnostics and bug-report export

## Requirements

- WoW Forever
- RestedXP Guides / RXPGuides

## Installation

1. Download the latest release archive.
2. Extract `RXP_Navigator` into your WoW `Interface/AddOns` folder.
3. Ensure RestedXP Guides is installed and enabled.
4. Start the game and configure the addon via `/rxpnav options`.

## Commands

```text
/rxpnav options
/rxpnav toggle
/rxpnav goals 0|1|2|3|4|5|6
/rxpnav maptest
/rxpnav bugreport
/rxpnav status
/rxpnav reset
```

## Screenshots

![RestedXP-Navigator](screenshots/RestedXP-Navigator_1.png)

![RestedXP-Navigator](screenshots/RestedXP-Navigator_2.png)

![RestedXP-Navigator](screenshots/RestedXP-Navigator_3.png)

## Project structure

```text
Core/
Debug/
Docs/
Map/
Media/
UI/
RXP_Navigator.toc
```

## Disclaimer

RestedXP-Navigator is an unofficial companion addon. It does not include or redistribute RestedXP guide content. The addon provides visual navigation only and does not automate movement, combat, interactions or gameplay input.

## License

All Rights Reserved. See `LICENSE`.
