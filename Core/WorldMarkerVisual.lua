local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end

local API = Navigator.API
Navigator.WorldMarkerVisual = Navigator.WorldMarkerVisual or {}
local Visual = Navigator.WorldMarkerVisual

local UPDATE_INTERVAL = 0.08
local DEFAULT_BEAM_SHOW_DISTANCE_YARDS = 65
local NPC_TEST_DURATION_SECONDS = 120

local elapsed = 0
local navFrame
local worldFrame
local npcTestFrame
local visibleNameplates = {}
local npcTestGUID, npcTestName, npcTestUntil

function Visual:ApplyPanelArtwork(frame, texture)
    local function CardSlice(u1,u2)
        local slice = frame:CreateTexture(nil,'BACKGROUND')
        slice:SetTexture(texture)
        slice:SetTexCoord(u1,u2,0,1)
        return slice
    end
    local left, middle, right = CardSlice(0,.15625), CardSlice(.15625,.84375), CardSlice(.84375,1)
    left:SetWidth(10)
    left:SetPoint('TOPLEFT')
    left:SetPoint('BOTTOMLEFT')
    right:SetWidth(10)
    right:SetPoint('TOPRIGHT')
    right:SetPoint('BOTTOMRIGHT')
    middle:SetPoint('TOPLEFT',left,'TOPRIGHT')
    middle:SetPoint('BOTTOMRIGHT',right,'BOTTOMLEFT')
end

local function BuildMarkerFrame(name, parent)
    local f = CreateFrame('Frame', name, parent or UIParent)
    f:SetSize(220, 200)
    f:SetFrameStrata('HIGH')
    f:SetFrameLevel(95)
    f:EnableMouse(false)

    f.stem = f:CreateTexture(nil, 'BACKGROUND', nil, 1)
    f.stem:SetPoint('BOTTOM', f, 'CENTER', 0, 0)

    f.beamGlow = f:CreateTexture(nil, 'BACKGROUND', nil, 0)
    f.beamGlow:SetTexture('Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_BeaconGlow.tga')
    f.beamGlow:SetPoint('BOTTOM', f, 'CENTER')
    f.beamGlow:SetSize(42, 116)
    f.beamGlow:SetBlendMode('ADD')
    f.beamGlow:Hide()


    f.icon = f:CreateTexture(nil, 'ARTWORK', nil, 5)
    f.icon:SetPoint('CENTER', f, 'CENTER')

    f.distance = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    f.distance:SetPoint('TOP', f, 'CENTER', 0, -22)
    f.distance:SetJustifyH('CENTER')
    f.distance:SetShadowOffset(1, -1)
    f.distance:SetShadowColor(0, 0, 0, 0.95)

    f.pinPlate = f:CreateTexture(nil,'BACKGROUND',nil,2)
    f.pinPlate:SetTexture('Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_BeaconPin.tga')
    f.pinPlate:SetSize(38,38)
    f.pinPlate:SetPoint('CENTER',f,'CENTER')
    f.pinPlate:Hide()

    f.targetCard = CreateFrame('Frame',nil,f)
    f.targetCard:SetSize(160,40)
    f.targetCard:SetPoint('BOTTOM',f,'CENTER',0,26)
    Visual:ApplyPanelArtwork(f.targetCard,'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_PinpointPanel.tga')

    f.targetName = f.targetCard:CreateFontString(nil,'OVERLAY','GameFontNormal')
    f.targetName:SetPoint('TOP',f.targetCard,'TOP',0,-7)
    f.targetName:SetShadowColor(0,0,0,.95)
    f.targetName:SetShadowOffset(1,-1)
    f.targetName:SetJustifyH('CENTER')
    f.targetName:SetWordWrap(true)
    f.cardObjective = f.targetCard:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    f.cardObjective:SetPoint('TOP',f.targetName,'BOTTOM',0,-4)
    f.cardObjective:SetJustifyH('CENTER')
    f.cardObjective:SetWordWrap(true)
    f.cardObjective:SetTextColor(.94,.86,.68,1)
    f.cardDistance = f.targetCard:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    f.cardDistance:SetPoint('TOP',f.targetName,'BOTTOM',0,-3)
    f.cardDistance:SetTextColor(.73,.69,.60,1)
    f.chevrons = f.targetCard:CreateTexture(nil,'ARTWORK')
    f.chevrons:SetTexture('Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_BeaconChevrons.tga')
    f.chevrons:SetSize(13,17)
    f.chevrons:SetAlpha(.74)
    f.chevrons:SetPoint('TOP',f.targetCard,'BOTTOM')
    f.targetCard:Hide()

    f:Hide()
    return f
