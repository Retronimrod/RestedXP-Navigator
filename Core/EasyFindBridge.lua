-- Independent adapter using the documented EasyFind actions/events only.
-- No EasyFind implementation, route database or artwork is bundled here.
local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end
local API = Navigator.API
local Bridge = {state = "disabled", suppress = false}
Navigator.EasyFindBridge = Bridge
local elapsed = 0
local function Now() return GetTime() end
local function Key(dest)
    if type(dest) ~= "table" then return nil end
    local map, x, y = tonumber(dest.mapID), tonumber(dest.x), tonumber(dest.y)
    if not map or not x or not y or map ~= map or x ~= x or y ~= y
        or map < 1 or map == math.huge or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return string.format("%d:%.4f:%.4f", map, x, y)
end
local function Same(a, b)
    return Key(a) and Key(a) == Key(b) and a.name == b.name
end
local function GoalKey(dest)
    local key = Key(dest)
    return key and (key .. ":" .. tostring(dest.name or ""))
end
function Bridge:IsEnabled()
    local db = API:GetDB()
    return db and db.enabled and db.useEasyFindGPS == true
end
function Bridge:SuppressNative() return self.suppress == true end
function Bridge:Call(action, ...)
    if not self.api then return nil end
    local ok, result = pcall(self.api.CallAction, "gps", action, ...)
    if ok then return result end
end
function Bridge:Desired()
    if Navigator.GroundTest and Navigator.GroundTest:GetTarget() then return nil end
    local element = API:GetCurrentNavigationElement()
    if not element or element.corpseNav then return nil end
    local model = API.GetNormalizedRXPData and API:GetNormalizedRXPData(element)
    if Navigator.HearthActions and Navigator.HearthActions:Classify(element, model) == "use" then return nil end
    local map, x, y = API:GetTargetMap(element)
    local instruction = API:GetTargetInstruction(element) or "RestedXP"
    -- Own strings and goal coordinates only; no guide content is redistributed.
    instruction = tostring(instruction):gsub("|T.-|t", ""):gsub("|A.-|a", "")
        :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local dest = {mapID = tonumber(map), x = tonumber(x), y = tonumber(y),
        name = "RestedXP: " .. instruction, step = instruction}
    if Key(dest) then return dest end
end
function Bridge:Connect()
    local api = EasyFind and EasyFind.API
    if not (api and api.VERSION == 1 and type(api.CallAction) == "function"
        and type(api.HasAction) == "function" and type(api.On) == "function"
        and type(api.Off) == "function") then return false end
    if not api.HasAction("gps", "navigate") then
        if InCombatLockdown and InCombatLockdown() then return false end
        -- CallAction is documented to load an installed extension on demand.
        pcall(api.CallAction, "gps", "destination")
    end
    for _, action in ipairs({"navigate", "clear", "destination", "canNavigate"}) do
        if not api.HasAction("gps", action) then return false end
    end
    if self.api ~= api then
        if self.api and self.listeners then
            for event, fn in pairs(self.listeners) do pcall(self.api.Off, "gps", event, fn) end
        end
        self.api = api
        self.listeners = {
            routeStarted = function(dest)
                -- EasyFind fires before it finishes installing the first
                -- waypoint. Process on the next tick, never clear in callback.
                if self.pending and Same(dest, self.pending.dest) then
                    self.completed = dest
                elseif self:IsEnabled() or self.pending or self.owned then
                    self.pending, self.completed, self.owned = nil, nil, nil
                    self.paused, self.suppress, self.state = true, true, "paused"
                end
            end,
            arrived = function(dest)
                if self.owned and Same(dest, self.owned) then self.arrivedKey = GoalKey(dest) end
                -- Never complete or advance a RestedXP step here.
            end,
            routeCleared = function()
                if self.clearing then return end
                if self.pending then self.paused = true end
                if self.owned then
                    self.owned = nil
                    self.paused, self.state = true, "paused"
                end
            end,
        }
        for event, fn in pairs(self.listeners) do api.On("gps", event, fn) end
    end
    return true
end
function Bridge:YieldNative()
    self.suppress = true
    if Navigator.WorldMarker and Navigator.WorldMarker.SuspendForExternalNavigation then
        Navigator.WorldMarker:SuspendForExternalNavigation()
    end
    if Navigator.WorldMarkerVisual and Navigator.WorldMarkerVisual.ReleaseForExternalNavigation then
        Navigator.WorldMarkerVisual:ReleaseForExternalNavigation()
    end
end
function Bridge:ClearOwned()
    local dest = self:Call("destination")
    if self.owned and Same(dest, self.owned) then
        self.clearing = true
        self:Call("clear")
        self.clearing = false
    end
    self.owned, self.arrivedKey = nil, nil
