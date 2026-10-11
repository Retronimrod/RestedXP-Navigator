# RestedXP-Navigator Changelog

## 1.5.27
- Restored the exact native-waypoint suppression strategy that was already proven to work in v1.5.15.
- The regression was introduced when the safety-hardening pass removed the `SuperTrackedFrameMixin:SetTargetAlphaForState()` suppression that prevented Blizzard's own alpha lerp from restoring the gold waypoint and distance.
- While RestedXP-Navigator owns the waypoint, Blizzard navigation states Invalid/Occluded/InRange/Disabled are visually suppressed and the native frame/child alpha is enforced at 0.
- The native `C_Navigation` waypoint itself remains active and still provides the world-space anchor for the RestedXP-Navigator marker.
- Original Blizzard alpha values are restored when RestedXP-Navigator releases the waypoint or the UI session ends.
- Later NPC-test/nameplate safety changes remain intact.

## 1.5.26
- Fixed the remaining duplicate gold Blizzard distance text under the RestedXP-Navigator marker.
- Instead of hiding the whole `SuperTrackedFrame`, the addon now sets only the visible child regions (`Icon`, `IconBorder`, `DistanceText`, `Arrow`) to alpha 0 while it owns the waypoint.
- Added a cosmetic `OnUpdate` hook on Blizzard's actual `SuperTrackedFrame`, so suppression is applied immediately after Blizzard updates the distance text each frame.
- Blizzard navigation logic, navigation-state alpha tables, frame geometry and protected/restricted regions remain untouched.
- Native child-region alpha is restored to 1 when RestedXP-Navigator releases the waypoint.

## 1.5.25
- Fixed Blizzard's gold waypoint icon and gold distance remaining visible underneath the RestedXP-Navigator marker.
- While RestedXP-Navigator owns a waypoint, the addon now hides Blizzard's entire `SuperTrackedFrame` presentation frame instead of hiding individual child regions.
- The underlying `C_Navigation` frame remains active and continues to provide RestedXP-Navigator's world-space anchor.
- No Blizzard navigation-state alpha tables are modified, no protected/restricted geometry is measured and no nameplate CVars are changed.
- The native presentation frame is restored when RestedXP-Navigator releases ownership.

## 1.5.24
- Restored hiding of Blizzard's duplicate gold waypoint visuals using a narrower cosmetic-only approach.
- Uses `hooksecurefunc` after Blizzard's own `SuperTrackedFrameMixin` updates and only hides the visible Icon, IconBorder, DistanceText and Arrow while RestedXP-Navigator owns the waypoint.
- Does not modify Blizzard navigation-state alpha tables, does not alter nameplate CVars, does not measure restricted regions and does not replace native navigation logic.
- All region operations are guarded and skipped if Blizzard marks a region forbidden.
- The native C_Navigation/SuperTrack waypoint remains fully active underneath and continues to provide the world-space anchor.

## 1.5.23
- Safety hardening pass for Blizzard addon-policy compliance.
- Removed all automatic changes to `nameplateShowFriends`, `nameplateShowFriendlyNpcs` and `nameplateShowEnemies`.
- Removed manipulation/suppression of Blizzard's native `SuperTrackedFrame` alpha and navigation-state presentation.
- The native Blizzard super-tracking presentation is allowed to behave normally again; RestedXP-Navigator no longer fights Blizzard's frame update logic.
- NPC anchoring remains diagnostic-only and read-only: `/rxpnav npctest` only uses nameplates already exposed by the player's own UI settings.
- Retained the safe nameplate-child diagnostic approach and kept all restricted frame geometry measurements removed.
- Documented the addon safety policy: no combat automation, no secure/protected API bypasses, no automatic pings, no restricted-region measurements and no silent UI preference changes.

## 1.5.22
- Shortened the vertical line under the NPC test marker by 50%.
- The Blizzard Assist test marker remains unchanged, but the pin/stem texture now renders at half height for a cleaner presentation over friendly and hostile NPCs.

## 1.5.21
- Fixed the NPC-anchor diagnostic for friendly NPCs.
- Friendly NPCs require Blizzard's dedicated `nameplateShowFriendlyNpcs` CVar in addition to `nameplateShowFriends`; the previous test only enabled the general friendly switch.
- `/rxpnav npctest` now temporarily enables both CVars for friendly NPC targets and restores the player's original settings afterwards.
- `/rxpnav npctest status` now reports the current Friends/FriendlyNPCs/Enemies CVar values for easier diagnosis.

## 1.5.20
- Fixed the NPC-test Lua taint caused by measuring restricted Blizzard nameplate regions (`NamePlate:GetCenter()`).
- The diagnostic no longer reads nameplate geometry at all.
- `/rxpnav npctest` now attaches the green Blizzard Assist test marker as a child of the selected NPC's actual nameplate frame, allowing WoW itself to maintain the world-space position.
- Removed screen-distance ranking and other nameplate frame measurements that can trigger `Action[FrameMeasurement] failed because [Can't measure restricted regions]`.
- Automatic production NPC snapping is temporarily conservative: it keeps the native waypoint rather than touching restricted nameplate geometry. The dedicated NPC test is now the safe path for validating direct nameplate attachment.

