local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.GrindHUD = Navigator.GrindHUD or { revision = 1 }
local GrindHUD = Navigator.GrindHUD

local function Clean(value)
    if value == nil then return nil end
    local s = tostring(value)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    s = s:gsub("\n", " ")
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s ~= "" and s or nil
end

local function AddText(parts, value)
    local s = Clean(value)
    if s and s ~= "" then parts[#parts + 1] = s end
end

local function StepText(step)
    if type(step) ~= "table" then return "" end
    local parts = {}

    AddText(parts, rawget(step, "text"))
    AddText(parts, rawget(step, "title"))
    AddText(parts, rawget(step, "tooltipText"))

    local elements = rawget(step, "elements")
    if type(elements) == "table" then
        for _, element in ipairs(elements) do
            if type(element) == "table" then
                AddText(parts, API:GetTargetInstruction(element))
                AddText(parts, API:GetQuestObjectiveText(element))
                AddText(parts, rawget(element, "text"))
                AddText(parts, rawget(element, "title"))
                AddText(parts, rawget(element, "tooltipText"))
            end
        end
    end

    return table.concat(parts, " ")
end

local function ParseTargetXP(text)
    text = Clean(text)
    if not text then return nil end

    -- RestedXP examples:
    -- "Grind to 1680+/2800xp"
    -- "Grind to 1680 / 2800 XP"
    -- Keep the match deliberately tied to "grind" so ordinary XP text does not
    -- create the HUD accidentally.
    local lower = text:lower()
    local grindStart = lower:find("grind", 1, true)
    if not grindStart then return nil end

    local tail = lower:sub(grindStart)
    local goal, total = tail:match("grind%s+to%s+(%d+)%s*%+?%s*/%s*(%d+)%s*xp")
    if not goal then
        goal, total = tail:match("grind%s+to%s+(%d+)%s*%+?%s*/%s*(%d+)")
    end
    if not goal then
        goal = tail:match("grind%s+to%s+(%d+)%s*%+?%s*xp")
    end

    goal = tonumber(goal)
    total = tonumber(total)
    if not goal or goal <= 0 then return nil end
    return goal, total
end

function GrindHUD:GetState()
    if not API.ResolveActiveGuideAndStep then return nil end

    local guide, stepIndex = API:ResolveActiveGuideAndStep()
    local steps = type(guide) == "table" and rawget(guide, "steps") or nil
    if type(steps) ~= "table" or not stepIndex then return nil end

    local step = rawget(steps, tonumber(stepIndex))
    if type(step) ~= "table" or step.skip or step.completed then return nil end

    local text = StepText(step)
    local goalXP, parsedMax = ParseTargetXP(text)
    if not goalXP then return nil end

    local currentXP = UnitXP and UnitXP("player") or nil
    local levelMax = UnitXPMax and UnitXPMax("player") or nil
    if type(currentXP) ~= "number" then return nil end
    if type(levelMax) ~= "number" or levelMax <= 0 then levelMax = parsedMax end
    if type(parsedMax) == "number" and parsedMax > 0 then levelMax = parsedMax end

    -- Once the requested threshold has been reached, the grind HUD is no
    -- longer useful. RestedXP usually advances the step immediately after this.
    if currentXP >= goalXP then return nil end

    local ratio = math.max(0, math.min(1, currentXP / goalXP))
    return {
        stepIndex = tonumber(stepIndex),
        currentXP = math.floor(currentXP + 0.5),
        goalXP = math.floor(goalXP + 0.5),
        levelMax = type(levelMax) == "number" and math.floor(levelMax + 0.5) or nil,
        remainingXP = math.max(0, math.floor(goalXP - currentXP + 0.5)),
        ratio = ratio,
        progressText = string.format("%d / %d XP", currentXP, goalXP),
        actionText = levelMax and
            string.format("Kill mobs to reach %d+ / %d XP", goalXP, levelMax) or
            string.format("Kill mobs to reach %d+ XP", goalXP),
    }
end
