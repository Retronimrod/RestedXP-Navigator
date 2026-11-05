local current, writes = nil, {}
RXPNavigator = {API = {GetDB = function() return {enabled = true} end}}
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
UiMapPoint = {CreateFromCoordinates = function(map, x, y, z) return {uiMapID = map, position = {x = x, y = y}, z = z} end}
C_Map = {
    GetUserWaypoint = function() return current end,
    SetUserWaypoint = function(point)
        writes[#writes + 1] = point
        -- Simulate a client that accepts the request but omits Z on readback.
        current = {uiMapID = point.uiMapID, position = point.position}
    end,
}
C_SuperTrack = {IsSuperTrackingAnything = function() return false end, SetSuperTrackedUserWaypoint = function() end}
assert(loadfile('Core/WorldMarker.lua'))()
local set
for i = 1, 60 do
    local name, value = debug.getupvalue(RXPNavigator.WorldMarker.RefreshNow, i)
    if name == 'SetDesiredTarget' then set = value; break end
    if not name then break end
end
assert(set)
local target = {key = '1:0.25000:0.75000', mapID = 1, x = 0.25, y = 0.75, z = 100}
assert(set(target) and #writes == 1 and writes[1].z == 100)
assert(set(target) and #writes == 1, 'Do not repeatedly reset an unchanged waypoint')
target.z = 110
assert(set(target) and #writes == 2 and writes[2].z == 110, 'Z-only changes must reach the client')
target.z = nil
assert(set(target) and #writes == 3 and writes[3].z == nil, 'Auto-height comparison must remove explicit Z')
current = {uiMapID = 1, position = {x = 0.5, y = 0.5}}
target.z = 90
assert(not set(target) and #writes == 3, 'Respect an externally replaced waypoint')
print('PASS: Z propagation, Z-only updates, missing-Z readback, auto-height reset and external waypoint ownership')
