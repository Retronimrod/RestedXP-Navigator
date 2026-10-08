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

function Planner:GetPlan(element)
    if type(element) ~= "table" then return nil end
    local travel = Navigator.TravelResolver and Navigator.TravelResolver.Resolve and Navigator.TravelResolver:Resolve(element) or nil
    local cross = travel and travel.crossInfo or (Navigator.TravelMode and Navigator.TravelMode.GetInfo and Navigator.TravelMode:GetInfo(element))

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
