local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.TravelPlanner = Navigator.TravelPlanner or { revision = 1 }
local Planner = Navigator.TravelPlanner

local function Stage(kind, label, element, extra)
    local stage = { kind = kind, label = label, element = element }
    if type(extra) == "table" then
        for k, v in pairs(extra) do stage[k] = v end
    end
    return stage
end

function Planner:GetPlan(element, crossOverride)
    if type(element) ~= "table" then return nil end
    local travel = Navigator.TravelResolver and Navigator.TravelResolver.Resolve and Navigator.TravelResolver:Resolve(element, crossOverride) or nil
    local cross = crossOverride or travel and travel.crossInfo or (Navigator.TravelMode and Navigator.TravelMode.GetInfo and Navigator.TravelMode:GetInfo(element))

    if cross and Navigator.TravelNetwork and Navigator.TravelNetwork.FindBestCrossContinentRoute then
        local route = Navigator.TravelNetwork:FindBestCrossContinentRoute(element, cross)
        if route then
            local approach = Navigator.TravelNetwork:BuildApproachElement(route)
            return {
                revision = self.revision,
                mode = "network",
                travel = travel,
                crossInfo = cross,
                route = route,
                routeRaw = route.raw or route,
                approachElement = approach,
                navigationElement = approach or element,
                destinationElement = element,
                stages = {
                    Stage("approach", route.fromName, approach, { mapID=route.fromMap, x=route.fromX, y=route.fromY }),
                    Stage(route.kind, route.toName, nil, { fromName=route.fromName, toName=route.toName }),
                    Stage("onward", cross.targetZone, element),
                },
            }
        end
    end

    if travel and travel.explicitTransport then
        return {
            revision = self.revision,
            mode = "explicit",
            travel = travel,
            navigationElement = element,
            destinationElement = element,
            stages = {
                Stage(travel.kind, travel.destination or travel.kindLabel, element),
            },
        }
    end

    return {
        revision = self.revision,
        mode = "direct",
        travel = travel,
        navigationElement = element,
        destinationElement = element,
        stages = { Stage("direct", travel and (travel.destination or travel.kindLabel) or nil, element) },
    }
end

function Planner:GetNavigationElement(element)
    local plan = self:GetPlan(element)
    return plan and plan.navigationElement or element, plan
end

function Navigator.API:GetSmartTravelPlan(element)
    return Planner:GetPlan(element)
end

-- HUD and minimap share this short-lived travel cache. Other consumers
-- keep live planning. Direction and distance are calculated outside this cache.
local hudTravel = {}
function Planner:InvalidateHUDTravelCache()
    hudTravel.valid = false
end

function Planner:GetHUDTravelInfo(element)
    if type(element) ~= "table" then
        self:InvalidateHUDTravelCache()
        return nil
    end
    local now = GetTime()
    local map, x, y = API:GetTargetMap(element)
    local playerMap = API:ResolvePlayerMapAndPosition(map)
    local revision = Navigator.RXPData and Navigator.RXPData.revision
    local questRevision = Navigator.Performance and Navigator.Performance.questRevision
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local cache = hudTravel
    if cache.valid and cache.faction == faction and playerMap and cache.playerMap == playerMap
        and cache.element == element and cache.step == element.step
        and cache.map == map and cache.x == x and cache.y == y
        and cache.corpse == element.corpseNav and cache.skip == element.skip
        and cache.completed == element.completed and cache.text == element.text
        and cache.title == element.title and cache.tag == element.tag
        and cache.revision == revision and cache.questRevision == questRevision
        and now >= cache.time and now - cache.time < .25 then
        return cache.info
    end
    cache.faction = faction
    cache.valid, cache.time = playerMap ~= nil, now
    cache.playerMap, cache.element, cache.step = playerMap, element, element.step
    cache.map, cache.x, cache.y = map, x, y
    cache.corpse, cache.skip, cache.completed = element.corpseNav, element.skip, element.completed
    cache.text, cache.title, cache.tag = element.text, element.title, element.tag
    cache.revision, cache.questRevision = revision, questRevision
    cache.planReady, cache.plan, cache.route = false, nil, nil
    cache.info = Navigator.TravelMode and Navigator.TravelMode:GetInfo(element) or nil
    return cache.info
end

function Planner:GetHUDTravelPlan(element, info)
    local cache = hudTravel
    -- Only a matching result from GetHUDTravelInfo may reuse the selected route.
    if cache.valid and cache.element == element and cache.info == info and cache.planReady then
        return cache.plan, cache.route
    end
    local plan = self:GetPlan(element, info)
    local route = plan and plan.routeRaw or (Navigator.TravelMode and Navigator.TravelMode:GetBestRoute(element, info))
    if cache.valid and cache.element == element and cache.info == info then
        cache.planReady, cache.plan, cache.route = true, plan, route
    end
    return plan, route
end

local hudTravelEvents = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
    "PLAYER_CONTROL_GAINED", "PLAYER_CONTROL_LOST", "PLAYER_MOUNT_DISPLAY_CHANGED", "TAXIMAP_OPENED",
    "HEARTHSTONE_BOUND", "SPELLS_CHANGED"}) do
    -- Optional events differ between client versions. A missing event must
    -- never interrupt module loading; the 0.25-second expiry still applies.
    pcall(hudTravelEvents.RegisterEvent, hudTravelEvents, event)
end
hudTravelEvents:SetScript("OnEvent", function() Planner:InvalidateHUDTravelCache() end)
