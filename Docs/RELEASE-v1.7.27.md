# RestedXP-Navigator v1.7.27

- Fix the Navigator transport selector suggesting Horde zeppelins to Alliance characters.
- Detect the character faction automatically using the client's locale-independent faction token; no manual faction switch is needed.
- Add Alliance ship connections in both directions: Menethil Harbor–Auberdine, Menethil Harbor–Theramore, Auberdine–Rut’theran Village and Feathermoon–Feralas.
- Keep Ratchet–Booty Bay available to both factions. Unknown character factions receive only explicitly neutral connections until their faction is available.
- Apply faction filtering to both the travel network and its fallback selector, including the known departure list.
- Invalidate cached HUD/minimap travel planning when the character faction changes. Existing performance optimizations remain in place.
- Update the in-game release notice in all 12 supported client-language variants.
- SPF bridge remains 0.3.8. This fixes Navigator's own transport selection and does not change SPF's independent routing policy.

Boarding-location references: Shortest Path Forever v1.43.5, Data/Routes.lua (dry boarding surfaces) and Data/Zones.lua (map bounds), generated from Forever build 1.60.1.70938 game data:
https://github.com/cjber/shortest-path-forever/blob/v1.43.5/Data/Routes.lua
https://github.com/cjber/shortest-path-forever/blob/v1.43.5/Data/Zones.lua

Validation: Lua syntax and module initialization checks; Horde, Alliance and unknown-faction route filtering; neutral availability; route selection in both continent directions; fallback filtering and faction-change cache invalidation. In-game dock arrival positions have not been separately tested on an Alliance character.
