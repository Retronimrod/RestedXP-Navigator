# RestedXP-Navigator v1.7.0-beta.6 — optional EasyFind GPS integration

## Installation and switch

Install EasyFind and EasyFind GPS separately through their official distribution channels, alongside RXPGuides and this Navigator. No EasyFind code, data or artwork is included in this package. The new option is OFF by default.

- `/rxpnav options` > General > Navigation über EasyFind GPS.
- `/rxpnav easyfind on` / `/rxpnav easyfind off` enable or disable the option.
- `/rxpnav easyfind status` reports adapter status.
- `/rxpnav easyfind resume` retries the current goal after a pause/failure. End an existing manual route in EasyFind first.

## Behavior

The independent adapter passes the current RestedXP goal to documented `EasyFind.API` actions. EasyFind handles route planning, travel choices, route progression and its own map/popout, arrow and world marker. Native Navigator route lines, HUD guidance and waypoint writing are suspended while external navigation owns the route. Goal submission is deduplicated; a changed goal waits for any earlier calculation to settle. Arrival does not advance the guide. Actual hearthstone-use steps, corpse navigation and the ground-height experiment retain the native path when no manual EasyFind route has priority.

Missing/incompatible API or a refused target falls back to the direct Navigator. A failed goal is not submitted repeatedly; a new goal or explicit resume retries. The adapter uses `navigate`, `canNavigate`, `destination`, `clear`, `routeStarted`, `arrived`, `routeCleared`, and public API registration helpers only. No `_ns` access, patching, copied solver, extracted route tables or foreign saved-variable writes.

Manual EasyFind routes pause automatic submission. Turning the bridge off clears only an identified owned route; a manual route is left alone. While such a manual route exists, native waypoint writers remain paused to avoid overwriting it, even after the bridge switch is off. End it in EasyFind to restore native navigation.

## Public API limitations

There is no documented calculation-cancellation endpoint or request token. Disabling mid-calculation waits for completion, then disposes of a matching late result. A calculation exceeding 60 seconds is reported as a timeout but remains guarded until a result settles; it is not safe to resume native waypoint writers while a late external result can still install its route. Request ownership uses goal map, rounded coordinates and name; an independently started, exactly identical named goal cannot be distinguished reliably. The first version therefore remains experimental.

Only the public destination and lifecycle events are available. Intermediate route geometry is not rendered by our Navigator. EasyFind preferences are not overwritten, and its separately installed visuals/settings remain authoritative. Enabling opens the documented EasyFind popout. Any terrain-height limitation of the native navigation frame remains unchanged.

## Validation and client checklist

Lua 5.1 syntax checks and LuaJIT mocked tests pass for opt-in/off, absent dependencies, async results, stale goals, matching late results after disable, manual takeover/clear, same-coordinate task changes, accepted/unsupported targets, hearth binding/use separation and timeout. Existing marker/ground-height regressions pass. This has NOT yet been tested against EasyFind inside WoW.

In game, verify: default-off behavior; missing dependency fallback; a normal local walking goal; a cross-zone travel goal; changing guide targets during planning; turning off during planning and active travel; manual route takeover; arrival without guide auto-completion; and return to native navigation. Install compatibility baseline examined: EasyFind GPS 1.3.2, public EasyFind API VERSION 1.
