# RestedXP-Navigator v1.7.0-beta.2

- Adds optional local raid-symbol artwork for native in-world navigation markers and the target header.
- General settings: enable local raid symbols, then cycle through star, circle, diamond, triangle, moon, square, cross and skull.
- All target types use the selected symbol. Existing navigation, distance, beam and ground-ring behavior is preserved; the symbol retains its original colors.
- Disable the option to restore the existing objective-specific PingUI appearance. The default stays unchanged.
- These are private 2D navigation textures, not shared raid world markers or 3D raid-marker models. No group membership or raid permissions are required for this local appearance.
- Includes the group-sharing toolbar from beta.1.

Validation: Lua 5.1 parsing, group-marker regression tests, and mocked checks for all eight symbols, invalid saved settings, colors and style restoration passed. WoW Forever client testing remains required.