## 1.5.19
- Improved `/rxpnav npctest` for NPCs that show only an overhead name but no actual Blizzard nameplate frame.
- The test now temporarily enables the appropriate Blizzard nameplate CVar (`nameplateShowFriends` or `nameplateShowEnemies`) for the selected NPC.
- Previous nameplate settings are restored automatically when the test stops, times out or the UI session ends.
- When the target's Blizzard nameplate is created, the diagnostic immediately detects it and anchors the green Assist test marker to its screen position.
- Added clearer chat diagnostics distinguishing an overhead NPC name from an actual C_NamePlate frame.

## 1.5.18
- Fixed the manual NPC-anchor test not rendering despite reporting a found nameplate.
- The cause was Lua lexical scope: `UpdateNPCTestFrame()` referenced `FindNamePlateByGUID()` and `IsNPCTestActive()` before those local functions had been declared, so the test updater resolved them as nil globals and failed silently inside `pcall`.
- Added proper forward declarations for the NPC-test helpers.
- NPC-test errors are now printed to chat instead of being silently swallowed.
- `/rxpnav npctest` now performs an immediate render attempt and reports whether the marker was actually displayed.

## 1.5.17
- Reworked `/rxpnav npctest` into a completely independent diagnostic overlay.
- The NPC test no longer depends on the current RestedXP waypoint, native world-marker ownership or automatic NPC-snap logic.
- The test marker copies the selected NPC nameplate's current screen coordinates onto a normal UIParent frame every update instead of anchoring directly to the recycled WorldFrame nameplate.
- This avoids nameplate frame restrictions/recycling issues and makes the test result unambiguous.
- The diagnostic marker uses Blizzard's green Assist ping assets and displays `NPC TEST: <name>` next to the NPC.

## 1.5.16
- Added a dedicated manual NPC-anchor test mode.
- Target any NPC and run `/rxpnav npctest` to force the RestedXP-Navigator marker to that NPC's visible nameplate for up to 120 seconds.
- Test mode uses the green Blizzard Assist marker and shows `NPC TEST: <name>` next to it for clear visual verification.
- Added `/rxpnav npctest status` and `/rxpnav npctest off`.
- The test reports whether a usable nameplate is currently visible, making it easier to diagnose multi-floor NPC anchoring independently from RestedXP metadata.

## 1.5.15
- Fixed the remaining semi-transparent/flickering Blizzard gold waypoint underneath the RestedXP-Navigator marker.
- Native SuperTrackedFrame suppression now uses Blizzard's own NavigationState alpha table, setting Invalid/Occluded/InRange/Disabled target alpha to zero while RestedXP-Navigator owns the waypoint.
- Icon, distance text and clamped arrow alpha are additionally enforced to zero every marker refresh to eliminate one-frame alpha interpolation flashes.
- Blizzard's normal navigation alpha values are restored automatically when RestedXP-Navigator releases the waypoint or the addon session ends.

## 1.5.14
- Hid Blizzard's default gold SuperTrackedFrame icon and its duplicate distance text while RestedXP-Navigator owns the waypoint.
- The underlying native C_Navigation world position remains active and continues to anchor the RestedXP-Navigator marker.
- Added distance directly beside the RestedXP-Navigator Blizzard-ping marker.
- Distance text inherits the marker color: blue for travel/non-threat, green for assist/turn-in, orange for attack and red for warnings.
- Kept the existing close-range stem and NPC-snap logic unchanged.

## 1.5.13
- Fixed a critical regression in 1.5.12 that unconditionally hid the Blizzard-style world marker after the NPC-snap anchor calculation.
- Restored the normal marker rendering path for both native 2D waypoint fallback and smart NPC snapping.
- Added a defensive protected refresh so a transient nameplate/API error cannot permanently break the marker update loop.

## 1.5.12
- Fixed a regression where smart NPC snapping could make the world marker disappear.
- The Blizzard navigation marker is now always anchored to the valid native C_Navigation frame first; NPC snapping is only applied as a safe optional refinement.
- NPC snapping is now conservative: only an exact RestedXP NPC-name match or an active-quest-related visible nameplate may replace the native 2D anchor.
- Hidden, transparent, recycled or off-screen nameplates are rejected automatically.
- Removed the broad nearest-friendly-NPC fallback because it could select the wrong unit or an unusable nameplate.
- The Blizzard stem remains visible for nearby snapped NPC targets, while the close-range ground-lift correction is disabled during NPC snapping.

## 1.5.11
- Added smart vertical NPC snapping for close-range RestedXP interaction targets.
- RestedXP map coordinates are fundamentally 2D, so multi-floor NPCs can otherwise appear on the ground floor even when the NPC is upstairs.
- Within 40 yd, Turn-in, Accept, Talk, Buy/Vendor, Trainer and similar interaction steps can now snap the Blizzard-style marker to a matching visible nameplate.
- Exact RestedXP NPC names are preferred; quest-related friendly units are the next priority, with a nearby friendly-NPC fallback for vendor/trainer-style instructions.
- When snapped to an NPC, the long ground stem is hidden so the marker follows the NPC's actual on-screen vertical position instead of pointing to the 2D terrain waypoint.
- Normal travel, kill, loot, corpse and other positional targets continue to use the existing world waypoint behavior.

## 1.5.10
- Improved close-range positioning of the Blizzard world marker.
- The Blizzard ground stem now dynamically extends upward below roughly 28 yd while its bottom remains anchored to the actual target position.
- This prevents the marker head from visually sinking into the ground as the player approaches the destination.
- The correction ramps in smoothly and reaches its strongest effect only at very short range.

