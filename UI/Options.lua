local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end
local API = Navigator.API
Navigator.Options = Navigator.Options or {}

local db
local optionsPanel
local optionsCategory
local defaults = API:GetDefaults()

local function SyncDB()
    db = API:GetDB()
    return db
end

local function L(key) return API:Translate(key) end
local function RefreshAll() return API:RefreshAll() end
local function ApplyHUDPosition() return API:ApplyHUDPosition() end
local function PrintMapDiagnostics(captureOnly) return API:PrintMapDiagnostics(captureOnly) end
local function GenerateBugReport() return API:GenerateBugReport() end
local function ShowInspectorExport() return API:ShowInspectorExport() end
local function GetRXPGuidesAddon() return API:GetRXPGuidesAddon() end
local function Print(message) return API:Print(message) end

local function TabText(key)
    local locale = GetLocale and GetLocale() or "enUS"
    local de = {
        general = "Allgemein",
        minimap = "Minimap",
        worldmap = "Weltkarte",
        hud = "HUD",
        overlays = "Overlays",
        corpse = "Corpse Run",
        advanced = "Erweitert",
    }
    local en = {
        general = "General",
        minimap = "Minimap",
        worldmap = "World Map",
        hud = "HUD",
        overlays = "Overlays",
        corpse = "Corpse Run",
        advanced = "Advanced",
    }
    return (locale == "deDE" and de[key]) or en[key] or key
end

local function Register(panel, control)
    if control and control.Refresh then
        panel.refreshers[#panel.refreshers + 1] = control
    end
    return control
end

local function MakeCheckbox(panel, parent, label, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetSize(26, 26)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)
    cb.label = text
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        RefreshAll()
    end)
    cb.Refresh = function(self) self:SetChecked(getter() and true or false) end
    return Register(panel, cb)
end

local function MakeSlider(panel, parent, label, x, y, width, minVal, maxVal, step, getter, setter, formatter)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(label)

    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y - 24)
    slider:SetWidth(width)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    if slider.Low then slider.Low:SetText(tostring(minVal)) end
    if slider.High then slider.High:SetText(tostring(maxVal)) end
    if slider.Text then slider.Text:SetText("") end

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    slider.valueText = value

    slider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        setter(v)
        value:SetText(formatter and formatter(v) or tostring(v))
        RefreshAll()
    end)
    slider.Refresh = function(self)
        local v = getter()
        self:SetValue(v)
        value:SetText(formatter and formatter(v) or tostring(v))
    end
    return Register(panel, slider)
end

local themeOrder = {"navigator", "emerald", "cyan", "gold", "red", "violet"}
local themeLabelKeys = {
    navigator="theme_navigator", emerald="theme_emerald", cyan="theme_cyan",
    gold="theme_gold", red="theme_red", violet="theme_violet"
}

local function MakeThemeDropdown(panel, parent, x, y)
    local dd = CreateFrame("Frame", "RXPNavigatorThemeDropdown", parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x - 16, y)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(dd, 190) end
    if UIDropDownMenu_JustifyText then UIDropDownMenu_JustifyText(dd, "LEFT") end

    local function SelectTheme(key)
        if not API:HasTheme(key) then return end
        db.theme = key
        if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(dd, key) end
        if UIDropDownMenu_SetText then UIDropDownMenu_SetText(dd, L(themeLabelKeys[key])) end
        RefreshAll()
    end

    if UIDropDownMenu_Initialize then
        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, key in ipairs(themeOrder) do
                local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
                info.text = L(themeLabelKeys[key])
                info.value = key
                info.checked = (db and db.theme == key) or false
                info.func = function() SelectTheme(key) end
                if UIDropDownMenu_AddButton then UIDropDownMenu_AddButton(info, level) end
            end
        end)
    end

    dd.Refresh = function(self)
        local key = (db and db.theme) or "navigator"
        if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(self, key) end
        if UIDropDownMenu_SetText then UIDropDownMenu_SetText(self, L(themeLabelKeys[key])) end
    end
    return Register(panel, dd)
end

