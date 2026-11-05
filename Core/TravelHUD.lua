local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.TravelHUD = Navigator.TravelHUD or { revision = 4 }

local HEARTH_ICON = "Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_Hearthstone.tga"

local TRAVEL_TEXT = {
    enUS = {
        useHearthstone = "Use your Hearthstone",
        useHearthstoneTo = "Use your Hearthstone to %s",
    },
    enGB = {
        useHearthstone = "Use your Hearthstone",
        useHearthstoneTo = "Use your Hearthstone to %s",
    },
    deDE = {
        useHearthstone = "Nutze deinen Ruhestein",
        useHearthstoneTo = "Nutze deinen Ruhestein nach %s",
    },
    frFR = {
        useHearthstone = "Utilisez votre Pierre de foyer",
        useHearthstoneTo = "Utilisez votre Pierre de foyer pour %s",
    },
    esES = {
        useHearthstone = "Usa tu piedra de hogar",
        useHearthstoneTo = "Usa tu piedra de hogar para %s",
    },
    esMX = {
        useHearthstone = "Usa tu piedra de hogar",
        useHearthstoneTo = "Usa tu piedra de hogar para %s",
    },
    itIT = {
        useHearthstone = "Usa la tua Pietra del Ritorno",
        useHearthstoneTo = "Usa la tua Pietra del Ritorno per %s",
    },
    ptBR = {
        useHearthstone = "Use sua Pedra de Regresso",
        useHearthstoneTo = "Use sua Pedra de Regresso para %s",
    },
    ruRU = {
        useHearthstone = "Используйте камень возвращения",
        useHearthstoneTo = "Используйте камень возвращения в %s",
    },
    koKR = {
        useHearthstone = "귀환석을 사용하세요",
        useHearthstoneTo = "%s으로 귀환석을 사용하세요",
    },
    zhCN = {
        useHearthstone = "使用你的炉石",
        useHearthstoneTo = "使用你的炉石前往%s",
    },
    zhTW = {
        useHearthstone = "使用你的爐石",
        useHearthstoneTo = "使用你的爐石前往%s",
    },
}

local function T(key, value)
    local code = GetLocale and GetLocale() or "enUS"
    local tableForLocale = TRAVEL_TEXT[code] or TRAVEL_TEXT.enUS
    local pattern = tableForLocale[key] or TRAVEL_TEXT.enUS[key] or ""
    if value and value ~= "" then return string.format(pattern, value) end
    return pattern
end