## 1.5.9
- Replaced the custom RestedXP-Navigator world-marker artwork with the actual Blizzard PingUI atlases already shipped in the WoW client.
- Travel/Goto uses Blizzard's OnMyWay marker, Kill uses Attack, Turn-in uses Assist, Dangerous/Elite/Boss uses Warning, and general interaction/loot/talk objectives use NonThreat.
- The close-range vertical position line now uses Blizzard's `Ping_GroundMarker_Pin_*` asset instead of a custom beam.
- The circular marker background and stroke use Blizzard's `Ping_GroundMarker_BG_*` and `Ping_GroundMarker_Stroke_*` atlases.
- No Blizzard image files are copied into the addon; the addon references the client's built-in atlases directly.
- At more than 65 yd only the marker head is shown; at 65 yd or closer the Blizzard ground pin/stem is added.

## 1.5.8
- Reworked the world-marker context assets around Blizzard's visual language while keeping all artwork original to RestedXP-Navigator.
- Added distinct marker styles for generic objectives, travel, quest turn-in, kill, warning/dangerous targets, loot/collect, talk/interact, accept, flight, portal, hearth, transport and corpse navigation.
- Kill targets use an amber sword marker, turn-ins use a green flag, travel uses a blue downward arrow, dangerous/elite/boss-style objectives use a red warning marker, and generic objectives retain a blue diamond style.

## 1.5.7
- Updated the custom world-marker art to a more Blizzard-inspired visual language while remaining fully original RestedXP-Navigator assets.
- The world-space beam now appears only at close range (default: 65 yd). At longer distances only the floating marker/icon remains visible.
- Improved the marker silhouette to better match Blizzard-style navigation pings: thinner beam, smaller floating icon and a darker circular badge with a clearer glow ring.
- The beam toggle now controls only the beam itself; the floating marker icon can remain visible even when the target is farther away.

## 1.5.6
- Adjusted the custom in-world marker visual so the beam rises upward from the target point instead of extending downward into the ground.
- The halo/context icon now floats above the target point, creating a clearer world-space marker for corpse runs and normal navigation.
- Minor visual tuning for the marker pulse and overlay sizing.

## 1.5.5
- Fixed the custom world-marker beam/context overlay not appearing reliably: the RestedXP-Navigator visual now anchors to Blizzard's navigation frame from UIParent instead of being parented inside the native frame.
- Added corpse world-marker support. While dead, the Navigator now uses the resolved corpse position as its native user waypoint, so the in-world marker/beam can guide the corpse run as well as the existing HUD and minimap guidance.
- Added an original RestedXP-Navigator corpse/skull context icon.
- The world-marker overlay re-anchors continuously so it follows recycled or repositioned Blizzard navigation frames reliably.

## 1.5.4
- Added original RestedXP-Navigator world-marker artwork; no WaypointUI code or assets are included.
- Added an optional animated cyan world-space beam, halo and context icon attached to Blizzard's native navigation frame.
- Added a fully original context-icon set for Kill, Loot, Travel, Talk, Accept, Turn-in, Flight, Portal, Hearth and transport targets.
- Added dynamic ETA based on actual progress toward the active RestedXP target with smoothed measured movement speed.
- Improved arrival detection: the old native marker is released at close range, after passing very close to it, or after the 30-second safety timeout.
- During marker handover the new RestedXP target can already be shown in the header/HUD while the previous native marker remains visible.

## 1.5.3
- Added native-marker handover: when RestedXP advances to a new target, the previous in-world marker can remain briefly while the new target is already shown in the Navigator header/HUD.
- The previous native marker is released as soon as the player reaches roughly 8 yd from it, or after a maximum of 30 seconds.
- This avoids abrupt marker jumps while respecting Blizzard's one-native-user-waypoint limitation.

## 1.5.1
- Added context-sensitive icons to the in-world target header.
- Travel/walking, kill, loot/collect, talk, quest accept/turn-in, flight, portal, Hearthstone and transport targets now use matching icons.
- Kept the native Blizzard in-world navigation marker and RestedXP target header behavior unchanged.

## 1.5.0
- Added an optional native in-world RestedXP target marker using Blizzard's built-in Forever navigation system.
- The marker follows the current RestedXP navigation point and uses Blizzard's native diamond/distance presentation.
- Smart travel routes prefer the immediate travel approach point where available.
- The feature is disabled by default and can be enabled under General -> Native in-world target marker.
- Existing quest/user super-tracking is preserved and restored where possible when the feature releases control.
- Added an optional streamer-style target header with RestedXP target name, distance and approximate ETA above the native world marker.

## 1.4.0
- Promoted the tested 1.4.0 development line to the stable 1.4.0 release.
- Added quest-object / collectible markers for RestedXP object-location loops on the World Map and Minimap.
- Added object classification, contextual tooltips and nearest-object highlighting while keeping non-object overlays unchanged.
- Added a dedicated Grind XP HUD with live XP progress, current/target XP, percentage display and grind instruction text.
- Grind steps hide ETA so the HUD remains focused on XP progress; normal navigation keeps the regular ETA display.
- Improved Grind HUD readability with larger progress text, a larger progress bar and increased spacing below navigation distance.
- Synchronized all public and internal version strings to 1.4.0 and removed obsolete beta labels from user-facing diagnostics.

