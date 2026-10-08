local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end


Navigator.MapOverlays = Navigator.MapOverlays or { revision = 4, pools = {} }

local hoverDriver
local hoverOwner

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

local function HideOverlayTooltip()
    if GameTooltip and hoverOwner and GameTooltip:GetOwner() == hoverOwner then
        GameTooltip:Hide()
    end
    if hoverOwner then hoverOwner:Hide() end
end

local function GetStepTooltipElement(step)
    if type(step) ~= "table" or type(step.elements) ~= "table" then return nil end
    local fallback
    for _, element in ipairs(step.elements) do
        if type(element) == "table" and not element.skip and not element.completed then
            fallback = fallback or element
            if element.mapTooltip or element.tooltipText or element.hiddentext or element.text or element.title then
                return element
            end
        end
    end
    return fallback
end

local function EnsureHoverDriver()
    if hoverDriver then return hoverDriver end
    hoverDriver = CreateFrame("Frame", "RXPNavigatorOverlayTooltipDriver", UIParent)
    hoverDriver.elapsed = 0
    hoverDriver.leaveElapsed = 0
    hoverDriver:Show()

    hoverOwner = CreateFrame("Frame", "RXPNavigatorOverlayTooltipOwner", UIParent)
    hoverOwner:SetSize(1, 1)
    hoverOwner:Hide()

    hoverDriver:SetScript("OnUpdate", function(self, dt)
        self.elapsed = (self.elapsed or 0) + (dt or 0)
        if self.elapsed < 0.035 then return end
        self.elapsed = 0

        local state = Navigator.MapOverlays
        local db = API:GetDB()
        local parent = state and state.hoverParent
        local entries = state and state.hoverEntries
        if not db or not db.showTaskTooltip or not parent or type(entries) ~= "table" or #entries == 0
            or not parent:IsShown() or not (WorldMapFrame and WorldMapFrame:IsShown()) then
            if state then state.hoverEntry = nil; state.hoverElement = nil end
            self.leaveElapsed = 0
            HideOverlayTooltip()
            return
        end

        local scale = parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
        if not scale or scale <= 0 then scale = 1 end
        local mx, my = GetCursorPosition()
        local cx, cy = parent:GetCenter()
        if not mx or not my or not cx or not cy then
            state.hoverEntry = nil
            state.hoverElement = nil
            HideOverlayTooltip()
            return
        end
        mx, my = mx / scale, my / scale
        local localX, localY = mx - cx, my - cy

        local best, bestDistance
        local enterThreshold = 10
        local stayThreshold = 15
        local currentElement = state.hoverElement
        for _, entry in ipairs(entries) do
            local points = entry.points
            if type(points) == "table" and #points >= 2 and entry.element then
                local n = #points
                local limit = entry.closeLoop and n or (n - 1)
                local threshold = (entry.element == currentElement) and stayThreshold or enterThreshold
                for i = 1, limit do
                    local a = points[i]
                    local b = points[(i % n) + 1]
                    local d = DistanceToSegment(localX, localY, a.x, a.y, b.x, b.y)
                    if d <= threshold and (not bestDistance or d < bestDistance) then
                        best, bestDistance = entry, d
                    end
                end
            end
        end

        if best then
            self.leaveElapsed = 0
            if state.hoverElement ~= best.element then
                state.hoverEntry = best
                state.hoverElement = best.element
                hoverOwner:Show()
                API:ShowElementTooltip(hoverOwner, best.element, { anchor = "ANCHOR_CURSOR" })
            else
                state.hoverEntry = best
                if GameTooltip and GameTooltip:GetOwner() ~= hoverOwner then
                    -- Another tooltip system may have taken ownership at a route crossing.
                    -- Overlay paths have priority while they remain hovered.
                    hoverOwner:Show()
                    API:ShowElementTooltip(hoverOwner, best.element, { anchor = "ANCHOR_CURSOR" })
                end
            end
        else
            self.leaveElapsed = (self.leaveElapsed or 0) + 0.035
            if self.leaveElapsed >= 0.14 then
                self.leaveElapsed = 0
                state.hoverEntry = nil
                state.hoverElement = nil
                HideOverlayTooltip()
            end
        end
    end)

    return hoverDriver
end

function Navigator.MapOverlays:HidePool(pool)
    if type(pool) ~= "table" then return end
    for _, obj in ipairs(pool) do if obj and obj.Hide then obj:Hide() end end
end