end
function Bridge:Tick()
    local enabled = self:IsEnabled()
    if not enabled and not self.pending and not self.owned and not self.paused then
        self.suppress, self.state = false, "disabled"; return
    end
    if not self:Connect() then
        self.suppress = false
        self.state = enabled and "unavailable" or "disabled"
        return
    end
    local desired = enabled and self:Desired() or nil
    local current = self:Call("destination")
    if self.completed and self.pending then
        local pending = self.pending
        self.completed, self.pending = nil, nil
        if Same(current, pending.dest) then
            self.owned = pending.dest
            if not enabled or not desired or GoalKey(desired) ~= pending.key or self.paused then self:ClearOwned() end
        else
            self.owned, self.paused = nil, current ~= nil
        end
        current = self:Call("destination")
    end
    if self.pending then
        self.suppress = true
        self.state = not enabled and "stopping" or (Now() - self.pending.time > 60 and "timeout" or "planning")
        -- No documented cancellation API. Keep native writers paused until
        -- the result settles, including when disabled mid-calculation.
        return
    end
    if self.owned and not Same(current, self.owned) then
        self.owned, self.paused = nil, true
    end
    if not enabled then
        self:ClearOwned()
        current = self:Call("destination")
        self.suppress = current ~= nil
        self.state = current and "manual" or "disabled"
        if not current then self.paused = nil end
        return
    end
    if self.paused then
        self.suppress = current ~= nil
        self.state = "paused"
        return
    end
    if current and not self.owned then
        self.paused, self.suppress, self.state = true, true, "paused"; return
    end
    if not desired then
        self:ClearOwned()
        self.suppress, self.state = false, "idle"; return
    end
    local key = GoalKey(desired)
    if self.owned and GoalKey(self.owned) == key then
        self.suppress = true
        self.state = self.arrivedKey == key and "arrived" or "active"; return
    end
    if self.failedKey == key then self.suppress, self.state = false, "fallback"; return end
    if self:Call("canNavigate", desired) ~= true then
        self:ClearOwned()
        self.failedKey, self.suppress, self.state = key, false, "fallback"; return
    end
    self:ClearOwned()
    self:YieldNative()
    self.pending = {dest = desired, key = key, time = Now()}
    self.state = "planning"
    -- popout is documented. Do not rely on the internal quiet option or
    -- change EasyFind settings to hide its map/arrow/beam.
    if self:Call("navigate", desired, {popout = true}) ~= true then
        self.pending, self.completed = nil, nil
        self.failedKey, self.suppress, self.state = key, false, "fallback"
    end
end
function Bridge:SetEnabled(value)
    local db = API:GetDB()
    if db then db.useEasyFindGPS = value == true end
    if value then self.failedKey = nil end
    self:Tick()
    if API.RefreshAll then API:RefreshAll() end
end
function Bridge:Resume()
    if self:Call("destination") and not self.owned then
        API:Print("EasyFind: Manuelle Route zuerst in EasyFind beenden."); return
    end
    self.paused, self.failedKey = nil, nil
    self:Tick()
end
function Bridge:PrintStatus()
    local texts = {
        disabled = "aus", unavailable = "EasyFind GPS fehlt oder API nicht kompatibel; direkte Navigation aktiv",
        idle = "bereit; kein geeignetes Ziel", planning = "Route wird berechnet",
        active = "EasyFind führt zum RestedXP-Ziel", arrived = "Ziel erreicht; warte auf RestedXP-Fortschritt",
        fallback = "Ziel nicht angenommen; direkte Navigation aktiv",
        paused = "pausiert; manuelle EasyFind-Navigation hat Vorrang. Fortsetzen: /rxpnav easyfind resume",
        stopping = "ausgeschaltet; laufende Berechnung wird noch abgewickelt",
        timeout = "Berechnung dauert über 60 Sekunden; warte auf Ergebnis, da keine öffentliche Abbruchfunktion existiert",
        manual = "aus; bestehende manuelle EasyFind-Route bleibt geschützt",
        error = "Adapterfehler; Details mit /rxpnav bugreport prüfen",
    }
    API:Print("EasyFind GPS: " .. (texts[self.state] or self.state))
end
local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("ADDON_LOADED")
driver:SetScript("OnEvent", function() elapsed = 0.5 end)
driver:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.5 then return end
    elapsed = 0
    local ok = pcall(Bridge.Tick, Bridge)
    if not ok then Bridge.state = "error"; Bridge.suppress = Bridge.pending ~= nil or Bridge.owned ~= nil end
end)
