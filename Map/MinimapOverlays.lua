local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.MinimapOverlays = Navigator.MinimapOverlays or {
    revision = 2,
    farmLines = {},
    patrolLines = {},
    objectPins = {},
}

local function SetLine(line, parent, x1, y1, x2, y2, thickness)
    line:ClearAllPoints()
    line:SetStartPoint("CENTER", parent, x1, y1)
    line:SetEndPoint("CENTER", parent, x2, y2)
    line:SetThickness(thickness)
    line:Show()
end

local function HidePool(pool)
    for _, line in ipairs(pool or {}) do line:Hide() end
end

function Navigator.MinimapOverlays:HideAll()
    HidePool(self.farmLines)
    HidePool(self.patrolLines)
    HidePool(self.objectPins)
end

function Navigator.MinimapOverlays:GetLine(pool, index, parent, subLevel)
    local line = pool[index]
    if not line then
        line = parent:CreateLine(nil, "ARTWORK", nil, subLevel or 0)
        line:Hide()
        pool[index] = line
    end
    return line
end

function Navigator.MinimapOverlays:GetObjectPin(index, parent)
    local pin = self.objectPins[index]
    if not pin then
        pin = CreateFrame("Button", nil, parent)
        -- Keep a comfortable invisible mouse target while the actual marker stays compact.
        pin:SetSize(18, 18)
        pin:EnableMouse(true)
        pin.icon = pin:CreateTexture(nil, "ARTWORK", nil, 3)
        pin.icon:SetPoint("CENTER")
        pin.icon:SetSize(6, 6)
        pin.ring = pin:CreateTexture(nil, "OVERLAY", nil, 4)
        pin.ring:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetRing.tga")
        pin.ring:SetPoint("CENTER")
        pin.ring:SetSize(9, 9)
        pin:SetScript("OnEnter", function(self)
            if Navigator.ObjectResolver and self.objectDescriptor then
                Navigator.ObjectResolver:ShowTooltip(self, self.objectDescriptor, self.objectDistance)
            end
        end)
        pin:SetScript("OnLeave", function(self)
            if Navigator.ObjectResolver then Navigator.ObjectResolver:HideTooltip(self) end
        end)
        pin:Hide()
        self.objectPins[index] = pin
    elseif pin:GetParent() ~= parent then
        pin:SetParent(parent)
    end
    return pin
end