function Navigator.MapOverlays:HideVisuals()
    if type(self.pools) == "table" then
        for _, pool in pairs(self.pools) do self:HidePool(pool) end
    end
end

function Navigator.MapOverlays:HideAll()
    self:HideVisuals()
    self.hoverEntries = {}
    self.hoverEntry = nil
    self.hoverElement = nil
    HideOverlayTooltip()
end

function Navigator.MapOverlays:GetPoolLine(kind, index, parent, layer, subLevel)
    self.pools[kind] = self.pools[kind] or {}
    local pool = self.pools[kind]
    local line = pool[index]
    if not line then
        line = parent:CreateLine(nil, layer or "ARTWORK", nil, subLevel or 2)
        line:Hide()
        pool[index] = line
    end
    return line
end

function Navigator.MapOverlays:GetPoolTexture(kind, index, parent, layer, subLevel)
    self.pools[kind] = self.pools[kind] or {}
    local pool = self.pools[kind]
    local tex = pool[index]
    if not tex then
        tex = parent:CreateTexture(nil, layer or "ARTWORK", nil, subLevel or 1)
        tex:Hide()
        pool[index] = tex
    end
    return tex
end

function Navigator.MapOverlays:GetObjectPin(index, parent)
    self.pools.objectPin = self.pools.objectPin or {}
    local pin = self.pools.objectPin[index]
    if not pin then
        pin = CreateFrame("Button", nil, parent)
        -- Keep a comfortable invisible mouse target while the actual object marker stays subtle.
        pin:SetSize(20, 20)
        pin.icon = pin:CreateTexture(nil, "ARTWORK", nil, 3)
        pin.icon:SetPoint("CENTER")
        pin.icon:SetSize(7, 7)
        pin.ring = pin:CreateTexture(nil, "OVERLAY", nil, 4)
        pin.ring:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetRing.tga")
        pin.ring:SetPoint("CENTER")
        pin.ring:SetSize(10, 10)
        pin:SetScript("OnEnter", function(self)
            if Navigator.ObjectResolver and self.objectDescriptor then
                Navigator.ObjectResolver:ShowTooltip(self, self.objectDescriptor, self.objectDistance)
            end
        end)
        pin:SetScript("OnLeave", function(self)
            if Navigator.ObjectResolver then Navigator.ObjectResolver:HideTooltip(self) end
        end)
        pin:Hide()
        self.pools.objectPin[index] = pin
    elseif pin:GetParent() ~= parent then
        pin:SetParent(parent)
    end
    return pin
end

function Navigator.MapOverlays:GetOverlayKind(element)
    if type(element) ~= "table" or type(element.segments) ~= "table" or #element.segments < 4 then return nil end
    local tag = Navigator.RXPData and Navigator.RXPData.GetTag and Navigator.RXPData:GetTag(element) or ""
    local text = API:LowerClean(element.text or element.title or "")
    local hasRange = tonumber(element.range) ~= nil

    if text:find("patrol", 1, true) or text:find("roam", 1, true) or text:find("wander", 1, true) then
        return "patrol"
    end
    if text:find("farm", 1, true) or text:find("grind", 1, true) or text:find("loop", 1, true) then
        return "farm"
    end
    if tag == "loop" or hasRange or text:find("search", 1, true) or text:find("area", 1, true) then
        return "search"
    end
    if tag == "line" or text:find("path", 1, true) or text:find("route", 1, true) then
        return "farm"
    end
    return nil
end