local function Clean(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and text or nil
end

local function GetTag(element)
    if type(element) ~= "table" then return nil end
    local tag = element.tag or element.action or element.type or element.command
    return tag and tostring(tag):lower() or nil
end

local function GetRXPAddon()
    if LibStub then
        local okAce, ace = pcall(LibStub, "AceAddon-3.0", true)
        if okAce and ace and type(ace.GetAddon) == "function" then
            local okAddon, addon = pcall(ace.GetAddon, ace, "RXPGuides", true)
            if okAddon and type(addon) == "table" then return addon end
        end
    end
    return rawget(_G, "RXPGuides")
end

local function IsHearth(e)
    if type(e) ~= "table" or e.skip or e.completed then return false end
    local tag = GetTag(e)
    if tag == "hs" or tag == "hsbatching" or tag == "home" or tag == "bindlocation" then return true end

    local text = Clean(e.text) or Clean(e.tooltipText) or Clean(e.mapTooltip) or Clean(e.rawtext)
    local low = text and text:lower() or ""
    return low:find("hearth to ", 1, true) ~= nil
        or low:find("use your hearthstone", 1, true) ~= nil
        or low:find("hearthstone to ", 1, true) ~= nil
        or low:find("ruhestein", 1, true) ~= nil
        or low:find("pierre de foyer", 1, true) ~= nil
        or low:find("piedra de hogar", 1, true) ~= nil
end

local function FindHearthInStep(step)
    if type(step) ~= "table" then return nil end
    if IsHearth(step) then return step end
    if type(step.elements) == "table" then
        for _, e in ipairs(step.elements) do
            if IsHearth(e) then return e end
        end
    end
    return nil
end

local function FindHearthElement(element)
    local addon = GetRXPAddon()
    local activeSteps = addon and addon.RXPFrame and addon.RXPFrame.activeSteps
    if type(activeSteps) == "table" then
        for _, step in ipairs(activeSteps) do
            local hearth = FindHearthInStep(step)
            if hearth then return hearth end
        end
    end

    if IsHearth(element) then return element end
    if type(element) == "table" then
        return FindHearthInStep(element.step)
    end
    return nil
end

local DESTINATION_PATTERNS = {
    "[Hh]earth%s+to%s+(.+)",
    "[Hh]earthstone%s+to%s+(.+)",
    "[Uu]se your [Hh]earthstone%s+to%s+(.+)",
    "[Nn]utze deinen [Rr]uhestein%s+nach%s+(.+)",
    "[Bb]enutze deinen [Rr]uhestein%s+nach%s+(.+)",
    "[Uu]tilisez votre [Pp]ierre de foyer%s+pour%s+(.+)",
    "[Uu]sa tu [Pp]iedra de hogar%s+para%s+(.+)",
    "[Uu]sa la tua [Pp]ietra del [Rr]itorno%s+per%s+(.+)",
    "[Uu]se sua [Pp]edra de [Rr]egresso%s+para%s+(.+)",
    "[Ии]спользуйте камень возвращения в%s+(.+)",
    "使用你的[炉爐]石前往%s*(.+)",
    "(.+)으로 귀환석을 사용하세요",
}

local function NormalizeDestination(destination)
    if not destination then return nil end
    destination = destination:gsub("%s*>>.*$", "")
    destination = destination:gsub("%s*%-%s*.*$", "")
    destination = destination:gsub("^to%s+", "")
    destination = destination:gsub("^nach%s+", "")
    destination = destination:gsub("^pour%s+", "")
    destination = destination:gsub("^para%s+", "")
    destination = destination:gsub("^per%s+", "")
    destination = destination:gsub("^前往", "")
    destination = destination:gsub("^%s+", ""):gsub("%s+$", "")
    return destination ~= "" and destination or nil
end

local function ExtractDestination(text)
    text = Clean(text)
    if not text then return nil end

    for _, pattern in ipairs(DESTINATION_PATTERNS) do
        local destination = text:match(pattern)
        destination = NormalizeDestination(destination)
        if destination then return destination end
    end
    return nil
end

local function AppendCandidate(list, value)
    value = Clean(value)
    if value then list[#list + 1] = value end
end

local function CollectCandidateTexts(hearth)
    local texts = {}
    if type(hearth) ~= "table" then return texts end

    AppendCandidate(texts, hearth.mapTooltip)
    AppendCandidate(texts, hearth.tooltipText)
    AppendCandidate(texts, hearth.hiddentext)
    AppendCandidate(texts, hearth.text)
    AppendCandidate(texts, hearth.rawtext)
    AppendCandidate(texts, hearth.title)
    AppendCandidate(texts, hearth.label)

    local step = hearth.step
    if type(step) == "table" then
        AppendCandidate(texts, step.mapTooltip)
        AppendCandidate(texts, step.tooltipText)
        AppendCandidate(texts, step.hiddentext)
        AppendCandidate(texts, step.text)
        AppendCandidate(texts, step.title)
        AppendCandidate(texts, step.label)

        if type(step.elements) == "table" then
            for _, e in ipairs(step.elements) do
                if e == hearth or IsHearth(e) then
                    AppendCandidate(texts, e.mapTooltip)
                    AppendCandidate(texts, e.tooltipText)
                    AppendCandidate(texts, e.hiddentext)
                    AppendCandidate(texts, e.text)
                    AppendCandidate(texts, e.rawtext)
                    AppendCandidate(texts, e.title)
                    AppendCandidate(texts, e.label)
                end
            end
        end
    end

    local instruction = API.GetTargetInstruction and API:GetTargetInstruction(hearth)
    AppendCandidate(texts, instruction)

    return texts
end

local function ResolveDestination(hearth)
    local candidates = CollectCandidateTexts(hearth)
    for _, text in ipairs(candidates) do
        local destination = ExtractDestination(text)
        if destination then return destination, text end
    end
    return nil, candidates[1]
end

function Navigator.TravelHUD:GetAnnouncement(element)
    local hearth = FindHearthElement(element)
    if not hearth then return nil end

    local destination, instruction = ResolveDestination(hearth)
    local message = destination and T("useHearthstoneTo", destination) or T("useHearthstone")

    return {
        kind = "hearthstone",
        title = message,
        action = nil,
        destination = destination,
        instruction = instruction,
        icon = HEARTH_ICON,
    }
end
