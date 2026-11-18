local _, bridge = ...
local navigator = RXPNavigator
local hideWorldLine = false

function bridge.UpdateMapRoutes(world, minimap)
    local alive = not UnitIsDeadOrGhost("player")
    hideWorldLine = world and alive
end

local smoother = navigator.RouteSmoother
if smoother and smoother.BuildPixelPath then
    local buildPath = smoother.BuildPixelPath
    function smoother:BuildPixelPath(points, strength)
        local overlay = _G.RXPNavigatorWorldMapOverlay
        local target = _G.RXPNavigatorWorldTargetPin
        if hideWorldLine and overlay and target and #points > 1 then
            -- The Navigator anchors its active pin before building the line,
            -- including when the goal is clipped to the map edge.
            local anchor, relativeTo, relativePoint, x, y = target:GetPoint()
            if anchor == "CENTER" and relativeTo == overlay and relativePoint == "TOPLEFT" then
                local scale = target:GetScale()
                x = x * scale - overlay:GetWidth() / 2
                y = y * scale + overlay:GetHeight() / 2
                for index = 2, #points do
                    local point = points[index]
                    if math.abs(point.x - x) < 0.25 and math.abs(point.y - y) < 0.25 then
                        -- The renderer uses this same temporary array for chevrons.
                        local count = #points
                        for i = index, count do points[i - index + 1] = points[i] end
                        for i = count - index + 2, count do points[i] = nil end
                        break
                    end
                end
            end
        end
        return buildPath(self, points, strength)
    end
end
