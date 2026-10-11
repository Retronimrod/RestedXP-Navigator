local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end

local API = Navigator.API
Navigator.WorldMarkerVisual = Navigator.WorldMarkerVisual or {}
local Visual = Navigator.WorldMarkerVisual

local UPDATE_INTERVAL = 0.08
local DEFAULT_BEAM_SHOW_DISTANCE_YARDS = 65
local CLOSE_RANGE_START_YARDS = 28
local CLOSE_RANGE_MAX_LIFT_PX = 58
local NPC_SNAP_MAX_DISTANCE_YARDS = 40

local elapsed = 0
local navFrame
local container
local groundStem
local groundBackground
local groundHighlight
local groundStroke
local markerIcon
local distanceText

local PING_KIT_COLORS = {
    OnMyWay = { 0.18, 0.72, 1.00 },
    Assist = { 0.23, 0.95, 0.34 },
    Attack = { 1.00, 0.62, 0.10 },
    Warning = { 1.00, 0.24, 0.24 },
    NonThreat = { 0.22, 0.68, 1.00 },
    Threat = { 1.00, 0.24, 0.24 },
}
local visibleNameplates = {}
local snappedNameplate
local npcTestGUID
local npcTestName
local npcTestUntil
local npcTestPlate
local NPC_TEST_DURATION_SECONDS = 120
local npcTestFrame
local npcTestBackground
local npcTestStem
local npcTestIcon
local npcTestText

-- Forward declarations are required because the test-frame updater is defined
-- before these helper implementations. Without this, Lua resolves the names
-- as globals and the diagnostic update silently fails inside pcall().
local FindNamePlateByGUID
local IsNPCTestActive

local function AtlasExists(atlas)
    if C_Texture and type(C_Texture.GetAtlasInfo) == "function" then
        local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
        return ok and info ~= nil
    end
    return true
end

local function SetAtlasSafe(texture, atlas, useAtlasSize)
    if not texture or not atlas or not AtlasExists(atlas) then return false end
    local ok = pcall(texture.SetAtlas, texture, atlas, useAtlasSize == true)
    return ok
end

local function NormalizeUnitName(name)
    if type(name) ~= "string" then return nil end
    name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return string.lower(name)
end

local function IsInteractiveTargetType(targetType, instruction)
    if targetType == "turnin" or targetType == "accept" or targetType == "talk" then
        return true
    end

    local text = string.lower(tostring(instruction or ""))
    return text:find("turn in", 1, true)
        or text:find("talk to", 1, true)
        or text:find("speak to", 1, true)
        or text:find("buy ", 1, true)
        or text:find("purchase", 1, true)
        or text:find("vendor", 1, true)
        or text:find("train ", 1, true)
        or text:find("learn ", 1, true)
        or text:find("abgeben", 1, true)
        or text:find("sprich", 1, true)
        or text:find("kaufe", 1, true)
end

local function GetPlateUnit(frame)
    if not frame then return nil end
    if frame.unitToken then return frame.unitToken end
    if frame.namePlateUnitToken then return frame.namePlateUnitToken end
    if type(frame.GetUnit) == "function" then
        local ok, unit = pcall(frame.GetUnit, frame)
        if ok then return unit end
    end
    return nil
end

local function IsQuestRelatedUnit(unit)
    if not unit or not (C_QuestLog and type(C_QuestLog.UnitIsRelatedToActiveQuest) == "function") then
        return false
    end
    local ok, related = pcall(C_QuestLog.UnitIsRelatedToActiveQuest, unit)
    return ok and related == true
end

local function GetFrameCenter(frame)
    if not frame or type(frame.GetCenter) ~= "function" then return nil end
    local ok, x, y = pcall(frame.GetCenter, frame)
    if not ok or type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

local function HideNPCTestFrame()
    if npcTestFrame then
        npcTestFrame:Hide()
        npcTestFrame:SetParent(UIParent)
        npcTestFrame:ClearAllPoints()
    end
