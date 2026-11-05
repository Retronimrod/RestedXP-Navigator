local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.TravelResolver = Navigator.TravelResolver or { revision = 1 }
local Resolver = Navigator.TravelResolver

local KIND_LABELS = {
    hearthstone = { enUS="Hearthstone", deDE="Ruhestein" },
    flight = { enUS="Flight", deDE="Flug" },
    zeppelin = { enUS="Zeppelin", deDE="Zeppelin" },
    boat = { enUS="Ship", deDE="Schiff" },
    portal = { enUS="Portal", deDE="Portal" },
    travel = { enUS="Travel", deDE="Reise" },
}

local function Localized(values)
    local locale = GetLocale and GetLocale() or "enUS"
    return values and (values[locale] or values.enUS) or nil
end

local function Clean(value)
    if value == nil then return nil end
    local s = tostring(value)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end

local function Lower(value)
    local s = Clean(value)
    return s and s:lower() or ""
end

local function DetectKind(element, model)
    local hint = API:GetTransportHint(element)
    if hint == "Hearthstone" then return "hearthstone", hint end
    if hint == "Flight" or hint == "Flight Path" then return "flight", hint end
    if hint == "Zeppelin" then return "zeppelin", hint end
    if hint == "Boat" then return "boat", hint end
    if hint == "Portal" then return "portal", hint end

    local tag = model and (model.semanticTag or model.tag)
    tag = tag and tostring(tag):lower() or ""
    if tag == "hs" or tag == "hsbatching" or tag == "home" or tag == "bindlocation" then return "hearthstone", hint end
    if tag == "fly" or tag == "fp" or tag == "flygoto" then return "flight", hint end

    local text = Lower((model and model.instruction) or API:GetTargetInstruction(element) or element.text or element.title)
    if text:find("zeppelin", 1, true) then return "zeppelin", hint end
    if text:find("boat", 1, true) or text:find("ship", 1, true) or text:find("schiff", 1, true) then return "boat", hint end
    if text:find("portal", 1, true) then return "portal", hint end
    if text:find("hearth", 1, true) or text:find("ruhestein", 1, true) then return "hearthstone", hint end
    if text:find("flight master", 1, true) or text:find("fly to", 1, true) or text:find("flight path", 1, true)
        or text:find("flugmeister", 1, true) or text:find("fliege", 1, true) or text:find("fliegt", 1, true) then
        return "flight", hint
    end

    local generic = API:DetectStepType(element)
    if generic == "travel" then return "travel", hint end
    return nil, hint
end

local function ExtractDestination(element, model)
    local explicit = Clean(model and model.targetName)
    if explicit then return explicit end

    local text = Clean((model and model.instruction) or API:GetTargetInstruction(element) or element.text or element.title)
    if not text then return nil end

    local patterns = {
        "[Tt]o%s+(.+)$",
        "[Nn]ach%s+(.+)$",
        "[Tt]owards%s+(.+)$",
        "[Zz]u%s+(.+)$",
    }
    for _, pattern in ipairs(patterns) do
        local found = text:match(pattern)
        if found then
            found = found:gsub("[%.,;:]$", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if found ~= "" and #found <= 80 then return found end
        end
    end
    return nil
end

function Resolver:Resolve(element)
    if type(element) ~= "table" then return nil end
    local model = API:GetNormalizedRXPData(element) or {}
    local kind, hint = DetectKind(element, model)
    if not kind then return nil end

    local mapID, x, y = model.mapID, model.x, model.y
    if not mapID then mapID, x, y = API:GetTargetMap(element) end

    local cross = Navigator.TravelMode and Navigator.TravelMode.GetInfo and Navigator.TravelMode:GetInfo(element) or nil
    local destination = ExtractDestination(element, model)
    if not destination and cross then destination = cross.targetZone end

    return {
        revision = self.revision,
        kind = kind,
        kindLabel = Localized(KIND_LABELS[kind]) or Localized(KIND_LABELS.travel),
        transportHint = hint,
        destination = destination,
        instruction = Clean(model.instruction or API:GetTargetInstruction(element)),
        mapID = mapID, x = x, y = y,
        crossContinent = cross ~= nil,
        crossInfo = cross,
        explicitTransport = kind ~= "travel",
        source = "RestedXP",
        element = element,
    }
end

function Resolver:IsTravel(element)
    return self:Resolve(element) ~= nil
end

function Navigator.API:GetTravelPlan(element)
    return Resolver:Resolve(element)
end