### 1.4.0 development history
## 1.4.0-beta5
- Increased the vertical spacing between the navigation distance and the Grind XP block.
- The XP progress text, percentage bar and grind instruction now sit visibly lower for a cleaner HUD layout.
- Normal navigation HUD spacing is unchanged.

## 1.4.0-beta4
- Grind HUD now hides ETA while an active RestedXP grind step is being tracked.
- Increased Grind XP progress text and action text for better readability.
- Enlarged the Grind XP progress bar.
- Added a centered percentage display directly on the progress bar.
- Normal navigation steps keep the regular ETA display unchanged.

## 1.4.0-beta3
- Added a dedicated Grind XP HUD for RestedXP grind steps.
- Grind steps such as `Grind to 1680+/2800xp` now show a slim progress bar below the navigation HUD.
- The HUD displays current progress as `997 / 1680 XP` and a gold action line such as `Kill mobs to reach 1680+ / 2800 XP`.
- Grind progress updates automatically from the player's current XP and hides when the target threshold is reached or the guide leaves the grind step.
- Travel/Hearthstone HUD modes suppress the Grind XP block so the two presentations cannot overlap.

## 1.4.0-beta2
- Reduced quest-object markers substantially on both World Map and Minimap.
- Normal object nodes are now intentionally subtle and semi-transparent.
- Only the nearest object keeps a small gold focus ring.
- Mouseover hit areas remain larger than the visible markers for usability.


## 1.4.0-beta1
- Added a generic quest-object / collectible marker system for RestedXP object-location loops.
- Object-location loops are rendered as individual markers instead of misleading connected route lines.
- Added automatic object classification for crystals/minerals, chests/caches, plants/herbs, mushrooms, eggs, containers, remains/corpses and a neutral fallback.
- Added object markers on both World Map and Minimap.
- The nearest visible object is highlighted with a gold ring; other object locations use a cyan ring.
- Added object tooltips with object type, instruction, quest progress and minimap distance when available.
- Added a dedicated "Quest object markers" option in the Overlays tab.
- Existing farm, patrol, search and normal navigation routes remain unchanged when a loop is not confidently identified as an object-collection loop.

## 1.3.0
- Major navigation architecture update with modular Core, UI, Map and Debug components.
- Added a central Target Resolver and unified tooltip engine for consistent target information across world map, minimap and route overlays.
- Added Travel Resolver, Travel Network and Smart Travel Planner for Hearthstone, flight, Zeppelin, ship, portal and generic travel steps.
- Cross-continent travel can now route to the relevant local departure point instead of drawing misleading straight-line routes.
- Added actionable Travel HUD information including destination and platform/departure details when available.
- Added three selectable HUD arrow styles and improved HUD readability.
- Added world-map farm/loop, patrol and search-area overlays plus minimap farm/patrol overlays.
- Added stable geometric mouseover tooltips for navigation and overlay paths, including fixes for tooltip flicker at route crossings and during redraws.
- Improved same-continent zone/submap routing using Blizzard UI-map hierarchy instead of relying on raw world-space IDs.
- Improved future-step navigation: +1 to +6 targets can be shown on the minimap and world map, with off-screen minimap goals clamped to the minimap edge.
- Rebuilt the settings interface into dedicated tabs and removed the preset system in favor of direct controls.
- Added confirmation before restoring default settings.
- Expanded diagnostics and bug-report exports.
- Fixed multiple routing, overlay, Lua parser, minimap and tooltip regressions found during beta testing.

---

## 1.3.0-beta42-hotfix14
- Future-step markers on the minimap now remain visible even when the next target is outside the current minimap radius; off-screen future goals are clamped to the minimap edge.
- Fixed future-target projection across neighbouring Forever zone/submap world-space IDs by using Blizzard UI-map continent hierarchy instead of raw world-space IDs.
- Added a local-map distance fallback for future targets when direct world-space distance is unavailable.
- Updated the internal diagnostics version string to the actual hotfix version.

## 1.3.0-beta42-hotfix13
- Fixed Minimap Next Steps being filtered out by the navigation RouteResolver.
- +1 to +6 minimap markers now read the next actual RestedXP guide targets directly.
- Loop/farm/overlay guide steps can now appear as future minimap targets without being inserted into the main navigation route.
- Main route geometry and Travel routing are unchanged.

## 1.3.0-beta42-hotfix12
- Fixed Minimap Next Steps being enabled while the configured future-goal count was still 0.
- Added a one-time migration that restores +3 future goals for this contradictory state.
- Added a Future Goals amount selector directly to the Minimap settings tab.
- Enabling Minimap Next Steps now automatically selects +3 when the amount was 0.
- Selecting 0 future goals disables Minimap Next Steps; selecting +1 to +6 enables it.

## 1.3.0-beta42-hotfix11
- Removed the preset system completely (Custom, Minimal, Classic, Full Navigation and Streamer).
- Removed the preset dropdown and descriptions from the General settings tab.
- Removed preset slash commands, preset diagnostics and the obsolete preset module.
- Defaults/Standardwerte remain available with confirmation dialog.

## 1.3.0-beta42-hotfix10
- Fixed Lua parser error in `Map/MapOverlays.lua` introduced by hotfix9.
- Corrected nested tooltip ownership logic while preserving the anti-flicker hover state.
- No route geometry, travel routing or preset behavior was intentionally changed.

