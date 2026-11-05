# RestedXP-Navigator v1.7.0-beta.10 — beta.2 baseline, native-icon anchoring

This package was rebuilt directly from RestedXP-Navigator-v1.7.0-beta.2.zip. It is not an incremental modification of betas 3–9. The original beta.2 archive remains unchanged.

## Targeted changes

- Follow Blizzard's rendered SuperTrackedFrame.Icon when available; use the native navigation frame as a fallback. Use an independent 1x1 attachment frame and re-anchor only when the native icon/host object changes.
- Leave the Blizzard parent frame, parent alpha and navigation-state alpha table running unchanged. Suppress only stock artwork via reversible visibility guards, including when the native UI shows those elements again. No EasyFind code/artwork is copied or called.
- Use one production anchor path, rather than switching automatically between waypoint and NPC-nameplate attachment. The old explicit NPC test remains separate.
- Select the native waypoint once per target change instead of repeating the selection every quarter second. Respect switching to another super-tracked object.
- Hide the normal world marker when the native point is invalid, not shown or clamped off-screen. The existing beta.2 HUD arrow remains available.
- Correct the displayed version for this build.

The beta.2 marker artwork, scale/beam/ring settings, local raid-symbol choice, group toolbar and original navigation are preserved. Later EasyFind integration, precision-mode redesign, ground-height commands, diagnostic additions and other post-beta.2 changes are not included. Restoring beta.2 also restores its original behavior outside this narrow scope.

## Installation / verification

Disable the separately installed EasyFind [GPS] addon to prevent concurrent waypoint control/duplicate artwork. Replace the entire RXP_Navigator folder; do not merge old experimental files. Keep your SavedVariables if you want to preserve your settings, then /reload.

Test one unchanged waypoint while standing still, turning the camera and jumping. This implementation follows the observed native-icon anchoring and artwork-hiding principles independently; equivalent in-game precision and fixed terrain height are not yet verified. There is no new terrain-height calculation or own 3D renderer.

Validation: Lua 5.1 parsing; beta.2 raid-symbol/group-marker regressions; tests for icon/fallback attachment, keeping the native parent/state untouched, persistent artwork hiding and restoring requested visibility. Byte comparison against the beta.2 archive verifies that only Core/WorldMarkerVisual.lua, Core/WorldMarker.lua, Core/RXP_Navigator.lua and RXP_Navigator.toc change among baseline package files. One release-note file is added. ZIP and TOC are verified.
