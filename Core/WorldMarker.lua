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
local headerFrame
local headerTitle
local headerDistance
local headerETA

local function CreateHeader()
    if headerFrame then return headerFrame end

    local frame = CreateFrame("Frame", "RXPNavigatorWorldMarkerHeader", UIParent)
    frame:SetSize(330, 44)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -42)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(40)
    frame:EnableMouse(false)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.015, 0.025, 0.035, 0.88)

    local top = frame:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(1)
    top:SetColorTexture(0.12, 0.70, 0.95, 0.85)

    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    bottom:SetColorTexture(0.12, 0.70, 0.95, 0.45)

    local icon = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    icon:SetPoint("LEFT", frame, "LEFT", 10, 2)
    icon:SetText("|cff2cc8ff◆|r")

    headerTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 34, -7)
    headerTitle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -76, -7)
    headerTitle:SetJustifyH("LEFT")
    headerTitle:SetWordWrap(false)

    headerDistance = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    headerDistance:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -7)
    headerDistance:SetJustifyH("RIGHT")
    headerDistance:SetTextColor(0.30, 0.85, 1.00, 1)

    headerETA = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerETA:SetPoint("TOPLEFT", headerTitle, "BOTTOMLEFT", 0, -3)
    headerETA:SetTextColor(0.72, 0.75, 0.78, 1)

    frame:Hide()
    headerFrame = frame
    return frame
end

local function HideHeader()
    if headerFrame then headerFrame:Hide() end
end

local function TruncateTitle(text, maxChars)
    text = tostring(text or "")
    maxChars = maxChars or 42
    if #text <= maxChars then return text end
    return text:sub(1, math.max(1, maxChars - 3)) .. "..."
end

local function FormatHeaderETA(seconds)
    if type(seconds) ~= "number" or seconds < 0 or seconds ~= seconds then return "" end
    seconds = math.min(seconds, 359999)
    local rounded = math.floor(seconds + 0.5)
    local h = math.floor(rounded / 3600)
    local m = math.floor((rounded % 3600) / 60)
    local sec = rounded % 60
    if h > 0 then
        return string.format("about %d:%02d:%02d", h, m, sec)
    end
    return string.format("about %d:%02d", m, sec)
end

local function UpdateHeader(target)
    local db = API:GetDB()
    if not db or db.showWorldMarkerHeader == false or not owned or not target or not target.element then
        HideHeader()
        return
    end

    local frame = CreateHeader()
    local resolved = API.GetResolvedTarget and API:GetResolvedTarget(target.element, { ordinal = 1 }) or nil
    local title = resolved and (resolved.title or resolved.instruction) or nil
    if not title or title == "" then
        title = API.GetTargetInstruction and API:GetTargetInstruction(target.element) or "RestedXP Target"
    end

    local distance
    if API.GetHUDNavigationMetrics then
        local _, d = API:GetHUDNavigationMetrics(target.element)
        distance = d
    end

    headerTitle:SetText(TruncateTitle(title, 42))

    if type(distance) == "number" then
        if API.FormatHUDDistance then
            headerDistance:SetText(API:FormatHUDDistance(distance))
        else
            headerDistance:SetText(string.format("%d yd", math.floor(distance + 0.5)))
        end

        local speed = 7.0
        if IsMounted and IsMounted() then speed = 14.0 end
        headerETA:SetText(FormatHeaderETA(distance / math.max(0.1, speed)))
    else
        headerDistance:SetText("")
        headerETA:SetText("")
    end

    frame:Show()
end

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
        HideHeader()
        return
    end

    EnableNativeNavigationCVar()

    local target = ResolveDesiredTarget()
    if not target then
        if not missingSince then missingSince = GetTime and GetTime() or 0 end
        local now = GetTime and GetTime() or 0
        if now - missingSince >= MISSING_GRACE then RestorePreviousState() end
        HideHeader()
        return
    end

    missingSince = nil
    local active = SetDesiredTarget(target)
    if active then UpdateHeader(target) else HideHeader() end
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