end

local BEACON_ACTIONS = {
    accept   = 'Interface\\GossipFrame\\AvailableQuestIcon',
    turnin   = 'Interface\\GossipFrame\\ActiveQuestIcon',
    talk     = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_talk',
    flight   = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_flight',
    zeppelin = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_zeppelin',
    boat     = 'Interface\\Icons\\INV_Misc_Map_01',
    kill     = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_kill',
    loot     = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_loot',
    vendor   = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_vendor',
    hearth   = 'Interface\\Icons\\INV_Misc_Rune_01',
    travel   = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_travel',
    book     = 'Interface\\Icons\\INV_Misc_Note_06',
    repair   = 'Interface\\MINIMAP\\TRACKING\\Repair',
    corpse   = 'Interface\\TargetingFrame\\UI-RaidTargetingIcon_8',
    train    = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_train',
    dungeon  = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_dungeon',
    plunder  = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_plunder',
    useitem  = 'Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Action_useitem',
    default  = 'Interface\\Icons\\INV_Misc_Map_01',
}
local TRANSPORT_ACTIONS = { flight=true, zeppelin=true, boat=true }

local function GetBeaconAction(status)
    if status.activeIconKey == 'corpse' then return 'corpse' end
    local transport = status.activeTransport
    if transport == 'Zeppelin' then return 'zeppelin' end
    if transport == 'Boat' or transport == 'Ship' then return 'boat' end
    if transport == 'Flight' or transport == 'Flight Path' then return 'flight' end
    local action = status.activeIconKey
    if action ~= 'accept' and action ~= 'turnin' then
        local guideAction = status.activeGuideAction or status.activeInstruction
        if API:IsItemUseInstruction(guideAction) then return 'useitem' end
        if API:IsKillInstruction(guideAction) then return 'kill' end
        local lower = (guideAction or ''):lower()
        if lower:match('^plündert?%s') or lower:match('^pluendert?%s')
            or lower:match('^loot%s') then return 'plunder' end
    end
    local instruction = (status.activeInstruction or ''):lower()
    if instruction:find('repair',1,true) or instruction:find('reparier',1,true) then return 'repair' end
    if instruction:find('read the',1,true) or instruction:find('read book',1,true)
        or instruction:find('lies das',1,true) or instruction:find('lies die',1,true) then return 'book' end
    if action == 'default' or not BEACON_ACTIONS[action] then
        if status.activeTargetType == 'vendor' then return 'vendor' end
        if status.activeTargetType == 'talk'
            or instruction:match('^sprich mit ') or instruction:match('^rede mit ')
            or instruction:match('^talk to ') or instruction:match('^speak to ') then return 'talk' end
        if status.activeTargetType == 'travel'
            or instruction:match('^geht ') or instruction:match('^gehe ')
            or instruction:match('^reist ') or instruction:match('^go ')
            or instruction:match('^travel ') then return 'travel' end
    end
    return BEACON_ACTIONS[action] and action or 'default'
end

local function GetActionTexture(action)
    return BEACON_ACTIONS[action] or BEACON_ACTIONS.default
end

