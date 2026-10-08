local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.RouteTooltip = Navigator.RouteTooltip or { revision = 5 }

local driver
local tooltipOwner

local function DistanceToSegment(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 <= 0.0001 then
        local ex, ey = px - ax, py - ay
        return math.sqrt(ex * ex + ey * ey)
    end
    local t = ((px - ax) * dx + (py - ay) * dy) / len2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local qx, qy = ax + dx * t, ay + dy * t
    local ex, ey = px - qx, py - qy
    return math.sqrt(ex * ex + ey * ey)
end

local function HideOwnedTooltip()
    if GameTooltip and tooltipOwner and GameTooltip:GetOwner() == tooltipOwner then
        GameTooltip:Hide()
    end
end

local function EnsureDriver()
    if driver then return driver end

    driver = CreateFrame("Frame", "RXPNavigatorRouteTooltipDriver", UIParent)
    driver:Show()
    driver.elapsed = 0

    tooltipOwner = CreateFrame("Frame", "RXPNavigatorRouteTooltipOwner", UIParent)
    tooltipOwner:SetSize(1, 1)
    tooltipOwner:Hide()

    driver:SetScript("OnUpdate", function(self, dt)
        self.elapsed = (self.elapsed or 0) + (dt or 0)
        if self.elapsed < 0.035 then return end
        self.elapsed = 0

        local state = Navigator.RouteTooltip

        -- Overlay paths (farm/patrol/search) get tooltip priority at crossings.
        -- This prevents the normal navigation tooltip from repeatedly stealing
        -- GameTooltip ownership and causing visible flicker.
        local overlayState = Navigator.MapOverlays
        if overlayState and overlayState.hoverEntry then
            if state then
                state.hovering = false
                state.hoverElement = nil
            end
            HideOwnedTooltip()
            if tooltipOwner then tooltipOwner:Hide() end
            return
        end

        local parent = state and state.parent
        local points = state and state.points
        local element = state and state.element
        local db = API:GetDB()

        if not db or not db.showTaskTooltip or not parent or not element
            or type(points) ~= "table" or #points < 2
            or not parent:IsShown()
            or not (WorldMapFrame and WorldMapFrame:IsShown()) then
            if state then state.hovering = false end
            HideOwnedTooltip()
            return
        end

        local scale = parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
        if not scale or scale <= 0 then scale = 1 end
        local mx, my = GetCursorPosition()
        local cx, cy = parent:GetCenter()
        if not mx or not my or not cx or not cy then
            state.hovering = false
            HideOwnedTooltip()
            return
        end

        mx, my = mx / scale, my / scale
        local localX, localY = mx - cx, my - cy

        -- 11 px gives a natural hover target without making large parts of
        -- the map unexpectedly interactive.
        local threshold = 11
        local hit = false
        for i = 2, #points do
            local a, b = points[i - 1], points[i]
            if DistanceToSegment(localX, localY, a.x, a.y, b.x, b.y) <= threshold then
                hit = true
                break
            end
        end

        if hit then
            if not state.hovering or state.hoverElement ~= element then
                state.hovering = true
                state.hoverElement = element
                tooltipOwner:Show()
                API:ShowElementTooltip(tooltipOwner, element)
            end
        else
            if state.hovering then
                state.hovering = false
                state.hoverElement = nil
                HideOwnedTooltip()
                tooltipOwner:Hide()
            end
        end
    end)

    return driver
end

function Navigator.RouteTooltip:HideAll()
    self.parent = nil
    self.points = nil
    self.element = nil
    self.hovering = false
    self.hoverElement = nil
    HideOwnedTooltip()
    if tooltipOwner then tooltipOwner:Hide() end
end

function Navigator.RouteTooltip:Update(parent, points, element)
    EnsureDriver()
    if not parent or type(points) ~= "table" or #points < 2 or not element then
        self:HideAll()
        return
    end

    self.parent = parent
    self.points = points
    self.element = element
end
