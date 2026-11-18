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
    "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "PLAYER_ENTERING_WORLD"}) do
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