local function ApplyBeacon(f, beamHeight, near, action)
    if f.beaconHeight == beamHeight and f.beaconNear == near and f.beaconAction == action then return end
    f.beaconHeight, f.beaconNear, f.beaconAction = beamHeight, near, action
    f.icon:SetSize(16,16)
    action = action or 'default'
    local r,g,b = 1,.86,.57
    f.icon:SetTexture(GetActionTexture(action))
    f.icon:SetTexCoord(0,1,0,1)
    f.icon:SetVertexColor(1,1,1,1)
    f.pinPlate:SetVertexColor(r,g,b,1)
    f.targetName:SetTextColor(r,g,b,1)
    f.chevrons:SetVertexColor(r,g,b,1)
    f.distance:SetTextColor(r,g,b,1)
    f.chevrons:SetShown(false)
    f.icon:SetShown(not near)
    f.pinPlate:SetShown(not near)
    f.targetCard:SetShown(near == true)
    f.stem:SetShown(beamHeight > 0)
    f.beamGlow:SetShown(beamHeight > 0)
    if beamHeight > 0 then
        f.stem:SetTexture('Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_BeaconGlow.tga')
        f.stem:SetTexCoord(0,1,0,1)
        f.stem:SetSize(7,beamHeight)
        f.stem:SetVertexColor((1+r)/2,(1+g)/2,(1+b)/2,1)
        f.beamGlow:SetSize(31,beamHeight)
        f.beamGlow:SetVertexColor(r,g,b,.58)
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

function Visual:RefreshPreview(f, settings)
    local db = settings or API:GetDB() or {}
    ApplyBeacon(f, db.showWorldMarkerBeam ~= false and 66 or 0, false, 'travel')
    f:SetScale(math.max(0.70, math.min(1.40, tonumber(db.worldMarkerScale) or 1)))
    f.distance:SetText(API:FormatHUDDistance(63, db))
    f.distance:SetShown(db.showWorldMarkerDistance ~= false)
    f:SetShown(db.showWorldMarkerNative == true)
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
    ApplyBeacon(npcTestFrame, 66, false, 'talk')
    npcTestFrame.distance:SetText(API:Localize('NPC TEST: ') .. tostring(npcTestName or '?'))
    npcTestFrame.distance:Show()
    npcTestFrame:Show()
end

local function ShouldSuppressNativeSuperTrack(status)
    local db = API:GetDB()
    if not db or not db.enabled or db.showWorldMarkerNative ~= true or db.worldMarkerHideBlizzard == false
        or not worldFrame or not worldFrame:IsShown() then return false end
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

local function ApplyNativeSuppression(status)
    if not ShouldSuppressNativeSuperTrack(status) then RestoreNativeSuppression(); return end
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

local function EnsureWorldFrame(frame)
    local anchor = frame
    if not anchor then return nil end
    if not worldFrame then
        worldFrame = BuildMarkerFrame('RXPNavigatorWorldMarkerFrame', UIParent)
        worldFrame:SetSize(1, 1)
    end
    if worldFrame.rxpAnchor ~= anchor then
        worldFrame:ClearAllPoints()
        worldFrame:SetPoint('CENTER', anchor, 'CENTER', 0, 0)
        worldFrame.rxpAnchor = anchor
    end
    if worldFrame.rxpPinpointAnchor ~= frame then
        worldFrame.targetCard:ClearAllPoints()
        worldFrame.targetCard:SetPoint('BOTTOM', frame, 'TOP', 0, 75)
        worldFrame.rxpPinpointAnchor = frame
    end
    return worldFrame
end