end

local function CreateNPCTestFrame(plate)
    if not plate then return nil end

    if not npcTestFrame then
        local f = CreateFrame("Frame", "RXPNavigatorNPCTestFrame", UIParent)
        f:SetSize(190, 130)
        f:SetFrameStrata("TOOLTIP")
        f:SetFrameLevel(200)
        f:EnableMouse(false)

        npcTestStem = f:CreateTexture(nil, "BACKGROUND")
        pcall(npcTestStem.SetAtlas, npcTestStem, "Ping_GroundMarker_Pin_Assist", true)
        do
            local stemW, stemH = npcTestStem:GetSize()
            if tonumber(stemW) and tonumber(stemH) and stemW > 0 and stemH > 0 then
                npcTestStem:SetSize(stemW, stemH * 0.5)
            end
        end

        npcTestBackground = f:CreateTexture(nil, "ARTWORK")
        pcall(npcTestBackground.SetAtlas, npcTestBackground, "Ping_GroundMarker_BG_Assist", true)

        npcTestIcon = f:CreateTexture(nil, "OVERLAY")
        pcall(npcTestIcon.SetAtlas, npcTestIcon, "Ping_Marker_Icon_Assist", true)

        npcTestText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        npcTestText:SetTextColor(0.23, 0.95, 0.34, 1)
        npcTestText:SetShadowOffset(1, -1)
        npcTestText:SetShadowColor(0, 0, 0, 1)

        npcTestFrame = f
    end

    -- Important: do NOT read GetCenter/GetLeft/GetTop/etc. from a nameplate.
    -- Forever marks nameplate regions as restricted. Instead, attach our own
    -- child directly to the nameplate and let WoW position it in world space.
    npcTestFrame:SetParent(plate)
    npcTestFrame:ClearAllPoints()
    npcTestFrame:SetPoint("BOTTOM", plate, "TOP", 0, 8)

    npcTestStem:ClearAllPoints()
    npcTestStem:SetPoint("BOTTOM", npcTestFrame, "BOTTOM", 0, 0)

    npcTestBackground:ClearAllPoints()
    npcTestBackground:SetPoint("BOTTOM", npcTestStem, "TOP", 0, -8)

    npcTestIcon:ClearAllPoints()
    npcTestIcon:SetPoint("CENTER", npcTestBackground, "CENTER", 0, 0)

    npcTestText:ClearAllPoints()
    npcTestText:SetPoint("LEFT", npcTestBackground, "RIGHT", 8, 0)

    return npcTestFrame
end

local function UpdateNPCTestFrame()
    if not IsNPCTestActive() then
        HideNPCTestFrame()
        return false
    end

    local plate = FindNamePlateByGUID(npcTestGUID)
    if not plate or not plate:IsShown() then
        HideNPCTestFrame()
        return false
    end

    local f = CreateNPCTestFrame(plate)
    if not f then
        HideNPCTestFrame()
        return false
    end

    if npcTestText then
        npcTestText:SetText("NPC TEST: " .. tostring(npcTestName or "?"))
    end

    f:Show()
    npcTestPlate = plate
    return true
end

local function FindBestInteractiveNameplate(status, navigationFrame)
    if not status then return nil end
    local distance = tonumber(status.activeTargetDistance)
    if not distance or distance > NPC_SNAP_MAX_DISTANCE_YARDS then return nil end
    if not IsInteractiveTargetType(status.activeTargetType, status.activeInstruction) then return nil end

    local wantedName = NormalizeUnitName(status.activeTargetName)
    if not wantedName then
        -- Without an exact NPC name we deliberately do not guess. Measuring
        -- or ranking nameplate frames is restricted in Forever and can taint
        -- the UI. Fall back to the native waypoint instead.
        return nil
    end

    for unit, plate in pairs(visibleNameplates) do
        if plate and plate:IsShown() and UnitExists and UnitExists(unit) then
            local isPlayer = UnitIsPlayer and UnitIsPlayer(unit) == true
            local unitName = UnitName and UnitName(unit) or nil
            if not isPlayer and NormalizeUnitName(unitName) == wantedName then
                return plate
            end
        end
    end

    return nil
