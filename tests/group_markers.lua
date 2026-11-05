-- Run from the repository root: lua tests/group_markers.lua
local frames, messages = {}, {}
local combat, grouped, raid, instance = false, true, false, false
local now, link = 10, "|Hworldmap:1:1000:2000|h[Map Pin]|h"
local currentPoint = { uiMapID = 1, position = { x = 0.1, y = 0.2 } }
local db = { enabled = true, showWorldMarkerNative = true }
_G.RXPNavigator = { API = {
    GetDB = function() return db end,
    Print = function() end,
} }
UIParent = {}
GameTooltip = setmetatable({}, { __index = function() return function() end end })
LE_PARTY_CATEGORY_INSTANCE = 2
GetLocale = function() return "deDE" end
InCombatLockdown = function() return combat end
IsInGroup = function(category) if category then return instance end; return grouped end
IsInRaid = function() return raid end
GetTime = function() return now end
PlaceRaidMarker = function() error("Marker must be invoked by a secure action, never Lua") end
C_Map = {
    GetUserWaypoint = function() return currentPoint end,
    GetUserWaypointHyperlink = function() return link end,
}
SendChatMessage = function(message, channel) messages[#messages + 1] = {message, channel} end

local function object()
    local o = { scripts = {}, attributes = {}, shown = false }
    local function mutate(self)
        assert(not combat, "UI mutated during combat")
    end
    for _, method in ipairs({"SetSize", "SetPoint", "SetFrameStrata", "SetAllPoints", "SetColorTexture", "SetTexture", "SetHighlightTexture", "SetText", "RegisterForClicks"}) do
        o[method] = mutate
    end
    function o:SetScript(name, fn) self.scripts[name] = fn end
    function o:RegisterEvent() end
    function o:SetAttribute(name, value) mutate(self); self.attributes[name] = value end
    function o:Show() mutate(self); self.shown = true end
    function o:Hide() mutate(self); self.shown = false end
    function o:CreateTexture() return object() end
    return o
end
CreateFrame = function(kind, name, parent, template)
    assert(not combat, "Frame created during combat")
    local frame = object()
    frame.name, frame.parent, frame.template = name, parent, template
    frames[#frames + 1] = frame
    return frame
end

assert(loadfile("Core/WorldMarker.lua"))()
local marker = RXPNavigator.WorldMarker
local getter = marker.GetShareableWaypointLink
local function upvalue(name, value)
    for i = 1, 30 do
        local found = debug.getupvalue(getter, i)
        if not found then break end
        if found == name then debug.setupvalue(getter, i, value); return end
    end
    error("Missing upvalue: " .. name)
end
local key = "1:0.10000:0.20000"
upvalue("owned", true)
upvalue("lastOwnedKey", key)
upvalue("activeTarget", {key = key})
assert(getter(marker) == link, "Owned target must be shareable")
currentPoint.position.x = 0.5
assert(getter(marker) == nil, "Never share a replaced user waypoint")
currentPoint.position.x = 0.1
upvalue("owned", false)
assert(getter(marker) == nil, "Unowned waypoint must not be shared")
upvalue("owned", true)
upvalue("activeTarget", {key = "different"})
assert(getter(marker) == nil, "Stale active target must not be shared")
upvalue("activeTarget", {key = key})
local getHyperlink = C_Map.GetUserWaypointHyperlink
C_Map.GetUserWaypointHyperlink = nil
assert(getter(marker) == nil, "Missing hyperlink API must be safe")
C_Map.GetUserWaypointHyperlink = getHyperlink

assert(loadfile("UI/GroupMarkers.lua"))()
local events = frames[#frames]
events.scripts.OnEvent()
local panel, share, buttons
buttons = {}
for _, frame in ipairs(frames) do
    if frame.name == "RXPNavigatorGroupMarkers" then panel = frame end
    if frame.template == "UIPanelButtonTemplate" then share = frame end
    if frame.template == "SecureActionButtonTemplate" then buttons[#buttons + 1] = frame end
end
assert(panel and panel.shown and #buttons == 8)
for i, button in ipairs(buttons) do
    assert(button.attributes.type1 == "worldmarker" and button.attributes.marker1 == i)
    assert(button.attributes.action1 == "set")
    assert(button.attributes.type2 == "worldmarker" and button.attributes.marker2 == i)
    assert(button.attributes.action2 == "clear")
end
assert(#messages == 0, "Loading and updating must never send chat")
share.scripts.OnClick()
assert(messages[1][1] == "RestedXP: " .. link and messages[1][2] == "PARTY")
share.scripts.OnClick()
assert(#messages == 1, "Rapid repeated click must be throttled")
now, raid = 14, true
share.scripts.OnClick()
assert(messages[2][2] == "RAID")
now, instance = 18, true
share.scripts.OnClick()
assert(messages[3][2] == "INSTANCE_CHAT")
now, currentPoint.position.x = 22, 0.5
share.scripts.OnClick()
assert(#messages == 3, "Click must reject a just-replaced waypoint")
currentPoint.position.x = 0.1
combat, grouped, instance, raid = true, false, false, false
events.scripts.OnEvent()
events.scripts.OnUpdate(nil, 1)
assert(panel.shown, "Protected visibility must be frozen during combat")
share.scripts.OnClick()
assert(#messages == 3, "A stale visible button must reject a departed group")
combat = false
events.scripts.OnEvent()
assert(not panel.shown, "Visibility must catch up after combat")
grouped, db.enabled = true, false
events.scripts.OnEvent()
assert(not panel.shown and getter(marker) == nil, "Disabled addon must not share")
db.enabled = true
events.scripts.OnEvent()
assert(panel.shown)
db.showWorldMarkerHeader = false
events.scripts.OnEvent()
assert(not panel.shown)
print("PASS: ownership, API fallback, secure attributes, chat routing, throttling and combat guards")
