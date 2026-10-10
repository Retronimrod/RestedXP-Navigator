local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end

local API = Navigator.API
Navigator.WorldMarker = Navigator.WorldMarker or {}
local WorldMarker = Navigator.WorldMarker

local UPDATE_INTERVAL = 0.25
local MISSING_GRACE = 1.0
local CVAR = "showInGameNavigation"

local elapsed = 0
local missingSince
local owned = false
local lastOwnedKey
local blockedTargetKey
local previousState

local function GetXY(pos)
    if not pos then return nil end
    if type(pos.GetXY) == "function" then
        local ok, x, y = pcall(pos.GetXY, pos)
        if ok then return x, y end
    end
    return pos.x, pos.y
end

local function PointToData(point)
    if not point then return nil end
    local mapID = tonumber(point.uiMapID or point.mapID)
    local x, y = GetXY(point.position or point.pos)
    x, y = tonumber(x), tonumber(y)
    if not mapID or not x or not y then return nil end
    return { mapID = mapID, x = x, y = y, z = tonumber(point.z) }
end

local function MakePoint(data)
    if not data or not data.mapID or not data.x or not data.y then return nil end
    if UiMapPoint and type(UiMapPoint.CreateFromCoordinates) == "function" then
        local ok, point = pcall(UiMapPoint.CreateFromCoordinates, data.mapID, data.x, data.y, data.z)
        if ok and point then return point end
    end
    if UiMapPoint and type(UiMapPoint.CreateFromVector2D) == "function" and CreateVector2D then
        local okVector, vector = pcall(CreateVector2D, data.x, data.y)
        if okVector and vector then
            local okPoint, point = pcall(UiMapPoint.CreateFromVector2D, data.mapID, vector)
            if okPoint and point then return point end
        end
    end
    return nil
end

local function PointKey(mapID, x, y)
    if not mapID or not x or not y then return nil end
    return string.format("%d:%.5f:%.5f", mapID, x, y)
end

local function GetCurrentWaypointData()
    if not (C_Map and type(C_Map.GetUserWaypoint) == "function") then return nil end
    local ok, point = pcall(C_Map.GetUserWaypoint)
    if not ok or not point then return nil end
    return PointToData(point)
end

local function GetCurrentWaypointKey()
    local data = GetCurrentWaypointData()
    if not data then return nil end
    return PointKey(data.mapID, data.x, data.y)
end

local function HasUnknownSuperTrack()
    if not (C_SuperTrack and type(C_SuperTrack.IsSuperTrackingAnything) == "function") then return false end
    local okAny, any = pcall(C_SuperTrack.IsSuperTrackingAnything)
    if not okAny or not any then return false end

    if type(C_SuperTrack.IsSuperTrackingQuest) == "function" then
        local ok, v = pcall(C_SuperTrack.IsSuperTrackingQuest)
        if ok and v then return false end
    end
    if type(C_SuperTrack.IsSuperTrackingUserWaypoint) == "function" then
        local ok, v = pcall(C_SuperTrack.IsSuperTrackingUserWaypoint)
        if ok and v then return false end
    end
    if type(C_SuperTrack.IsSuperTrackingCorpse) == "function" then
        local ok, v = pcall(C_SuperTrack.IsSuperTrackingCorpse)
        if ok and v then return true end
    end

    return true
end

local function CapturePreviousState()
    if previousState then return end

    previousState = {
        waypoint = GetCurrentWaypointData(),
        superUserWaypoint = false,
        questID = nil,
    }

    if C_SuperTrack then
        if type(C_SuperTrack.IsSuperTrackingUserWaypoint) == "function" then
            local ok, v = pcall(C_SuperTrack.IsSuperTrackingUserWaypoint)
            previousState.superUserWaypoint = ok and v and true or false
        end

        if type(C_SuperTrack.IsSuperTrackingQuest) == "function"
           and type(C_SuperTrack.GetSuperTrackedQuestID) == "function" then
            local okQuest, isQuest = pcall(C_SuperTrack.IsSuperTrackingQuest)
            if okQuest and isQuest then
                local okID, questID = pcall(C_SuperTrack.GetSuperTrackedQuestID)
                if okID and type(questID) == "number" and questID > 0 then
                    previousState.questID = questID
                end
            end
        end
    end
end

local function EnableNativeNavigationCVar()
    if not (C_CVar and type(C_CVar.GetCVar) == "function" and type(C_CVar.SetCVar) == "function") then return end
    local ok, value = pcall(C_CVar.GetCVar, CVAR)
    if ok and tostring(value) ~= "1" then
        pcall(C_CVar.SetCVar, CVAR, "1")
    end
end

