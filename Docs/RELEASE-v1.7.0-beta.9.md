# RestedXP-Navigator v1.7.0-beta.9

Fixes the normal world-marker symbol remaining visible at Blizzard's screen-edge/clamped navigation position when the camera turns away from the waypoint. Previously only the beam was hidden there. The whole world marker now hides on clamped, invalid, disabled or unreadable navigation positions, checked every rendered frame. It returns after the point has remained valid/unclamped for 150 ms, allowing the native anchor transition to settle. The existing HUD direction arrow remains independent.

This is a visibility/turn-away fix. It does NOT solve player-height coupling while jumping and does not claim terrain anchoring. No artificial screen-space jump compensation or height freeze is applied. EasyFind integration remains removed.

Validation: Lua 5.1 parsing and LuaJIT mocked regression tests pass, including clamping, invalid/disabled states, return-to-view delay and API failure. Package and TOC verified. In-game visual confirmation remains required.
