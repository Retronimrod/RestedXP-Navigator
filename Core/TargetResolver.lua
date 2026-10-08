local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.TargetResolver = Navigator.TargetResolver or { revision = 1 }
local Resolver = Navigator.TargetResolver

local function Clean(value)
    if value == nil then return nil end
    local s = tostring(value)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end

local function Localized(labels)
    local locale = GetLocale and GetLocale() or "enUS"
    return labels[locale] or labels.enUS or next(labels)
end

local TYPE_LABELS = {
    accept={enUS="Accept quest",deDE="Quest annehmen"},
    turnin={enUS="Turn in quest",deDE="Quest abgeben"},
    kill={enUS="Defeat enemies",deDE="Gegner besiegen"},
    loot={enUS="Collect / Loot",deDE="Sammeln / Plündern"},
    talk={enUS="Talk",deDE="Sprechen"},
    travel={enUS="Travel",deDE="Reisen"},
    explore={enUS="Explore",deDE="Erkunden"},
    objective={enUS="Objective",deDE="Ziel"},
}

local TRANSPORT_TYPE = {
    ["Flight"]="flight", ["Flight Path"]="flight",
    ["Hearthstone"]="hearthstone", ["Zeppelin"]="zeppelin",
    ["Boat"]="boat", ["Portal"]="portal",
}

local function InferSpecificType(element, genericType, transportHint)
    if transportHint and TRANSPORT_TYPE[transportHint] then return TRANSPORT_TYPE[transportHint] end
    local model = API:GetNormalizedRXPData(element)
    local tag = model and (model.semanticTag or model.tag)
    if tag == "explore" or tag == "discover" then return "explore" end
    if genericType then return genericType end
    return "objective"
end

function Resolver:Resolve(element, context)
    if type(element) ~= "table" then return nil end
    context = type(context) == "table" and context or {}
    local model = API:GetNormalizedRXPData(element) or {}
    local genericType = API:DetectStepType(element)
    local transportHint = API:GetTransportHint(element)
    local targetType = InferSpecificType(element, genericType, transportHint)
    local instruction = Clean(model.instruction or API:GetTargetInstruction(element))
    local objective = Clean(API:GetQuestObjectiveText(element))
    local targetName = Clean(model.targetName or model.itemName)
    local stepIndex = tonumber(model.stepIndex or element.rxpNavigatorStepIndex)
    local mapID, x, y = model.mapID, model.x, model.y
    if not mapID then mapID, x, y = API:GetTargetMap(element) end

    local ordinal = tonumber(context.ordinal)
    local futureOrdinal = tonumber(context.futureOrdinal)
    if not ordinal and futureOrdinal then ordinal = futureOrdinal + 1 end
    ordinal = ordinal or 1

    local typeLabel = API:GetStepTypeDisplayName(genericType)
    if not typeLabel and TYPE_LABELS[targetType] then typeLabel = Localized(TYPE_LABELS[targetType]) end
    if not typeLabel and TYPE_LABELS.objective then typeLabel = Localized(TYPE_LABELS.objective) end

    local title = targetName
    if not title or title == "" then
        title = instruction or typeLabel
    end

    local travelPlan = Navigator.TravelResolver and Navigator.TravelResolver.Resolve and Navigator.TravelResolver:Resolve(element) or nil
    local smartTravelPlan = Navigator.TravelPlanner and Navigator.TravelPlanner.GetPlan and Navigator.TravelPlanner:GetPlan(element) or nil
    if smartTravelPlan and smartTravelPlan.mode == "network" and Navigator.Presentation and Navigator.Presentation.FormatTravelObjective then
        local travelObjective = Navigator.Presentation:FormatTravelObjective(smartTravelPlan)
        if travelObjective and travelObjective ~= "" then objective = travelObjective end
    end

    return {
        revision = self.revision,
        source = "RestedXP",
        element = element,
        type = targetType,
        genericType = genericType,
        typeLabel = typeLabel,
        transport = transportHint,
        travelPlan = travelPlan,
        smartTravelPlan = smartTravelPlan,
        travelKind = (smartTravelPlan and smartTravelPlan.route and smartTravelPlan.route.kind) or (travelPlan and travelPlan.kind) or nil,
        destination = travelPlan and travelPlan.destination or nil,
        title = title,
        instruction = instruction,
        objective = objective,
        questID = model.questID,
        objectiveIndex = model.objectiveIndex,
        objectiveMax = model.objectiveMax,
        itemID = model.itemID,
        itemName = Clean(model.itemName),
        targetName = targetName,
        stepIndex = stepIndex,
        ordinal = ordinal,
        futureOrdinal = math.max(0, ordinal - 1),
        mapID = mapID, x = x, y = y,
        completed = model.completed == true,
        skipped = model.skipped == true,
        lowPriority = model.lowPriority == true,
        icon = API:GetStepIcon(genericType),
    }
end

function Resolver:ResolveMany(members)
    local out = {}
    if type(members) ~= "table" then return out end
    for _, member in ipairs(members) do
        local element = member and (member.element or member)
        if element then
            local resolved = self:Resolve(element, { ordinal = member.ordinal or 1 })
            if resolved then out[#out + 1] = resolved end
        end
    end
    return out
end

function Resolver:GetPrimaryTitle(element, context)
    local r = self:Resolve(element, context)
    return r and r.title or nil
end

function Navigator.API:GetResolvedTarget(element, context)
    return Resolver:Resolve(element, context)
end
