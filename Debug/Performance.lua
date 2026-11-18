local Navigator = RXPNavigator
local Performance = {questRevision = 0, objectives = setmetatable({}, {__mode = "k"})}
Navigator.Performance = Performance

-- Store both results. The objective type controls the kill/loot icon.
function Performance:GetObjective(element)
    if type(element) ~= "table" then return Navigator:GetQuestObjectiveTextRaw(element) end
    local now = GetTime()
    local revision = Navigator.RXPData.revision
    local cached = self.objectives[element]
    if cached and cached.revision == revision and cached.questRevision == self.questRevision
        and now >= cached.time and now - cached.time < .1 then
        return cached.text, cached.kind
    end
    local started = Navigator.navigationProfileActive and debugprofilestop()
    local text, kind = Navigator:GetQuestObjectiveTextRaw(element)
    if started then Navigator:RecordNavigationTiming("Quest objectives", debugprofilestop() - started) end
    if issecretvalue and (issecretvalue(text) or issecretvalue(kind)) then return text, kind end
    self.objectives[element] = {time=now, revision=revision, questRevision=self.questRevision, text=text, kind=kind}
    return text, kind
end

-- GetTime is shared by callbacks in the same rendered frame. Reuse work only
-- within that frame, with event/guide invalidation and distinct fallback maps.
local frameTime, frameRevision, frameQuestRevision
local positions, continents = {}, {}
local playerWorld = {}
local function BeginFrame()
    local now = GetTime()
    local revision = Navigator.RXPData.revision
    if frameTime ~= now or frameRevision ~= revision or frameQuestRevision ~= Performance.questRevision then
        frameTime, frameRevision, frameQuestRevision = now, revision, Performance.questRevision
        wipe(positions)
        wipe(continents)
        wipe(playerWorld)
    end
end

function Performance:GetPlayerPosition(preferredMapID)
    BeginFrame()
    local key = preferredMapID or 0
    local cached = positions.primary or positions[key]
    if cached then return cached.map, cached.x, cached.y, cached.source end
    local map, x, y, source = Navigator:ResolvePlayerMapRaw(preferredMapID)
    -- Failed lookups are retried, so zone/loading transitions can recover.
    if map and x and y then
        local result = {map=map, x=x, y=y, source=source}
        positions[key] = result
        if source == "C_Map.GetBestMapForUnit" or source == "MapUtil.GetDisplayableMapForPlayer" then
            positions.primary = result
        end
    end
    return map, x, y, source
end

function Performance:GetPlayerWorld(mapID, x, y)
    BeginFrame()
    if playerWorld.map == mapID and playerWorld.x == x and playerWorld.y == y then
        return playerWorld.wx, playerWorld.wy, playerWorld.continent
    end
    local wx, wy, continent = Navigator.API:GetWorldPosForMap(mapID, x, y)
    if wx and wy then
        playerWorld.map, playerWorld.x, playerWorld.y = mapID, x, y
        playerWorld.wx, playerWorld.wy, playerWorld.continent = wx, wy, continent
    end
    return wx, wy, continent
end

function Performance:GetContinent(mapID)
    if not mapID then return nil end
    BeginFrame()
    local cached = continents[mapID]
    if cached then return cached.map, cached.name end
    local map, name = Navigator:ResolveContinentMapRaw(mapID)
    if map then continents[mapID] = {map=map, name=name} end
    return map, name
end

local function Measure(object, method, label)
    local original = object and object[method]
    if type(original) ~= "function" then return end
    object[method] = function(...)
        if not Navigator.navigationProfileActive then return original(...) end
        local started = debugprofilestop()
        local a, b, c, d, e = original(...)
        Navigator:RecordNavigationTiming(label, debugprofilestop() - started)
        return a, b, c, d, e
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE",
    "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST"}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event)
    Performance.questRevision = Performance.questRevision + 1
    if event ~= "PLAYER_LOGIN" then return end
    Measure(Navigator, "ResolvePlayerMapRaw", "Player map lookup")
    Measure(Navigator.TargetResolver, "Resolve", "Target resolution")
    Measure(Navigator.RouteResolver, "GetCurrentPlan", "Current route plan")
    Measure(Navigator.RouteResolver, "GetFuturePlans", "Future route plans")
    Measure(Navigator.GrindHUD, "GetState", "Grind state")
    Measure(Navigator.MinimapOverlays, "Update", "Minimap overlays")
    Measure(Navigator.MinimapFuture, "Update", "Minimap future")
    Measure(Navigator.MapOverlays, "Render", "World overlays")
end)
