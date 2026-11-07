local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end

local API = Navigator.API
Navigator.WorldMarkerVisual = Navigator.WorldMarkerVisual or {}
local Visual = Navigator.WorldMarkerVisual

local STYLE_KITS={NonThreat=true,OnMyWay=true,Attack=true,Assist=true,Warning=true}
local STYLE_OPTIONS={
    {id='auto',label='Automatic by objective'}, {id='NonThreat',label='Diamond'},
    {id='OnMyWay',label='Arrow'}, {id='Attack',label='Sword'},
    {id='Assist',label='Interaction'}, {id='Warning',label='Warning'}, {id='raid',label='Raid symbols'},
}
function Visual:GetStyleOptions() return STYLE_OPTIONS end
function Visual:GetStyle(db)
    if db and db.worldMarkerUseRaidSymbols==true then return 'raid' end
    return db and STYLE_KITS[db.worldMarkerStyle] and db.worldMarkerStyle or 'auto'
end
function Visual:SetStyle(db,id)
    if not db or (id~='auto' and id~='raid' and not STYLE_KITS[id]) then return false end
    db.worldMarkerUseRaidSymbols=id=='raid'
    if id~='raid' then db.worldMarkerStyle=id end
    return true
end
function Visual:GetStyleLabel(db)
    local id=self:GetStyle(db)
    for _,option in ipairs(STYLE_OPTIONS) do if option.id==id then return option.label end end
end

local UPDATE_INTERVAL = 0.08
local DEFAULT_BEAM_SHOW_DISTANCE_YARDS = 65
local NPC_TEST_DURATION_SECONDS = 120
local GROUND_RING_TEXTURE = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_GroundRing.tga'

local elapsed = 0
local navFrame
local worldFrame
local npcAnchorFrame
local npcTestFrame
local visibleNameplates = {}
local npcTestGUID, npcTestName, npcTestUntil

local PING_KIT_COLORS = {
    OnMyWay = {0.18, 0.72, 1.00},
    Assist = {0.23, 0.95, 0.34},
    Attack = {1.00, 0.62, 0.10},
    Warning = {1.00, 0.24, 0.24},
    NonThreat = {0.22, 0.68, 1.00},
    Threat = {1.00, 0.24, 0.24},
}

local function GetConfiguredKitColor(kit, db)
    local base = PING_KIT_COLORS[kit] or PING_KIT_COLORS.NonThreat
    if not db or db.worldMarkerCustomColors ~= true then return base end
    if kit == 'Assist' then
        return {db.markerAssistR or base[1], db.markerAssistG or base[2], db.markerAssistB or base[3]}
    elseif kit == 'OnMyWay' then
        return {db.markerTravelR or base[1], db.markerTravelG or base[2], db.markerTravelB or base[3]}
    elseif kit == 'Attack' or kit == 'Warning' or kit == 'Threat' then
        return {db.markerAttackR or base[1], db.markerAttackG or base[2], db.markerAttackB or base[3]}
    end
    return {db.markerDefaultR or base[1], db.markerDefaultG or base[2], db.markerDefaultB or base[3]}
end

local function AtlasExists(atlas)
    if C_Texture and type(C_Texture.GetAtlasInfo) == 'function' then
        local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
        return ok and info ~= nil
    end
    return true
end

local function SetAtlasSafe(texture, atlas, useAtlasSize)
    if not texture or not atlas or not AtlasExists(atlas) then return false end
    return pcall(texture.SetAtlas, texture, atlas, useAtlasSize == true)
end

local function NormalizeName(name)
    if type(name) ~= 'string' then return nil end
    name = name:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then return nil end
    return string.lower(name)
end

local function IsInteractiveTarget(status)
    if not status then return false end
    local t = status.activeIconKey or status.activeTargetType
    if t == 'turnin' or t == 'accept' or t == 'vendor' or t == 'train' or t == 'hearth' then
        return true
    end
    local text = string.lower(tostring(status.activeInstruction or ''))
    local keys = {
        'turn in', 'accept', 'pick up', 'vendor', 'buy ', 'purchase', 'sell ', 'repair',
        'innkeeper', 'hearthstone', 'set hearth', 'train ', 'learn ',
        'abgeben', 'annehmen', 'kaufe', 'verkaufe', 'gasthaus', 'ruhestein', 'trainer',
    }
    for _, key in ipairs(keys) do
        if text:find(key, 1, true) then return true end
    end
    return false
