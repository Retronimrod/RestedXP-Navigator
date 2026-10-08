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
    line:ClearAllPoints()
    line:SetStartPoint("CENTER", parent, x1, y1)
    line:SetEndPoint("CENTER", parent, x2, y2)
    line:SetThickness(thickness)
    line:Show()
end

function Navigator.MinimapFuture:Update(ctx)
    self:HideAll()
    if not ctx or not ctx.enabled or ctx.corpseMode then return end
    local futureCount = math.max(0, math.min(6, tonumber(ctx.futureGoals) or 0))
    if futureCount <= 0 then return end

    -- Future minimap markers must represent the next RestedXP guide steps,
    -- not the route-resolver path. The route resolver intentionally skips
    -- loop/farm/overlay steps because they are not linear travel nodes; that
    -- filtering is correct for navigation geometry but must not hide +1/+2/+3
    -- guide targets from the minimap.
    local targets = API:GetSelectedFutureTargets(futureCount)
    if type(targets) ~= "table" or #targets == 0 then return end

    local shown = 0
    local lineCount = 0
    local previousX, previousY = ctx.currentX, ctx.currentY

    for ordinal = 1, #targets do
        local element = targets[ordinal]
        local x, y, _, offscreen = API:GetMinimapFuturePoint(
            element,
            ctx.playerMapID, ctx.playerX, ctx.playerY,
            ctx.halfW, ctx.halfH, ctx.viewRadius,
            ctx.markerSize, ctx.rotating, true
        )
        if x and y then
            shown = shown + 1
            local marker = self:GetMarker(shown, ctx.overlay)
            marker.rxpElement = element
            marker.rxpOrdinal = ordinal
            marker.label:SetText("+" .. tostring(ordinal))
            if offscreen then marker.label:SetTextColor(0.80, 0.94, 1.00, 1.00) else marker.label:SetTextColor(0.68, 0.92, 1.00, 0.95) end
            local alpha = math.max(0.38, 0.78 - (ordinal - 1) * 0.10)
            if offscreen then alpha = math.max(0.46, alpha * 0.82) end
            marker:SetAlpha(alpha)
            local size = math.max(9, math.min(13, (tonumber(ctx.markerSize) or 14) * 0.72))
            marker:SetSize(size, size)
            marker:ClearAllPoints()
            marker:SetPoint("CENTER", ctx.overlay, "CENTER", x, y)
            marker:Show()

            -- Connect the visible current/next targets with a deliberately
            -- subdued route, so the active player->current line remains dominant.
            if previousX and previousY then
                local dx, dy = x - previousX, y - previousY
                if math.sqrt(dx * dx + dy * dy) > 2 then
                    lineCount = lineCount + 1
                    local line, shadow = self:GetLine(lineCount, ctx.overlay)
                    shadow:SetColorTexture(0.02, 0.12, 0.18, 0.60)
                    line:SetColorTexture(0.28, 0.78, 1.00, math.max(0.28, alpha * 0.62))
                    SetLine(shadow, ctx.overlay, previousX, previousY, x, y, 3.6)
                    SetLine(line, ctx.overlay, previousX, previousY, x, y, 1.8)
                end
            end
            previousX, previousY = x, y
        end
    end

    for i = shown + 1, #self.markers do self.markers[i]:Hide() end
    for i = lineCount + 1, #self.lines do self.lines[i]:Hide() end
    for i = lineCount + 1, #self.shadows do self.shadows[i]:Hide() end
end
