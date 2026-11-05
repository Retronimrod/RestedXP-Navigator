local db = {enabled = true}
RXPNavigator = {API = {GetDB = function() return db end}, WorldMarker = {GetStatus = function() return {owned = true} end}}
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
local function region(alpha)
    return {alpha = alpha, GetAlpha = function(self) return self.alpha end,
        SetAlpha = function(self, value) self.alpha = value end}
end
SuperTrackedFrame = {Icon = region(0.7), IconBorder = region(0), DistanceText = region(1), Arrow = region(0.4),
    SetAlpha = function() error('Native parent alpha must remain untouched') end,
    SetTargetAlphaForState = function() error('Native state table must remain untouched') end}
assert(loadfile('Core/WorldMarkerVisual.lua'))()
local apply
for i = 1, 60 do
    local name, fn = debug.getupvalue(RXPNavigator.WorldMarkerVisual.Refresh, i)
    if name == 'ApplyNativeSuppression' then apply = fn; break end
    if not name then break end
end
assert(apply)
apply(); apply()
assert(SuperTrackedFrame.Icon.alpha == 0 and SuperTrackedFrame.DistanceText.alpha == 0)
db.worldMarkerHideBlizzard = false
apply()
assert(SuperTrackedFrame.Icon.alpha == 0.7 and SuperTrackedFrame.IconBorder.alpha == 0)
assert(SuperTrackedFrame.DistanceText.alpha == 1 and SuperTrackedFrame.Arrow.alpha == 0.4)
print('PASS: artwork-only suppression, native state/parent unchanged and original child alpha restored')
