# RestedXP-Navigator v1.7.0-beta.8 — native marker lifecycle test

- An unchanged waypoint is no longer selected as the super-tracked target every 0.25 seconds, including during legacy arrival hold. The engine target is selected once for each newly applied point/height. Manual changes to another tracking type are respected instead of repeatedly reasserting the user waypoint.
- Native marker artwork is hidden at the child-region level only. The Blizzard parent alpha and navigation-state alpha table are left unchanged; original child alpha values are restored when ownership ends.
- Fixes the hardcoded v1.6.11 startup/version display. Version now comes from addon metadata.
- `/rxpnav markerstatus` reports active/requested/client waypoint keys, native target-selection count, user-waypoint tracking, screen validity and clamping. Use before/after jumping and while standing still with camera movement to distinguish goal changes from projection movement.

These changes address concrete differences found during source comparison. They are NOT proof that character-height movement is solved; in-game testing is required. Different screenshots/camera angles alone cannot identify a changed world target. No EasyFind integration or external data/artwork is included.

Validation: Lua 5.1 parsing; LuaJIT regressions including 200 unchanged refreshes with a single native target-selection call, child-only suppression and restoration, waypoint ownership, local raid symbols, hearth binding and ground test behavior. ZIP integrity and TOC entries verified.
