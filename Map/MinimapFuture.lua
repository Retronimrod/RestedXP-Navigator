local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.MinimapFuture = Navigator.MinimapFuture or { revision = 3, markers = {}, lines = {}, shadows = {} }

function Navigator.MinimapFuture:HideAll()
    for _, marker in ipairs(self.markers) do marker:Hide() end
    for _, line in ipairs(self.lines) do line:Hide() end
    for _, line in ipairs(self.shadows) do line:Hide() end
end

function Navigator.MinimapFuture:GetMarker(index, parent)
    local marker = self.markers[index]
    if marker then return marker end

    marker = CreateFrame("Button", nil, parent)
    marker:SetSize(13, 13)
    marker:SetFrameLevel((parent:GetFrameLevel() or 1) + 8)
    marker:EnableMouse(true)

    local ring = marker:CreateTexture(nil, "ARTWORK", nil, 3)
    ring:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetRing.tga")
    ring:SetAllPoints()
    ring:SetVertexColor(0.22, 0.78, 1.00, 0.82)
    marker.ring = ring

    local center = marker:CreateTexture(nil, "ARTWORK", nil, 4)
    center:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetCenter.tga")
    center:SetPoint("TOPLEFT", 3, -3)
    center:SetPoint("BOTTOMRIGHT", -3, 3)
    center:SetVertexColor(0.35, 0.90, 1.00, 0.88)
    marker.center = center

    local label = marker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", marker, "BOTTOM", 0, 0)
    label:SetTextColor(0.68, 0.92, 1.00, 0.95)
    if label.SetShadowOffset then label:SetShadowOffset(1, -1) end
    marker.label = label

    marker:SetScript("OnEnter", function(self)
        if not self.rxpElement then return end
        API:ShowElementTooltip(self, self.rxpElement, { futureOrdinal = self.rxpOrdinal or 1, anchor = "ANCHOR_LEFT" })
    end)
    marker:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    self.markers[index] = marker
    return marker
end

function Navigator.MinimapFuture:GetLine(index, parent)
    local line = self.lines[index]
    local shadow = self.shadows[index]
    if not line then
        shadow = parent:CreateLine(nil, "ARTWORK", nil, 1)
        line = parent:CreateLine(nil, "ARTWORK", nil, 2)
        shadow:Hide(); line:Hide()
        self.shadows[index] = shadow
        self.lines[index] = line
    end
    return line, shadow
end

local function SetLine(line, parent, x1, y1, x2, y2, thickness)
    if line.rxpX1 ~= x1 or line.rxpY1 ~= y1 or line.rxpX2 ~= x2 or line.rxpY2 ~= y2 then
        line:ClearAllPoints()
        line:SetStartPoint("CENTER", parent, x1, y1)
        line:SetEndPoint("CENTER", parent, x2, y2)
        line.rxpX1, line.rxpY1, line.rxpX2, line.rxpY2 = x1, y1, x2, y2
    end
    if line.rxpThickness ~= thickness then line:SetThickness(thickness); line.rxpThickness = thickness end
    line:Show()
end

function Navigator.MinimapFuture:Update(ctx)
    self:HideAll()
end
