local Navigator = _G.RXPNavigator
if not Navigator then return end

-- Route Smoother ------------------------------------------------------------
-- Builds a visually smooth path through the exact projected RXP route points.
-- Cubic Bezier segments pass through every original waypoint; only the line
-- between waypoints is rounded. Target positions and route semantics are not
-- changed.
Navigator.RouteSmoother = Navigator.RouteSmoother or { revision = 1 }

function Navigator.RouteSmoother:BuildPixelPath(points, strength)
    if type(points) ~= "table" or #points < 2 then return points or {} end
    strength = tonumber(strength) or 0.20
    if strength < 0 then strength = 0 elseif strength > 0.32 then strength = 0.32 end

    local out = { { x = points[1].x, y = points[1].y, sourceSegment = 0 } }
    local function Dist(a, b)
        local dx, dy = b.x - a.x, b.y - a.y
        return math.sqrt(dx * dx + dy * dy)
    end
    local function Unit(dx, dy, fallbackX, fallbackY)
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 0.001 then return fallbackX or 1, fallbackY or 0 end
        return dx / len, dy / len
    end

    for i = 1, #points - 1 do
        local p1, p2 = points[i], points[i + 1]
        local p0 = points[i - 1] or p1
        local p3 = points[i + 2] or p2
        local segLen = Dist(p1, p2)
        if segLen < 1.0 then
            out[#out + 1] = { x = p2.x, y = p2.y, sourceSegment = i }
        else
            local sx, sy = Unit(p2.x - p1.x, p2.y - p1.y, 1, 0)
            local t1x, t1y = Unit(p2.x - p0.x, p2.y - p0.y, sx, sy)
            local t2x, t2y = Unit(p3.x - p1.x, p3.y - p1.y, sx, sy)

            -- Prevent control handles from pointing backwards on very sharp
            -- turns, which would otherwise create loops or hooks.
            if t1x * sx + t1y * sy < 0.18 then t1x, t1y = sx, sy end
            if t2x * sx + t2y * sy < 0.18 then t2x, t2y = sx, sy end

            local handle = segLen * strength
            local c1x, c1y = p1.x + t1x * handle, p1.y + t1y * handle
            local c2x, c2y = p2.x - t2x * handle, p2.y - t2y * handle
            local subdivisions = (segLen < 70 and 3) or (segLen < 170 and 4) or 5

            for j = 1, subdivisions do
                local t = j / subdivisions
                local u = 1 - t
                local x = u*u*u*p1.x + 3*u*u*t*c1x + 3*u*t*t*c2x + t*t*t*p2.x
                local y = u*u*u*p1.y + 3*u*u*t*c1y + 3*u*t*t*c2y + t*t*t*p2.y
                out[#out + 1] = { x = x, y = y, sourceSegment = i }
            end
        end
    end
    return out
end
function Navigator.RouteSmoother:BuildSegmentPath(smoothPoints, sourcePoints, segmentIndex)
    local out = {}
    local startPoint = sourcePoints and sourcePoints[segmentIndex]
    if startPoint then out[#out + 1] = { x = startPoint.x, y = startPoint.y } end
    for _, point in ipairs(smoothPoints or {}) do
        if point.sourceSegment == segmentIndex then
            out[#out + 1] = { x = point.x, y = point.y }
        end
    end
    return out
end

