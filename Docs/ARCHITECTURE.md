# RestedXP-Navigator architecture

## Core
`Core/RXP_Navigator.lua` owns runtime state, map/player coordinate resolution, navigation rendering orchestration and the narrow `Navigator.API` surface used by modules.

`Core/TravelHUD.lua` contains travel-instruction interpretation.

`Core/RouteSmoother.lua` contains route geometry smoothing.

## Debug
`Debug/Inspector.lua` owns inspector capture/export state and RestedXP structure inspection.

`Debug/Diagnostics.lua` owns status, map diagnostics, bug-report generation and corpse-run diagnostics.

Debug data is kept in SavedVariables; WoW addons do not write arbitrary runtime log files to disk.

## UI
Settings, route tooltips and minimap button implementations live in `UI/`.

## Map
World-map/minimap overlay modules live in `Map/`.

## Media
Only runtime media assets are stored in `Media/`. Development previews are not packaged.

## Target and Tooltip pipeline
- `Core/TargetResolver.lua` converts RXP elements into a stable Navigator target model.
- `UI/TooltipEngine.lua` renders that model consistently for route, world-map and minimap hover surfaces.
- Renderers should request target metadata through `Navigator.API:GetResolvedTarget()` rather than parsing RXP fields independently.
