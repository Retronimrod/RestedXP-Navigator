# RestedXP-Navigator v1.7.0-beta.7

## Removed external navigation

Removed the optional EasyFind GPS adapter, settings switch, slash commands, optional dependencies, and adapter-owned saved-variable registration. No EasyFind API calls, source, route data or artwork remain in the runtime/package. The existing RestedXP-Navigator navigation, minimap/world-map lines and HUD work independently again. No other installed addon or its settings are modified.

IMPORTANT: Disable the separately installed EasyFind [GPS] addon in WoW's AddOns list to prevent it from continuing to render a stored route or manipulate the shared user waypoint. Replace the old RXP_Navigator folder with this package, then /reload. EasyFind itself may remain installed for unrelated features; its GPS extension must not navigate concurrently.

## Own world-marker positioning

The local world marker now prefers Blizzard's displayed SuperTrackedFrame.Icon as its anchor, falling back to the navigation frame when no icon is available. Anchoring is changed only when the underlying anchor object changes. This independently implemented use of Blizzard UI regions does not bundle or call EasyFind.

Precision appearance uses our own static two-layer light beam made from simple color textures/gradients, not EasyFind artwork or animations. The light beam is hidden within eight yards and when the navigation point is clamped to the screen edge. Local raid symbols remain selectable. The existing optional nameplate mode remains separate; no claim is made that EasyFind supplied an NPC anchor. Shared engine navigation still determines the point's height; terrain anchoring is NOT solved by this change.

Minimap cleanup now also hides additional farm/patrol/object overlays when the route is hidden, preventing stale drawn lines.

## Validation

All Lua files parse under Lua 5.1. LuaJIT regression tests cover Blizzard-icon/fallback anchors, static beam geometry and visibility, raid symbols/style restoration, hearth binding/use separation, waypoint ownership and ground-test behavior. Runtime/TOC scans find no EasyFind integration references. ZIP integrity and TOC file inclusion are checked. In-game visual verification remains required.