end

local function GetNamePlateForUnitSafe(unit)
    if not unit or not C_NamePlate or type(C_NamePlate.GetNamePlateForUnit) ~= "function" then
        return nil
    end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then return plate end
    return nil
end

FindNamePlateByGUID = function(guid)
    if not guid then return nil end

    local direct = GetNamePlateForUnitSafe("target")
    if direct and UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target") == guid then
        return direct
    end

    for unit, plate in pairs(visibleNameplates) do
        if plate and plate:IsShown() and UnitExists and UnitExists(unit) and UnitGUID and UnitGUID(unit) == guid then
            return plate
        end
    end
    return nil
end

IsNPCTestActive = function()
    if not npcTestGUID then return false end
    if npcTestUntil and GetTime and GetTime() >= npcTestUntil then
        npcTestGUID = nil
        npcTestName = nil
        npcTestUntil = nil
        npcTestPlate = nil
        HideNPCTestFrame()
        RestoreNPCTestCVars()
        return false
    end
    return true
end

local function ReadCVar(name)
    if C_CVar and type(C_CVar.GetCVar) == "function" then
        local ok, value = pcall(C_CVar.GetCVar, name)
        if ok then return value end
    end
    if type(GetCVar) == "function" then
        local ok, value = pcall(GetCVar, name)
        if ok then return value end
    end
    return nil
end

local function RestoreNPCTestCVars()
    -- v1.5.23+: diagnostic mode is read-only and never changes player CVars.
end

local function EnsureTargetNameplateVisible(unit)
    -- Safety policy: never change Blizzard nameplate CVars automatically.
    -- The NPC test only uses nameplates that the client is already exposing
    -- under the player's own UI settings.
    return GetNamePlateForUnitSafe(unit)
end

function Visual:StartNPCTest(unit)
    unit = unit or "target"

    if not UnitExists or not UnitExists(unit) then
        API:Print("NPC-Test: Kein NPC anvisiert. Bitte einen NPC auswählen und /rxpnav npctest erneut ausführen.")
        return false
    end
    if UnitIsPlayer and UnitIsPlayer(unit) then
        API:Print("NPC-Test: Bitte einen NPC und keinen Spieler auswählen.")
        return false
    end

    local guid = UnitGUID and UnitGUID(unit) or nil
    local name = UnitName and UnitName(unit) or "NPC"
    local friendly = UnitIsFriend and UnitIsFriend("player", unit) == true
    local attackable = UnitCanAttack and UnitCanAttack("player", unit) == true
    if not guid then
        API:Print("NPC-Test: Die Unit-GUID konnte nicht gelesen werden.")
        return false
    end

    npcTestGUID = guid
    npcTestName = name
    npcTestUntil = (GetTime and GetTime() or 0) + NPC_TEST_DURATION_SECONDS

    -- Overhead NPC names are not necessarily Blizzard nameplate frames.
    -- The diagnostic is intentionally read-only: it never changes the
    -- player's nameplate settings.
    npcTestPlate = EnsureTargetNameplateVisible(unit)

    if npcTestPlate then
        API:Print(string.format("NPC-Test aktiv: %s. Sichtbare Blizzard-Nameplate gefunden – Marker wird 120 Sekunden direkt am NPC verankert.", tostring(name)))
    else
        API:Print(string.format("NPC-Test aktiv: %s. Keine sichtbare Blizzard-Nameplate vorhanden. Der Test ändert deine Nameplate-Einstellungen bewusst nicht.", tostring(name)))
    end

    elapsed = UPDATE_INTERVAL
    local ok, rendered = pcall(UpdateNPCTestFrame)
    if not ok then
        API:Print("NPC-Test Fehler beim Start: " .. tostring(rendered))
    elseif rendered then
        API:Print("NPC-Testmarker sichtbar und an der NPC-Nameplate verankert.")
    else
        API:Print("NPC-Testmarker konnte noch nicht dargestellt werden; Nameplate bleibt unter Beobachtung.")
    end
    return true
