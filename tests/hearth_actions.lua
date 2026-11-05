-- Run from repository root: lua tests/hearth_actions.lua
local locale = "enUS"
GetLocale = function() return locale end
RXPGuides = {RXPFrame = {activeSteps = {}}}
RXPNavigator = {API = {
    GetNormalizedRXPData = function(_, e)
        return {semanticTag = e.semanticTag or e.tag, instruction = e.text}
    end,
    GetTargetInstruction = function(_, e) return e.text end,
    GetTransportHint = function() return "Hearthstone" end,
    GetTargetMap = function() return 1, 0.5, 0.5 end,
}}
assert(loadfile("Core/HearthActions.lua"))()
assert(loadfile("Core/TravelHUD.lua"))()
assert(loadfile("Core/TravelResolver.lua"))()
local actions, hud, resolver = RXPNavigator.HearthActions, RXPNavigator.TravelHUD, RXPNavigator.TravelResolver
for _, tag in ipairs({"home", "bindlocation"}) do
    local bind = {tag = tag, text = "Set your Hearthstone to Crossroads"}
    assert(actions:Classify(bind) == "bind")
    assert(hud:GetAnnouncement(bind) == nil, "Binding must not override navigation with a use announcement")
    assert(resolver:Resolve(bind) == nil, "Binding must not become a teleport plan, even with a stale transport hint")
    local step = {elements = {{tag = "goto", text = "Talk to Innkeeper Boorand"}, bind}}
    RXPGuides.RXPFrame.activeSteps = {step}
    assert(hud:GetAnnouncement(step.elements[1]) == nil, "Active-step scanning must not misclassify a sibling bind command")
end
RXPGuides.RXPFrame.activeSteps = {}
local examples = {
    {text = "|cffffff00Set your Hearthstone to Crossroads|r"},
    {text = "Binde deinen Ruhestein in Crossroads"},
    {tag = "goto", text = "Talk to Innkeeper Boorand", tooltipText = "Set your Hearthstone to Crossroads"},
    {tag = "goto", semanticTag = "home", text = "Set your Hearthstone to Crossroads"},
}
for _, e in ipairs(examples) do
    assert(hud:GetAnnouncement(e) == nil)
    assert(resolver:Resolve(e) == nil)
end
for _, tag in ipairs({"hs", "hsbatching"}) do
    local e = {tag = tag, text = "Use your Hearthstone to Crossroads"}
    assert(actions:Classify(e) == "use")
    local announcement = hud:GetAnnouncement(e)
    assert(announcement and announcement.title == "Use your Hearthstone to Crossroads")
    assert(resolver:Resolve(e).kind == "hearthstone")
    e.completed = true
    assert(hud:GetAnnouncement(e) == nil)
end
locale = "deDE"
local german = {text = "Benutze deinen Ruhestein nach Crossroads"}
assert(hud:GetAnnouncement(german).title == "Nutze deinen Ruhestein nach Crossroads")
assert(hud:GetAnnouncement({text = "Beim Gastwirt kannst du deinen Ruhestein binden"}) == nil)
assert(hud:GetAnnouncement({text = "Talk about the Hearthstone with the innkeeper"}) == nil)
assert(hud:GetAnnouncement({tag = "home", text = "Use your Hearthstone to Crossroads"}) == nil, "Binding tag takes precedence over text")
print("PASS: bind/use separation, Crossroads active step, semantic tags, localized text and actual hearthstone use")
