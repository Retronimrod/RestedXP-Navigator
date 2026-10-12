local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end

local API = Navigator.API
Navigator.WorldMarker = Navigator.WorldMarker or {}
local WorldMarker = Navigator.WorldMarker

local UPDATE_INTERVAL = 0.25
local MISSING_GRACE = 1.0
local CVAR = "showInGameNavigation"
local ARRIVAL_HOLD_SECONDS = 30
local ARRIVAL_RADIUS_YARDS = 8
local ARRIVAL_PASS_RADIUS_YARDS = 12
local ARRIVAL_PASS_DELTA_YARDS = 3
local ETA_ALPHA = 0.25
local ETA_MIN_SPEED = 0.5
local ETA_MIN_DELTA_DISTANCE = 0.20
local ETA_STALE_SECONDS = 4
local BEAM_SHOW_DISTANCE_YARDS = 65

local elapsed = 0
local missingSince
local owned = false
local lastOwnedKey
local blockedTargetKey
local previousState
local activeTarget
local pendingTarget
local arrivalHoldStartedAt
local arrivalMinDistance
local etaTargetKey
local etaLastDistance
local etaLastTime
local etaAverageSpeed
local etaLastProgressTime
local headerFrame
local headerIcon
local headerTitle
local headerDistance
local headerETA

local PING_TEXTURE_KITS = {
    -- Final simplified Blizzard-native marker mapping.
    -- Green: quest accept/turn-in, vendor, innkeeper/hearth, trainer.
    -- Blue arrow: movement/travel.
    -- Orange sword: combat/kill.
    -- Blue diamond: everything else.
    default = "NonThreat",
    accept = "Assist",
    turnin = "Assist",
    vendor = "Assist",
    train = "Assist",
    hearth = "Assist",

    travel = "OnMyWay",
    map = "OnMyWay",
    portal = "OnMyWay",

    kill = "Attack",
    warning = "Attack",

    talk = "NonThreat",
    flight = "NonThreat",
    loot = "NonThreat",
    corpse = "NonThreat",
}


local function DetectIconStepType(target, title, instruction)
    local element = target and target.element or nil
    if element and element.corpseNav then return "corpse" end

    local stepType = API.DetectStepType and API:DetectStepType(element) or nil
    local text = string.lower(tostring(title or "") .. " " .. tostring(instruction or ""))

    -- Explicit semantic instructions have priority over a generic "talk" step.
    if text:find("turn in", 1, true) or text:find("turnin", 1, true)
       or text:find("hand in", 1, true) or text:find("abgeben", 1, true)
       or text:find("abgabe", 1, true) then
        return "turnin"
    end
    if text:find("accept", 1, true) or text:find("pick up", 1, true)
       or text:find("take quest", 1, true) or text:find("annehmen", 1, true) then
        return "accept"
    end
    if text:find("vendor", 1, true) or text:find("vendor trash", 1, true)
       or text:find("buy ", 1, true) or text:find("purchase", 1, true)
       or text:find("sell ", 1, true) or text:find("repair", 1, true)
       or text:find("kaufe", 1, true) or text:find("verkaufe", 1, true) then
        return "vendor"
    end
    if text:find("innkeeper", 1, true) or text:find("hearthstone", 1, true)
       or text:find("set hearth", 1, true) or text:find("bind ", 1, true)
       or text:find("gasthaus", 1, true) or text:find("ruhestein", 1, true) then
        return "hearth"
    end
    if text:find("flight master", 1, true) or text:find("flight path", 1, true)
       or text:find("fly to", 1, true) or text:find("take flight", 1, true)
       or text:find("flugmeister", 1, true) or text:find("flugpunkt", 1, true) then
        return "flight"
    end
    if text:find("kill", 1, true) or text:find("slay", 1, true)
       or text:find("slain", 1, true) or text:find("defeat", 1, true)
       or text:find("töte", 1, true) or text:find("toete", 1, true) then
        return "kill"
    end
    if text:find("dangerous", 1, true) or text:find("warning", 1, true)
       or text:find("elite", 1, true) or text:find("boss", 1, true)
       or text:find("gefährlich", 1, true) or text:find("gefaehrlich", 1, true) then
        return "warning"
    end
    if text:find("loot", 1, true) or text:find("collect", 1, true)
       or text:find("gather", 1, true) or text:find("sammel", 1, true)
       or text:find("plünder", 1, true) or text:find("pluender", 1, true) then
        return "loot"
    end

    if stepType == "accept" or stepType == "turnin" or stepType == "kill"
       or stepType == "loot" or stepType == "travel" then
        return stepType
    end
    if stepType == "talk" then return "talk" end

    if text:find("talk", 1, true) or text:find("speak", 1, true)
       or text:find("sprich", 1, true) or text:find("rede mit", 1, true) then
        return "talk"
    end

    return stepType
