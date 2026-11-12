local _, bridge = ...
local navigator = RXPNavigator
local hideWorldLine, hideMinimapLine = false, false
local minimapOverlay, activeMinimapRegions
local media = "interface/addons/rxp_navigator/media/"

function bridge.UpdateMapRoutes(world, minimap)
    local alive = not UnitIsDeadOrGhost("player")
    hideWorldLine = world and alive
    hideMinimapLine = minimap and alive
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

local function FindMinimapRegions(overlay)
    local regions = {}
    for _, region in ipairs({overlay:GetRegions()}) do
        if region:IsObjectType("Texture") then
            local texture = region:GetTexture()
            if type(texture) == "string" or type(texture) == "number" then
                if type(texture) == "string" then texture = texture:lower():gsub("\\", "/") end
                local layer, sublevel = region:GetDrawLayer()
                if layer == "OVERLAY" and (
                    ((sublevel == 5 or sublevel == 6) and (type(texture) == "number" or texture == media .. "rxpnav_linefade.tga"))
                    or (sublevel == 7 and region:GetWidth() == 12
                        and (type(texture) == "number" or texture == media .. "rxpnav_arrowwhite.tga"))
                ) then
                    regions[#regions + 1] = region
                end
            end
        end
    end
    return regions
end

if navigator.MinimapFuture and navigator.MinimapFuture.Update then
    hooksecurefunc(navigator.MinimapFuture, "Update", function(_, context)
        if not hideMinimapLine or not context or context.corpseMode then return end
        local overlay = context.overlay
        if not overlay or overlay ~= _G.RXPNavigatorOverlay then return end
        if minimapOverlay ~= overlay then
            minimapOverlay = overlay
            activeMinimapRegions = FindMinimapRegions(overlay)
        end
        for _, region in ipairs(activeMinimapRegions) do region:Hide() end
    end)
end