function Navigator.MapOverlays:ProjectElementPoints(element, displayMapID, width, height)
    local mapID = tonumber(element.zone)
    if not mapID or type(element.segments) ~= "table" then return nil end
    local points = {}
    for i = 1, #element.segments, 2 do
        local sx, sy = tonumber(element.segments[i]), tonumber(element.segments[i + 1])
        if sx and sy then
            local mx, my = API:PositionInDisplayedMap(mapID, sx / 100, sy / 100, displayMapID, true)
            if mx and my then
                points[#points + 1] = { x = mx * width - width / 2, y = -my * height + height / 2 }
            end
        end
    end
    return #points >= 2 and points or nil
end

function Navigator.MapOverlays:GetOverlaySteps(maxFuture)
    local out = {}
    local guide, stepIndex = API:ResolveActiveGuideAndStep()
    local steps = guide and rawget(guide, "steps")
    if type(steps) ~= "table" then return out end

    local function AddStep(step)
        if type(step) ~= "table" or step.skip or step.completed then return end
        for _, existing in ipairs(out) do if existing == step then return end end
        out[#out + 1] = step
    end

    if stepIndex and steps[stepIndex] then AddStep(steps[stepIndex]) end

    maxFuture = math.max(0, math.min(6, tonumber(maxFuture) or 0))
    if maxFuture > 0 and stepIndex then
        local added = 0
        for i = stepIndex + 1, #steps do
            local step = steps[i]
            if type(step) == "table" and not step.skip and not step.completed then
                AddStep(step)
                added = added + 1
                if added >= maxFuture then break end
            end
        end
    end
    return out
end

function Navigator.MapOverlays:GetStepText(step)
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

function Navigator.MapOverlays:GetLoopKind(step)
    local text = self:GetStepText(step)
    if text:find("patrol", 1, true) or text:find("roam", 1, true) or text:find("wander", 1, true) then
        return "patrol"
    end
    -- RXP #loop is most commonly a repeated farming/grinding circuit. Explicit
    -- grind/farm/xp language is strong evidence; otherwise a loop remains a
    -- farm circuit rather than being mistaken for linear navigation.
    if text:find("grind", 1, true) or text:find("farm", 1, true) or text:find("xp", 1, true) then
        return "farm"
    end
    return "farm"
end

function Navigator.MapOverlays:ProjectLoopStep(step, displayMapID, width, height)
    if type(step) ~= "table" or not step.loop or type(step.elements) ~= "table" then return nil end
    local points = {}
    local lastX, lastY
    for _, element in ipairs(step.elements) do
        if type(element) == "table" and not element.skip and not element.completed then
            local tag = Navigator.RXPData and Navigator.RXPData.GetTag and Navigator.RXPData:GetTag(element) or ""
            if tag and (tag == "goto" or tag == "groundgoto" or tag == "questgoto" or tag:find("goto", 1, true)) then
                local mapID, x, y = API:GetTargetMap(element)
                if mapID and x and y then
                    local mx, my = API:PositionInDisplayedMap(mapID, x, y, displayMapID, true)
                    if mx and my then
                        local px, py = mx * width - width / 2, -my * height + height / 2
                        if not lastX or math.abs(px - lastX) > 0.5 or math.abs(py - lastY) > 0.5 then
                            points[#points + 1] = { x = px, y = py }
                            lastX, lastY = px, py
                        end
                    end
                end
            end
        end
    end
    return #points >= 3 and points or nil
end

function Navigator.MapOverlays:Collect(displayMapID, width, height, maxFuture)
    local overlays = {}
    for _, step in ipairs(self:GetOverlaySteps(maxFuture)) do
        -- RXP #loop blocks are represented as many ordinary .goto elements.
        -- Build one dedicated overlay from those points so they never masquerade
        -- as the player's cyan navigation route.
        if step.loop then
            local loopPoints = self:ProjectLoopStep(step, displayMapID, width, height)
            if loopPoints then
                local objectDescriptor = Navigator.ObjectResolver and Navigator.ObjectResolver:GetDescriptorForLoop(step) or nil
                if objectDescriptor then
                    overlays[#overlays + 1] = { kind = "object", points = loopPoints, step = step, objectDescriptor = objectDescriptor }
                else
                    overlays[#overlays + 1] = { kind = self:GetLoopKind(step), points = loopPoints, step = step, closeLoop = true }
                end
            end
        end

        if type(step.elements) == "table" then
            for _, element in ipairs(step.elements) do
                local kind = self:GetOverlayKind(element)
                if kind then
                    local points = self:ProjectElementPoints(element, displayMapID, width, height)
                    if points then overlays[#overlays + 1] = { kind = kind, points = points, element = element } end
                end
            end
        end
    end
    return overlays
end

function Navigator.MapOverlays:DrawContinuous(points, kind, parent, thickness, r, g, b, a, startIndex, closeLoop)
    local index = startIndex or 0
    for i = 2, #points do
        local p1, p2 = points[i - 1], points[i]
        index = index + 1
        local line = self:GetPoolLine(kind, index, parent, "ARTWORK", 2)
        line:SetColorTexture(r, g, b, a)
        API:SetNativeWorldLine(line, parent, p1.x, p1.y, p2.x, p2.y, thickness)
    end
    if closeLoop and #points > 2 then
        index = index + 1
        local line = self:GetPoolLine(kind, index, parent, "ARTWORK", 2)
        line:SetColorTexture(r, g, b, a)
        API:SetNativeWorldLine(line, parent, points[#points].x, points[#points].y, points[1].x, points[1].y, thickness)
    end
    return index
end

function Navigator.MapOverlays:DrawDashed(points, kind, parent, thickness, r, g, b, a, dash, gap, startIndex, closeLoop)
    local index = startIndex or 0
    local n = #points
    local limit = closeLoop and n or (n - 1)
    for i = 1, limit do
        local p1 = points[i]
        local p2 = points[(i % n) + 1]
        local dx, dy = p2.x - p1.x, p2.y - p1.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0.001 then
            local ux, uy = dx / len, dy / len
            local pos = 0
            while pos < len do
                local segStart = pos
                local segEnd = math.min(len, pos + dash)
                if segEnd - segStart > 0.8 then
                    index = index + 1
                    local line = self:GetPoolLine(kind, index, parent, "ARTWORK", 2)
                    line:SetColorTexture(r, g, b, a)
                    API:SetNativeWorldLine(line, parent,
                        p1.x + ux * segStart, p1.y + uy * segStart,
                        p1.x + ux * segEnd, p1.y + uy * segEnd,
                        thickness)
                end
                pos = pos + dash + gap
            end
        end
    end
    return index
end

function Navigator.MapOverlays:Render(displayMapID, parent, width, height, boost)
    local db = API:GetDB()
    if not db or not db.enabled or not db.showWorldMap then
        self:HideAll()
        return
    end

    -- Re-render only the visual pools. Do not clear hover/tooltip ownership here:
    -- World map refreshes can happen many times per second and HideAll() would
    -- close/reopen GameTooltip on every refresh, causing visible flicker.
    self:HideVisuals()

    local overlays = self:Collect(displayMapID, width, height, db.futureGoals or 0)
    self.hoverParent = parent
    self.hoverEntries = {}
    EnsureHoverDriver()
    local searchLineIndex, searchFillIndex = 0, 0
    local patrolLineIndex = 0
    local farmLineIndex, farmNodeIndex = 0, 0
    local objectPinIndex = 0

    local playerPX, playerPY
    local playerMapID, playerX, playerY = API:ResolvePlayerMapAndPosition(displayMapID)
    if playerMapID and playerX and playerY then
        local pmx, pmy = API:PositionInDisplayedMap(playerMapID, playerX, playerY, displayMapID, true)
        if pmx and pmy then
            playerPX, playerPY = pmx * width - width / 2, -pmy * height + height / 2
        end
    end

    local searchThickness = math.max(2.0, 2.1 * (boost or 1))
    local patrolThickness = math.max(1.8, 2.0 * (boost or 1))
    local farmThickness = math.max(1.8, 2.1 * (boost or 1))

    for _, overlayData in ipairs(overlays) do
        local points = overlayData.points
        local tooltipElement = overlayData.element or GetStepTooltipElement(overlayData.step)
        if overlayData.kind == "object" and db.showObjectMarkers ~= false then
            local nearestIndex, nearestDistance
            if playerPX and playerPY then
                for i, point in ipairs(points) do
                    local dx, dy = point.x - playerPX, point.y - playerPY
                    local d = math.sqrt(dx * dx + dy * dy)
                    if not nearestDistance or d < nearestDistance then nearestIndex, nearestDistance = i, d end
                end
            end
            for i, point in ipairs(points) do
                objectPinIndex = objectPinIndex + 1
                local pin = self:GetObjectPin(objectPinIndex, parent)
                local active = (i == nearestIndex)
                -- Visual marker is intentionally much smaller than its mouse hit area.
                pin:SetSize(20, 20)
                pin.icon:SetSize(active and 10 or 7, active and 10 or 7)
                pin.ring:SetSize(active and 14 or 10, active and 14 or 10)
                pin.icon:SetTexture((overlayData.objectDescriptor and overlayData.objectDescriptor.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
                pin.icon:SetVertexColor(1, 1, 1, active and 0.95 or 0.68)
                if active then pin.ring:SetVertexColor(1.00, 0.72, 0.12, 0.88)
                else pin.ring:SetVertexColor(0.35, 0.95, 1.00, 0.22) end
                pin.objectDescriptor = overlayData.objectDescriptor
                pin.objectDistance = nil
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", parent, "CENTER", point.x, point.y)
                pin:Show()
            end
        elseif overlayData.kind == "search" and db.showSearchAreas then
            local minX, maxX, minY, maxY = points[1].x, points[1].x, points[1].y, points[1].y
            for i = 2, #points do
                local p = points[i]
                if p.x < minX then minX = p.x end
                if p.x > maxX then maxX = p.x end
                if p.y < minY then minY = p.y end
                if p.y > maxY then maxY = p.y end
            end
            searchFillIndex = searchFillIndex + 1
            local fill = self:GetPoolTexture("searchFill", searchFillIndex, parent, "BACKGROUND", 1)
            fill:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetRing.tga")
            fill:SetBlendMode("ADD")
            local sr, sg, sb = Navigator.Presentation and Navigator.Presentation:GetColor("search") or 0.58, 0.88, 1.00
            fill:SetVertexColor(sr, sg, sb, math.max(0.05, math.min(0.55, db.searchAreaAlpha or 0.18)))
            fill:ClearAllPoints()
            fill:SetPoint("CENTER", parent, "CENTER", (minX + maxX) / 2, (minY + maxY) / 2)
            fill:SetSize(math.max(42, (maxX - minX) * 1.20), math.max(42, (maxY - minY) * 1.20))
            fill:Show()
            local sr, sg, sb = Navigator.Presentation and Navigator.Presentation:GetColor("search") or 0.58, 0.88, 1.00
            searchLineIndex = self:DrawContinuous(points, "searchLine", parent, searchThickness, sr, sg, sb, math.min(1.0, (db.searchAreaAlpha or 0.18) + 0.55), searchLineIndex, true)
            if tooltipElement then self.hoverEntries[#self.hoverEntries + 1] = { points = points, element = tooltipElement, closeLoop = true, kind = "search" } end
        elseif overlayData.kind == "patrol" and db.showPatrolPaths then
            local pr, pg, pb = Navigator.Presentation and Navigator.Presentation:GetColor("patrol") or 1.00, 0.82, 0.34
            patrolLineIndex = self:DrawDashed(points, "patrolLine", parent, patrolThickness, pr, pg, pb, db.patrolAlpha or 0.78, 14, 9, patrolLineIndex, overlayData.closeLoop == true)
            if tooltipElement then self.hoverEntries[#self.hoverEntries + 1] = { points = points, element = tooltipElement, closeLoop = overlayData.closeLoop == true, kind = "patrol" } end
        elseif overlayData.kind == "farm" and db.showFarmRoutes then
            local fr, fg, fb = Navigator.Presentation and Navigator.Presentation:GetColor("farm") or 0.42, 1.00, 0.70
            farmLineIndex = self:DrawContinuous(points, "farmLine", parent, farmThickness, fr, fg, fb, db.farmAlpha or 0.86, farmLineIndex, overlayData.closeLoop == true)
            if tooltipElement then self.hoverEntries[#self.hoverEntries + 1] = { points = points, element = tooltipElement, closeLoop = overlayData.closeLoop == true, kind = "farm" } end
            for _, point in ipairs(points) do
                farmNodeIndex = farmNodeIndex + 1
                local dot = self:GetPoolTexture("farmNode", farmNodeIndex, parent, "ARTWORK", 3)
                dot:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_TargetCenter.tga")
                dot:SetVertexColor(math.min(1, (fr or 0.42) + 0.30), math.min(1, (fg or 1.00)), math.min(1, (fb or 0.70) + 0.16), math.min(1.0, (db.farmAlpha or 0.86) + 0.08))
                dot:SetSize(7, 7)
                dot:ClearAllPoints()
                dot:SetPoint("CENTER", parent, "CENTER", point.x, point.y)
                dot:Show()
            end
        end
    end

    for i = searchLineIndex + 1, #(self.pools.searchLine or {}) do self.pools.searchLine[i]:Hide() end
    for i = searchFillIndex + 1, #(self.pools.searchFill or {}) do self.pools.searchFill[i]:Hide() end
    for i = patrolLineIndex + 1, #(self.pools.patrolLine or {}) do self.pools.patrolLine[i]:Hide() end
    for i = farmLineIndex + 1, #(self.pools.farmLine or {}) do self.pools.farmLine[i]:Hide() end
    for i = farmNodeIndex + 1, #(self.pools.farmNode or {}) do self.pools.farmNode[i]:Hide() end
    for i = objectPinIndex + 1, #(self.pools.objectPin or {}) do self.pools.objectPin[i]:Hide() end
end