end

local function FormatDistance(distance)
    if type(distance) ~= 'number' then return '' end
    if distance >= 1000 then return string.format('%.1f km', distance / 1000) end
    return string.format((_G.RXPNavigatorLocale and _G.RXPNavigatorLocale:Get('%d yd')) or '%d yd', math.floor(distance + 0.5))
end

local function BuildMarkerFrame(name, parent)
    local f = CreateFrame('Frame', name, parent or UIParent)
    f:SetSize(220, 200)
    f:SetFrameStrata('HIGH')
    f:SetFrameLevel(95)
    f:EnableMouse(false)

    -- The only custom world-marker art we keep: a soft oval floor ring.
    f.groundRing = f:CreateTexture(nil, 'BACKGROUND', nil, 0)
    f.groundRing:SetTexture(GROUND_RING_TEXTURE)
    f.groundRing:SetBlendMode('ADD')
    f.groundRing:SetSize(48, 17)
    f.groundRing:SetPoint('CENTER', f, 'CENTER', 0, 0)
    f.groundRing:Hide()

    -- Blizzard PingUI atlases, with optional local raid-target symbol artwork.
    f.stem = f:CreateTexture(nil, 'BACKGROUND', nil, 1)
    f.stem:SetPoint('BOTTOM', f, 'CENTER', 0, 0)

    f.bg = f:CreateTexture(nil, 'BACKGROUND', nil, 2)
    f.bg:SetPoint('BOTTOM', f.stem, 'TOP', 0, -8)

    f.highlight = f:CreateTexture(nil, 'BACKGROUND', nil, 3)
    f.highlight:SetPoint('CENTER', f.bg, 'CENTER')
    f.highlight:SetAlpha(0.18)

    f.stroke = f:CreateTexture(nil, 'BACKGROUND', nil, 4)
    f.stroke:SetPoint('CENTER', f.bg, 'CENTER')
    f.stroke:SetAlpha(0.34)

    f.icon = f:CreateTexture(nil, 'ARTWORK', nil, 5)
    f.icon:SetPoint('CENTER', f.bg, 'CENTER')

    f.distance = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    f.distance:SetPoint('LEFT', f.bg, 'RIGHT', 7, 0)
    f.distance:SetJustifyH('LEFT')
    f.distance:SetShadowOffset(1, -1)
    f.distance:SetShadowColor(0, 0, 0, 0.95)

    f:Hide()
    return f
end