end

local function ResolveHeaderIconKey(target, title, instruction)
    local element = target and target.element or nil
    if not element then return "default" end

    local stepType = DetectIconStepType(target, title, instruction)
    local transport = API.GetTransportHint and API:GetTransportHint(element) or nil

    if stepType == "accept" then return "accept" end
    if stepType == "turnin" then return "turnin" end
    if stepType == "kill" then return "kill" end
    if stepType == "vendor" then return "vendor" end
    if stepType == "hearth" then return "hearth" end
    if stepType == "flight" then return "flight" end

    if stepType == "travel" then
        if transport == "Hearthstone" then return "hearth" end
        if transport == "Flight" or transport == "Flight Path" then return "flight" end
        if transport == "Portal" then return "portal" end
        if transport == "Boat" or transport == "Zeppelin" then return "map" end
        return "travel"
    end
    if stepType == "corpse" then return "corpse" end
    if stepType == "warning" then return "warning" end
    return PING_TEXTURE_KITS[stepType] and stepType or "default"
end

local function ResolveHeaderPingKit(target, title, instruction)
    local key = ResolveHeaderIconKey(target, title, instruction)
    return PING_TEXTURE_KITS[key] or PING_TEXTURE_KITS.default, key
end

local function SetBlizzardPingAtlas(texture, atlas)
    if not texture or not atlas then return false end
    if C_Texture and type(C_Texture.GetAtlasInfo) == "function" then
        local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
        if ok and not info then return false end
    end
    local ok = pcall(texture.SetAtlas, texture, atlas, false)
    return ok
end

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

    local iconBG = frame:CreateTexture(nil, "ARTWORK")
    iconBG:SetSize(20, 20)
    iconBG:SetPoint("LEFT", frame, "LEFT", 10, 0)
    iconBG:SetColorTexture(0.07, 0.11, 0.16, 0.95)

    headerIcon = frame:CreateTexture(nil, "OVERLAY")
    headerIcon:SetSize(16, 16)
    headerIcon:SetPoint("CENTER", iconBG, "CENTER", 0, 0)
    headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    headerTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 36, -7)
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


local function ResetDynamicETA(targetKey, distance, now)
    etaTargetKey = targetKey
    etaLastDistance = distance
    etaLastTime = now
    etaAverageSpeed = nil
    etaLastProgressTime = nil
end

local function CalculateDynamicETA(targetKey, distance)
    if type(distance) ~= "number" then return nil end
    local now = GetTime and GetTime() or 0

    if etaTargetKey ~= targetKey or type(etaLastDistance) ~= "number" or type(etaLastTime) ~= "number" then
        ResetDynamicETA(targetKey, distance, now)
        return nil
    end

    local dt = now - etaLastTime
    if dt < 0.15 then return etaAverageSpeed and (distance / etaAverageSpeed) or nil end

    local delta = etaLastDistance - distance
    etaLastDistance = distance
    etaLastTime = now

    if delta >= ETA_MIN_DELTA_DISTANCE then
        local speed = delta / math.max(0.01, dt)
        if speed >= ETA_MIN_SPEED then
            etaAverageSpeed = etaAverageSpeed and (etaAverageSpeed + ETA_ALPHA * (speed - etaAverageSpeed)) or speed
            etaLastProgressTime = now
        end
    end

    if etaLastProgressTime and (now - etaLastProgressTime) > ETA_STALE_SECONDS then
        etaAverageSpeed = nil
    end

    if etaAverageSpeed and etaAverageSpeed >= ETA_MIN_SPEED then
        return distance / etaAverageSpeed
    end
    return nil
end