local function RestorePreviousState()
    if not owned and not previousState then return end

    local currentKey = GetCurrentWaypointKey()
    if owned and lastOwnedKey and currentKey == lastOwnedKey then
        if previousState and previousState.waypoint then
            local point = MakePoint(previousState.waypoint)
            if point and C_Map and type(C_Map.SetUserWaypoint) == "function" then
                pcall(C_Map.SetUserWaypoint, point)
            end
        elseif C_Map and type(C_Map.ClearUserWaypoint) == "function" then
            pcall(C_Map.ClearUserWaypoint)
        end
    end

    if previousState and previousState.questID and C_SuperTrack and type(C_SuperTrack.SetSuperTrackedQuestID) == "function" then
        pcall(C_SuperTrack.SetSuperTrackedQuestID, previousState.questID)
    elseif previousState and previousState.superUserWaypoint
       and C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    elseif owned and C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, false)
    end

    owned = false
    lastOwnedKey = nil
    previousState = nil
end

local function RelinquishToExternalWaypoint(targetKey)
    owned = false
    lastOwnedKey = nil
    previousState = nil
    blockedTargetKey = targetKey
end

local function GetDesiredElement()
    if API.IsCorpseRunMode and API:IsCorpseRunMode() then return nil end

    local plan
    if Navigator.RouteResolver and type(Navigator.RouteResolver.GetCurrentPlan) == "function" then
        local ok, value = pcall(Navigator.RouteResolver.GetCurrentPlan, Navigator.RouteResolver)
        if ok then plan = value end
    end

    local element = plan and (plan.nextPoint or plan.goal) or nil
    if not element and API.GetNavigationTargets then
        local targets = API:GetNavigationTargets(0)
        element = type(targets) == "table" and targets[1] or nil
    end
    if not element or element.corpseNav then return nil end

    if Navigator.TravelPlanner and type(Navigator.TravelPlanner.GetPlan) == "function" then
        local ok, travelPlan = pcall(Navigator.TravelPlanner.GetPlan, Navigator.TravelPlanner, element)
        if ok and travelPlan and travelPlan.mode == "network" and travelPlan.approachElement then
            element = travelPlan.approachElement
        end
    end

    return element
end

local function ResolveDesiredTarget()
    local element = GetDesiredElement()
    if not element then return nil end

    local mapID, x, y = API:GetTargetMap(element)
    mapID, x, y = tonumber(mapID), tonumber(x), tonumber(y)
    if not mapID or not x or not y then return nil end
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end

    if C_Map and type(C_Map.CanSetUserWaypointOnMap) == "function" then
        local ok, allowed = pcall(C_Map.CanSetUserWaypointOnMap, mapID)
        if not ok or not allowed then return nil end
    end

    return {
        element = element,
        mapID = mapID,
        x = x,
        y = y,
        key = PointKey(mapID, x, y),
    }
end

local function SetDesiredTarget(target)
    if not target or not target.key then return false end
    if blockedTargetKey and blockedTargetKey == target.key then return false end
    if blockedTargetKey and blockedTargetKey ~= target.key then blockedTargetKey = nil end

    if owned then
        local currentKey = GetCurrentWaypointKey()
        if currentKey and lastOwnedKey and currentKey ~= lastOwnedKey then
            RelinquishToExternalWaypoint(target.key)
            return false
        end
    elseif HasUnknownSuperTrack() then
        return false
    end

    if owned and lastOwnedKey == target.key then
        if C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
            pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
        end
        return true
    end

    if not owned then CapturePreviousState() end

    local point = MakePoint(target)
    if not point or not (C_Map and type(C_Map.SetUserWaypoint) == "function") then
        return false
    end

    EnableNativeNavigationCVar()

    local okSet, wasSet = pcall(C_Map.SetUserWaypoint, point)
    if not okSet or wasSet == false then
        if not owned then previousState = nil end
        return false
    end

    if C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
        local ok = pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
        if not ok then
            if not owned then previousState = nil end
            return false
        end
    else
        if not owned then previousState = nil end
        return false
    end

    owned = true
    lastOwnedKey = target.key
    return true
end

function WorldMarker:RefreshNow()
    local db = API:GetDB()
    if not db or not db.enabled or db.showWorldMarkerNative ~= true then
        missingSince = nil
        blockedTargetKey = nil
        RestorePreviousState()
        return
    end

    EnableNativeNavigationCVar()

    local target = ResolveDesiredTarget()
    if not target then
        if not missingSince then missingSince = GetTime and GetTime() or 0 end
        local now = GetTime and GetTime() or 0
        if now - missingSince >= MISSING_GRACE then RestorePreviousState() end
        return
    end

    missingSince = nil
    SetDesiredTarget(target)
end

function WorldMarker:GetStatus()
    return {
        enabled = API:GetDB() and API:GetDB().showWorldMarkerNative == true or false,
        owned = owned,
        lastOwnedKey = lastOwnedKey,
        blockedTargetKey = blockedTargetKey,
    }
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:SetScript("OnEvent", function()
    elapsed = UPDATE_INTERVAL
end)
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + (dt or 0)
    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0
    WorldMarker:RefreshNow()
end)