end

function Visual:StopNPCTest()
    local wasActive = npcTestGUID ~= nil
    npcTestGUID = nil
    npcTestName = nil
    npcTestUntil = nil
    npcTestPlate = nil
    snappedNameplate = nil
    HideNPCTestFrame()
    RestoreNPCTestCVars()
    if wasActive then
        API:Print("NPC-Test beendet.")
    else
        API:Print("NPC-Test war nicht aktiv.")
    end
end

function Visual:GetNPCTestStatus()
    local active = IsNPCTestActive()
    local remaining = 0
    if active and npcTestUntil and GetTime then
        remaining = math.max(0, npcTestUntil - GetTime())
    end
    return {
        active = active,
        guid = npcTestGUID,
        name = npcTestName,
        remaining = remaining,
        plateVisible = active and FindNamePlateByGUID(npcTestGUID) ~= nil or false,
    }
end

local function GetNPCTestNameplate()
    if not IsNPCTestActive() then return nil end
    local plate = FindNamePlateByGUID(npcTestGUID)
    if plate and plate:IsShown() then
        local alpha = type(plate.GetEffectiveAlpha) == "function" and plate:GetEffectiveAlpha() or 1
        local x, y = GetFrameCenter(plate)
        if x and y and alpha and alpha > 0.05 then
            npcTestPlate = plate
            return plate
        end
    end
    npcTestPlate = nil
    return nil
end

local function ShouldSuppressNativeSuperTrack()
    if not Navigator.WorldMarker or not Navigator.WorldMarker.GetStatus then return false end
    local status = Navigator.WorldMarker:GetStatus()
    return status and status.owned == true
end

local NATIVE_NAV_ALPHA_DEFAULTS = {
    Invalid = 0.0,
    Occluded = 0.6,
    InRange = 1.0,
    Disabled = 0.0,
}

local nativeSuppressed = false

local function SetNativeNavigationStateAlphas(frame, suppress)
    if not frame or type(frame.SetTargetAlphaForState) ~= "function" then return end
    if not Enum or not Enum.NavigationState then return end

    local values
    if suppress then
        values = {
            Invalid = 0,
            Occluded = 0,
            InRange = 0,
            Disabled = 0,
        }
    else
        values = NATIVE_NAV_ALPHA_DEFAULTS
    end

    for name, alpha in pairs(values) do
        local state = Enum.NavigationState[name]
        if state ~= nil then
            pcall(frame.SetTargetAlphaForState, frame, state, alpha)
        end
    end
end

local function ApplyNativeSuperTrackSuppression()
    local frame = _G.SuperTrackedFrame
    local suppress = ShouldSuppressNativeSuperTrack()

    if frame then
        SetNativeNavigationStateAlphas(frame, suppress)

        if suppress then
            pcall(frame.SetAlpha, frame, 0)
            if frame.Icon then pcall(frame.Icon.SetAlpha, frame.Icon, 0) end
            if frame.DistanceText then pcall(frame.DistanceText.SetAlpha, frame.DistanceText, 0) end
            if frame.Arrow then pcall(frame.Arrow.SetAlpha, frame.Arrow, 0) end
            if frame.IconBorder then pcall(frame.IconBorder.SetAlpha, frame.IconBorder, 0) end
        elseif nativeSuppressed then
            if frame.Icon then pcall(frame.Icon.SetAlpha, frame.Icon, 1) end
            if frame.DistanceText then pcall(frame.DistanceText.SetAlpha, frame.DistanceText, 1) end
            if frame.Arrow then pcall(frame.Arrow.SetAlpha, frame.Arrow, 1) end
            if frame.IconBorder then pcall(frame.IconBorder.SetAlpha, frame.IconBorder, 1) end
            pcall(frame.SetAlpha, frame, 1)
        end
    end

    nativeSuppressed = suppress
