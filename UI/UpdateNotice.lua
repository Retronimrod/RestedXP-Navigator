local Navigator = RXPNavigator
local API = Navigator.API
local version = "1.7.5"

local function ShowNotice()
    local db = RXPNavigatorDB
    if API:GetVersion() ~= version or db.hideSPFUpdateNotice or db.spfUpdateNoticeVersion == version then return end
    local wizard = _G.RXPNavigatorSetupWizard
    if InCombatLockdown() or (wizard and wizard:IsShown()) then
        C_Timer.After(2, ShowNotice)
        return
    end

    local ui = Navigator.UI
    local frame = CreateFrame("Frame", "RXPNavigatorSPFUpdateNotice", UIParent)
    frame:SetPoint("CENTER")
    frame:SetSize(570, 250)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    ui:Window(frame, 570, 250)
    ui:Label(frame, "Shortest Path Forever API update", 22, -22, 526, "GameFontNormalLarge")
    ui:Label(frame, "The bridge now supports SPF API v2. This should fix the locked bridge switch and restore its display controls.", 22, -76, 526)
    ui:Label(frame, "Still having trouble? Open Advanced > Bug Report, copy the report, and include it in your CurseForge comment.", 22, -128, 526)
    local checkbox = ui:Checkbox(frame)
    checkbox:SetPoint("BOTTOMLEFT", 22, 28)
    checkbox:SetScript("OnClick", function(self)
        db.hideSPFUpdateNotice = self:GetChecked() and true or nil
    end)
    ui:Label(frame, "Do not show this message again", 54, -193, 265)
    local close = ui:Button(frame, CLOSE or "Close", 128, 28)
    close:SetPoint("BOTTOMRIGHT", -22, 28)
    close:SetScript("OnClick", function() frame:Hide() end)
    if UISpecialFrames then table.insert(UISpecialFrames, frame:GetName()) end
    db.spfUpdateNoticeVersion = version
    frame:Show()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    C_Timer.After(2, ShowNotice)
end)
