local nav = _G.RXPNavigator
local flight = {}
nav.FlightRoute = flight

local tracks = nav.FlightReference
local stops = {
    [23] = {1677.6, -4315.7}, -- Orgrimmar
    [25] = {-441.8, -2596.1}, -- Crossroads
    [80] = {-894.6, -3773},   -- Ratchet
}
local hooks = setmetatable({}, {__mode="k"})
local overlay, label
local lines = {}

local function Hide()
    if overlay then overlay:Hide() end
end

local function FindSource()
    for slot = 1, NumTaxiNodes() do
        if TaxiNodeGetType(slot) == "CURRENT" then return slot end
    end
end

local function Preview(slot, button)
    Hide()
    local db = nav.API:GetDB()
    if not db or not db.enabled or db.showWorldMap == false
        or not (GetTaxiMapID and C_TaxiMap and C_TaxiMap.GetAllTaxiNodes
        and NumTaxiNodes and TaxiNodeGetType and GetNumRoutes and TaxiGetNodeSlot) then return end
    if TaxiNodeGetType(slot) ~= "REACHABLE" or GetNumRoutes(slot) ~= 1 then return end

    local sourceSlot = FindSource()
    if TaxiGetNodeSlot(slot, 1, true) ~= sourceSlot or TaxiGetNodeSlot(slot, 1, false) ~= slot then return end
    local sourceButton = sourceSlot and _G["TaxiButton"..sourceSlot]
    local map = GetTaxiMapID()
    if not sourceButton or not map or not TaxiFrame or not TaxiFrame:IsShown() then return end
    local from, to
    for _, node in ipairs(C_TaxiMap.GetAllTaxiNodes(map) or {}) do
        if node.slotIndex == sourceSlot then from = node.nodeID end
        if node.slotIndex == slot then to = node.nodeID end
    end
    if not from or not to then return end
    local points = tracks[from..":"..to]
    if not points then return end

    local start, goal = stops[from], stops[to]
    local ax, ay = sourceButton:GetCenter()
    local bx, by = button:GetCenter()
    local tx, ty = TaxiFrame:GetCenter()
    if not ax or not ay or not bx or not by or not tx or not ty then return end
    local scale = TaxiFrame:GetEffectiveScale()
    local sa, sb = sourceButton:GetEffectiveScale()/scale, button:GetEffectiveScale()/scale
    ax, ay = ax*sa-tx, ay*sa-ty
    bx, by = bx*sb-tx, by*sb-ty
    local sx = (bx-ax)/(goal[2]-start[2])
    local sy = (by-ay)/(goal[1]-start[1])

    if not overlay then
        overlay = CreateFrame("Frame", nil, TaxiFrame)
        overlay:SetAllPoints()
        overlay:SetFrameLevel(TaxiFrame:GetFrameLevel()+5)
        overlay:EnableMouse(false)
        label = overlay:CreateFontString(nil,"OVERLAY","GameFontNormal")
        label:SetPoint("TOP",overlay,"TOP",0,-28)
        label:SetTextColor(1,.84,.49)
    end
    local count = 0
    for i = 3, #points, 2 do
        count = count + 1
        local line = lines[count]
        if not line then
            line = overlay:CreateLine(nil,"OVERLAY")
            line:SetColorTexture(1,.77,.29,.95)
            lines[count] = line
        end
        line:SetStartPoint("CENTER",overlay,ax+(points[i-1]-start[2])*sx,ay+(points[i-2]-start[1])*sy)
        line:SetEndPoint("CENTER",overlay,ax+(points[i+1]-start[2])*sx,ay+(points[i]-start[1])*sy)
        line:SetThickness(3)
        line:Show()
    end
    for i=count+1,#lines do lines[i]:Hide() end
    label:SetText(nav.API:Localize("Flight route") .. " · " .. (TaxiNodeName(slot) or ""))
    overlay:Show()
end

local function HookButtons()
    for i=1,NumTaxiNodes and NumTaxiNodes() or 0 do
        local button = _G["TaxiButton"..i]
        if button and not hooks[button] then
            local slot = i
            hooks[button] = true
            button:HookScript("OnEnter",function(self) Preview(slot,self) end)
            button:HookScript("OnLeave",Hide)
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("TAXIMAP_OPENED")
events:RegisterEvent("TAXIMAP_CLOSED")
events:SetScript("OnEvent",function(_,event)
    if event == "TAXIMAP_CLOSED" then Hide(); return end
    if C_Timer and C_Timer.After then C_Timer.After(0,HookButtons) else HookButtons() end
end)