function Navigator.MinimapOverlays:GetSteps(maxFuture)
    local out = {}
    local guide, stepIndex = API:ResolveActiveGuideAndStep()
    local steps = guide and rawget(guide, "steps")
    if type(steps) ~= "table" or not stepIndex then return out end

    local function Add(step)
        if type(step) ~= "table" or step.skip or step.completed then return end
        for _, existing in ipairs(out) do if existing == step then return end end
        out[#out + 1] = step
    end

    Add(steps[stepIndex])
    maxFuture = math.max(0, math.min(6, tonumber(maxFuture) or 0))
    local added = 0
    for i = stepIndex + 1, #steps do
        local step = steps[i]
        if type(step) == "table" and not step.skip and not step.completed then
            Add(step)
            added = added + 1
            if added >= maxFuture then break end
        end
    end
    return out
end

function Navigator.MinimapOverlays:GetStepText(step)
    if type(step) ~= "table" or type(step.elements) ~= "table" then return "" end
    local chunks = {}
    for _, element in ipairs(step.elements) do
        if type(element) == "table" then
            local value = API:LowerClean(element.text or element.title or element.tooltipText or "")
            if value and value ~= "" then chunks[#chunks + 1] = value end
        end
    end
    return table.concat(chunks, " ")
end

function Navigator.MinimapOverlays:GetLoopKind(step)
    local text = self:GetStepText(step)
    if text:find("patrol", 1, true) or text:find("roam", 1, true) or text:find("wander", 1, true) then
        return "patrol"
    end
    return "farm"
end

function Navigator.MinimapOverlays:GetElementKind(element)
    if type(element) ~= "table" or type(element.segments) ~= "table" or #element.segments < 4 then return nil end
    local tag = Navigator.RXPData and Navigator.RXPData.GetTag and Navigator.RXPData:GetTag(element) or ""
    local text = API:LowerClean(element.text or element.title or "")

    if text:find("patrol", 1, true) or text:find("roam", 1, true) or text:find("wander", 1, true) then
        return "patrol"
    end
    if text:find("farm", 1, true) or text:find("grind", 1, true) or text:find("loop", 1, true) then
        return "farm"
    end
    if tag == "line" and (text:find("path", 1, true) or text:find("route", 1, true)) then
        return "farm"
    end
    return nil
end

function Navigator.MinimapOverlays:MapPoint(ctx, mapID, x, y)
    local fake = { zone = mapID, x = x, y = y }
    return API:GetMinimapFuturePoint(
        fake,
        ctx.playerMapID, ctx.playerX, ctx.playerY,
        ctx.halfW, ctx.halfH, ctx.viewRadius,
        ctx.markerSize, ctx.rotating
    )
end

function Navigator.MinimapOverlays:LoopPoints(step, ctx)
    if type(step) ~= "table" or not step.loop or type(step.elements) ~= "table" then return nil end
    local points = {}
    for _, element in ipairs(step.elements) do
        if type(element) == "table" and not element.skip and not element.completed then
            local tag = Navigator.RXPData and Navigator.RXPData.GetTag and Navigator.RXPData:GetTag(element) or ""
            if tag and (tag == "goto" or tag == "groundgoto" or tag == "questgoto" or tag:find("goto", 1, true)) then
                local mapID, x, y = API:GetTargetMap(element)
                if mapID and x and y then
                    local px, py, distance = self:MapPoint(ctx, mapID, x, y)
                    points[#points + 1] = px and py and {x=px, y=py, distance=distance} or false
                end
            end
        end
    end
    return #points >= 2 and points or nil
end

function Navigator.MinimapOverlays:ElementPoints(element, ctx)
    if type(element) ~= "table" or type(element.segments) ~= "table" then return nil end
    local mapID = tonumber(element.zone)
    if not mapID then return nil end
    local points = {}
    for i = 1, #element.segments, 2 do
        local sx, sy = tonumber(element.segments[i]), tonumber(element.segments[i+1])
        if sx and sy then
            local px, py = self:MapPoint(ctx, mapID, sx / 100, sy / 100)
            points[#points + 1] = px and py and {x=px, y=py} or false
        end
    end
    return #points >= 2 and points or nil
end

function Navigator.MinimapOverlays:DrawFarm(points, ctx, startIndex, closeLoop)
    local index = startIndex or 0
    local n = #points
    local limit = closeLoop and n or (n - 1)
    for i = 1, limit do
        local a = points[i]
        local b = points[(i % n) + 1]
        if a and b then
            local dx, dy = b.x - a.x, b.y - a.y
            if math.sqrt(dx*dx + dy*dy) > 1.0 then
                index = index + 1
                local line = self:GetLine(self.farmLines, index, ctx.overlay, 0)
                local cr, cg, cb = 0.42, 1.00, 0.70
                if Navigator.Presentation then
                    cr, cg, cb = Navigator.Presentation:GetColor("farm")
                end
                line:SetColorTexture(cr, cg, cb, 0.68)
                SetLine(line, ctx.overlay, a.x, a.y, b.x, b.y, 1.7)
            end
        end
    end
    return index
end

function Navigator.MinimapOverlays:DrawPatrol(points, ctx, startIndex, closeLoop)
    local index = startIndex or 0
    local n = #points
    local limit = closeLoop and n or (n - 1)
    for i = 1, limit do
        local a = points[i]
        local b = points[(i % n) + 1]
        if a and b then
            local dx, dy = b.x - a.x, b.y - a.y
            local len = math.sqrt(dx*dx + dy*dy)
            if len > 1.0 then
                local ux, uy = dx / len, dy / len
                local pos = 0
                local dash, gap = 7, 5
                while pos < len do
                    local s = pos
                    local e = math.min(len, pos + dash)
                    if e - s > 0.8 then
                        index = index + 1
                        local line = self:GetLine(self.patrolLines, index, ctx.overlay, 0)
                        local cr, cg, cb = 1.00, 0.82, 0.34
                        if Navigator.Presentation then
                            cr, cg, cb = Navigator.Presentation:GetColor("patrol")
                        end
                        line:SetColorTexture(cr, cg, cb, 0.72)
                        SetLine(line, ctx.overlay,
                            a.x + ux*s, a.y + uy*s,
                            a.x + ux*e, a.y + uy*e,
                            1.6)
                    end
                    pos = pos + dash + gap
                end
            end
        end
    end
    return index
end

function Navigator.MinimapOverlays:DrawObjects(points, ctx, descriptor, startIndex)
    local index = startIndex or 0
    local nearest, nearestDistance
    for i, point in ipairs(points or {}) do
        if point and type(point.distance) == "number" and (not nearestDistance or point.distance < nearestDistance) then
            nearest, nearestDistance = i, point.distance
        end
    end
    for i, point in ipairs(points or {}) do
        if point then
            index = index + 1
            local pin = self:GetObjectPin(index, ctx.overlay)
            local active = (i == nearest)
            pin:SetSize(18, 18)
            pin.icon:SetSize(active and 9 or 6, active and 9 or 6)
            pin.ring:SetSize(active and 13 or 9, active and 13 or 9)
            pin.icon:SetTexture((descriptor and descriptor.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
            pin.icon:SetVertexColor(1, 1, 1, active and 0.95 or 0.66)
            if active then pin.ring:SetVertexColor(1.00, 0.72, 0.12, 0.88)
            else pin.ring:SetVertexColor(0.35, 0.95, 1.00, 0.18) end
            pin.objectDescriptor = descriptor
            pin.objectDistance = point.distance
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", ctx.overlay, "CENTER", point.x, point.y)
            pin:Show()
        end
    end
    return index
end

function Navigator.MinimapOverlays:Update(ctx)
    if not ctx or not ctx.overlay or ctx.corpseMode then
        self:HideAll()
        return
    end

    local db = API:GetDB()
    if not db or not db.enabled or not db.showMinimap then
        self:HideAll()
        return
    end

    -- Lines are transient render primitives and may be rebuilt every update.
    -- Keep object-pin frames alive until the end of the update so mouseover
    -- tooltips do not flicker when the minimap refreshes.
    HidePool(self.farmLines)
    HidePool(self.patrolLines)

    local farmCount, patrolCount, objectCount = 0, 0, 0
    for _, step in ipairs(self:GetSteps(ctx.futureGoals or 0)) do
        if step.loop then
            local objectDescriptor = Navigator.ObjectResolver and Navigator.ObjectResolver:GetDescriptorForLoop(step) or nil
            local points = self:LoopPoints(step, ctx)
            if points then
                if objectDescriptor and db.showObjectMarkers ~= false then
                    objectCount = self:DrawObjects(points, ctx, objectDescriptor, objectCount)
                else
                    local kind = self:GetLoopKind(step)
                    if kind == "patrol" and db.showPatrolPaths then
                        patrolCount = self:DrawPatrol(points, ctx, patrolCount, true)
                    elseif kind == "farm" and db.showFarmRoutes then
                        farmCount = self:DrawFarm(points, ctx, farmCount, true)
                    end
                end
            end
        end

        if type(step.elements) == "table" then
            for _, element in ipairs(step.elements) do
                local kind = self:GetElementKind(element)
                if kind then
                    local points = self:ElementPoints(element, ctx)
                    if points then
                        if kind == "patrol" and db.showPatrolPaths then
                            patrolCount = self:DrawPatrol(points, ctx, patrolCount, false)
                        elseif kind == "farm" and db.showFarmRoutes then
                            farmCount = self:DrawFarm(points, ctx, farmCount, false)
                        end
                    end
                end
            end
        end
    end

    for i = farmCount + 1, #self.farmLines do self.farmLines[i]:Hide() end
    for i = patrolCount + 1, #self.patrolLines do self.patrolLines[i]:Hide() end
    for i = objectCount + 1, #self.objectPins do self.objectPins[i]:Hide() end
end