local function ApplyBlizzardStyle(f, kit, showStem, shortStem, showGroundRing, settings)
    if not f then return end
    local db = settings or API:GetDB()
    if db and db.worldMarkerUseRaidSymbols~=true and STYLE_KITS[db.worldMarkerStyle] then kit=db.worldMarkerStyle end
    kit = kit or 'NonThreat'

    local iconAtlas = ('Ping_Marker_Icon_%s'):format(kit)
    local bgAtlas = ('Ping_GroundMarker_BG_%s'):format(kit)
    local pinAtlas = ('Ping_GroundMarker_Pin_%s'):format(kit)
    local strokeAtlas = ('Ping_GroundMarker_Stroke_%s'):format(kit)

    -- If a requested kit is unavailable on this client, fall back to the
    -- Blizzard blue diamond rather than substituting custom artwork.
    if not SetAtlasSafe(f.icon, iconAtlas, true) then
        kit = 'NonThreat'
        SetAtlasSafe(f.icon, 'Ping_Marker_Icon_NonThreat', true)
        bgAtlas = 'Ping_GroundMarker_BG_NonThreat'
        pinAtlas = 'Ping_GroundMarker_Pin_NonThreat'
        strokeAtlas = 'Ping_GroundMarker_Stroke_NonThreat'
    end

    SetAtlasSafe(f.bg, bgAtlas, true)
    SetAtlasSafe(f.highlight, bgAtlas, true)
    SetAtlasSafe(f.stroke, strokeAtlas, true)

    if showStem then
        SetAtlasSafe(f.stem, pinAtlas, true)
        if shortStem then
            local w, h = f.stem:GetSize()
            w = tonumber(w) or 8
            h = tonumber(h) or 72
            f.stem:SetSize(w, math.max(20, h * 0.5))
        end
        f.stem:Show()

        f.bg:ClearAllPoints()
        f.bg:SetPoint('BOTTOM', f.stem, 'TOP', 0, -8)
        f.highlight:ClearAllPoints()
        f.highlight:SetPoint('CENTER', f.bg, 'CENTER')
        f.stroke:ClearAllPoints()
        f.stroke:SetPoint('CENTER', f.bg, 'CENTER')
    else
        f.stem:Hide()
        f.bg:ClearAllPoints()
        f.bg:SetPoint('CENTER', f, 'CENTER', 0, 18)
        f.highlight:ClearAllPoints()
        f.highlight:SetPoint('CENTER', f.bg, 'CENTER')
        f.stroke:ClearAllPoints()
        f.stroke:SetPoint('CENTER', f.bg, 'CENTER')
    end

    f.icon:ClearAllPoints()
    f.icon:SetPoint('CENTER', f.bg, 'CENTER')

    local color = GetConfiguredKitColor(kit, db)

    if db and db.worldMarkerCustomColors == true then
        f.bg:SetVertexColor(color[1], color[2], color[3], 1)
        f.highlight:SetVertexColor(color[1], color[2], color[3], 1)
        f.stroke:SetVertexColor(color[1], color[2], color[3], 1)
        f.icon:SetVertexColor(color[1], color[2], color[3], 1)
        f.stem:SetVertexColor(color[1], color[2], color[3], 1)
    else
        f.bg:SetVertexColor(1,1,1,1)
        f.highlight:SetVertexColor(1,1,1,1)
        f.stroke:SetVertexColor(1,1,1,1)
        f.icon:SetVertexColor(1,1,1,1)
        f.stem:SetVertexColor(1,1,1,1)
    end

    f.distance:ClearAllPoints()
    f.distance:SetPoint('LEFT', f.bg, 'RIGHT', 7, 0)
    f.distance:SetTextColor(color[1], color[2], color[3], 1)

    local ringEnabled = db and db.showWorldMarkerGroundRing ~= false
    if f.groundRing and ringEnabled and showGroundRing and showStem then
        local ringScale = tonumber(db.worldMarkerGroundRingScale) or 1.0
        ringScale = math.max(0.65, math.min(1.50, ringScale))
        local ringAlpha = tonumber(db.worldMarkerGroundRingAlpha) or 0.72
        ringAlpha = math.max(0.15, math.min(1.0, ringAlpha))

        f.groundRing:SetTexture(GROUND_RING_TEXTURE)
        local rr, rg, rb = color[1], color[2], color[3]
        if db.worldMarkerGroundRingUseMarkerColor == false then
            rr = db.worldMarkerGroundRingR or rr
            rg = db.worldMarkerGroundRingG or rg
            rb = db.worldMarkerGroundRingB or rb
        end
        f.groundRing:SetVertexColor(rr, rg, rb, 1)
        f.groundRing:SetSize(48 * ringScale, 17 * ringScale)
        f.groundRing:SetAlpha(ringAlpha)
        f.groundRing:ClearAllPoints()
        f.groundRing:SetPoint('CENTER', f.stem, 'BOTTOM', 0, 0)
        f.groundRing:Show()
    elseif f.groundRing then
        f.groundRing:Hide()
    end

    f.bg:Show()
    f.highlight:Show()
    f.stroke:Show()
    f.icon:Show()

    local raidSymbol = Navigator.WorldMarker and Navigator.WorldMarker:GetLocalRaidSymbolIndex(db)
    if raidSymbol then
        f.icon:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcon_' .. raidSymbol)
        f.icon:SetTexCoord(0, 1, 0, 1)
        f.icon:SetSize(28, 28)
        -- Raid symbols retain their recognizable colors, even with custom colors.
        f.icon:SetVertexColor(1, 1, 1, 1)
        f.bg:Hide()
        f.highlight:Hide()
        f.stroke:Hide()
    end
end

-- An isolated preview uses exactly the production artwork, without acquiring
-- navigation ownership or touching Blizzard's live frame.
function Visual:CreatePreview(parent)
    local f = BuildMarkerFrame(nil, parent)
    if parent and parent.GetFrameStrata then f:SetFrameStrata(parent:GetFrameStrata()) end
    if parent and parent.GetFrameLevel then f:SetFrameLevel(parent:GetFrameLevel()+5) end
    f:SetPoint('CENTER', parent, 'CENTER', -25, -38)
    return f
end