local function UpdateHeader(target)
    local db = API:GetDB()
    if not db or db.showWorldMarkerHeader == false or not owned or not target or not target.element then
        HideHeader()
        return
    end

    local frame = CreateHeader()
    local resolved = API.GetResolvedTarget and API:GetResolvedTarget(target.element, { ordinal = 1 }) or nil
    local instruction = resolved and resolved.instruction or nil
    local title = resolved and (resolved.title or resolved.instruction) or nil
    if not title or title == "" then
        title = API.GetTargetInstruction and API:GetTargetInstruction(target.element) or "RestedXP Target"
    end
    if (not instruction or instruction == "") and API.GetTargetInstruction then
        instruction = API:GetTargetInstruction(target.element)
    end

    local distance
    if API.GetHUDNavigationMetrics then
        local _, d = API:GetHUDNavigationMetrics(target.element)
        distance = d
    end

    headerTitle:SetText(TruncateTitle(title, 42))
    if headerIcon then
        local kit = ResolveHeaderPingKit(target, title, instruction)
        local atlas = ("Ping_Marker_Icon_%s"):format(kit)
        if not SetBlizzardPingAtlas(headerIcon, atlas) then
            SetBlizzardPingAtlas(headerIcon, "Ping_Marker_Icon_NonThreat")
        end
    end

    if type(distance) == "number" then
        if API.FormatHUDDistance then
            headerDistance:SetText(API:FormatHUDDistance(distance))
        else
            headerDistance:SetText(string.format("%d yd", math.floor(distance + 0.5)))
        end

        local dynamicETA = CalculateDynamicETA(target.key, distance)
        if dynamicETA then
            headerETA:SetText(FormatHeaderETA(dynamicETA))
        else
            headerETA:SetText("measuring...")
        end
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
        local ok, value = pcall(C_SuperTrack.IsSuperTrackingQuest)
        if ok and value then return false end
    end
    if type(C_SuperTrack.IsSuperTrackingUserWaypoint) == "function" then
        local ok, value = pcall(C_SuperTrack.IsSuperTrackingUserWaypoint)
        if ok and value then return false end
    end
    if type(C_SuperTrack.IsSuperTrackingCorpse) == "function" then
        local ok, value = pcall(C_SuperTrack.IsSuperTrackingCorpse)
        if ok and value then return true end
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
            local ok, value = pcall(C_SuperTrack.IsSuperTrackingUserWaypoint)
            previousState.superUserWaypoint = ok and value and true or false
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

local nativeNavigationWarningShown = false
local function EnableNativeNavigationCVar()
    -- Safety policy: never change the player's Blizzard navigation setting.
    -- We only read it and rely on the user/client configuration already in place.
    if not (C_CVar and type(C_CVar.GetCVar) == "function") then return true end
    local ok, value = pcall(C_CVar.GetCVar, CVAR)
    if not ok then return true end
    if tostring(value) == "1" then return true end
    if not nativeNavigationWarningShown and API and API.Print then
        nativeNavigationWarningShown = true
        API:Print("World Marker: Blizzard In-Game Navigation is disabled. Enable it in the game settings to use in-world markers.")
    end
    return false
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
    activeTarget = nil
    pendingTarget = nil
    arrivalHoldStartedAt = nil
    arrivalMinDistance = nil
    ResetDynamicETA(nil, nil, GetTime and GetTime() or 0)
end

local function RelinquishToExternalWaypoint(targetKey)
    owned = false
    lastOwnedKey = nil
    previousState = nil
    activeTarget = nil
    pendingTarget = nil
    arrivalHoldStartedAt = nil
    arrivalMinDistance = nil
    ResetDynamicETA(nil, nil, GetTime and GetTime() or 0)
    blockedTargetKey = targetKey
end

local function GetDesiredElement()
    if API.IsCorpseRunMode and API:IsCorpseRunMode() then
        local corpse = API.GetCorpseNavigationElement and API:GetCorpseNavigationElement() or nil
        if corpse then
            corpse.corpseNav = true
            return corpse
        end
    end

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
    if not element then return nil end

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

local function GetTargetDistance(target)
    if not target or not target.element or not API.GetHUDNavigationMetrics then return nil end
    local _, distance = API:GetHUDNavigationMetrics(target.element)
    if type(distance) ~= "number" or distance ~= distance then return nil end
    return distance
end

local function ArrivalHoldExpired(now)
    if not arrivalHoldStartedAt then return false end
    return (now - arrivalHoldStartedAt) >= ARRIVAL_HOLD_SECONDS
end

