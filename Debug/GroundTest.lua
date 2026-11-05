local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end
local API = Navigator.API
local Test = {}
Navigator.GroundTest = Test
local target, baseZ, startedAt, previous
local function Print(text) API:Print("Bodentest: " .. text) end
local function Finite(value)
    if issecretvalue and issecretvalue(value) then return false end
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end
function Test:GetTarget() return target end
local function Refresh()
    if Navigator.WorldMarker then Navigator.WorldMarker:RefreshNow() end
    if Navigator.WorldMarkerVisual then Navigator.WorldMarkerVisual:Refresh() end
end
function Test:Stop()
    if not target then return end
    target, baseZ, startedAt = nil, nil, nil
    local db = API:GetDB()
    if db and previous then
        for _, key in ipairs({"showWorldMarkerNative", "showWorldMarkerBeam", "showWorldMarkerHeader", "worldMarkerPrecision"}) do
            db[key] = previous[key]
        end
    end
    previous = nil
    Refresh()
    Print("beendet; vorherige Anzeige-Einstellungen wiederhergestellt.")
end
function Test:Status()
    if not target then Print("nicht aktiv. Start: /rxpnav groundtest here"); return end
    local returned
    if C_Map and type(C_Map.GetUserWaypoint) == "function" then
        local ok, point = pcall(C_Map.GetUserWaypoint)
        if ok then returned = point end
    end
    Print(string.format("map=%d X=%.5f Y=%.5f; gemessene Z=%.3f; angeforderte Z=%s; zurückgelesene Z=%s",
        target.mapID, target.x, target.y, baseZ, tostring(target.z), tostring(returned and returned.z)))
    local status = Navigator.WorldMarker and Navigator.WorldMarker:GetStatus()
    Print("Navigator besitzt Punkt: " .. tostring(status and status.owned) .. "; Höhe allein beweist noch keine Bodenverankerung.")
end
function Test:Start()
    local db = API:GetDB()
    if not db or not db.enabled then Print("Navigator zuerst einschalten: /rxpnav on"); return end
    if InCombatLockdown and InCombatLockdown() then Print("bitte außerhalb des Kampfes testen."); return end
    for _, name in ipairs({"IsFlying", "IsFalling", "IsSwimming"}) do
        local fn = _G[name]
        if type(fn) == "function" and fn() then Print("bitte auf trockenem, festem Boden stehen."); return end
    end
    if GetUnitSpeed and GetUnitSpeed("player") > 0 then Print("zum Messen bitte stillstehen."); return end
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition and UnitPosition) then
        Print("benötigte Positions-API fehlt."); return
    end
    local ok, mapID, x, y, z = pcall(function()
        local map = C_Map.GetBestMapForUnit("player")
        local pos = map and C_Map.GetPlayerMapPosition(map, "player")
        local px, py
        if pos then
            if type(pos.GetXY) == "function" then px, py = pos:GetXY() else px, py = pos.x, pos.y end
        end
        local _, _, height = UnitPosition("player")
        return map, px, py, height
    end)
    if not ok or not Finite(mapID) or not Finite(x) or not Finite(y) or not Finite(z)
        or x < 0 or x > 1 or y < 0 or y > 1 then
        Print("Position oder Höhe nicht lesbar; kein Testpunkt gesetzt."); return
    end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(mapID) then
        Print("auf dieser Karte sind keine Benutzerwegpunkte möglich."); return
    end
    if not target then
        previous = {}
        for _, key in ipairs({"showWorldMarkerNative", "showWorldMarkerBeam", "showWorldMarkerHeader", "worldMarkerPrecision"}) do previous[key] = db[key] end
    end
    db.showWorldMarkerNative, db.showWorldMarkerBeam, db.showWorldMarkerHeader, db.worldMarkerPrecision = true, false, true, true
    baseZ, startedAt = z, GetTime()
    target = {mapID = mapID, x = x, y = y, z = z,
        element = {zone = mapID, x = x, y = y, tag = "goto", text = "Bodentest: gemessene Spielerhöhe"}}
    Refresh()
    Print("Punkt an deiner Position gespeichert. Jetzt 10–20 Schritte weggehen und Kamera drehen. Test endet nach 3 Minuten.")
    self:Status()
end
function Test:Command(command)
    if command == "here" then self:Start()
    elseif command == "off" then self:Stop()
    elseif command == "status" then self:Status()
    elseif command == "auto" and target then
        target.z = nil; Refresh(); self:Status()
    elseif command:match("^z%s") and target then
        local offset = tonumber(command:match("^z%s+(.+)$"))
        if not Finite(offset) or math.abs(offset) > 100 then Print("Höhenversatz zwischen -100 und 100 angeben."); return end
        target.z = baseZ + offset; Refresh(); self:Status()
    else Print("/rxpnav groundtest here | z 0 | z 10 | z -10 | auto | status | off") end
end
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", function() Test:Stop() end)
events:SetScript("OnUpdate", function()
    if target and GetTime() - startedAt >= 180 then Test:Stop() end
end)