function Visual:PrintStatus()
    local db = API:GetDB()
    local status = Navigator.WorldMarker and Navigator.WorldMarker:GetStatus()
    local frame = ObtainNavigationFrame()
    local cvar = C_CVar and C_CVar.GetCVar and C_CVar.GetCVar('showInGameNavigation')
    local valid = C_Navigation and C_Navigation.HasValidScreenPosition and C_Navigation.HasValidScreenPosition()
    local clamped = C_Navigation and C_Navigation.WasClampedToScreen and C_Navigation.WasClampedToScreen()
    API:Print(('World marker: style=%s, enabled=%s, Blizzard=%s, owned=%s, frame=%s, valid=%s, clamped=%s, visible=%s, reason=%s'):format(
        'beacon', tostring(db and db.enabled and db.showWorldMarkerNative),
        tostring(cvar), tostring(status and status.owned), tostring(frame ~= nil),
        tostring(valid), tostring(clamped), tostring(worldFrame and worldFrame:IsShown() or false),
        tostring(status and status.waypointReason)))
end

local function GetPinpointContent(status, action)
    if action == 'corpse' then return API:Localize('Corpse'), '', false end
    local area = action == 'loot' or action == 'kill' or action == 'useitem' or action == 'plunder'
        or status.activeTargetType == 'loot' or status.activeTargetType == 'kill'
    if status.activeTravelTitle then return status.activeTravelTitle, '', false end
    local instruction = status.activeInstruction
    local counter = instruction and instruction:match('%d+%s*/%s*%d+%s*$') and instruction or nil
    area = area or counter ~= nil or status.activeGuideAction ~= nil
    local title = status.activeGuideAction or (not counter and instruction or nil)
    local objective = area and (status.activeObjective or counter or status.activeItemName) or nil
    if not title or title == '' then
        title = status.activeTargetName
        if area and (not title or title == '' or title == objective or title:match('%d+%s*/%s*%d+%s*$')) then
            title = API:Localize('Objective')
        end
    elseif objective and objective ~= '' then
        -- Separate a plain loot clause when the quest log already gives its objective.
        local first, rest = title:match('^(.-)%.%s+(.+)$')
        if first and not rest:find('%.%s+%S') then
            local clause = rest:lower()
            if clause:match('^loot%s') or clause:match('^plündert%s') then title = first end
        end
    end
    if not title or title == '' then
        local label = action == 'zeppelin' and 'Zeppelin'
            or action == 'boat' and 'Ship'
            or action == 'flight' and 'Flight' or 'Navigation'
        title = API:Localize(label)
    end
    if objective == title then objective = nil end
    return title, objective or '', area
end

function Visual:GetObjectiveContent(status)
    local action = GetBeaconAction(status)
    local title, objective, area = GetPinpointContent(status, action)
    return title, objective, area, GetActionTexture(action)
end

local function IsConversation(status, action, title, area)
    if area or TRANSPORT_ACTIONS[action] or not title or title == ''
        or title == 'Zum RestedXP-Ziel' or title == 'RestedXP-Ziel'
        or title == API:Localize('Navigation') then return false end
    return action == 'accept' or action == 'turnin' or action == 'talk'
end

local function UpdatePinpoint(f, title, objective, distanceText)
    if f.lastTargetName ~= title or f.lastCardObjective ~= objective then
        f.lastTargetName, f.lastCardObjective = title, objective
        f.targetName:SetWidth(0)
        f.cardObjective:SetWidth(0)
        f.targetName:SetText(title)
        f.cardObjective:SetText(objective)
        local width = math.max(100, math.min(290, math.ceil(math.max(
            f.targetName:GetStringWidth(), f.cardObjective:GetStringWidth()))))
        f.targetName:SetWidth(width)
        f.cardObjective:SetWidth(width)
        f.cardObjective:SetShown(objective ~= '')
        f.cardDistance:ClearAllPoints()
        f.cardDistance:SetPoint('TOP',objective ~= '' and f.cardObjective or f.targetName,'BOTTOM',0,-3)
        f.pinpointWidth = width + 20
        f.pinpointHeight = math.ceil(f.targetName:GetStringHeight())
            + (objective ~= '' and math.ceil(f.cardObjective:GetStringHeight()) + 4 or 0) + 14
    end
    if f.lastCardDistance ~= distanceText then
        f.lastCardDistance = distanceText
        f.cardDistance:SetText(distanceText)
        f.cardDistance:SetShown(distanceText ~= '')
    end
    f.targetCard:SetSize(f.pinpointWidth, f.pinpointHeight + (distanceText == '' and 0 or 13))
