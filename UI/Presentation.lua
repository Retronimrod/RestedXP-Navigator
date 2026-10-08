local Navigator = _G.RXPNavigator
if not Navigator then return end

Navigator.Presentation = Navigator.Presentation or { revision = 1 }
local P = Navigator.Presentation

P.palette = {
    navigation = {0.08, 0.74, 1.00},
    future = {0.30, 0.62, 1.00},
    search = {0.58, 0.88, 1.00},
    patrol = {1.00, 0.82, 0.34},
    farm = {0.42, 1.00, 0.70},
    corpse = {0.96, 0.10, 0.08},
    travel = {1.00, 0.78, 0.22},
}

P.transportIcons = {
    hearthstone = "Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Hearthstone.tga",
    flight = "Interface\\MINIMAP\\TRACKING\\FlightMaster",
    zeppelin = "Interface\\MINIMAP\\TRACKING\\FlightMaster",
    boat = "Interface\\MINIMAP\\TRACKING\\FlightMaster",
    portal = "Interface\\Icons\\Spell_Arcane_PortalOrgrimmar",
    travel = "Interface\\MINIMAP\\TRACKING\\FlightMaster",
}

local labels = {
    hearthstone = {enUS="Hearthstone",deDE="Ruhestein"},
    flight = {enUS="Flight",deDE="Flug"},
    zeppelin = {enUS="Zeppelin",deDE="Zeppelin"},
    boat = {enUS="Ship",deDE="Schiff"},
    portal = {enUS="Portal",deDE="Portal"},
    travel = {enUS="Travel",deDE="Reise"},
    approach = {enUS="Go to",deDE="Gehe zu"},
    objectiveLabel = {enUS="Objective",deDE="Ziel"},
    tower = {enUS="Zeppelin tower",deDE="Zeppelinturm"},
    takeZeppelin = {enUS="Take the Zeppelin to",deDE="Nimm den Zeppelin nach"},
    takeShip = {enUS="Take the ship to",deDE="Nimm das Schiff nach"},
    takeFlight = {enUS="Fly to",deDE="Fliege nach"},
    usePortal = {enUS="Use the portal to",deDE="Nutze das Portal nach"},
    southPlatform = {enUS="South platform",deDE="Südliche Plattform"},
    northPlatform = {enUS="North platform",deDE="Nördliche Plattform"},
    westPlatform = {enUS="West platform",deDE="Westliche Plattform"},
    eastPlatform = {enUS="East platform",deDE="Östliche Plattform"},
    ["then"] = {enUS="Then",deDE="Danach"},
}

local function L(key)
    local locale = GetLocale and GetLocale() or "enUS"
    local item = labels[key]
    return item and (item[locale] or item.enUS) or key
end

function P:GetColor(kind)
    local c = self.palette[kind] or self.palette.navigation
    return c[1], c[2], c[3]
end

function P:GetTransportIcon(kind)
    return self.transportIcons[kind] or self.transportIcons.travel
end

function P:GetTransportLabel(kind)
    return L(kind or "travel")
end

function P:FormatTravelTitle(plan)
    if not plan then return nil end
    local travel = plan.travel
    local route = plan.route
    -- A network plan must describe the immediate transport leg. The final RXP
    -- destination can be another zone beyond the transport arrival point.
    local kind = route and route.kind or (travel and travel.kind) or "travel"
    local label = self:GetTransportLabel(kind)
    local destination = route and route.toName or (travel and travel.destination)
    if destination and destination ~= "" then return label .. " -> " .. destination end
    return label
end

local function PlatformLabel(detail)
    if not detail or detail == "" then return nil end
    local d = tostring(detail):lower()
    if d:find("south platform", 1, true) then return L("southPlatform") end
    if d:find("north platform", 1, true) then return L("northPlatform") end
    if d:find("west platform", 1, true) then return L("westPlatform") end
    if d:find("east platform", 1, true) then return L("eastPlatform") end
    local suffix = tostring(detail):match("%-%s*(.+)$")
    return suffix or tostring(detail)
end

local function ApproachName(route)
    if not route then return nil end
    local kind = tostring(route.kind or ""):lower()
    local fromName = route.fromName or "?"
    if kind == "zeppelin" then
        return L("tower") .. " " .. tostring(fromName)
    end
    return tostring(fromName)
end

local function TransportInstruction(route)
    if not route then return nil end
    local kind = tostring(route.kind or ""):lower()
    local destination = route.toName or "?"
    if kind == "zeppelin" then return L("takeZeppelin") .. " " .. tostring(destination) end
    if kind == "boat" or kind == "ship" then return L("takeShip") .. " " .. tostring(destination) end
    if kind == "flight" then return L("takeFlight") .. " " .. tostring(destination) end
    if kind == "portal" then return L("usePortal") .. " " .. tostring(destination) end
    return L("then") .. ": " .. tostring(destination)
end

function P:FormatTravelContext(plan)
    if not plan then return nil end
    if plan.mode == "network" and plan.route then
        local route = plan.route
        local lines = {}
        lines[#lines + 1] = L("objectiveLabel") .. ": " .. ApproachName(route)
        local platform = PlatformLabel(route.fromDetail)
        if platform and platform ~= "" then lines[#lines + 1] = platform end
        local instruction = TransportInstruction(route)
        if instruction then lines[#lines + 1] = instruction end
        return table.concat(lines, "\n")
    end
    local travel = plan.travel
    return travel and travel.instruction or nil
end

function P:FormatTravelObjective(plan)
    if not plan then return nil end
    if plan.mode == "network" and plan.route then
        local route = plan.route
        local objective = L("approach") .. ": " .. ApproachName(route)
        local platform = PlatformLabel(route.fromDetail)
        if platform and platform ~= "" then objective = objective .. " - " .. platform end
        local instruction = TransportInstruction(route)
        if instruction then objective = objective .. "; " .. instruction end
        return objective
    end
    return self:FormatTravelContext(plan)
end