local function MakeChoiceDropdown(panel, parent, name, x, y, width, choices, getter, setter)
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x - 16, y)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(dd, width or 160) end
    if UIDropDownMenu_JustifyText then UIDropDownMenu_JustifyText(dd, "LEFT") end

    if UIDropDownMenu_Initialize then
        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, choice in ipairs(choices) do
                local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
                info.text = L(choice.label)
                info.value = choice.value
                info.checked = getter() == choice.value
                info.func = function()
                    setter(choice.value)
                    if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(dd, choice.value) end
                    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(dd, L(choice.label)) end
                    RefreshAll()
                end
                if UIDropDownMenu_AddButton then UIDropDownMenu_AddButton(info, level) end
            end
        end)
    end

    dd.Refresh = function(self)
        local current = getter()
        local label = choices[1].label
        for _, choice in ipairs(choices) do
            if choice.value == current then label = choice.label break end
        end
        if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(self, current) end
        if UIDropDownMenu_SetText then UIDropDownMenu_SetText(self, L(label)) end
    end
    return Register(panel, dd)
end

local function OpenHUDColorPicker(onChanged)
    if not ColorPickerFrame or not db then return end
    local oldR, oldG, oldB = db.hudColorR or 0.08, db.hudColorG or 0.74, db.hudColorB or 1.0
    local function ApplyColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        db.hudColorR, db.hudColorG, db.hudColorB = r, g, b
        if onChanged then onChanged(r, g, b) end
        RefreshAll()
    end
    local function CancelColor(previous)
        local r, g, b = oldR, oldG, oldB
        if type(previous) == "table" then
            r, g, b = previous.r or r, previous.g or g, previous.b or b
        end
        db.hudColorR, db.hudColorG, db.hudColorB = r, g, b
        if onChanged then onChanged(r, g, b) end
        RefreshAll()
    end

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = oldR, g = oldG, b = oldB,
            swatchFunc = ApplyColor,
            cancelFunc = CancelColor,
        })
    else
        ColorPickerFrame:SetColorRGB(oldR, oldG, oldB)
        ColorPickerFrame.func = ApplyColor
        ColorPickerFrame.cancelFunc = CancelColor
        ColorPickerFrame:Show()
    end
end

