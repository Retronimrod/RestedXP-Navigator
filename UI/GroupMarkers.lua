local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end
local API = Navigator.API
local panel, shareButton
local lastSharedAt
local elapsed = 0
local de = GetLocale and GetLocale() == "deDE"
local function L(german, english) return API.Localize and API:Localize(english) or (de and german or english) end

local function GetChannel()
    if not IsInGroup or not IsInGroup() then return nil end
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    return "PARTY"
end

local function GetLink()
    local marker = Navigator.WorldMarker
    return marker and marker.GetShareableWaypointLink and marker:GetShareableWaypointLink()
end

local function Tooltip(button, title, text)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(text, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function ShareTarget()
    -- Resolve at click time: the guide, group or user waypoint may have changed.
    local channel, link = GetChannel(), GetLink()
    if not channel or not link then
        API:Print(L("Kein aktuelles Navigationsziel zum Teilen oder keine Gruppe.", "No current navigation destination to share, or no group."))
        return
    end
    local now = GetTime()
    if lastSharedAt and now - lastSharedAt < 3 then return end
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if type(send) ~= "function" then return end
    local ok = pcall(send, "RestedXP: " .. link, channel)
    if ok then lastSharedAt = now end
end

local function CreatePanel()
    if panel or (InCombatLockdown and InCombatLockdown()) then return end
    -- Independent parent: hiding the frequently updated navigation header must
    -- never attempt to hide a protected action button during combat.
    panel = CreateFrame("Frame", "RXPNavigatorGroupMarkers", UIParent)
    panel:SetSize(330, 28)
    panel:SetPoint("TOP", UIParent, "TOP", 0, -90)
    panel:SetFrameStrata("HIGH")
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.015, 0.025, 0.035, 0.88)

    shareButton = Navigator.UI and Navigator.UI:Button(panel,"Share target",108,22) or CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    shareButton:SetSize(108, 22)
    shareButton:SetPoint("LEFT", 4, 0)
    shareButton:SetText(L("Ziel teilen", "Share target"))
    if shareButton.GetFontString then
        local label = shareButton:GetFontString()
        if label then label:SetScale(math.min(1, 100 / math.max(1, label:GetStringWidth()))) end
    end
    shareButton:SetScript("OnClick", ShareTarget)
    Tooltip(shareButton, L("Ziel teilen", "Share target"), L(
        "Sendet den aktuellen Navigationspunkt als klickbaren Kartenlink in den Gruppenchat. Setzt keinen Raid-Weltmarker.",
        "Sends the current navigation point as a clickable map link to group chat. Does not place a raid world marker."))

    if type(PlaceRaidMarker) == "function" then
        -- World-marker indices differ from unit raid-target icon indices.
        local icons = {6, 4, 3, 7, 1, 2, 5, 8}
        for index, icon in ipairs(icons) do
            local button = CreateFrame("Button", nil, panel, "SecureActionButtonTemplate")
            button:SetSize(23, 23)
            button:SetPoint("LEFT", 116 + (index - 1) * 26, 0)
            button:RegisterForClicks("AnyUp", "AnyDown")
            button:SetAttribute("type1", "worldmarker")
            button:SetAttribute("marker1", index)
            button:SetAttribute("action1", "set")
            -- Clear this marker only, never the group's entire marker layout.
            button:SetAttribute("type2", "worldmarker")
            button:SetAttribute("marker2", index)
            button:SetAttribute("action2", "clear")
            local texture = button:CreateTexture(nil, "ARTWORK")
            texture:SetAllPoints()
            texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. icon)
            button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            Tooltip(button, _G["WORLD_MARKER" .. index] or L("Raid-Weltmarker ", "Raid world marker ") .. index, L(
                "Linksklick: Platzierungsmodus öffnen, danach auf den Boden klicken. Rechtsklick: diesen Marker entfernen. Gruppenrechte und Reichweite bestimmt WoW; keine automatische Platzierung am Navigationsziel.",
                "Left-click: open placement targeting, then click the ground. Right-click: clear this marker. WoW determines permissions and range; no automatic placement at the navigation destination."))
        end
    end
    panel:Hide()
    if Navigator.LayoutEditor then Navigator.LayoutEditor:Register('Group',panel) end
end

local function Refresh()
    -- No protected frame creation, visibility or attribute writes in combat.
    -- Visibility catches up immediately on PLAYER_REGEN_ENABLED.
    if InCombatLockdown and InCombatLockdown() then return end
    CreatePanel()
    local db = API:GetDB()
    if (Navigator.LayoutEditor and Navigator.LayoutEditor:IsEditing())
        or not db or not db.enabled or db.showWorldMarkerHeader == false
        or db.showWorldMarkerNative ~= true or not GetChannel() or not GetLink() then
        panel:Hide()
        return
    end
    local header = _G.RXPNavigatorWorldMarkerHeader
    if header and header:IsShown() and db.layoutGroupX == nil and db.layoutGroupY == nil then
        panel:ClearAllPoints()
        panel:SetPoint("TOP",header,"BOTTOM",0,-4)
    end
    panel:Show()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:SetScript("OnEvent", Refresh)
events:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.5 then return end
    elapsed = 0
    Refresh()
end)
