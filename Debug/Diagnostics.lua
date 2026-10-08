local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.Diagnostics = Navigator.Diagnostics or {}

local function Print(msg) API:Print(msg) end

local function GetMapTypeName(mapType)
    local names = {[0]="Cosmic",[1]="World",[2]="Continent",[3]="Zone",[4]="Dungeon",[5]="Micro",[6]="Orphan"}
    return names[tonumber(mapType)] or tostring(mapType or "?")
end

function Navigator.Diagnostics:PrintMapDiagnostics(captureOnly)
    if captureOnly then API:BeginInspectorCapture("map diagnostics") end
    Print("=== RestedXP-Navigator Map Diagnostics ===")
    local rawPlayerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local targetForResolve = API:GetCurrentNavigationElement()
    local preferredPlayerMapID = targetForResolve and API:GetTargetMap(targetForResolve) or nil
    local playerMapID, px, py, playerMapSource = API:ResolvePlayerMapAndPosition(preferredPlayerMapID)
    local pInfo = playerMapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(playerMapID)
    Print("Version: " .. tostring(API:GetVersion()))
    Print("Raw player map: " .. tostring(rawPlayerMapID))
    local displayableMapID
    if MapUtil and type(MapUtil.GetDisplayableMapForPlayer) == "function" then
        local ok, id = pcall(MapUtil.GetDisplayableMapForPlayer)
        if ok then displayableMapID = id end
    end
    local legacyAreaID = type(GetCurrentMapAreaID) == "function" and GetCurrentMapAreaID() or nil
    local wmMapID = WorldMapFrame and ((type(WorldMapFrame.GetMapID) == "function" and WorldMapFrame:GetMapID()) or WorldMapFrame.mapID) or nil
    local legacyX, legacyY
    if type(GetPlayerMapPosition) == "function" then
        local ok, x, y = pcall(GetPlayerMapPosition, "player")
        if ok then legacyX, legacyY = x, y end
    end
    Print("Displayable player map: " .. tostring(displayableMapID))
    Print("Legacy current area: " .. tostring(legacyAreaID))
    Print("WorldMapFrame map: " .. tostring(wmMapID))
    Print("Legacy player position: " .. tostring(legacyX) .. ", " .. tostring(legacyY))
    local unitA, unitB, unitZ, unitInstance
    if type(UnitPosition) == "function" then
        local okUnit, a, b, z, instanceID = pcall(UnitPosition, "player")
        if okUnit then unitA, unitB, unitZ, unitInstance = a, b, z, instanceID end
    end
    Print("UnitPosition raw: " .. tostring(unitA) .. ", " .. tostring(unitB) .. ", z=" .. tostring(unitZ) .. " instance=" .. tostring(unitInstance))
    Print("Resolved player map: " .. tostring(playerMapID) .. " | " .. tostring(pInfo and pInfo.name) .. " | type=" .. GetMapTypeName(pInfo and pInfo.mapType))
    Print("Player map source: " .. tostring(playerMapSource))
    Print("Player position: " .. tostring(px) .. ", " .. tostring(py))
    Print("Ghost/Corpse mode: " .. tostring(API:IsCorpseRunMode()))
    local target = API:GetCurrentNavigationElement()
    local tm, tx, ty = API:GetTargetMap(target)
    local tInfo = tm and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(tm)
    Print("Target map: " .. tostring(tm) .. " | " .. tostring(tInfo and tInfo.name) .. " | x=" .. tostring(tx) .. " y=" .. tostring(ty))
    if playerMapID and tm and tx and ty then
        local mx, my = API:PositionInDisplayedMap(tm, tx, ty, playerMapID, true)
        Print("Projection to player map: " .. ((mx and my) and ("OK x="..tostring(mx).." y="..tostring(my)) or "FAILED"))
    end
    local twx, twy, tc = API:GetTargetWorld(target)
    local pwx, pwy, pc
    if playerMapID then pwx, pwy, pc = API:GetWorldPosForMap(playerMapID, px, py) end
    Print("Player world: " .. tostring(pwx) .. ", " .. tostring(pwy) .. " continent=" .. tostring(pc))
    Print("Target world: " .. tostring(twx) .. ", " .. tostring(twy) .. " continent=" .. tostring(tc))
    local travelInfo = target and Navigator.TravelMode and Navigator.TravelMode:GetInfo(target)
    if travelInfo then
        Print("Travel mode: true | " .. tostring(travelInfo.playerContinent) .. " -> " .. tostring(travelInfo.targetContinent) .. " | " .. tostring(travelInfo.targetContinentName) .. " -> " .. tostring(travelInfo.targetZone))
    else
        Print("Travel mode: false")
    end
    local db = API:GetDB()
    Print("Minimap enabled: " .. tostring(db and db.showMinimap) .. " | World map enabled: " .. tostring(db and db.showWorldMap) .. " | HUD: " .. tostring(db and db.showHUDArrow))
    Print("Future goals: +" .. tostring(db and db.futureGoals or 0))
    if captureOnly then API:EndInspectorCapture() end
end

