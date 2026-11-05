-- Independent fake public API; no EasyFind code is loaded by these tests.
local db, now, element = {enabled = true}, 0, {zone = 1, x = 0.2, y = 0.3, text = "Talk to Boorand"}
local listeners, current, queued = {}, nil, nil
local navigations, clears, yields, loads = 0, 0, 0, 0
local accept = true
GetTime = function() return now end
InCombatLockdown = function() return false end
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
RXPNavigator = {API = {
    GetDB = function() return db end,
    GetCurrentNavigationElement = function() return element end,
    GetTargetMap = function(_, e) return e.zone, e.x, e.y end,
    GetTargetInstruction = function(_, e) return e.text end,
    GetNormalizedRXPData = function(_, e) return {tag = e.tag, instruction = e.text} end,
    Print = function() end,
}, WorldMarker = {SuspendForExternalNavigation = function() yields = yields + 1 end}}
assert(loadfile('Core/HearthActions.lua'))()
assert(loadfile('Core/EasyFindBridge.lua'))()
local b = RXPNavigator.EasyFindBridge
local function fire(event, dest) for _, fn in ipairs(listeners[event] or {}) do fn(dest) end end
local api = {VERSION = 1}
api.HasAction = function(_, action) return action ~= 'missing' end
api.On = function(_, event, fn)
    listeners[event] = listeners[event] or {}; table.insert(listeners[event], fn)
end
api.Off = function() end
api.CallAction = function(_, action, dest, opts)
    if action == 'destination' then return current end
    if action == 'canNavigate' then return accept end
    if action == 'navigate' then
        assert(b:SuppressNative() and yields > 0, 'Release our waypoint before external navigation')
        assert(opts.popout == true)
        navigations, queued = navigations + 1, dest
        return true
    end
    if action == 'clear' then
        clears = clears + 1; fire('routeCleared'); current = nil
    end
end
local function finish()
    current = queued
    fire('routeStarted', queued)
    queued = nil
    -- Matching completion is intentionally processed after the event callback.
    b:Tick()
end
b:Tick()
assert(b.state == 'disabled' and not b:SuppressNative())
b:SetEnabled(true)
assert(b.state == 'unavailable' and not b:SuppressNative())
EasyFind = {API = api}
b:Tick()
assert(b.state == 'planning' and navigations == 1)
for i = 1, 10 do b:Tick() end
assert(navigations == 1, 'Do not restart pending calculation every tick')
finish()
assert(b.state == 'active' and b:SuppressNative())
b:Tick(); assert(navigations == 1)
fire('arrived', current); b:Tick()
assert(b.state == 'arrived' and navigations == 1, 'Arrival must not advance the guide or restart route')
b:SetEnabled(false)
assert(clears == 1 and b.state == 'disabled' and not b:SuppressNative())
-- A late result while disabled must be settled, without touching native early.
b:SetEnabled(true)
b:SetEnabled(false)
assert(b.state == 'stopping' and b:SuppressNative())
finish()
assert(b.state == 'disabled' and not b:SuppressNative() and clears == 2)
-- Rapid guide changes: let the old result settle, then request latest goal.
b:SetEnabled(true)
element = {zone = 1, x = 0.8, y = 0.9, text = 'Next target'}
b:Tick()
local requests = navigations
assert(b.state == 'planning' and navigations == requests)
finish()
assert(b.state == 'planning' and queued.x == 0.8 and navigations == requests + 1)
finish(); assert(b.state == 'active')
-- A manual route wins; disabling never clears somebody else's destination.
current = {mapID = 1, x = 0.4, y = 0.5, name = 'Manual destination'}
fire('routeStarted', current)
local before = clears
b:Tick(); assert(b.state == 'paused' and b:SuppressNative())
b:SetEnabled(false)
assert(clears == before and current and b.state == 'manual')
b:SetEnabled(true); b:Resume(); assert(b.state == 'paused')
current = nil; fire('routeCleared'); b:Resume()
finish(); assert(b.state == 'active')
-- True hearthstone use/corpse navigation stays with the original navigator.
element = {zone = 1, x = 0.1, y = 0.1, tag = 'hs', text = 'Use your Hearthstone to Crossroads'}
b:Tick(); assert(b.state == 'idle' and not b:SuppressNative())
element = {zone = 1, x = 0.1, y = 0.1, corpseNav = true, text = 'Corpse'}
b:Tick(); assert(b.state == 'idle')
element = {zone = 1, x = 0.1, y = 0.1, tag = 'home', text = 'Set your Hearthstone to Crossroads'}
b:Tick(); finish(); assert(b.state == 'active')
-- Unsupported target is a bounded fallback, retried only by explicit resume.
accept = false
element = {zone = 2, x = 0.5, y = 0.5, text = 'Unsupported map'}
b:Tick(); assert(b.state == 'fallback' and not b:SuppressNative())
requests = navigations
b:Tick(); assert(navigations == requests)
accept = true; b:Resume(); assert(b.state == 'planning')
now = 61; b:Tick(); assert(b.state == 'timeout' and b:SuppressNative())
b:SetEnabled(false); finish()
assert(not b:SuppressNative() and b.state == 'disabled')
-- Manual clear during calculation requests pause; do not adopt late result.
b:SetEnabled(true)
fire('routeCleared')
finish()
assert(b.state == 'paused' and not b:SuppressNative() and current == nil)
b:SetEnabled(false)
-- Changing only task text at the same coordinate updates the destination.
b:SetEnabled(true); finish()
requests = navigations
element.text = 'New task at the same inn'
b:Tick()
assert(b.state == 'planning' and navigations == requests + 1)
finish(); b:SetEnabled(false)
print('PASS: EasyFind opt-in, missing dependency, async planning, arrival, late results, target changes, manual routes, fallback and timeout')