## 1.3.0-beta42-hotfix9
- Fixed persistent world-map overlay tooltip flicker caused by `MapOverlays:Render()` clearing tooltip state on every redraw.
- Overlay redraws now refresh only visual pools while preserving active hover ownership.
- Hover ownership now follows the logical RestedXP element rather than transient render-entry tables.

## 1.3.0-beta42-hotfix8
- Stabilized overlay-path tooltips with hover hysteresis and a short leave delay.
- Overlay tooltips now take priority over the normal route tooltip at crossings, preventing tooltip ownership flicker.
- No routing or map geometry behavior was intentionally changed.

## 1.3.0-beta42-hotfix7
- Fixed MinimapOverlays DrawFarm crash caused by the blue color variable shadowing the route point variable `b`.
- Applied the same safe color-variable handling to patrol rendering to prevent the same class of error.
- Overlay tooltip behavior from hotfix6 remains enabled.

## 1.3.0-beta42-hotfix6
- Added geometric mouseover tooltips for world-map overlay paths (farm/loop, patrol and search-area outlines).
- Overlay tooltips now use the same RestedXP tooltip engine as the main navigation route.
- No route rendering or travel-planner behavior was intentionally changed.

## 1.3.0-beta42-hotfix5
- Fixed normal navigation disappearing around same-continent zone/submap transitions such as Hillsbrad Foothills and Alterac Mountains.
- Cross-continent Travel Mode now uses Blizzard's UI-map hierarchy as the primary continent check instead of treating raw world-space IDs as authoritative.
- World-space IDs are retained only as a conservative fallback when the map hierarchy cannot identify both continents.
- Travel routing, HUD presentation and preset UI from previous hotfixes remain intact.

## 1.3.0-beta42-hotfix4
- Added dynamic descriptions for the General-tab presets (Custom, Minimal, Classic, Full Navigation and Streamer).
- Added a confirmation dialog before restoring all settings to defaults.
- No navigation, routing, Travel HUD or map behavior was intentionally changed.

## 1.3.0-beta42-hotfix3
- Replaced the Unicode travel arrow with ASCII `->` to avoid missing-glyph placeholders in WoW Forever.
- Increased travel-distance readability with a larger outlined font.
- Restored actionable travel guidance below the HUD: departure point, platform and transport destination.
- Network travel objectives now resolve to the actionable transport instruction instead of only the final zone objective.

## 1.3.0-beta42-hotfix2
- Restored minimap navigation lines during cross-continent travel by routing to the selected local transport departure point.
- Restored world-map navigation lines to the same departure point instead of suppressing all route geometry in Travel Mode.
- Travel HUD now shows the immediate transport leg (for example `Zeppelin → Undercity`) instead of the final zone destination.
- Removed the small three-line Start/Platform/Then context block and increased travel-title readability with an outlined font.

## 1.3.0-beta42-hotfix1
- Fixed a Lua parser error in `UI/Presentation.lua` caused by using the reserved keyword `then` as an unquoted table key.
- No navigation, routing, HUD or map behavior was intentionally changed.

## 1.3.0-beta42
- Added a shared presentation layer for navigation, travel, search, patrol, farm and corpse visuals.
- Unified travel labels/icons in HUD and travel metadata in tooltips.
- World-map and minimap overlay colors now use the same palette.
- Beta42 includes all beta39-41 Travel Resolver, Travel Network and Smart Travel Planner work.

## 1.3.0-beta41
- Added a central best-route Travel Planner.
- Cross-continent plans are represented as approach -> transport -> onward stages.
- HUD cross-continent guidance now consumes the planner while retaining the safe legacy fallback.
- Explicit RestedXP travel instructions remain authoritative and are never replaced by guessed transport actions.

## 1.3.0-beta40
- Added a dedicated Travel Network module.
- Existing verified zeppelin and ship links are exposed as structured network routes.
- Explicit RestedXP travel elements are exposed as dynamic travel points.
- Cross-continent route selection now delegates through the network layer while retaining the established safe fallback.

## 1.3.0-beta39
- Added a central Travel Resolver for Hearthstone, flight, zeppelin, ship, portal and generic travel steps.
- Travel metadata now exposes destination, transport kind, coordinates and cross-continent context without changing established navigation behavior.

## 1.3.0-beta38
- Added a central TargetResolver that normalizes current and future RestedXP navigation targets into one Navigator-owned model.
- Added a unified TooltipEngine for route, world-map and minimap future-target tooltips.
- Tooltips now use the same target type, instruction, objective, step and travel metadata across renderers.
- Added narrow API accessors for normalized RXP metadata without exposing core lexical internals.
- Kept route rendering and navigation behavior unchanged from beta37.

## 1.3.0-beta37 – Core Cleanup & Stabilization
- Moved inspector capture/export and RestedXP inspection code into `Debug/Inspector.lua`.
- Moved status, map diagnostics, bug-report generation and corpse-run diagnostics into `Debug/Diagnostics.lua`.
- Reduced the main Core chunk's top-level local-variable pressure to create headroom for future development.
- Added a narrow Core-to-module API for diagnostics instead of direct lexical access.
- Removed development preview PNGs from the runtime Media folder.
- Added architecture documentation.
- No intentional change to navigation behavior, map rendering, HUD arrows or settings.

## 1.3.0-beta35
- Increased the visible size of the Crystal Glow HUD arrow so it reads clearly in-game.
- Re-centered the Compass Bronze HUD arrow around the compass hub so rotation pivots from the compass center.

