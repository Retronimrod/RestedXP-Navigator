local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.ObjectResolver = Navigator.ObjectResolver or { revision = 1 }
local Resolver = Navigator.ObjectResolver

local ICONS = {
    crystal   = "Interface\\Icons\\INV_Misc_Gem_Crystal_01",
    chest     = "Interface\\Icons\\INV_Misc_TreasureChest04b",
    herb      = "Interface\\Icons\\INV_Misc_Herb_19",
    mushroom  = "Interface\\Icons\\INV_Mushroom_11",
    egg       = "Interface\\Icons\\INV_Egg_02",
    container = "Interface\\Icons\\INV_Misc_Bag_10",
    corpse    = "Interface\\Icons\\INV_Misc_Bone_01",
    object    = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local LABELS = {
    crystal={enUS="Crystal / mineral",deDE="Kristall / Mineral"},
    chest={enUS="Chest / cache",deDE="Truhe / Vorrat"},
    herb={enUS="Plant / herb",deDE="Pflanze / Kraut"},
    mushroom={enUS="Mushroom",deDE="Pilz"},
    egg={enUS="Egg",deDE="Ei"},
    container={enUS="Container",deDE="Behälter"},
    corpse={enUS="Remains / corpse",deDE="Überreste / Leiche"},
    object={enUS="Quest object",deDE="Questobjekt"},
}

local function L(labels)
    local locale = GetLocale and GetLocale() or "enUS"
    return labels and (labels[locale] or labels.enUS) or nil
end

local function Clean(value)
    if value == nil then return nil end
    local s = tostring(value)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s ~= "" and s or nil
end

local function StepElements(step)
    return type(step) == "table" and type(step.elements) == "table" and step.elements or nil
end

local function ElementTag(element)
    if Navigator.RXPData and Navigator.RXPData.GetTag then
        return Navigator.RXPData:GetTag(element) or ""
    end
    return ""
end

function Resolver:GetStepText(step)
    local elements = StepElements(step)
    if not elements then return "" end
    local chunks = {}
    for _, element in ipairs(elements) do
        if type(element) == "table" then
            local instruction = API:GetTargetInstruction(element)
            local objective = API:GetQuestObjectiveText(element)
            local raw = element.text or element.title or element.tooltipText
            if instruction and instruction ~= "" then chunks[#chunks + 1] = instruction end
            if objective and objective ~= "" then chunks[#chunks + 1] = objective end
            if raw and raw ~= "" then chunks[#chunks + 1] = raw end
        end
    end
    return API:LowerClean(table.concat(chunks, " ")) or ""
end

function Resolver:HasMobElement(step)
    local elements = StepElements(step)
    if not elements then return false end
    for _, element in ipairs(elements) do
        if type(element) == "table" then
            local tag = ElementTag(element)
            if tag == "mob" or tag == "target" then
                local text = API:LowerClean(API:GetTargetInstruction(element) or element.text or "") or ""
                if tag == "mob" or text:find("kill", 1, true) or text:find("slay", 1, true) then return true end
            end
        end
    end
    return false
end

function Resolver:IsObjectActionStep(step)
    if type(step) ~= "table" or step.skip or step.completed or self:HasMobElement(step) then return false end
    local text = self:GetStepText(step)
    if text == "" then return false end

    -- Strong interaction language. Avoid broad "collect" matching because RXP
    -- also uses .collect for vendor purchases and inventory preparation.
    local positive =
        text:find("click on", 1, true) or text:find("click the", 1, true) or
        text:find("click ", 1, true) or text:find("open the", 1, true) or
        text:find("open ", 1, true) or text:find("pick up", 1, true) or
        text:find("pickup", 1, true) or text:find("gather ", 1, true) or
        text:find("harvest ", 1, true) or text:find("interact", 1, true) or
        text:find("loot the", 1, true)
    if not positive then return false end

    if text:find("vendor", 1, true) or text:find("buy ", 1, true) then return false end
    return true
end

function Resolver:GetRepresentativeElement(step)
    local elements = StepElements(step)
    if not elements then return nil end
    local fallback
    for _, element in ipairs(elements) do
        if type(element) == "table" and not element.skip and not element.completed then
            fallback = fallback or element
            local objective = API:GetQuestObjectiveText(element)
            if objective and objective ~= "" then return element end
        end
    end
    return fallback
end

local function StripProgress(text)
    text = Clean(text)
    if not text then return nil end
    text = text:gsub("^%s*%d+%s*/%s*%d+%s*", "")
    text = text:gsub("^%s*%-%s*", "")
    return Clean(text)
end

function Resolver:Classify(text)
    text = API:LowerClean(text or "") or ""
    if text:find("crystal",1,true) or text:find("gem",1,true) or text:find("ore",1,true) or text:find("stone",1,true) then return "crystal" end
    if text:find("mushroom",1,true) or text:find("fungus",1,true) then return "mushroom" end
    if text:find("herb",1,true) or text:find("flower",1,true) or text:find("plant",1,true) or text:find("leaf",1,true) then return "herb" end
    if text:find("egg",1,true) then return "egg" end
    if text:find("chest",1,true) or text:find("cache",1,true) or text:find("coffer",1,true) or text:find("crate",1,true) then return "chest" end
    if text:find("barrel",1,true) or text:find("box",1,true) or text:find("container",1,true) or text:find("supply",1,true) then return "container" end
    if text:find("corpse",1,true) or text:find("carcass",1,true) or text:find("remains",1,true) or text:find("bone",1,true) then return "corpse" end
    return "object"
end

function Resolver:GetStepIndex(step, guide)
    if type(step) ~= "table" or type(guide) ~= "table" then return nil end
    local idx = tonumber(rawget(step, "index"))
    local steps = rawget(guide, "steps")
    if idx and type(steps) == "table" and steps[idx] == step then return idx end
    if type(steps) == "table" then
        for i, candidate in ipairs(steps) do if candidate == step then return i end end
    end
    return idx
end

function Resolver:GetDescriptorForLoop(step)
    if type(step) ~= "table" or not step.loop then return nil end
    local guide = API:ResolveActiveGuideAndStep()
    local steps = guide and rawget(guide, "steps")
    if type(steps) ~= "table" then return nil end
    local idx = self:GetStepIndex(step, guide)
    if not idx then return nil end

    local actionStep
    -- Object-location loops in RXP are usually immediately followed by the
    -- click/open/gather objective. Keep the search deliberately narrow so farm
    -- and patrol loops cannot be misclassified from unrelated later steps.
    for offset = 1, 2 do
        local candidate = steps[idx + offset]
        if type(candidate) == "table" and not candidate.skip and not candidate.completed then
            if self:IsObjectActionStep(candidate) then actionStep = candidate; break end
            if candidate.loop then break end
        end
    end
    if not actionStep then return nil end

    local element = self:GetRepresentativeElement(actionStep)
    if not element then return nil end
    local instruction = Clean(API:GetTargetInstruction(element))
    local objective = Clean(API:GetQuestObjectiveText(element))
    local model = API:GetNormalizedRXPData(element) or {}
    local name = StripProgress(objective) or Clean(model.targetName or model.itemName) or instruction or L(LABELS.object)
    local combined = table.concat({name or "", instruction or "", objective or ""}, " ")
    local objectType = self:Classify(combined)

    return {
        loopStep = step,
        actionStep = actionStep,
        element = element,
        objectType = objectType,
        icon = ICONS[objectType] or ICONS.object,
        typeLabel = L(LABELS[objectType] or LABELS.object),
        name = name,
        instruction = instruction,
        objective = objective,
        stepIndex = tonumber(rawget(actionStep, "index")) or (idx + 1),
    }
end

function Resolver:ShowTooltip(owner, descriptor, distance)
    if not owner or not descriptor or not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    local icon = descriptor.icon and ("|T" .. descriptor.icon .. ":16:16:0:0|t ") or ""
    GameTooltip:AddLine(icon .. (descriptor.name or descriptor.typeLabel or L(LABELS.object)), 0.95, 0.76, 0.22)
    if descriptor.typeLabel then GameTooltip:AddLine(descriptor.typeLabel, 0.45, 0.85, 1.00) end
    if descriptor.instruction and descriptor.instruction ~= descriptor.name then GameTooltip:AddLine(descriptor.instruction, 1, 1, 1, true) end
    if descriptor.objective then
        local label = (GetLocale and GetLocale() == "deDE") and "Fortschritt: " or "Progress: "
        GameTooltip:AddLine(label .. descriptor.objective, 0.65, 0.95, 0.65, true)
    end
    if type(distance) == "number" then
        local label = (GetLocale and GetLocale() == "deDE") and "Entfernung: " or "Distance: "
        GameTooltip:AddLine(label .. tostring(math.floor(distance + 0.5)) .. " yd", 0.75, 0.82, 1.00)
    end
    GameTooltip:Show()
end

function Resolver:HideTooltip(owner)
    if GameTooltip and (not owner or GameTooltip:GetOwner() == owner) then GameTooltip:Hide() end
end