end

local function RestoreNativeSuperTrackPresentation()
    local frame = _G.SuperTrackedFrame
    if not frame then return end

    SetNativeNavigationStateAlphas(frame, false)

    if frame.Icon then pcall(frame.Icon.SetAlpha, frame.Icon, 1) end
    if frame.DistanceText then pcall(frame.DistanceText.SetAlpha, frame.DistanceText, 1) end
    if frame.Arrow then pcall(frame.Arrow.SetAlpha, frame.Arrow, 1) end
    if frame.IconBorder then pcall(frame.IconBorder.SetAlpha, frame.IconBorder, 1) end
    pcall(frame.SetAlpha, frame, 1)

    nativeSuppressed = false
end

local function InstallNativeFrameSuppression()
    -- Deliberately no hook: use Blizzard's own exposed navigation-state
    -- alpha interface and enforce the hidden state from our refresh cycle.
end

local function FormatDistance(distance)
    if type(distance) ~= "number" then return "" end
    if distance >= 1000 then
        return string.format("%.1f km", distance / 1000)
    end
    return string.format("%d yd", math.floor(distance + 0.5))
end

local function DestroyVisual()
    if container then
        container:Hide()
        container:SetParent(UIParent)
    end
    navFrame = nil
    snappedNameplate = nil
end

local function CreateVisual(frame)
    if not frame then return end
    if container and navFrame == frame then return end

    DestroyVisual()
    navFrame = frame

    -- Intentionally not parented into Blizzard's navigation frame; we only
    -- anchor to it so Blizzard frame visibility/clipping cannot hide our marker.
    container = CreateFrame("Frame", nil, UIParent)
    container:SetSize(200, 200)
    container:SetPoint("CENTER", frame, "CENTER", 0, 0)
    container:SetFrameStrata("HIGH")
    container:SetFrameLevel(90)
    container:EnableMouse(false)

    -- Exact structure used by Blizzard's PingPinFrame GroundPin:
    -- stem from center, background above it, then marker icon in the background.
    groundStem = container:CreateTexture(nil, "BACKGROUND", nil, 1)
    groundStem:SetPoint("BOTTOM", container, "CENTER", 0, 0)

    groundBackground = container:CreateTexture(nil, "BACKGROUND", nil, 2)
    groundBackground:SetPoint("BOTTOM", groundStem, "TOP", 0, -8)

    groundHighlight = container:CreateTexture(nil, "BACKGROUND", nil, 3)
    groundHighlight:SetPoint("BOTTOM", groundStem, "TOP", 0, -8)
    groundHighlight:SetAlpha(0.18)

    groundStroke = container:CreateTexture(nil, "BACKGROUND", nil, 4)
    groundStroke:SetPoint("BOTTOM", groundStem, "TOP", 0, -8)
    groundStroke:SetAlpha(0.34)

    markerIcon = container:CreateTexture(nil, "ARTWORK", nil, 1)
    markerIcon:SetPoint("CENTER", groundBackground, "CENTER", 0, 0)

    distanceText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    distanceText:SetPoint("LEFT", groundBackground, "RIGHT", 7, 0)
    distanceText:SetJustifyH("LEFT")
    distanceText:SetShadowOffset(1, -1)
    distanceText:SetShadowColor(0, 0, 0, 0.95)
    distanceText:SetText("")

    container:Hide()
end

local function ObtainNavigationFrame()
    if not (C_Navigation and type(C_Navigation.GetFrame) == "function") then
        DestroyVisual()
        return nil
    end

    local ok, frame = pcall(C_Navigation.GetFrame)
    if not ok or not frame then
        DestroyVisual()
        return nil
    end

    CreateVisual(frame)
    return frame
end