local function ArrivalTargetReached()
    local distance = GetTargetDistance(activeTarget)
    if type(distance) ~= "number" then return false end

    arrivalMinDistance = math.min(arrivalMinDistance or distance, distance)
    if distance <= ARRIVAL_RADIUS_YARDS then return true end

    -- If the player passed very close to the point and is moving away again,
    -- count it as reached instead of keeping the old marker behind the player.
    if arrivalMinDistance <= ARRIVAL_PASS_RADIUS_YARDS
       and distance >= arrivalMinDistance + ARRIVAL_PASS_DELTA_YARDS then
        return true
    end
    return false
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
    local now = GetTime and GetTime() or 0

    -- Blizzard exposes only one native user waypoint at a time. When RestedXP
    -- advances, keep the previous native marker alive briefly so the player can
    -- actually arrive at it. The Navigator header/HUD can already show the new
    -- destination during this handover.
    if owned and activeTarget and target.key ~= activeTarget.key then
        pendingTarget = target
        if not arrivalHoldStartedAt then
            arrivalHoldStartedAt = now
            arrivalMinDistance = GetTargetDistance(activeTarget)
        end

        local releaseOldMarker = ArrivalTargetReached() or ArrivalHoldExpired(now)
        if not releaseOldMarker then
            if C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
                pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
            end
            UpdateHeader(target)
            return
        end

        arrivalHoldStartedAt = nil
        arrivalMinDistance = nil
        pendingTarget = nil
    else
        pendingTarget = nil
        arrivalHoldStartedAt = nil
        arrivalMinDistance = nil
    end

    local active = SetDesiredTarget(target)
    if active then
        activeTarget = target
        UpdateHeader(target)
    else
        HideHeader()
    end
end

function WorldMarker:GetActiveResolvedTarget()
    local target = activeTarget
    if not target or not target.element then return nil end
    if API.GetResolvedTarget then
        return API:GetResolvedTarget(target.element, { ordinal = 1 })
    end
    return nil
end

function WorldMarker:GetActiveTargetDistance()
    return GetTargetDistance(activeTarget)
end

function WorldMarker:GetActivePingTextureKit()
    local target = activeTarget
    if not target or not target.element then return PING_TEXTURE_KITS.default end
    local resolved = API.GetResolvedTarget and API:GetResolvedTarget(target.element, { ordinal = 1 }) or nil
    local instruction = resolved and resolved.instruction or nil
    local title = resolved and (resolved.title or resolved.instruction) or nil
    if not title or title == "" then
        title = API.GetTargetInstruction and API:GetTargetInstruction(target.element) or ""
    end
    if (not instruction or instruction == "") and API.GetTargetInstruction then
        instruction = API:GetTargetInstruction(target.element)
    end
    local kit = ResolveHeaderPingKit(target, title, instruction)
    return kit or PING_TEXTURE_KITS.default
end

function WorldMarker:GetActiveIconKey()
    local target = activeTarget
    if not target or not target.element then return "default" end
    local resolved = API.GetResolvedTarget and API:GetResolvedTarget(target.element, { ordinal = 1 }) or nil
    local instruction = resolved and resolved.instruction or nil
    local title = resolved and (resolved.title or resolved.instruction) or nil
    if not title or title == "" then
        title = API.GetTargetInstruction and API:GetTargetInstruction(target.element) or ""
    end
    if (not instruction or instruction == "") and API.GetTargetInstruction then
        instruction = API:GetTargetInstruction(target.element)
    end
    return ResolveHeaderIconKey(target, title, instruction)
end

function WorldMarker:GetStatus()
    local db = API:GetDB()
    local resolved = self:GetActiveResolvedTarget()
    return {
        enabled = db and db.showWorldMarkerNative == true or false,
        owned = owned,
        lastOwnedKey = lastOwnedKey,
        blockedTargetKey = blockedTargetKey,
        activeTargetKey = activeTarget and activeTarget.key or nil,
        pendingTargetKey = pendingTarget and pendingTarget.key or nil,
        arrivalHoldSeconds = ARRIVAL_HOLD_SECONDS,
        arrivalRadiusYards = ARRIVAL_RADIUS_YARDS,
        beamShowDistanceYards = tonumber(db and db.worldMarkerBeamDistance) or BEAM_SHOW_DISTANCE_YARDS,
        activeTargetDistance = self:GetActiveTargetDistance(),
        activeIconKey = self:GetActiveIconKey(),
        activePingTextureKit = self:GetActivePingTextureKit(),
        activeTargetName = resolved and resolved.targetName or nil,
        activeQuestID = resolved and resolved.questID or nil,
        activeTargetType = resolved and (resolved.genericType or resolved.type) or nil,
        activeInstruction = resolved and resolved.instruction or nil,
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
