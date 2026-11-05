-- Run from repository root: lua tests/ground_test.lua
local db = {enabled = true, showWorldMarkerNative = false, showWorldMarkerBeam = true}
local now, z, moving = 0, 100, false
local frames, applied = {}, {}
GetTime = function() return now end
InCombatLockdown = function() return false end
GetUnitSpeed = function() return moving and 1 or 0 end
UnitPosition = function() return 10, 20, z, 1 end
C_Map = {
    GetBestMapForUnit = function() return 1 end,
    GetPlayerMapPosition = function() return {x = 0.25, y = 0.75} end,
    CanSetUserWaypointOnMap = function() return true end,
    GetUserWaypoint = function() return applied end,
}
CreateFrame = function()
    local f = {RegisterEvent = function() end, scripts = {}}
    function f:SetScript(name, fn) self.scripts[name] = fn end
    frames[#frames + 1] = f
    return f
end
RXPNavigator = {API = {GetDB = function() return db end, Print = function() end}}
RXPNavigator.WorldMarker = {
    RefreshNow = function()
        local t = RXPNavigator.GroundTest:GetTarget()
        applied = t and {z = t.z} or {}
    end,
    GetStatus = function() return {owned = true} end,
}
assert(loadfile('Debug/GroundTest.lua'))()
local test = RXPNavigator.GroundTest
test:Command('here')
assert(test:GetTarget().z == 100 and applied.z == 100)
assert(db.showWorldMarkerNative and db.showWorldMarkerBeam == false and db.worldMarkerPrecision)
test:Command('z 10')
assert(test:GetTarget().z == 110)
test:Command('z -10')
assert(test:GetTarget().z == 90, 'Offsets must refer to sampled height, not accumulate')
test:Command('z 999')
assert(test:GetTarget().z == 90)
test:Command('auto')
assert(test:GetTarget().z == nil)
test:Command('z 0')
assert(test:GetTarget().z == 100)
test:Command('off')
assert(test:GetTarget() == nil and db.showWorldMarkerNative == false and db.showWorldMarkerBeam == true)
assert(db.worldMarkerPrecision == nil, 'Restore missing saved settings too')
moving = true
test:Command('here')
assert(not test:GetTarget())
moving, z = false, nil
test:Command('here')
assert(not test:GetTarget(), 'Unreadable player height must not create a guessed point')
z = 100
test:Command('here')
now = 181
frames[1].scripts.OnUpdate()
assert(not test:GetTarget() and db.showWorldMarkerNative == false)
test:Command('here')
frames[1].scripts.OnEvent(nil, 'PLAYER_LOGOUT')
assert(not test:GetTarget() and db.worldMarkerPrecision == nil)
print('PASS: ground-height sample, absolute offsets, no-height comparison, validation, timeout and settings restore')