local function ShouldShow()
    local db = API:GetDB()

    InstallNativeFrameSuppression()
    ApplyNativeSuperTrackSuppression()
    if not db or not db.enabled or db.showWorldMarkerNative ~= true then
        return false
    end

    if not Navigator.WorldMarker or not Navigator.WorldMarker.GetStatus then
        return false
    end

    local status = Navigator.WorldMarker:GetStatus()
    return status and status.owned == true
end

local function ApplyBlizzardPingStyle(kit, showStem, distance)
    kit = kit or "NonThreat"

    -- These are Blizzard's own PingUI atlases, not copied assets:
    -- Ping_Marker_Icon_Attack / Assist / OnMyWay / Warning / NonThreat
    -- Ping_GroundMarker_BG_*
    -- Ping_GroundMarker_Pin_*
    -- Ping_GroundMarker_Stroke_*
    local iconAtlas = ("Ping_Marker_Icon_%s"):format(kit)
    local bgAtlas = ("Ping_GroundMarker_BG_%s"):format(kit)
    local pinAtlas = ("Ping_GroundMarker_Pin_%s"):format(kit)
    local strokeAtlas = ("Ping_GroundMarker_Stroke_%s"):format(kit)

    if not SetAtlasSafe(markerIcon, iconAtlas, true) then
        kit = "NonThreat"
        SetAtlasSafe(markerIcon, "Ping_Marker_Icon_NonThreat", true)
        bgAtlas = "Ping_GroundMarker_BG_NonThreat"
        pinAtlas = "Ping_GroundMarker_Pin_NonThreat"
        strokeAtlas = "Ping_GroundMarker_Stroke_NonThreat"
    end

    SetAtlasSafe(groundBackground, bgAtlas, true)
    SetAtlasSafe(groundHighlight, bgAtlas, true)
    SetAtlasSafe(groundStroke, strokeAtlas, true)

    if showStem then
        SetAtlasSafe(groundStem, pinAtlas, true)

        -- C_Navigation's screen point drops lower as the camera gets very
        -- close to the target. Keep the Blizzard marker head readable by
        -- extending the ground stem upward while its bottom remains anchored
        -- to the actual target point. This keeps the pin visually planted on
        -- the ground instead of letting the marker head sink below it.
        local baseWidth, baseHeight = groundStem:GetSize()
        baseWidth = tonumber(baseWidth) or 8
        baseHeight = tonumber(baseHeight) or 72

        local lift = 0
        if snappedNameplate == nil and type(distance) == "number" and distance < CLOSE_RANGE_START_YARDS then
            local t = 1 - math.max(0, math.min(CLOSE_RANGE_START_YARDS, distance)) / CLOSE_RANGE_START_YARDS
            -- Smoothstep makes the correction subtle at 20-30 yd and
            -- progressively stronger only when the player is very close.
            t = t * t * (3 - 2 * t)
            lift = CLOSE_RANGE_MAX_LIFT_PX * t
        end

        groundStem:SetSize(baseWidth, baseHeight + lift)
        groundStem:Show()
        groundBackground:ClearAllPoints()
        groundBackground:SetPoint("BOTTOM", groundStem, "TOP", 0, -8)
        groundHighlight:ClearAllPoints()
        groundHighlight:SetPoint("BOTTOM", groundStem, "TOP", 0, -8)
        groundStroke:ClearAllPoints()
        groundStroke:SetPoint("BOTTOM", groundStem, "TOP", 0, -8)
    else
        groundStem:Hide()
        groundBackground:ClearAllPoints()
        groundBackground:SetPoint("CENTER", container, "CENTER", 0, 18)
        groundHighlight:ClearAllPoints()
        groundHighlight:SetPoint("CENTER", groundBackground, "CENTER")
        groundStroke:ClearAllPoints()
        groundStroke:SetPoint("CENTER", groundBackground, "CENTER")
    end
end