local function MakeHUDColorButton(panel, parent, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(L("hudColor"))

    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(128, 25)
    b:SetPoint("TOPLEFT", x, y - 22)
    b:SetText("")

    local swatch = b:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", 6, -5)
    swatch:SetPoint("BOTTOMRIGHT", -6, 5)
    b.swatch = swatch

    local function UpdateSwatch(r, g, bl)
        swatch:SetColorTexture(r or db.hudColorR or 0.08, g or db.hudColorG or 0.74, bl or db.hudColorB or 1.0, 1)
    end
    b:SetScript("OnClick", function() OpenHUDColorPicker(UpdateSwatch) end)
    b.Refresh = function() UpdateSwatch() end
    UpdateSwatch()
    return Register(panel, b)
end

local function MakeSectionTitle(parent, text, y)
    local h = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    h:SetPoint("TOPLEFT", 18, y)
    h:SetText(text)
    return h
end

local function CreatePage(panel, key)
    local page = CreateFrame("Frame", nil, panel.body)
    page:SetAllPoints(panel.body)
    page:Hide()
    panel.pages[key] = page
    return page
end

local function BuildGeneralPage(panel)
    local page = CreatePage(panel, "general")
    MakeSectionTitle(page, TabText("general"), -8)

    MakeCheckbox(panel, page, L("enabled"), 18, -48, function() return db.enabled end, function(v) db.enabled=v end)
    MakeCheckbox(panel, page, L("ghostNav"), 340, -48, function() return db.keepGhostNavigation end, function(v) db.keepGhostNavigation=v end)

    local themeLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    themeLabel:SetPoint("TOPLEFT", 18, -96)
    themeLabel:SetText(L("colorTheme"))
    MakeThemeDropdown(panel, page, 18, -114)

    local function ResetSettings()
        for k,v in pairs(defaults) do db[k]=v end
        ApplyHUDPosition()
        RefreshAll()
        Print(L("resetDone"))
        panel:Refresh()
    end

    if StaticPopupDialogs then
        StaticPopupDialogs["RXPNAV_RESET_CONFIRM"] = {
            text = L("resetConfirm"),
            button1 = YES or L("resetConfirmYes"),
            button2 = NO or L("resetConfirmNo"),
            OnAccept = ResetSettings,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    local reset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    reset:SetSize(160, 26)
    reset:SetPoint("TOPLEFT", 18, -200)
    reset:SetText(L("reset"))
    reset:SetScript("OnClick", function()
        if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs["RXPNAV_RESET_CONFIRM"] then
            StaticPopupDialogs["RXPNAV_RESET_CONFIRM"].text = L("resetConfirm")
            StaticPopup_Show("RXPNAV_RESET_CONFIRM")
        else
            ResetSettings()
        end
    end)
end

local function BuildMinimapPage(panel)
    local page = CreatePage(panel, "minimap")
    MakeSectionTitle(page, TabText("minimap"), -8)

    MakeCheckbox(panel, page, L("minimap"), 18, -48, function() return db.showMinimap end, function(v) db.showMinimap=v end)
    MakeCheckbox(panel, page, L("distance"), 340, -48, function() return db.showDistance end, function(v) db.showDistance=v end)
    MakeCheckbox(panel, page, L("animation"), 18, -82, function() return db.animation end, function(v) db.animation=v end)
    MakeCheckbox(panel, page, "Next Steps on Minimap", 340, -82,
        function() return db.showMinimapFutureGoals ~= false end,
        function(v)
            db.showMinimapFutureGoals = v
            if v and (tonumber(db.futureGoals) or 0) <= 0 then db.futureGoals = 3 end
        end)

    local minimapFutureLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapFutureLabel:SetPoint("TOPLEFT", 340, -116)
    minimapFutureLabel:SetText(L("upcomingAmount"))
    local minimapFutureChoices = {}
    for i=0,6 do minimapFutureChoices[#minimapFutureChoices+1] = {value=i,label="future"..i} end
    MakeChoiceDropdown(panel, page, "RXPNavigatorMinimapFutureDropdown", 340, -134, 170, minimapFutureChoices,
        function() return db.futureGoals or 0 end,
        function(v)
            db.futureGoals = v
            if v == 0 then db.showMinimapFutureGoals = false else db.showMinimapFutureGoals = true end
        end)

    local styleLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    styleLabel:SetPoint("TOPLEFT", 18, -138)
    styleLabel:SetText(L("line"))
    local styles = {{key="thin",text=L("thin")},{key="normal",text=L("normal")},{key="strong",text=L("strong")}}
    panel.styleButtons = {}
    for i, info in ipairs(styles) do
        local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        b:SetSize(88,25)
        b:SetPoint("TOPLEFT", 18 + (i-1)*96, -160)
        b:SetText(info.text)
        b.styleKey = info.key
        b:SetScript("OnClick", function(self) db.lineStyle=self.styleKey; RefreshAll(); panel:Refresh() end)
        panel.styleButtons[#panel.styleButtons+1] = b
    end

    MakeSlider(panel, page, L("maxMinimap"), 340, -138, 220, 40, 160, 4,
        function() return db.lineLength end,
        function(v) db.lineLength=v end,
        function(v) return string.format("%d px",v) end)

    MakeSlider(panel, page, L("minimapMarkerSize"), 18, -238, 220, 8, 28, 1,
        function() return db.minimapTargetSize or 14 end,
        function(v) db.minimapTargetSize=v end,
        function(v) return string.format("%d px",v) end)

    MakeSlider(panel, page, L("minimapAnimSpeed"), 340, -238, 220, 0.2, 2.0, 0.1,
        function() return db.minimapAnimationSpeed or 0.5 end,
        function(v) db.minimapAnimationSpeed=v end,
        function(v) return string.format("%.1fx",v) end)

    MakeCheckbox(panel, page, L("minimapButton"), 18, -334,
        function() return db.showMinimapButton ~= false end,
        function(v) db.showMinimapButton=v end)
end

local function BuildWorldMapPage(panel)
    local page = CreatePage(panel, "worldmap")
    MakeSectionTitle(page, TabText("worldmap"), -8)

    MakeCheckbox(panel, page, L("worldmap"), 18, -48, function() return db.showWorldMap end, function(v) db.showWorldMap=v end)
    MakeCheckbox(panel, page, L("marker"), 340, -48, function() return db.showTargetMarker end, function(v) db.showTargetMarker=v end)
    MakeCheckbox(panel, page, L("tooltip"), 18, -82, function() return db.showTaskTooltip end, function(v) db.showTaskTooltip=v end)
    MakeCheckbox(panel, page, L("rxpActiveCircle"), 340, -82,
        function() return db.showRXPActivePinCircle end,
        function(v)
            db.showRXPActivePinCircle=v
            if v then
                local rxp = GetRXPGuidesAddon()
                if type(rxp) == "table" and type(rxp.UpdateMap) == "function" then pcall(rxp.UpdateMap, true) end
            end
            RefreshAll()
        end)

    local futureLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    futureLabel:SetPoint("TOPLEFT", 18, -142)
    futureLabel:SetText(L("upcomingAmount"))
    local futureChoices = {}
    for i=0,6 do futureChoices[#futureChoices+1] = {value=i,label="future"..i} end
    MakeChoiceDropdown(panel, page, "RXPNavigatorFutureDropdown", 18, -160, 170, futureChoices,
        function() return db.futureGoals or 0 end,
        function(v) db.futureGoals=v end)

    local futureDesc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    futureDesc:SetPoint("TOPLEFT", 340, -142)
    futureDesc:SetWidth(290)
    futureDesc:SetJustifyH("LEFT")
    futureDesc:SetText(L("futureDesc"))

    MakeSlider(panel, page, L("worldMarkerSize"), 18, -246, 220, 8, 28, 1,
        function() return db.worldTargetSize or 14 end,
        function(v) db.worldTargetSize=v end,
        function(v) return string.format("%d px",v) end)

    MakeSlider(panel, page, L("worldAnimSpeed"), 340, -246, 220, 0.2, 2.0, 0.1,
        function() return db.worldAnimationSpeed or 0.5 end,
        function(v) db.worldAnimationSpeed=v end,
        function(v) return string.format("%.1fx",v) end)
end

local function BuildHUDPage(panel)
    local page = CreatePage(panel, "hud")
    MakeSectionTitle(page, L("hudSettings"), -8)

    MakeCheckbox(panel, page, L("hudArrow"), 18, -48, function() return db.showHUDArrow end, function(v) db.showHUDArrow=v end)
    MakeCheckbox(panel, page, L("hudLock"), 340, -48, function() return db.hudLocked end, function(v) db.hudLocked=v end)
    MakeCheckbox(panel, page, L("hudDistance"), 18, -82, function() return db.hudShowDistance end, function(v) db.hudShowDistance=v end)
    MakeCheckbox(panel, page, L("hudETA"), 340, -82, function() return db.hudShowETA end, function(v) db.hudShowETA=v end)

    MakeSlider(panel, page, L("hudSize"), 18, -138, 220, 0.55, 2.0, 0.05,
        function() return db.hudSize or 1 end,
        function(v) db.hudSize=v end,
        function(v) return string.format("%d%%", math.floor(v*100+0.5)) end)

    MakeSlider(panel, page, L("hudTextSize"), 340, -138, 220, 0.70, 1.60, 0.05,
        function() return db.hudTextSize or 1 end,
        function(v) db.hudTextSize=v end,
        function(v) return string.format("%d%%", math.floor(v*100+0.5)) end)

    local styleLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    styleLabel:SetPoint("TOPLEFT", 18, -232)
    styleLabel:SetText(L("hudArrowStyle"))
    local styleChoices = {
        {value="classic",label="hudStyleClassic"},
        {value="compass",label="hudStyleCompass"},
        {value="crystal",label="hudStyleCrystal"},
    }
    MakeChoiceDropdown(panel, page, "RXPNavigatorHUDStyleDropdown", 18, -250, 190, styleChoices,
        function() return db.hudArrowStyle or "classic" end,
        function(v) db.hudArrowStyle=v end)

    MakeHUDColorButton(panel, page, 340, -232)

    local resetPos = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    resetPos:SetSize(190,25)
    resetPos:SetPoint("TOPLEFT", 18, -326)
    resetPos:SetText(L("hudResetPos"))
    resetPos:SetScript("OnClick", function()
        db.hudPoint="TOP"; db.hudRelativePoint="TOP"; db.hudX=0; db.hudY=-120
        ApplyHUDPosition(); RefreshAll()
    end)
end

local function BuildOverlaysPage(panel)
    local page = CreatePage(panel, "overlays")
    MakeSectionTitle(page, TabText("overlays"), -8)

    MakeCheckbox(panel, page, L("searchAreas"), 18, -48, function() return db.showSearchAreas end, function(v) db.showSearchAreas=v end)
    MakeCheckbox(panel, page, L("patrolPaths"), 340, -48, function() return db.showPatrolPaths end, function(v) db.showPatrolPaths=v end)
    MakeCheckbox(panel, page, L("farmRoutes"), 18, -82, function() return db.showFarmRoutes end, function(v) db.showFarmRoutes=v end)
    MakeCheckbox(panel, page, L("objectMarkers"), 340, -82, function() return db.showObjectMarkers ~= false end, function(v) db.showObjectMarkers=v end)

    MakeSlider(panel, page, L("searchAreaOpacity"), 18, -150, 220, 0.05, 0.55, 0.01,
        function() return db.searchAreaAlpha or 0.18 end,
        function(v) db.searchAreaAlpha=v end,
        function(v) return string.format("%d%%",math.floor(v*100+0.5)) end)

    MakeSlider(panel, page, L("patrolOpacity"), 340, -150, 220, 0.20, 1.0, 0.02,
        function() return db.patrolAlpha or 0.78 end,
        function(v) db.patrolAlpha=v end,
        function(v) return string.format("%d%%",math.floor(v*100+0.5)) end)

    MakeSlider(panel, page, L("farmOpacity"), 18, -246, 220, 0.20, 1.0, 0.02,
        function() return db.farmAlpha or 0.86 end,
        function(v) db.farmAlpha=v end,
        function(v) return string.format("%d%%",math.floor(v*100+0.5)) end)
end

local function BuildCorpsePage(panel)
    local page = CreatePage(panel, "corpse")
    MakeSectionTitle(page, L("corpseSettings"), -8)

    MakeSlider(panel, page, L("corpseSkullOpacity"), 18, -62, 220, 0.10, 1.0, 0.05,
        function() return db.corpseSkullAlpha or 0.30 end,
        function(v) db.corpseSkullAlpha=v end,
        function(v) return string.format("%d%%",math.floor(v*100+0.5)) end)

    MakeSlider(panel, page, L("corpseHudSkullSize"), 340, -62, 220, 12, 56, 2,
        function() return db.corpseHudSkullSize or 24 end,
        function(v) db.corpseHudSkullSize=v end,
        function(v) return string.format("%d px",v) end)

    MakeSlider(panel, page, L("corpseRouteSkullSize"), 18, -158, 220, 8, 30, 1,
        function() return db.corpseRouteSkullSize or 14 end,
        function(v) db.corpseRouteSkullSize=v end,
        function(v) return string.format("%d px",v) end)

    MakeSlider(panel, page, L("corpseAnimSpeed"), 340, -158, 220, 0.2, 2.0, 0.1,
        function() return db.corpseAnimationSpeed or 0.5 end,
        function(v) db.corpseAnimationSpeed=v end,
        function(v) return string.format("%.1fx",v) end)
end

local function BuildAdvancedPage(panel)
    local page = CreatePage(panel, "advanced")
    MakeSectionTitle(page, TabText("advanced"), -8)

    MakeSlider(panel, page, L("animSpeed"), 18, -62, 220, 0.2, 2.0, 0.1,
        function() return db.animationSpeed end,
        function(v) db.animationSpeed=v; db.minimapAnimationSpeed=v; db.worldAnimationSpeed=v end,
        function(v) return string.format("%.1fx",v) end)

    MakeSlider(panel, page, L("targetSize"), 340, -62, 220, 10, 26, 1,
        function() return db.targetSize end,
        function(v) db.targetSize=v; db.minimapTargetSize=v; db.worldTargetSize=v end,
        function(v) return string.format("%d px",v) end)

    MakeCheckbox(panel, page, L("offscreenIndicator"), 18, -158, function() return db.showOffscreenIndicator end, function(v) db.showOffscreenIndicator=v end)
    MakeCheckbox(panel, page, L("currentHighlight"), 340, -158, function() return db.currentHighlight end, function(v) db.currentHighlight=v end)
    MakeCheckbox(panel, page, L("stepTypeIcons"), 18, -192, function() return db.showStepTypeIcons end, function(v) db.showStepTypeIcons=v end)
    MakeCheckbox(panel, page, L("questProgress"), 340, -192, function() return db.showQuestProgress end, function(v) db.showQuestProgress=v end)
    MakeCheckbox(panel, page, L("zoneHints"), 18, -226, function() return db.showZoneHints end, function(v) db.showZoneHints=v end)
    MakeCheckbox(panel, page, L("transportHints"), 340, -226, function() return db.showTransportHints end, function(v) db.showTransportHints=v end)
    MakeCheckbox(panel, page, L("spiritHealer"), 18, -260, function() return db.showSpiritHealer end, function(v) db.showSpiritHealer=v end)

    local maptest = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    maptest:SetSize(180,25)
    maptest:SetPoint("TOPLEFT",18,-330)
    maptest:SetText(L("mapDiagnostics"))
    maptest:SetScript("OnClick", function() PrintMapDiagnostics(true); ShowInspectorExport() end)

    local bug = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    bug:SetSize(180,25)
    bug:SetPoint("TOPLEFT",210,-330)
    bug:SetText(L("bugReport"))
    bug:SetScript("OnClick", GenerateBugReport)
end

local function SelectTab(panel, key)
    panel.activeTab = key
    for pageKey, page in pairs(panel.pages) do
        if pageKey == key then page:Show() else page:Hide() end
    end
    for tabKey, button in pairs(panel.tabButtons) do
        if tabKey == key then
            button:Disable()
        else
            button:Enable()
        end
    end
end

local function BuildTabs(panel)
    local order = {"general","minimap","worldmap","hud","overlays","corpse","advanced"}
    local x = 14
    for _, key in ipairs(order) do
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        local width = (key == "worldmap" or key == "advanced") and 96 or 86
        b:SetSize(width, 27)
        b:SetPoint("TOPLEFT", x, -72)
        b:SetText(TabText(key))
        b:SetScript("OnClick", function() SelectTab(panel, key) end)
        panel.tabButtons[key] = b
        x = x + width + 4
    end
end

local function BuildOptionsPanel()
    SyncDB()
    if optionsPanel then return optionsPanel end

    local p = CreateFrame("Frame", "RXPNavigatorOptionsPanel")
    p.name = "RestedXP-Navigator"
    p.pages = {}
    p.tabButtons = {}
    p.refreshers = {}
    p.styleButtons = {}

    local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetText("RestedXP-Navigator")

    local sub = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    sub:SetWidth(650)
    sub:SetJustifyH("LEFT")
    sub:SetText(L("subtitle"))

    local divider = p:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.45,0.36,0.12,0.75)
    divider:SetPoint("TOPLEFT", 16, -104)
    divider:SetPoint("TOPRIGHT", -16, -104)
    divider:SetHeight(1)

    p.body = CreateFrame("Frame", nil, p)
    p.body:SetPoint("TOPLEFT", 12, -116)
    p.body:SetPoint("BOTTOMRIGHT", -12, 12)

    BuildTabs(p)
    BuildGeneralPage(p)
    BuildMinimapPage(p)
    BuildWorldMapPage(p)
    BuildHUDPage(p)
    BuildOverlaysPage(p)
    BuildCorpsePage(p)
    BuildAdvancedPage(p)

    function p:Refresh()
        SyncDB()
        if not db then return end
        for _, control in ipairs(self.refreshers) do
            if control and control.Refresh then control:Refresh() end
        end
        for _, b in ipairs(self.styleButtons or {}) do
            if b.styleKey == db.lineStyle then b:Disable() else b:Enable() end
        end
    end

    p:SetScript("OnShow", function(self)
        self:Refresh()
        SelectTab(self, self.activeTab or "general")
    end)

    SelectTab(p, "general")

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(p, "RestedXP-Navigator")
        Settings.RegisterAddOnCategory(category)
        optionsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(p)
        optionsCategory = p
    end

    optionsPanel = p
    return p
end

local function OpenOptions()
    SyncDB()
    local p = BuildOptionsPanel()
    p:Refresh()
    if Settings and Settings.OpenToCategory and optionsCategory then
        local id = optionsCategory.ID or optionsCategory
        Settings.OpenToCategory(id)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(p)
        InterfaceOptionsFrame_OpenToCategory(p)
    else
        Print("Öffne die Blizzard-Optionen > AddOns > RestedXP-Navigator")
    end
end

function Navigator.Options:Build() return BuildOptionsPanel() end
function Navigator.Options:Open() return OpenOptions() end
function Navigator.Options:Refresh()
    SyncDB()
    if optionsPanel and optionsPanel.Refresh then optionsPanel:Refresh() end
end