## 1.3.0-beta34
- Rebuilt all three HUD arrow styles as WoW-compatible 32-bit TGA textures with alpha transparency.
- Classic Clear is neutral-tinted so the custom HUD arrow color setting remains functional.
- Compass Bronze and Crystal Glow now use their own baked visual styles without black backgrounds or source-image artifacts.
- All HUD arrow assets use the existing 256x144 right-facing rotation baseline expected by the navigator.

## 1.3.0-beta33
- Rebuilt the addon settings UI around seven dedicated tabs instead of one long scrolling page.
- Added tabs for General, Minimap, World Map, HUD, Overlays, Corpse Run and Advanced.
- Grouped related controls onto their own pages to reduce clutter and improve usability.
- Removed the oversized settings scroll child from the previous layout.
- Kept all existing settings and behavior available through the new tab layout.

## 1.3.0-beta32
- Refactored the addon into Core, UI, Map, Media and Docs folders.
- Moved the complete settings/options UI out of the main Lua chunk to reduce local-variable pressure.
- Added a narrow cross-file API for options without exposing core internals directly.
- Moved all TGA assets into Media and updated texture paths.
- Kept SavedVariables for diagnostics instead of runtime log files, since WoW addons cannot write arbitrary log files.

## 1.3.0-beta31
- Added three selectable HUD arrow styles: Classic Clear, Compass Bronze and Crystal Glow.
- Added a HUD arrow style dropdown in the addon settings.
- Preserved beta30 as the default arrow style and kept corpse-run tinting intact.

## 1.3.0-beta30
- Refreshed the on-screen navigation arrow with a cleaner polished cyan-blue HUD design.
- Preserved the existing arrow rotation, size, color settings, corpse-run behavior, distance and ETA logic.
- Updated internal addon version metadata to 1.3.0-beta30.

## 1.3.0-beta29
- Replaced the Hearthstone Travel HUD icon with the new polished Hearthstone artwork.
- Travel HUD now resolves the Hearthstone destination more reliably from direct hearth step text and localized step labels.
- Hearthstone announcements now display the target destination again (for example: "Use your Hearthstone to Thunder Bluff").
- Kept the single-line localized message style and hidden secondary grey line.

# Changelog

## 1.3.0-beta28
- Fixed Lua syntax warning introduced in beta27 by removing a duplicated legacy Hearthstone HUD block.
- Fixed Hearthstone HUD fallback texture path escaping.
- Keeps the custom Hearthstone artwork, localized destination message, and single-line Travel HUD layout.

## 1.3.0-beta27
- Added a custom Hearthstone Travel HUD icon with transparent edges and localized Hearthstone-to-destination messaging.
- Travel HUD now hides the secondary grey context line for Hearthstone announcements.

RestedXP-Navigator

## 1.3.0-beta26
- Fixed Hearthstone Travel HUD detection for RestedXP #completewith steps.
- Travel HUD now reads RXPFrame.activeSteps, matching what RestedXP actually displays in the guide window.
- Keeps RXPG_ARROW.element as a compatibility fallback only.

# RestedXP-Navigator

## 1.3.0-beta25
- Added Travel HUD announcements for Hearthstone guide steps.
- Hearthstone steps now replace the directional arrow with a Hearthstone icon and clear instruction.
- Displays destination when it can be extracted from the active RestedXP instruction.
- Hides distance/ETA-style navigation for Hearthstone actions because they are not walking routes.

# RestedXP-Navigator

## 1.3.0-beta24
- Added farm routes to the minimap as subtle green path lines.
- Added patrol routes to the minimap as subtle amber dashed paths.
- Search areas remain World Map only.
- No extra minimap labels, icons, or markers are added for these overlays.
- Farm/patrol overlays are hidden during corpse-run navigation.

# RestedXP-Navigator

## 1.3.0-beta23
- Replaced World Map route hover hitboxes with direct cursor-to-route geometry detection.
- Cyan route tooltip now uses the actual smoothed route geometry instead of invisible frames.
- Removed the baked-in gold inner ring from the minimap Navigator icon.
- Retained the separate neutral dark/silver outer minimap-button ring.
- No hover glow or button animation.

# RestedXP-Navigator

## 1.3.0-beta22
- Fixed route tooltip Lua error: removed Button-only RegisterForClicks call from hover frames.
- Fixed minimap button texture paths in the modular button file.
- Kept the minimap button neutral, dark/silver, round, draggable, and non-animated.
- No navigation behavior changes.

# RestedXP-Navigator

## 1.3.0-beta21
- Reworked active-route hover hitboxes: hover frames are now parented directly to the Blizzard map canvas for reliable cyan-route tooltips.
- Added a custom neutral silver/dark minimap button ring with no gold glow.
- Kept the minimap button static on hover and draggable around the minimap rim.

# RestedXP-Navigator

## 1.3.0-beta20
- Fixed corpse-run map validation: invalid negative/out-of-map corpse coordinates are no longer cached or rendered.
- Fixed the modular bug-report normalization call.
- Rebuilt the minimap settings button as a compact static circular rim button without the clipped TrackingBorder artwork.
- Minimap button remains draggable around the minimap radius and has no hover animation.
- Future-step minimap overlays remain suppressed during corpse runs so corpse navigation stays authoritative.

# RestedXP-Navigator