function Visual:RefreshPreview(f, kit, settings)
    local db = settings or API:GetDB() or {}
    ApplyBlizzardStyle(f, kit or 'OnMyWay', db.showWorldMarkerBeam ~= false, false, true, db)
    f:SetScale(math.max(0.70, math.min(1.40, tonumber(db.worldMarkerScale) or 1)))
    f.distance:SetText(FormatDistance(63))
    f.distance:SetShown(db.showWorldMarkerDistance ~= false)
    f:Show()
end

local function GetNamePlateForUnitSafe(unit)
    if not unit or not C_NamePlate or type(C_NamePlate.GetNamePlateForUnit) ~= 'function' then return nil end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then return plate end
    return nil
end

local function FindNamePlateByGUID(guid)
    if not guid then return nil end
    if UnitExists and UnitExists('target') and UnitGUID and UnitGUID('target') == guid then
        local plate = GetNamePlateForUnitSafe('target')
        if plate then return plate end
    end
    for unit, plate in pairs(visibleNameplates) do
        if plate and plate:IsShown() and UnitExists and UnitExists(unit) and UnitGUID and UnitGUID(unit) == guid then
            return plate
        end
    end
    return nil
end

local function FindExactNPCPlate(status)
    local db = API:GetDB()
    if not db or db.worldMarkerNPCAutoAnchor == false then return nil end
    if not IsInteractiveTarget(status) then return nil end
    local distance = tonumber(status.activeTargetDistance)
    local maxDistance = tonumber(db.worldMarkerNPCMaxDistance) or 75
    if not distance or distance > maxDistance then return nil end

    local wanted = NormalizeName(status.activeTargetName)
    if not wanted then return nil end

    for unit, plate in pairs(visibleNameplates) do
        if plate and plate:IsShown() and UnitExists and UnitExists(unit) then
            local isPlayer = UnitIsPlayer and UnitIsPlayer(unit) == true
            if not isPlayer and NormalizeName(UnitName and UnitName(unit) or nil) == wanted then
                return plate
            end
        end
    end
    return nil
end

local function ParentMarkerToPlate(f, plate, yOffset)
    if not f or not plate then return false end
    -- No restricted nameplate geometry is read. Our own frame is simply
    -- parented to Blizzard's nameplate and WoW maintains its screen position.
    f:SetParent(plate)
    f:ClearAllPoints()
    f:SetPoint('BOTTOM', plate, 'TOP', 0, yOffset or 8)
    f:SetFrameStrata('TOOLTIP')
    f:SetFrameLevel(200)
    return true
end

local function ResetMarkerParent(f)
    if not f then return end
    if f.groundRing then f.groundRing:Hide() end
    if f.stem then f.stem:Hide() end
    if f.bg then f.bg:Hide() end
    if f.highlight then f.highlight:Hide() end
    if f.stroke then f.stroke:Hide() end
    if f.icon then f.icon:Hide() end
    f:Hide()
    f:SetParent(UIParent)
    f:ClearAllPoints()
end

function Visual:StartNPCTest(unit)
    unit = unit or 'target'
    if not UnitExists or not UnitExists(unit) then
        API:Print(API:Localize('NPC test: no NPC selected.'))
        return false
    end
    if UnitIsPlayer and UnitIsPlayer(unit) then
        API:Print(API:Localize('NPC test: select an NPC, not a player.'))
        return false
    end
    npcTestGUID = UnitGUID and UnitGUID(unit) or nil
    npcTestName = UnitName and UnitName(unit) or 'NPC'
    npcTestUntil = (GetTime and GetTime() or 0) + NPC_TEST_DURATION_SECONDS
    if not npcTestGUID then return false end
    API:Print(string.format(API:Localize('NPC test active: %s. Settings are unchanged.'), tostring(npcTestName)))
    return true
end

function Visual:StopNPCTest()
    npcTestGUID, npcTestName, npcTestUntil = nil, nil, nil
    ResetMarkerParent(npcTestFrame)
    API:Print(API:Localize('NPC test ended.'))
end

function Visual:GetNPCTestStatus()
    local active = npcTestGUID ~= nil and (not npcTestUntil or not GetTime or GetTime() < npcTestUntil)
    return {
        active = active,
        name = npcTestName,
        remaining = active and math.max(0, npcTestUntil - GetTime()) or 0,
        plateVisible = active and FindNamePlateByGUID(npcTestGUID) ~= nil or false,
    }
