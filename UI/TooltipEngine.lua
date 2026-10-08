local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.TooltipEngine = Navigator.TooltipEngine or { revision = 1 }
local Engine = Navigator.TooltipEngine

local function T(en, de)
    local locale = GetLocale and GetLocale() or "enUS"
    return locale == "deDE" and de or en
end

local function IsSameText(a, b)
    if not a or not b then return false end
    local function norm(s)
        return tostring(s):lower():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            :gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    end
    return norm(a) == norm(b)
end

local function SetOwner(owner, anchor)
    if not owner or not GameTooltip then return false end
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    return true
end

local function AddHeader(resolved, context)
    context = context or {}
    local prefix
    if resolved.futureOrdinal and resolved.futureOrdinal > 0 then
        prefix = "+" .. tostring(resolved.futureOrdinal)
    elseif context.showCurrentLabel then
        prefix = T("Current", "Aktuell")
    end

    local header = resolved.typeLabel or T("Objective", "Ziel")
    if resolved.transport and resolved.transport ~= "Flight Path" then
        header = resolved.transport
    end
    if resolved.icon then header = "|T" .. resolved.icon .. ":14:14:0:0|t " .. header end
    if prefix then header = prefix .. "  •  " .. header end
    GameTooltip:AddLine(header, 0.95, 0.76, 0.22)

    if resolved.stepIndex then
        GameTooltip:AddLine(T("Step ", "Schritt ") .. tostring(resolved.stepIndex), 0.55, 0.75, 0.95)
    end
end

local function AddBody(resolved)
    if resolved.title and not IsSameText(resolved.title, resolved.instruction) then
        GameTooltip:AddLine(resolved.title, 0.35, 0.90, 1.00, true)
    end
    if resolved.instruction then
        GameTooltip:AddLine(resolved.instruction, 1, 1, 1, true)
    end
    if resolved.objective and not IsSameText(resolved.objective, resolved.instruction) then
        GameTooltip:AddLine(T("Objective: ", "Ziel: ") .. resolved.objective, 0.45, 0.85, 1.00, true)
    end
    if resolved.travelPlan or resolved.smartTravelPlan then
        local travel = resolved.travelPlan or {}
        local smart = resolved.smartTravelPlan
        if smart and smart.route then
            travel = {
                destination = smart.route.toName or travel.destination,
                kindLabel = Navigator.Presentation and Navigator.Presentation:GetTransportLabel(smart.route.kind) or travel.kindLabel,
            }
        end
        if travel.destination and not IsSameText(travel.destination, resolved.title) then
            GameTooltip:AddLine(T("Destination: ", "Zielort: ") .. travel.destination, 1.00, 0.80, 0.28, true)
        end
        if travel.kindLabel then
            GameTooltip:AddLine(T("Travel type: ", "Reiseart: ") .. travel.kindLabel, 0.72, 0.82, 1.00, true)
        end
    end
end

function Engine:ShowElement(owner, element, context)
    if not element or not SetOwner(owner, context and context.anchor) then return end
    local resolved = Navigator.TargetResolver and Navigator.TargetResolver:Resolve(element, context)
    if not resolved then return end
    AddHeader(resolved, context)
    AddBody(resolved)
    GameTooltip:Show()
    return resolved
end

function Engine:ShowCluster(owner, members, fallbackElement, fallbackOrdinal)
    if not SetOwner(owner, "ANCHOR_CURSOR") then return end
    local resolved = Navigator.TargetResolver and Navigator.TargetResolver:ResolveMany(members) or {}
    if #resolved == 0 and fallbackElement then
        local one = Navigator.TargetResolver and Navigator.TargetResolver:Resolve(fallbackElement, { ordinal = fallbackOrdinal or 1 })
        if one then resolved[1] = one end
    end
    if #resolved == 0 then return end

    if #resolved > 1 then
        GameTooltip:AddLine(T("Multiple navigation goals", "Mehrere Navigationsziele"), 0.95, 0.76, 0.22)
        GameTooltip:AddLine(" ")
    end
    for i, target in ipairs(resolved) do
        AddHeader(target, { showCurrentLabel = #resolved > 1 })
        AddBody(target)
        if i < #resolved then GameTooltip:AddLine(" ") end
    end
    GameTooltip:Show()
    return resolved
end

function Engine:Hide(owner)
    if not GameTooltip then return end
    if not owner or GameTooltip:GetOwner() == owner then GameTooltip:Hide() end
end