## 1.3.0-beta19
- Reworked the minimap button to use a Blizzard-style round minimap edge frame.
- Kept the button static on mouseover; no hover animation or glow.
- Added visible, subdued route segments between minimap upcoming-goal markers.
- Fixed world-map active-route tooltips by moving hover hitboxes to TOOLTIP strata and increasing hover coverage.

# RestedXP-Navigator

## 1.3.0-beta18
- Removed the permanent KILL/TRAVEL action pill from the world map.
- Added mouseover tooltips directly along the active cyan route.
- Reworked the minimap settings button: round logo, fixed circular border, positioned on the minimap rim.
- Removed hover highlight/animation from the minimap button.
- Dragging still moves the button around the minimap radius and saves its angle.

# RestedXP-Navigator

## 1.3.0-beta17
- Added upcoming RestedXP goal markers to the minimap using the existing Upcoming Goals setting.
- Future minimap targets are shown only when they are inside the current minimap view to avoid edge clutter.
- Added readable action text (Travel, Kill, Loot, Talk, Accept, Turn In) to the current World Map destination.
- Reworked the minimap settings button with a circular Navigator logo.
- Minimap button can now be dragged around the minimap; its angle/position is saved.
- Left click opens settings; right click toggles the Navigator.

# RestedXP-Navigator

## 1.3.0-beta16
- Fixed invalid texture sublevel used by the new action badge (WoW supports -8..7 only).
- Fixed the action-badge texture path.
- Restricted action badges to the current World Map target marker; minimap markers remain clean.
- Prevents targetDot initialization failure and its resulting repeated minimap errors.

# RestedXP-Navigator

## 1.3.0-beta15
- Added a compact action badge to the current cyan destination marker.
- Badges distinguish Kill, Loot/Collect, Talk, Accept, Turn-in and Travel actions.
- Future target markers remain icon-free to keep the map clean.
- Quest progress and step numbers remain tooltip-only.

# RestedXP-Navigator

## 1.3.0-beta14
- Fixed MapOverlays startup/runtime error caused by a missing GetTargetMap bridge in the modular Core API.
- Restored loop/farm overlay projection for #loop guide steps.
- Verified every modular API call has a matching Core API export.
- Keeps #loop geometry separated from the normal cyan navigation route.

# RestedXP-Navigator

## 1.3.0-beta13 - Loop Route Separation
- RXP `#loop` steps are no longer appended to the normal cyan navigation route.
- Optional grind loops are rendered as dedicated green farm-route overlays.
- Active loop steps keep only the current RXP waypoint as direct HUD/minimap guidance.
- Future route resolution skips loop geometry while continuing with later real navigation targets.
- Loop rendering is derived from the actual ordered `.goto` points contained in the RXP step.

# RestedXP-Navigator

## 1.3.0-beta12
- Fixed a modularization startup error where BuildSegmentPath was still defined in the core before the RouteSmoother module loaded.
- RouteSmoother functionality now lives entirely inside its dedicated module.
- No navigation behavior changes.

# RestedXP-Navigator

## 1.3.0-beta11
- Refactored the addon into multiple Lua modules to permanently avoid WoW's 200-local main-chunk limit.
- Split route smoothing, RestedXP world-map filtering, map overlays and the minimap settings button into dedicated files.
- Added a narrow cross-file API instead of exposing core implementation details.
- Preserved the Beta 10 Search Area, Patrol Path and Farm Route overlays and their opacity controls.
- Preserved the minimap settings button and all existing navigation fallbacks.

# RestedXP-Navigator

## 1.3.0-beta10
- Added experimental world-map overlays for search areas, patrol paths, and farm routes based on RXP step geometry.
- Added separate opacity settings for search areas, patrol paths, and farm routes.
- Added a new minimap settings button for quick access to the Navigator options.
- Keeps overlays behind the main navigation route so the active route stays readable.
- Preserves existing fallback navigation behavior.

# 1.3.0-beta9 - Lua Local Limit Fix

- Moved smooth-route segment helpers into `Navigator.RouteSmoother`.
- Moved native RestedXP map-label filtering into `Navigator.WorldMapFilter`.
- Reduces top-level local-variable pressure to avoid WoW Lua's 200-local main-chunk limit.
- Keeps smooth route rendering and curve-aligned arrows unchanged.

# 1.3.0-beta8 - Smooth Route Arrows

- Direction arrows now follow the smoothed World/Zone Map route instead of the original straight-line segments.
- Arrow rotation is calculated from the local curve tangent, keeping chevrons aligned with bends.
- Arrow density remains intentionally sparse; route targets and RXP waypoint positions are unchanged.

# 1.3.0-beta7 - Smooth Route Rendering

- Added curved route rendering for World and Zone maps.
- RXP waypoints remain exact route anchors; only the visual segments between them are smoothed.
- Added loop protection for sharp turns.
- Keeps animated direction arrows sparse and based on the original route segments.
- Preserves the RXP Route Resolver, map cleanup, tooltip-only detail model, Travel Mode and Corpse Run behavior.

# 1.3.0-beta6 - Map Cleanup

- Added a World Map option to show/hide RestedXP's active target circle.
- The RestedXP white targeting circle is hidden visually by default without changing RestedXP guide data or disabling its map-pin engine.
- Re-enabling the option asks RestedXP to redraw its pins immediately.
- Existing Navigator route, marker, tooltip and Route Resolver behavior remains unchanged.
- Native RestedXP objective counters remain suppressed on the world/zone map and available through tooltips instead.

