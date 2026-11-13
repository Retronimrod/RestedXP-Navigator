local _, bridge = ...
local window, title, content, scroll, child
local returnWindow
local function T(text) return RXPNavigator.API:Localize(text) end
local modeLabels = {
    walk = "On foot",
    flight = "Flight",
    boat = "Boat",
    zeppelin = "Zeppelin",
    lift = "Lift",
    tram = "Tram",
    portal = "Portal",
    teleport = "Teleport",
    hearth = "Hearthstone",
}

local function Duration(seconds)
    if type(seconds) ~= "number" then return "—" end
    seconds = math.max(0, math.floor(seconds + .5))
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

local function BuildWindow()
    local ui = RXPNavigator.UI
    window = CreateFrame("Frame", "RXPNavigatorSPFRoutePreview", UIParent, "BackdropTemplate")
    window:SetSize(620, 390)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetScript("OnHide", function()
        local settings = returnWindow
        returnWindow = nil
        if settings then settings:Show() end
    end)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    ui:Window(window, 620, 390)
    if UISpecialFrames then table.insert(UISpecialFrames, window:GetName()) end
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)
    ui:Label(window, T("Route preview"), 20, -18, 535, "GameFontNormalLarge")
    title = ui:Label(window, "", 20, -43, 545)
    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -83)
    scroll:SetPoint("BOTTOMRIGHT", -38, 24)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(550, 1)
    scroll:SetScrollChild(child)
    content = ui:Label(child, "", 0, 0, 545)
end

function RXPNavigatorSPFPreview(settingsWindow)
    local navigator = RXPNavigator.API
    local api = bridge.GetRouter()
    if not api or type(api.EstimateDetail) ~= "function" then
        navigator:Print("SPF: " .. T("Route API unavailable."))
        return
    end
    local element = navigator:GetCurrentNavigationElement()
    local toMap, toX, toY
    if element and not element.corpseNav then toMap, toX, toY = navigator:GetTargetMap(element) end
    local fromMap, fromX, fromY
    if toMap then fromMap, fromX, fromY = navigator:ResolvePlayerMapAndPosition(toMap) end
    if not fromMap or not fromX or not fromY or not toX or not toY then
        navigator:Print("SPF: " .. T("No origin or guide destination available."))
        return
    end

    local detail, reason = api.EstimateDetail(fromMap, fromX, fromY, toMap, toX, toY)
    if not window then BuildWindow() end
    title:SetText(navigator:GetTargetInstruction(element) or "")
    local lines = {}
    if detail then
        lines[1] = T("Estimated travel time: %s"):format(Duration(detail.seconds))
        for index, leg in ipairs(detail.legs or {}) do
            local wait = leg.wait and ("  (%s)"):format(T("Wait: %s"):format(Duration(leg.wait))) or ""
            local labels = modeLabels[leg.mode]
            local mode = labels and T(labels) or leg.mode or "-"
            lines[#lines + 1] = ("%d.  %s - %s  ·  %s%s"):format(index, mode,
                leg.to or "—", Duration(leg.seconds), wait)
        end
    else
        lines[1] = T("No route available") .. " (" .. tostring(reason or "—") .. ")"
    end
    content:SetText(table.concat(lines, "\n\n"))
    local settings = settingsWindow or _G.RXPNavigatorControlCenter
    if settings and settings:IsShown() then
        returnWindow = settings
        settings:Hide()
    end
    window:Show()
    window:Raise()
    child:SetHeight(math.max(1, content:GetStringHeight() + 12))
    scroll:SetVerticalScroll(0)
end