end

local function UpdateNPCTest()
    if not npcTestGUID then ResetMarkerParent(npcTestFrame); return end
    if npcTestUntil and GetTime and GetTime() >= npcTestUntil then
        Visual:StopNPCTest(); return
    end
    local plate = FindNamePlateByGUID(npcTestGUID)
    if not plate or not plate:IsShown() then ResetMarkerParent(npcTestFrame); return end
    if not npcTestFrame then npcTestFrame = BuildMarkerFrame('RXPNavigatorNPCTestFrame', UIParent) end
    ParentMarkerToPlate(npcTestFrame, plate, 8)
    ApplyBlizzardStyle(npcTestFrame, 'Assist', true, true, false)
    npcTestFrame.distance:SetText(API:Localize('NPC TEST: ') .. tostring(npcTestName or '?'))
    npcTestFrame.distance:Show()
    npcTestFrame:Show()
end

local function ShouldSuppressNativeSuperTrack()
    local db = API:GetDB()
    if not db or db.worldMarkerHideBlizzard == false then return false end
    if not Navigator.WorldMarker or not Navigator.WorldMarker.GetStatus then return false end
    local status = Navigator.WorldMarker:GetStatus()
    return status and status.owned == true
end

-- Cosmetic replacement only: never stop the native parent update or
-- alter the navigation state's alpha table. Hidden regions keep their anchors.
local stockVisuals = setmetatable({}, {__mode = 'k'})
local function HideArtwork(region)
    if not region or type(region.Hide) ~= 'function' or type(region.IsShown) ~= 'function' then return end
    local record = stockVisuals[region]
    if not record then
        record = {restoreShown = region:IsShown(), muted = false}
        stockVisuals[region] = record
        if hooksecurefunc then
            if type(region.Show) == 'function' then
                hooksecurefunc(region, 'Show', function()
                    if record.muted then record.restoreShown = true; region:Hide() end
                end)
            end
            if type(region.SetShown) == 'function' then
                hooksecurefunc(region, 'SetShown', function(_, visible)
                    if record.muted then
                        record.restoreShown = visible == true
                        if visible then region:Hide() end
                    end
                end)
            end
        end
    elseif not record.muted then
        record.restoreShown = region:IsShown()
    end
    record.muted = true
    region:Hide()
end

local function RestoreNativeSuppression()
    for region, record in pairs(stockVisuals) do
        if record.muted then
            record.muted = false
            if record.restoreShown then region:Show() else region:Hide() end
        end
    end
end

local function HideNativeArtwork(owner)
    if not owner then return end
    if type(owner.GetRegions) == 'function' then
        for _, region in ipairs({owner:GetRegions()}) do HideArtwork(region) end
    end
    if type(owner.GetChildren) == 'function' then
        for _, child in ipairs({owner:GetChildren()}) do HideArtwork(child) end
    end
end

local function ApplyNativeSuppression()
    if not ShouldSuppressNativeSuperTrack() then RestoreNativeSuppression(); return end
    local face = _G.SuperTrackedFrame
    if face then
        for _, name in ipairs({'Icon', 'IconBorder', 'DistanceText', 'Arrow'}) do HideArtwork(face[name]) end
        HideNativeArtwork(face)
    end
    -- Only artwork underneath the engine host is suppressed, not the host
    -- itself. Our replacement is an independent UIParent frame.
    HideNativeArtwork(navFrame)
end

local function ObtainNavigationFrame()
    if not (C_Navigation and type(C_Navigation.GetFrame) == 'function') then return nil end
    local ok, frame = pcall(C_Navigation.GetFrame)
    if not ok then return nil end
    navFrame = frame
    return frame
end

function Visual:GetWaypointAnchor(frame)
    if not frame then return nil end
    local face = _G.SuperTrackedFrame
    return (face and face.Icon) or frame
end

local function EnsureWorldFrame(frame)
    if not frame then return nil end
    local anchor = Visual:GetWaypointAnchor(frame)
    if not worldFrame then
        worldFrame = BuildMarkerFrame('RXPNavigatorWorldMarkerFrame', UIParent)
        worldFrame:SetSize(1, 1)
    end
    if worldFrame.rxpAnchor ~= anchor then
        worldFrame:ClearAllPoints()
        worldFrame:SetPoint('CENTER', anchor, 'CENTER', 0, 0)
        worldFrame.rxpAnchor = anchor
    end
    return worldFrame