function Visual:Refresh()
    local frame = navFrame or ObtainNavigationFrame()
    if not frame or not container then return end

    if not ShouldShow() then
        snappedNameplate = nil
        if distanceText then distanceText:Hide() end
        container:Hide()
        if not ShouldSuppressNativeSuperTrack() then
        else
                end
        return
    end

    local status = Navigator.WorldMarker:GetStatus()

    -- Always start from Blizzard's valid native navigation position. NPC
    -- snapping is only an optional refinement; it must never make the marker
    -- disappear if a nameplate is missing, hidden or recycled.
    container:ClearAllPoints()
    container:SetPoint("CENTER", frame, "CENTER", 0, 0)
    snappedNameplate = nil

    local manualTestPlate = nil
    -- Automatic NPC snapping is intentionally conservative in this build.
    -- Nameplate geometry is restricted in Forever, so the production marker
    -- keeps the native navigation anchor. The dedicated /rxpnav npctest uses
    -- a safe child-frame attachment to validate nameplate anchoring without
    -- reading restricted frame measurements.
    snappedNameplate = nil

    local kit = status.activePingTextureKit or "NonThreat"
    local distance = status.activeTargetDistance
    local beamRange = status.beamShowDistanceYards or DEFAULT_BEAM_SHOW_DISTANCE_YARDS
    local db = API:GetDB()


    -- Far away: exact Blizzard marker head only.
    -- Close: exact Blizzard ground stem is added.
    local showStem = db.showWorldMarkerBeam ~= false
        and type(distance) == "number"
        and distance <= beamRange

    ApplyBlizzardPingStyle(kit, showStem, distance)

    local color = PING_KIT_COLORS[kit] or PING_KIT_COLORS.NonThreat
    if distanceText then
        distanceText:SetText(FormatDistance(distance))
        distanceText:SetTextColor(color[1], color[2], color[3], 1)
        distanceText:ClearAllPoints()
        distanceText:SetPoint("LEFT", groundBackground, "RIGHT", 7, 0)
        distanceText:Show()
    end

    groundBackground:Show()
    groundHighlight:Show()
    groundStroke:Show()
    markerIcon:Show()
    container:Show()

    -- Enforce once more at the end of the same refresh cycle so Blizzard's
    -- alpha lerp cannot flash the original gold marker for a frame.
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("NAVIGATION_FRAME_CREATED")
eventFrame:RegisterEvent("NAVIGATION_FRAME_DESTROYED")
eventFrame:RegisterEvent("SUPER_TRACKING_PATH_UPDATED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGOUT" then
        RestoreNativeSuperTrackPresentation()
        return
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if unit and C_NamePlate and type(C_NamePlate.GetNamePlateForUnit) == "function" then
            local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
            if ok and plate then
                visibleNameplates[unit] = plate
                if npcTestGUID and UnitGUID and UnitExists and UnitExists(unit) and UnitGUID(unit) == npcTestGUID then
                    npcTestPlate = plate
                    pcall(UpdateNPCTestFrame)
                    API:Print("NPC-Test: Blizzard-Nameplate erkannt – Testmarker jetzt verankert.")
                end
            end
        end
        elapsed = UPDATE_INTERVAL
        return
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if unit then visibleNameplates[unit] = nil end
        elapsed = UPDATE_INTERVAL
        return
    elseif event == "NAVIGATION_FRAME_DESTROYED" then
        DestroyVisual()
    else
            ObtainNavigationFrame()
        elapsed = UPDATE_INTERVAL
    end
end)

eventFrame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + (dt or 0)
    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0

    -- NPC test rendering is intentionally independent from RestedXP's current
    -- waypoint so we can verify nameplate anchoring in isolation.
    local testOK, testResult = pcall(UpdateNPCTestFrame)
    if not testOK then
        if npcTestGUID then
            API:Print("NPC-Test Fehler: " .. tostring(testResult))
        end
        HideNPCTestFrame()
    end

    local ok = pcall(Visual.Refresh, Visual)
    if not ok and container then
        container:Hide()
    end
end)