function Navigator.Diagnostics:GenerateBugReport()
    API:BeginInspectorCapture("bug report")
    Print("=== RestedXP-Navigator Bug Report ===")
    Print("Please copy this block into your CurseForge report.")
    Print("Timestamp: " .. (date and date("%Y-%m-%d %H:%M:%S") or "n/a"))
    self:PrintMapDiagnostics(false)
    local _, stepIndex = API:ResolveActiveGuideAndStep()
    local rxpc = rawget(_G, "RXPCData")
    Print("RXP guide group: " .. tostring(rxpc and rxpc.currentGuideGroup))
    Print("RXP guide: " .. tostring(rxpc and rxpc.currentGuideName))
    Print("RXP current step: " .. tostring(stepIndex or (rxpc and rxpc.currentStep)))
    local current = API:GetCurrentNavigationElement()
    local currentModel = Navigator.RXPData and Navigator.RXPData.Normalize and Navigator.RXPData:Normalize(current) or nil
    Print("Instruction: " .. tostring(API:GetTargetInstruction(current)))
    if currentModel then
        Print("RXP normalized: tag=" .. tostring(currentModel.tag) .. " semanticTag=" .. tostring(currentModel.semanticTag) .. " questID=" .. tostring(currentModel.questID) .. " obj=" .. tostring(currentModel.objectiveIndex) .. " item=" .. tostring(currentModel.itemName) .. " target=" .. tostring(currentModel.targetName))
    end
    local routePlan = Navigator.RouteResolver and Navigator.RouteResolver:GetCurrentPlan()
    Print("RXP route: resolved=" .. tostring(routePlan and routePlan.resolved or false) .. " nodes=" .. tostring(routePlan and routePlan.nodes and #routePlan.nodes or 0) .. " fallback=" .. tostring(routePlan and routePlan.fallback or false))
    local db = API:GetDB()
    Print("Settings: minimapMarker="..tostring(db and db.minimapTargetSize).." worldMarker="..tostring(db and db.worldTargetSize).." miniSpeed="..tostring(db and db.minimapAnimationSpeed).." worldSpeed="..tostring(db and db.worldAnimationSpeed))
    API:EndInspectorCapture()
    API:ShowInspectorExport()
end

function Navigator.Diagnostics:Status()
    local element = API:GetCurrentNavigationElement()
    local db = API:GetDB()
    Print("Version " .. tostring(API:GetVersion()) .. " RestedXP-Navigator")
    Print("Modus: RXP Route Resolver mit direktem Fallback")
    Print("Aktiv: " .. tostring(db and db.enabled))
    Print("Theme: " .. tostring(API:GetThemeName()))
    Print("RestedXP-Ziel: " .. (element and "gefunden" or "nicht gefunden"))
    local rxp = API:GetRXPGuidesAddon()
    local af = _G.RXPG_ARROW
    local disableArrow = rxp and rxp.settings and rxp.settings.profile and rxp.settings.profile.disableArrow
    Print("RXP intern: API=" .. (rxp and "ok" or "fehlt") .. " | ArrowFrame=" .. (af and "ok" or "fehlt") .. " | Element=" .. (af and af.element and "ja" or "nein") .. " | disableArrow=" .. tostring(disableArrow))
    Print("RXP Data Integration: tag-aware | normalized model rev=" .. tostring(Navigator.RXPData and Navigator.RXPData.revision) .. " | V2 events=" .. tostring(Navigator.rxpEventBridgeReady))
    local routePlan = Navigator.RouteResolver and Navigator.RouteResolver:GetCurrentPlan()
    Print("RXP Route Resolver: " .. tostring(routePlan and routePlan.resolved or false) .. " | nodes=" .. tostring(routePlan and routePlan.nodes and #routePlan.nodes or 0) .. " | fallback=" .. tostring(routePlan and routePlan.fallback or false))
    Print("Minimap: " .. tostring(db and db.showMinimap) .. " | Weltkarte: " .. tostring(db and db.showWorldMap) .. " | Navigationspfeil: " .. tostring(db and db.showHUDArrow))
    Print("Navigationspfeil-Stil: " .. tostring(db and db.hudArrowStyle or "classic") .. " | Größe: " .. tostring(db and db.hudSize) .. " | Gesperrt: " .. tostring(db and db.hudLocked))
    Print("Zielmarker: " .. tostring(db and db.showTargetMarker) .. " | Mouseover-Tooltip: " .. tostring(db and db.showTaskTooltip))
    Print("Linienstärke: " .. tostring(db and db.lineStyle) .. " | Animation: " .. tostring(db and db.animation))
    Print("Folgeziele: +" .. tostring(db and db.futureGoals or 0))
    if element then
        local mapID, x, y = API:GetTargetMap(element)
        Print(string.format("Ziel: map=%s x=%.2f y=%.2f", tostring(mapID), (x or 0) * 100, (y or 0) * 100))
        Print("Aufgabe: " .. API:GetTargetInstruction(element))
    end
end

function Navigator.Diagnostics:DeathStatus()
    local db = API:GetDB()
    local ghost = API:IsCorpseRunMode()
    local corpse = API:GetCorpseNavigationElement()
    Print("Corpse Run: " .. tostring(ghost) .. " | keepGhostNavigation=" .. tostring(db and db.keepGhostNavigation))
    if corpse then
        local mapID, x, y = API:GetTargetMap(corpse)
        Print(string.format("Leiche: map=%s x=%.2f y=%.2f", tostring(mapID), (x or 0) * 100, (y or 0) * 100))
    else
        Print("Leiche: kein Corpse-Waypoint gefunden")
    end
end
