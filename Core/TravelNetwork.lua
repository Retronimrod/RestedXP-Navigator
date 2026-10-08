local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.TravelNetwork = Navigator.TravelNetwork or { revision = 1 }
local Network = Navigator.TravelNetwork

local MODE_WEIGHT = {
    zeppelin = 250,
    boat = 250,
    flight = 120,
    portal = 80,
    hearthstone = 20,
    travel = 300,
}

local function NormalizeKind(kind)
    kind = kind and tostring(kind):lower() or "travel"
    if kind == "ship" then return "boat" end
    return kind
end

local function Distance(ax, ay, bx, by)
    if not (ax and ay and bx and by) then return nil end
    local dx, dy = bx - ax, by - ay
    return math.sqrt(dx * dx + dy * dy)
end

function Network:GetStaticRoutes()
    local out = {}
    local routes = Navigator.TravelMode and Navigator.TravelMode.routes or nil
    if type(routes) ~= "table" then return out end
    for _, route in ipairs(routes) do
        if type(route) == "table" and route.fromMap and route.fromX and route.fromY and route.toMap and route.toX and route.toY then
            out[#out + 1] = {
                source = "curated",
                kind = NormalizeKind(route.kind),
                label = route.kind,
                fromName = route.fromName,
                fromDetail = route.fromDetail,
                fromMap = route.fromMap, fromX = route.fromX, fromY = route.fromY,
                toName = route.toName,
                toMap = route.toMap, toX = route.toX, toY = route.toY,
                raw = route,
            }
        end
    end
    return out
end

function Network:GetDynamicNode(element)
    local travel = Navigator.TravelResolver and Navigator.TravelResolver.Resolve and Navigator.TravelResolver:Resolve(element) or nil
    if not travel or not travel.mapID or not travel.x or not travel.y then return nil end
    return {
        source = "rxp",
        kind = travel.kind,
        name = travel.destination or travel.kindLabel,
        mapID = travel.mapID,
        x = travel.x,
        y = travel.y,
        element = element,
        travel = travel,
    }
end

function Network:BuildApproachElement(route)
    if type(route) ~= "table" or not route.fromMap then return nil end
    return {
        zone = route.fromMap,
        x = route.fromX,
        y = route.fromY,
        arrow = true,
        textOnly = true,
        travelPoint = true,
        rxpNavigatorTravelPoint = true,
        travelKind = route.kind,
        travelName = route.fromName,
        travelDestination = route.toName,
    }
end

function Network:FindBestCrossContinentRoute(element, info)
    info = info or (Navigator.TravelMode and Navigator.TravelMode.GetInfo and Navigator.TravelMode:GetInfo(element))
    if not info then return nil end

    local best, bestScore
    for _, route in ipairs(self:GetStaticRoutes()) do
        local fromWX, fromWY, fromContinent = API:GetWorldPosForMap(route.fromMap, route.fromX, route.fromY)
        local toWX, toWY, toContinent = API:GetWorldPosForMap(route.toMap, route.toX, route.toY)
        if fromWX and fromWY and toWX and toWY and fromContinent == info.playerContinent and toContinent == info.targetContinent then
            local approach = Distance(info.playerWorldX, info.playerWorldY, fromWX, fromWY)
            local onward = Distance(toWX, toWY, info.targetWorldX, info.targetWorldY)
            if approach and onward then
                local score = approach + onward + (MODE_WEIGHT[route.kind] or MODE_WEIGHT.travel)
                if not bestScore or score < bestScore then
                    bestScore = score
                    best = route
                    best.approachDistance = approach
                    best.onwardDistance = onward
                    best.score = score
                end
            end
        end
    end
    return best
end

function Network:GetKnownTravelPoints(element)
    local points = {}
    local dynamic = self:GetDynamicNode(element)
    if dynamic then points[#points + 1] = dynamic end
    for _, route in ipairs(self:GetStaticRoutes()) do
        points[#points + 1] = {
            source = route.source,
            kind = route.kind,
            name = route.fromName,
            mapID = route.fromMap,
            x = route.fromX,
            y = route.fromY,
            destination = route.toName,
            route = route,
        }
    end
    return points
end

-- Preserve the established TravelMode API while routing selection through the
-- dedicated network module. Callers from older beta code continue to work.
if Navigator.TravelMode then
    Navigator.TravelMode.GetBestRoute = function(_, element, info)
        local route = Network:FindBestCrossContinentRoute(element, info)
        return route and (route.raw or route) or nil
    end
end

function Navigator.API:GetKnownTravelPoints(element)
    return Network:GetKnownTravelPoints(element)
end
