## 1.4.0
- Added quest-object / collectible markers for RestedXP object-location loops on the World Map and Minimap.
- Added object classification, tooltips and nearest-object highlighting while keeping non-object overlay routes unchanged.
- Added a dedicated Grind XP HUD with live XP progress, a percentage bar and grind-step action text.
- Grind steps hide ETA to keep the HUD focused on XP progress; normal navigation keeps the regular ETA display.
- Improved Grind HUD readability with larger progress text, a larger progress bar and increased spacing below the navigation distance.

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

# RestedXP-Navigator Changelog

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

# RestedXP-Navigator Changelog

## 1.4.0-beta1
- Added a generic quest-object / collectible marker system for RestedXP object-location loops.
- Object-location loops are rendered as individual markers instead of misleading connected route lines.
- Added automatic object classification for crystals/minerals, chests/caches, plants/herbs, mushrooms, eggs, containers, remains/corpses and a neutral fallback.
- Added object markers on both World Map and Minimap.
- The nearest visible object is highlighted with a gold ring; other object locations use a cyan ring.
- Added object tooltips with object type, instruction, quest progress and minimap distance when available.
- Added a dedicated "Quest object markers" option in the Overlays tab.
- Existing farm, patrol, search and normal navigation routes remain unchanged when a loop is not confidently identified as an object-collection loop.

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