end

local function EnsureNPCAutoFrame(plate)
    if not npcAnchorFrame then npcAnchorFrame = BuildMarkerFrame('RXPNavigatorNPCAutoAnchorFrame', UIParent) end
    ParentMarkerToPlate(npcAnchorFrame, plate, 8)
    return npcAnchorFrame
end

function Visual:Refresh()
    local db = API:GetDB()
    ApplyNativeSuppression()

    if not db or not db.enabled or db.showWorldMarkerNative ~= true
       or not Navigator.WorldMarker or not Navigator.WorldMarker.GetStatus then
        if worldFrame then worldFrame:Hide() end
        ResetMarkerParent(npcAnchorFrame)
        return
    end

    local status = Navigator.WorldMarker:GetStatus()
    if not status or status.owned ~= true then
        if worldFrame then worldFrame:Hide() end
        ResetMarkerParent(npcAnchorFrame)
        ApplyNativeSuppression()
        return
    end

    local distance = tonumber(status.activeTargetDistance)
    local kit = status.activePingTextureKit or 'NonThreat'
    local beamRange = tonumber(db.worldMarkerBeamDistance) or tonumber(status.beamShowDistanceYards) or DEFAULT_BEAM_SHOW_DISTANCE_YARDS
    local scale = tonumber(db.worldMarkerScale) or 1.0
    scale = math.max(0.70, math.min(1.40, scale))

    -- One production anchor path only. Automatic nameplate snapping used to
    -- switch the visual away from the actual native waypoint. The explicit
    -- NPC test command remains available separately.
    ResetMarkerParent(npcAnchorFrame)
    local frame = ObtainNavigationFrame()
    if not frame or (frame.IsShown and not frame:IsShown()) then
        if worldFrame then worldFrame:Hide() end
        return
    end
    if C_Navigation and C_Navigation.HasValidScreenPosition then
        local ok, valid = pcall(C_Navigation.HasValidScreenPosition)
        if not ok or not valid then
            if worldFrame then worldFrame:Hide() end
            return
        end
    end
    if C_Navigation and C_Navigation.WasClampedToScreen then
        local ok, clamped = pcall(C_Navigation.WasClampedToScreen)
        if not ok or clamped then
            if worldFrame then worldFrame:Hide() end
            return
        end
    end

    local f = EnsureWorldFrame(frame)
    f:SetScale(scale)
    local showStem = db.showWorldMarkerBeam ~= false
        and type(distance) == 'number'
        and distance <= beamRange

    ApplyBlizzardStyle(f, kit, showStem, false, true)
    f.distance:SetText(FormatDistance(distance))
    f.distance:SetShown(db.showWorldMarkerDistance ~= false)
    f:Show()
    ApplyNativeSuppression()
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGIN')
events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:RegisterEvent('NAVIGATION_FRAME_CREATED')
events:RegisterEvent('NAVIGATION_FRAME_DESTROYED')
events:RegisterEvent('SUPER_TRACKING_PATH_UPDATED')
events:RegisterEvent('NAME_PLATE_UNIT_ADDED')
events:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
events:RegisterEvent('PLAYER_LOGOUT')
events:SetScript('OnEvent', function(_, event, unit)
    if event == 'PLAYER_LOGOUT' then
        RestoreNativeSuppression()
        return
    elseif event == 'NAME_PLATE_UNIT_ADDED' then
        local plate = GetNamePlateForUnitSafe(unit)
        if plate then visibleNameplates[unit] = plate end
    elseif event == 'NAME_PLATE_UNIT_REMOVED' then
        if unit then visibleNameplates[unit] = nil end
    elseif event == 'NAVIGATION_FRAME_DESTROYED' then
        navFrame = nil
        if worldFrame then worldFrame:Hide() end
    else
        ObtainNavigationFrame()
    end
    elapsed = UPDATE_INTERVAL
end)

events:SetScript('OnUpdate', function(_, dt)
    elapsed = elapsed + (dt or 0)
    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0
    local ok = pcall(UpdateNPCTest)
    if not ok then ResetMarkerParent(npcTestFrame) end
    local ok2 = pcall(Visual.Refresh, Visual)
    if not ok2 then
        if worldFrame then worldFrame:Hide() end
        ResetMarkerParent(npcAnchorFrame)
    end
end)
