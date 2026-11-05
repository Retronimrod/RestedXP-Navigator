-- Run from the repository root: lua tests/local_raid_symbols.lua
local db = {}
RXPNavigator = {API = {GetDB = function() return db end}}
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
assert(loadfile('Core/WorldMarker.lua'))()
assert(loadfile('Core/WorldMarkerVisual.lua'))()
local marker = RXPNavigator.WorldMarker
assert(marker:GetLocalRaidSymbolIndex(db) == nil)
db.worldMarkerUseRaidSymbols = true
for _, bad in ipairs({'invalid', 0, 9, math.huge, -math.huge}) do
    db.worldMarkerRaidSymbol = bad
    assert(marker:GetLocalRaidSymbolIndex(db) == 3)
end
db.worldMarkerRaidSymbol = 0/0
assert(marker:GetLocalRaidSymbolIndex(db) == 3)
local apply
for i = 1, 60 do
    local name, value = debug.getupvalue(RXPNavigator.WorldMarkerVisual.Refresh, i)
    if name == 'ApplyBlizzardStyle' then apply = value; break end
    if not name then break end
end
assert(apply, 'Style application must be testable')
local function texture()
    local t = {}
    function t:SetAtlas(atlas) self.atlas = atlas; self.texture = nil end
    function t:SetTexture(path) self.texture = path; self.atlas = nil end
    function t:SetTexCoord(...) self.coords = {...} end
    function t:SetSize(w,h) self.width, self.height = w,h end
    function t:GetSize() return self.width or 8, self.height or 72 end
    function t:SetVertexColor(...) self.color = {...} end
    function t:Show() self.shown = true end
    function t:Hide() self.shown = false end
    function t:ClearAllPoints() end
    function t:SetPoint() end
    function t:SetTextColor() end
    function t:SetAlpha() end
    return t
end
local f = {}
for _, part in ipairs({'icon','bg','highlight','stroke','stem','distance','groundRing'}) do f[part] = texture() end
db.worldMarkerCustomColors = true
for i = 1, 8 do
    db.worldMarkerRaidSymbol = i
    apply(f, 'Attack', true, false, true)
    assert(f.icon.texture == 'Interface\\TargetingFrame\\UI-RaidTargetingIcon_' .. i)
    assert(f.icon.width == 28 and f.icon.height == 28)
    assert(f.icon.color[1] == 1 and f.icon.color[2] == 1 and f.icon.color[3] == 1)
    assert(not f.bg.shown and not f.highlight.shown and not f.stroke.shown)
    assert(f.icon.shown and f.stem.shown and f.groundRing.shown)
end
db.worldMarkerUseRaidSymbols = false
apply(f, 'Assist', false, false, false)
assert(f.icon.atlas == 'Ping_Marker_Icon_Assist' and f.icon.texture == nil)
assert(f.bg.shown and f.highlight.shown and f.stroke.shown)
assert(not f.stem.shown and not f.groundRing.shown)
print('PASS: all eight local raid symbols, invalid settings, original colors and style restoration')
