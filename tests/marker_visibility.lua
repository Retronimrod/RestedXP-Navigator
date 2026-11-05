local now, clamped, valid, state = 0, false, true, 2
RXPNavigator = {API = {}}
GetTime = function() return now end
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
Enum = {NavigationState = {Invalid = 0, Occluded = 1, InRange = 2, Disabled = 3}}
C_Navigation = {
    HasValidScreenPosition = function() return valid end,
    WasClampedToScreen = function() return clamped end,
    GetTargetState = function() return state end,
}
assert(loadfile('Core/WorldMarkerVisual.lua'))()
local visual = RXPNavigator.WorldMarkerVisual
assert(not visual:IsWorldPointVisible())
now = 0.2; assert(visual:IsWorldPointVisible())
clamped = true; assert(not visual:IsWorldPointVisible(), 'A screen-edge point is never a world marker')
clamped = false; assert(not visual:IsWorldPointVisible(), 'Do not flash while transitioning back on-screen')
now = 0.4; assert(visual:IsWorldPointVisible())
valid = false; assert(not visual:IsWorldPointVisible())
valid = true; state = 0; assert(not visual:IsWorldPointVisible())
state = 3; assert(not visual:IsWorldPointVisible())
state = 2; assert(not visual:IsWorldPointVisible())
now = 0.6; assert(visual:IsWorldPointVisible())
C_Navigation.WasClampedToScreen = function() error('unreadable state') end
assert(not visual:IsWorldPointVisible())
C_Navigation = nil; assert(not visual:IsWorldPointVisible())
print('PASS: off-screen/invalid/disabled hiding, return-to-view settling and unreadable API fallback')