# RestedXP-Navigator 1.3.0-beta3

- Fixed WoW Lua main-chunk local-variable limit warning (>200 locals) introduced in beta2.
- Moved the diagnostic Inspector table into the Navigator namespace.
- Fixed several latent Inspector helper references used by diagnostic commands.
- Keeps the RXP Data Integration and clean world-map progress behavior from beta2.

# 1.3.0-beta2

- Suppress native RestedXP world/zone-map objective counters such as `0/60`; objective progress remains available in Navigator target tooltips only.
- Keeps RestedXP map-pin data and waypoint engine untouched; only the native progress text is hidden.

## 1.3.0-beta1

### RXP Data Integration
- Added a Navigator-owned normalized data model for RestedXP navigation elements.
- RestedXP parser tags are now preferred over locale-dependent text heuristics for step classification.
- Added structured extraction of quest IDs, objective indexes, objective maxima, item IDs/names, target names, step indexes and map coordinates.
- Navigation elements such as `.goto` can now inherit relevant structured objective metadata from sibling elements in the same RestedXP step without changing the selected navigation coordinate.
- Quest objective matching now prioritizes RestedXP's explicit `.complete` objective index (`obj`) before heuristic matching.
- Objective matching can use structured RestedXP mob/item/target names as an additional signal.
- RestedXP `mapTooltip`, `tooltipText` and hidden text fields are preferred before raw guide text when available.

### Event Integration
- Added optional listeners for RestedXP V2 AceEvent messages: `UpdateActiveSteps`, `QuestDataLoaded`, `GuideStepsChanged` and `GuideWindowRefresh`.
- Event-driven updates invalidate normalized RXP metadata and request a coalesced Navigator refresh.
- Existing polling remains enabled as a compatibility fallback for older RestedXP builds or future internal message changes.

### Compatibility / Safety
- No visual map, minimap or HUD redesign in this beta.
- Existing 1.2.0 navigation rendering remains the fallback authority.
- Added normalized RXP metadata and V2-event status to `/rxpnav status` and `/rxpnav bugreport` diagnostics.

## 1.2.0

### Added
- Added cross-continent Travel Mode for RestedXP destinations on another continent.
- Added travel guidance for verified transport points such as Zeppelin and boat connections where available.
- Added destination-zone routing when the player is outside the currently displayed zone.
- Added off-screen minimap target guidance for distant targets.
- Added navigation presets: Minimal, Classic, Full Navigation and Streamer.
- Added `/rxpnav maptest` diagnostics and `/rxpnav bugreport` export.
- Added enhanced Corpse Run navigation with corpse-focused route styling and proximity feedback.

### World & Zone Map
- Upcoming RestedXP targets can now be previewed up to +6 steps ahead.
- Nearby future targets are grouped into a single marker to reduce map clutter.
- Grouped-marker tooltips list the RestedXP steps at that location.
- Current and future targets use consistent marker sizing while remaining visually distinguishable.
- Animated direction indicators are shown along visible route segments.
- Zone-map routing now projects the player correctly when the destination zone is open but the player is still outside it.
- Removed route-distance labels, step-type icons and quest counters from the map itself for a cleaner route display.

### Target Tooltips
- Moved detailed step information from map labels into mouseover tooltips.
- Quest tooltips now show the concrete Blizzard objective when it can be matched safely.
- Kill steps can display the matching mob objective and counter.
- Loot/collect steps can display the matching item objective and counter.
- Multi-objective quests are matched against the active RestedXP instruction instead of automatically using the first incomplete objective.
- If an objective cannot be matched reliably, the addon avoids showing a misleading counter.

### Navigation Arrow & Minimap
- Improved the configurable on-screen Navigation Arrow.
- Added independent arrow/text sizing and additional presentation controls.
- Added zone-transition hints.
- Improved minimap route rendering and target handling.
- Added separate minimap/world-map marker-size and animation-speed settings.

### Travel
- Cross-continent routing no longer draws misleading direct minimap navigation to another continent.
- Travel Mode keeps the HUD visible and shows the required continent/zone transition.
- Known transport routes can display the transport destination and departure location.
- When a verified departure point is available, navigation can lead to that travel point first.
- Normal RestedXP navigation resumes automatically after the continent transition.

### Corpse Run
- Added automatic corpse-focused navigation while the player is ghosted.
- Added blood-red route presentation and moving skull route indicators.
- Added corpse distance and proximity feedback.
- Added optional Spirit Healer information when supported by the client.

### Fixed
- Fixed world-map and zone-map projection issues affecting upcoming RestedXP goals.
- Fixed several cases where future targets had valid coordinates but were not rendered.
- Fixed compatibility fallbacks for player-map detection on WoW Forever.
- Fixed Lua errors in diagnostic/export helpers.
- Fixed an options-panel refresh error caused by a removed route-distance control.
- Fixed unsupported glyph rendering in the Travel HUD.
- Fixed HUD update issues introduced while separating arrow and text sizing.
- Avoided processing protected movement-speed values for ETA calculation.

## 1.1.0
- Added upcoming RestedXP goal preview.
- Added grouped future target markers and expanded tooltips.
- Reorganized options into clearer navigation sections.
- Improved future-target selection and map projection.
- Added initial corpse/ghost navigation fallback.
