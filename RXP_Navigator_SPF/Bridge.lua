local owner, bridge = ...
local navigator = RXPNavigator and RXPNavigator.API
local frame = CreateFrame("Frame")
local submitted
local elapsed = 0
local kinds = {accept = "pickup", turnin = "turnin", kill = "objective", loot = "objective"}

local function Router()
    local api = ShortestPathForever and ShortestPathForever.API
    if api and (api.version == 1 or api.version == 2) and type(api.NavigateRoute) == "function"
        and type(api.Cancel) == "function" and type(api.CurrentStop) == "function"
        and type(api.Active) == "function" then return api end
end

-- Use SPF's registered settings so its callbacks refresh the display.
local function SyncSPFDisplay(db, enabled)
    if InCombatLockdown() or not Settings or not Settings.GetSetting then return end
    local previous = db.previousSPFDisplay or {}
    local function SyncSetting(key, override)
        local setting = Settings.GetSetting("ShortestPathForever_" .. key)
        if not setting then return end
        local value = setting:GetValue()
        if override ~= nil then
            if previous[key] == nil then previous[key] = value end
            if value ~= override then setting:SetValue(override) end
        elseif previous[key] ~= nil then
            if value ~= previous[key] then setting:SetValue(previous[key]) end
            previous[key] = nil
        end
    end

    local hudOverride
    if enabled and db.hideSPFHUD ~= false then hudOverride = false end
    local trackerOverride = enabled and true or nil
    SyncSetting("arrow", hudOverride)
    SyncSetting("compass", hudOverride)
    SyncSetting("journeyTracker", trackerOverride)
    SyncSetting("tracker", trackerOverride)
    db.previousSPFDisplay = next(previous) and previous or nil
end

local function SyncTarget()
    local api = Router()
    if not RXPNavigatorSPFDB then return end
    local settings = navigator and navigator:GetDB()
    SyncSPFDisplay(RXPNavigatorSPFDB, api and RXPNavigatorSPFDB.enabled and settings and settings.enabled)
    if not api or not navigator then return end
    if not RXPNavigatorSPFDB.enabled or not settings or not settings.enabled or UnitIsDeadOrGhost("player") then
        if api.CurrentStop(owner) then api.Cancel(owner) end
        submitted = nil
        return
    end
    local element = navigator:GetCurrentNavigationElement()
    local map, x, y
    if element and not element.corpseNav then map, x, y = navigator:GetTargetMap(element) end
    if not map or not x or not y then
        if api.CurrentStop(owner) then api.Cancel(owner) end
        submitted = nil
        return
    end
    if InCombatLockdown() then return end
    if not api.CurrentStop(owner) then
        if api.Active() then return end
        if type(api.Journey) == "function" then
            local journey, reason = api.Journey()
            if reason == "loading" or (journey and journey.owner ~= owner) then return end
        end
    end

    local resolved = navigator:GetResolvedTarget(element, {ordinal = 1})
    local title = resolved and resolved.title or navigator:GetTargetInstruction(element)
    local kind = kinds[navigator:DetectStepType(element)]
    local questID = resolved and resolved.questID
    local key = table.concat({map, x, y, title or "", kind or "", questID or ""}, "|")
    if submitted == key then return end
    local stop = {map = map, x = x, y = y, title = title, kind = kind, hold = true}
    if type(questID) == "number" and questID > 0 then
        if kind == "objective" then stop.questID = questID end
        if kind == "turnin" then stop.handins = {questID} end
    end
    if api.NavigateRoute(owner, {stop}) then submitted = key end
end

bridge.GetRouter = Router

local function Sync()
    SyncTarget()
    local settings = navigator and navigator:GetDB()
    local db = RXPNavigatorSPFDB
    local enabled = Router() and db and db.enabled and settings and settings.enabled
    bridge.UpdateMapRoutes(enabled and db.hideActiveWorld ~= false, enabled and db.hideActiveMinimap ~= false)
end

local options = {enabled = false, hideSPFHUD = true, hideActiveWorld = true, hideActiveMinimap = true}
local controls = {}

function controls:IsAvailable()
    return Router() ~= nil
end

function controls:CanPreview()
    local api = Router()
    return api and type(api.EstimateDetail) == "function"
end

function controls:GetOption(key)
    local value = RXPNavigatorSPFDB and RXPNavigatorSPFDB[key]
    if value == nil then return options[key] end
    return value
end

function controls:SetOption(key, value)
    if options[key] == nil or not RXPNavigatorSPFDB then return end
    RXPNavigatorSPFDB[key] = value == true
    if key == "enabled" then RXPNavigatorSPFDB.activationOfferV2Answered = true end
    Sync()
end

function controls:OpenPreview(settingsWindow)
    RXPNavigatorSPFPreview(settingsWindow)
end

RXPNavigator.SPFBridge = controls

local canOfferActivation, activationPromptShown
local activationDialog = "RXPNAV_SPF_ACTIVATION"
local function OfferActivation()
    local db = RXPNavigatorSPFDB
    if not canOfferActivation or not db or db.activationOfferV2Answered or activationPromptShown then return end
    if db.enabled then
        db.activationOfferV2Answered = true
        return
    end
    if not controls:IsAvailable() or InCombatLockdown() or UnitIsDeadOrGhost("player") then return end
    local wizard = RXPNavigator.SetupWizard
    if wizard and wizard:IsOpen() then return end
    if not StaticPopupDialogs or not StaticPopup_Show then return end

    StaticPopupDialogs[activationDialog] = {
        text = navigator:Localize("Shortest Path Forever is available. Would you like to enable the SPF bridge for RestedXP-Navigator?"),
        button1 = navigator:Localize("Enable"),
        button2 = navigator:Localize("No, thanks"),
        OnAccept = function()
            controls:SetOption("enabled", true)
            local settings = RXPNavigator.ControlCenter
            if settings then settings:Refresh() end
        end,
        OnCancel = function()
            db.activationOfferV2Answered = true
        end,
        timeout = 0,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    activationPromptShown = StaticPopup_Show(activationDialog) ~= nil
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, addon)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent(event)
        C_Timer.After(2, function() canOfferActivation = true end)
        return
    end
    if addon ~= owner then return end
    RXPNavigatorSPFDB = RXPNavigatorSPFDB or {}
    self:UnregisterEvent("ADDON_LOADED")
end)
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.5 then return end
    elapsed = 0
    Sync()
    OfferActivation()
end)

SLASH_RXPNAVSPF1 = "/rxpspf"
SlashCmdList.RXPNAVSPF = function(msg)
    local command = (msg or ""):lower():match("^%s*(.-)%s*$")
    if command == "route" then controls:OpenPreview(); return end
    if command == "on" or command == "off" then
        controls:SetOption("enabled", command == "on")
        local settings = RXPNavigator.ControlCenter
        if settings then settings:Refresh() end
    end
    local status = not Router() and navigator:Localize("Route API unavailable.")
        or navigator:Localize(RXPNavigatorSPFDB.enabled and "Enabled" or "Disabled")
    print("RXP Shortest Path Bridge: " .. status .. " | /rxpspf on | /rxpspf off | /rxpspf route")
end
