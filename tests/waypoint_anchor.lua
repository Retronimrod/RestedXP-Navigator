RXPNavigator = {API = {GetDB = function() return {} end}, WorldMarker = {GetStatus = function() return {owned = true} end}}
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
-- Emulate secure post-hooks without loading any third-party addon code.
hooksecurefunc = function(obj, method, hook)
    local original = obj[method]
    obj[method] = function(self, ...)
        original(self, ...)
        hook(self, ...)
    end
end
local function artwork(shown)
    return {visible = shown, IsShown = function(self) return self.visible end,
        Show = function(self) self.visible = true end,
        Hide = function(self) self.visible = false end,
        SetShown = function(self, value) self.visible = value end}
end
local icon, distance = artwork(true), artwork(false)
SuperTrackedFrame = {Icon = icon, DistanceText = distance,
    SetAlpha = function() error('Native parent alpha must not be changed') end,
    SetTargetAlphaForState = function() error('Native navigation table must not be changed') end,
    Hide = function() error('Native parent must keep running') end}
assert(loadfile('Core/WorldMarkerVisual.lua'))()
local visual, apply, restore = RXPNavigator.WorldMarkerVisual
local host = {}
assert(visual:GetWaypointAnchor(host) == icon)
for i = 1, 60 do
    local name, fn = debug.getupvalue(visual.Refresh, i)
    if name == 'ApplyNativeSuppression' then apply = fn end
    if not name then break end
end
assert(apply)
for i = 1, 60 do
    local name, fn = debug.getupvalue(apply, i)
    if name == 'RestoreNativeSuppression' then restore = fn end
    if not name then break end
end
assert(restore)
apply()
assert(not icon.visible and not distance.visible)
icon:Show(); assert(not icon.visible, 'Native Show must not bring back duplicate artwork')
distance:SetShown(true); assert(not distance.visible)
restore()
assert(icon.visible and distance.visible, 'Restore the visibility most recently requested by native UI')
apply(); distance:SetShown(false); restore(); assert(not distance.visible)
SuperTrackedFrame = nil
assert(visual:GetWaypointAnchor(host) == host)
assert(visual:GetWaypointAnchor(nil) == nil)
print('PASS: icon/fallback anchoring, hidden-art hooks, preserved native parent/state and visibility restoration')