end

function Visual:Refresh()
    local db = API:GetDB()
    if not db or not db.enabled or db.showWorldMarkerNative ~= true
       or not Navigator.WorldMarker or not Navigator.WorldMarker.GetStatus then
        if worldFrame then worldFrame:Hide() end
        RestoreNativeSuppression()
        return
    end

    local status = Navigator.WorldMarker:GetStatus()
    if not status or status.owned ~= true then
        if worldFrame then worldFrame:Hide() end
        RestoreNativeSuppression()
        return
    end

    local distance = tonumber(status.activeTargetDistance)
    local beamRange = tonumber(db.worldMarkerBeamDistance) or tonumber(status.beamShowDistanceYards) or DEFAULT_BEAM_SHOW_DISTANCE_YARDS
    local scale = tonumber(db.worldMarkerScale) or 1.0
    scale = math.max(0.70, math.min(1.40, scale))

    local threshold = beamRange + (worldFrame and worldFrame.beaconNear and 2 or -2)
    local action = GetBeaconAction(status)
    local near, clamped, title, objective, area
    near = false
    if distance ~= nil and distance <= threshold then
        if status.activeConversationTitle then
            title, objective, area = status.activeConversationTitle, status.activeConversationNote or '', false
            near = true
        else
            title, objective, area = GetPinpointContent(status, action)
            near = IsConversation(status, action, title, area)
        end
    end
    local frame = ObtainNavigationFrame()
    if not frame or (frame.IsShown and not frame:IsShown()) then
        if worldFrame then worldFrame:Hide() end
        RestoreNativeSuppression()
        return
    end
    if C_Navigation and C_Navigation.HasValidScreenPosition then
        local ok, valid = pcall(C_Navigation.HasValidScreenPosition)
        if not ok or not valid then
            if worldFrame then worldFrame:Hide() end
            RestoreNativeSuppression()
            return
        end
    end
    if C_Navigation and C_Navigation.WasClampedToScreen then
        local ok
        ok, clamped = pcall(C_Navigation.WasClampedToScreen)
        if not ok then
            if worldFrame then worldFrame:Hide() end
            RestoreNativeSuppression()
            return
        end
        if clamped then near = false end
    end

    local f = EnsureWorldFrame(frame)
    if f.lastScale ~= scale then f:SetScale(scale); f.lastScale = scale end
    local showBeam = not clamped and not near and db.showWorldMarkerBeam ~= false
        and distance ~= nil and distance <= beamRange
    if near then
        local detail = db.showWorldMarkerDistance ~= false and (distance and API:FormatHUDDistance(distance) or '') or ''
        UpdatePinpoint(f, title, objective, detail)
    end
    ApplyBeacon(f, showBeam and 215 or 0, near, action)
    f.chevrons:SetShown(near and not area and not TRANSPORT_ACTIONS[action])
    local distanceText = (distance and API:FormatHUDDistance(distance) or '')
    if f.lastDistanceText ~= distanceText then
        f.lastDistanceText = distanceText
        f.distance:SetText(distanceText)
    end
    f.distance:SetShown(not near and db.showWorldMarkerDistance ~= false and distanceText ~= "")
    f:Show()
    ApplyNativeSuppression(status)
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
    local started = Navigator.navigationProfileActive and debugprofilestop()
    local ok2 = pcall(Visual.Refresh, Visual)
    if started then
        Navigator:RecordNavigationTiming("World marker", debugprofilestop() - started)
    end
    if not ok2 then
        if worldFrame then worldFrame:Hide() end
    end
end)
