local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.Debug = Navigator.Debug or {}
Navigator.Inspector = Navigator.Inspector or {}

-- Inspector state lives outside Core so diagnostics do not consume Core's
-- top-level local-variable budget.
Navigator.Debug.captureActive = Navigator.Debug.captureActive or false
Navigator.Debug.logLines = Navigator.Debug.logLines or {}
Navigator.Debug.logLabel = Navigator.Debug.logLabel or ""
Navigator.Debug.exportFrame = Navigator.Debug.exportFrame or nil

function Navigator.Debug:BeginCapture(label)
    self.logLines = {}
    self.logLabel = tostring(label or "RestedXP Navigator Inspector")
    self.captureActive = true
end

function Navigator.Debug:EndCapture()
    self.captureActive = false
end

function Navigator.Debug:CaptureLine(msg)
    if not self.captureActive then return end
    self.logLines[#self.logLines + 1] = tostring(msg)
end

function Navigator.Debug:GetExportText()
    local header = "RestedXP-Navigator Inspector Export"
    if self.logLabel ~= "" then header = header .. " - " .. self.logLabel end
    return header .. "\n" .. string.rep("=", 72) .. "\n" .. table.concat(self.logLines, "\n")
end

function Navigator.Debug:ShowExport()
    if #self.logLines == 0 then
        API:Print("Keine Inspector-Ausgabe vorhanden. Zuerst /rxpnav inspectsteps oder /rxpnav inspectstep N ausführen.")
        return
    end
    if not self.exportFrame then
        local f = CreateFrame("Frame", "RXPNavigatorInspectorExportFrame", UIParent, "BackdropTemplate")
        f:SetSize(760, 520)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetClampedToScreen(true)
        if f.SetBackdrop then
            f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=11,right=12,top=12,bottom=11}})
        end
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -18)
        title:SetText("RestedXP-Navigator Inspector Export")
        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 24, -45)
        hint:SetText("Text ist markiert – Strg+C kopiert ihn in die Zwischenablage.")
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 24, -68)
        scroll:SetPoint("BOTTOMRIGHT", -42, 52)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(680)
        edit:SetMaxLetters(200000)
        if edit.SetTextInsets then edit:SetTextInsets(6,6,6,6) end
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        edit:SetScript("OnTextChanged", function(self)
            local h = 400
            if self.GetStringHeight then
                local ok, value = pcall(self.GetStringHeight, self)
                if ok and type(value) == "number" then h = math.max(400, value + 30) end
            else
                local txt = self:GetText() or ""
                local lines = 1
                for _ in string.gmatch(txt, "\n") do lines = lines + 1 end
                h = math.max(400, lines * 15 + 30)
            end
            self:SetHeight(h)
        end)
        scroll:SetScrollChild(edit)
        f.edit = edit
        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetSize(120, 24)
        close:SetPoint("BOTTOMRIGHT", -24, 20)
        close:SetText(CLOSE or "Close")
        close:SetScript("OnClick", function() f:Hide() end)
        self.exportFrame = f
    end
    self.exportFrame.edit:SetText(self:GetExportText())
    self.exportFrame:Show()
    self.exportFrame.edit:SetFocus()
    self.exportFrame.edit:HighlightText()
end


function Navigator.Inspector.ISafeValue(v)
    local tv = type(v)
    if tv == "nil" then return "nil" end
    if tv == "string" then
        local s = v:gsub("\n", " "):gsub("\r", " ")
        if #s > 90 then s = s:sub(1, 87) .. "..." end
        return s
    end
    if tv == "number" or tv == "boolean" then
        local ok, s = pcall(tostring, v)
        return ok and s or ("<" .. tv .. ">")
    end
    if tv == "table" then return "<table>" end
    return "<" .. tv .. ">"
end

function Navigator.Inspector.IRaw(t, k)
    if type(t) ~= "table" then return nil end
    local ok, v = pcall(rawget, t, k)
    if ok then return v end
    return nil
end

function Navigator.Inspector.ISafeNext(t, k)
    if type(t) ~= "table" then return nil end
    local ok, nk, nv = pcall(next, t, k)
    if ok then return nk, nv end
    return nil
end

function Navigator.Inspector.IKeyName(k)
    local tk = type(k)
    if tk == "string" then return k end
    if tk == "number" then return "[" .. tostring(k) .. "]" end
    return "<" .. tk .. "-key>"
end

function Navigator.Inspector.GetAceRXPAddon()
    if not LibStub then return nil end
    local okAce, ace = pcall(LibStub, "AceAddon-3.0", true)
    if not okAce or not ace or type(ace.GetAddon) ~= "function" then return nil end
    local ok, addon = pcall(ace.GetAddon, ace, "RXPGuides", true)
    if ok and type(addon) == "table" then return addon end
    return nil
end

function Navigator.Inspector.ILooksStepLike(t)
    if type(t) ~= "table" then return false end
    if type(Navigator.Inspector.IRaw(t, "elements")) == "table" then return true end
    if Navigator.Inspector.IRaw(t, "step") ~= nil or Navigator.Inspector.IRaw(t, "stepNum") ~= nil or Navigator.Inspector.IRaw(t, "stepNumber") ~= nil then return true end
    if Navigator.Inspector.IRaw(t, "active") ~= nil and (Navigator.Inspector.IRaw(t, "text") ~= nil or Navigator.Inspector.IRaw(t, "label") ~= nil or Navigator.Inspector.IRaw(t, "title") ~= nil) then return true end
    return false
end

function Navigator.Inspector.ILooksStepsContainer(t)
    if type(t) ~= "table" then return false end
    if type(Navigator.Inspector.IRaw(t, "steps")) == "table" then return true end
    local count, stepish = 0, 0
    local k = nil
    while count < 10 do
        local nk, v = Navigator.Inspector.ISafeNext(t, k)
        if nk == nil then break end
        k = nk
        if type(nk) == "number" and type(v) == "table" then
            count = count + 1
            if Navigator.Inspector.ILooksStepLike(v) then stepish = stepish + 1 end
        end
    end
    return count >= 2 and stepish >= 2
end

function Navigator.Inspector.IFirstText(t)
    if type(t) ~= "table" then return "" end
    for _, key in ipairs({"text","label","title","name","instruction"}) do
        local v = Navigator.Inspector.IRaw(t, key)
        if type(v) == "string" and v ~= "" then return Navigator.Inspector.ISafeValue(v) end
    end
    local elements = Navigator.Inspector.IRaw(t, "elements")
    if type(elements) == "table" then
        local k = nil
        local n = 0
        while n < 12 do
            local nk, e = Navigator.Inspector.ISafeNext(elements, k)
            if nk == nil then break end
            k = nk; n = n + 1
            if type(e) == "table" then
                for _, key in ipairs({"text","label","title","name","instruction"}) do
                    local v = Navigator.Inspector.IRaw(e, key)
                    if type(v) == "string" and v ~= "" then return Navigator.Inspector.ISafeValue(v) end
                end
            end
        end
    end
    return ""
end

function Navigator.Inspector.ICoordSummary(t)
    if type(t) ~= "table" then return "" end
    local vals = {}
    for _, key in ipairs({"map","mapID","zone","x","y","zx","zy","wx","wy","arrow","textOnly","active","completed","skip"}) do
        local v = Navigator.Inspector.IRaw(t, key)
        if v ~= nil then vals[#vals+1] = key .. "=" .. Navigator.Inspector.ISafeValue(v) end
    end
    return table.concat(vals, " ")
end

function Navigator.Inspector.IDescribeStepsContainer(t, path)
    local steps = Navigator.Inspector.IRaw(t, "steps")
    if type(steps) ~= "table" then steps = t end
    API:Print("Step-Quelle: " .. path)
    local k = nil
    local shown = 0
    while shown < 8 do
        local nk, step = Navigator.Inspector.ISafeNext(steps, k)
        if nk == nil then break end
        k = nk
        if type(nk) == "number" and type(step) == "table" then
            shown = shown + 1
            local num = Navigator.Inspector.IRaw(step,"step") or Navigator.Inspector.IRaw(step,"stepNum") or Navigator.Inspector.IRaw(step,"stepNumber") or Navigator.Inspector.IRaw(step,"number") or nk
            local txt = Navigator.Inspector.IFirstText(step)
            API:Print("  Step " .. Navigator.Inspector.ISafeValue(num) .. " | " .. Navigator.Inspector.ICoordSummary(step) .. (txt ~= "" and (" | " .. txt) or ""))
            local elements = Navigator.Inspector.IRaw(step, "elements")
            if type(elements) == "table" then
                local ek = nil
                local ec = 0
                while ec < 4 do
                    local enk, e = Navigator.Inspector.ISafeNext(elements, ek)
                    if enk == nil then break end
                    ek = enk
                    if type(e) == "table" then
                        local cs = Navigator.Inspector.ICoordSummary(e)
                        local et = Navigator.Inspector.IFirstText(e)
                        if cs ~= "" or et ~= "" then
                            ec = ec + 1
                            API:Print("    E" .. Navigator.Inspector.IKeyName(enk) .. " " .. cs .. (et ~= "" and (" | " .. et) or ""))
                        end
                    end
                end
            end
        end
    end
    if shown == 0 then API:Print("  (keine numerischen Step-Einträge gefunden)") end
end

function Navigator.Inspector.IScanRoot(root, rootName, maxDepth, maxNodes, out)
    if type(root) ~= "table" then return 0 end
    local seen = {}
    local nodes = 0
    local function walk(t, path, depth)
        if type(t) ~= "table" or seen[t] or depth > maxDepth or nodes >= maxNodes then return end
        seen[t] = true
        nodes = nodes + 1
        if Navigator.Inspector.ILooksStepsContainer(t) then
            out[#out+1] = {path=path, value=t}
            if #out >= 12 then return end
        end
        local k = nil
        local entries = 0
        while entries < 80 and nodes < maxNodes and #out < 12 do
            local nk, v = Navigator.Inspector.ISafeNext(t, k)
            if nk == nil then break end
            k = nk; entries = entries + 1
            if type(v) == "table" then
                local key = Navigator.Inspector.IKeyName(nk)
                -- Avoid huge UI/back-reference branches; we care about data containers.
                local low = type(nk) == "string" and nk:lower() or ""
                if low ~= "parent" and low ~= "owner" and low ~= "frame" and low ~= "frames" and low ~= "children" then
                    walk(v, path .. "." .. key, depth + 1)
                end
            end
        end
    end
    walk(root, rootName, 0)
    return nodes
end

function Navigator.Inspector.IListRXPGlobals()
    local names = {}
    local k = nil
    local guard = 0
    while guard < 20000 do
        local nk, v = Navigator.Inspector.ISafeNext(_G, k)
        if nk == nil then break end
        k = nk; guard = guard + 1
        if type(nk) == "string" then
            local low = nk:lower()
            if low:find("rxp", 1, true) or low:find("rested", 1, true) then
                names[#names+1] = {name=nk, value=v}
            end
        end
    end
    table.sort(names, function(a,b) return a.name < b.name end)
    API:Print("RXP/Rested globals: " .. tostring(#names))
    for i=1, math.min(#names, 35) do
        API:Print("  _G." .. names[i].name .. " = " .. Navigator.Inspector.ISafeValue(names[i].value))
    end
    return names
end

function Navigator.Inspector.ISafeInspectFrames()
    local found = 0
    if type(EnumerateFrames) ~= "function" then return end
    local f = EnumerateFrames()
    local guard = 0
    while f and guard < 3000 and found < 30 do
        guard = guard + 1
        local name
        if type(f.GetName) == "function" then
            local ok, n = pcall(f.GetName, f)
            if ok then name = n end
        end
        if type(name) == "string" and (name:find("RXP") or name:find("Rested")) then
            local shown = false
            if type(f.IsShown) == "function" then local ok,v=pcall(f.IsShown,f); if ok then shown=v end end
            local txt = ""
            if type(f.GetText) == "function" then local ok,v=pcall(f.GetText,f); if ok and type(v)=="string" then txt=Navigator.Inspector.ISafeValue(v) end end
            API:Print("Frame " .. name .. " shown=" .. tostring(shown) .. (txt ~= "" and (" text=" .. txt) or ""))
            found = found + 1
        end
        f = EnumerateFrames(f)
    end
    API:Print("Benannte RXP-Frames: " .. tostring(found))
end

function Navigator.Inspector.IDescribeRelevantRootKeys(root, rootName)
    if type(root) ~= "table" then return end
    local hits = {}
    local k = nil
    local guard = 0
    while guard < 1000 do
        local nk, v = Navigator.Inspector.ISafeNext(root, k)
        if nk == nil then break end
        k = nk; guard = guard + 1
        if type(nk) == "string" then
            local low = nk:lower()
            if low:find("guide",1,true) or low:find("step",1,true) or low:find("quest",1,true) or
               low:find("route",1,true) or low:find("track",1,true) or low:find("active",1,true) or
               low:find("current",1,true) or low:find("data",1,true) or low:find("list",1,true) then
                hits[#hits+1] = nk .. "=" .. Navigator.Inspector.ISafeValue(v)
            end
        end
    end
    if #hits > 0 then
        API:Print("Relevante Keys in " .. rootName .. ":")
        table.sort(hits)
        for i=1, math.min(#hits, 40) do API:Print("  " .. hits[i]) end
    end
end

function Navigator.Inspector.SafeInspectSteps()
    API:BeginInspectorCapture("inspectsteps")
    API:Print("=== RestedXP SAFE Step Inspector ===")
    local roots = {}
    local api = rawget(_G, "RXPGuides")
    if type(api) == "table" then roots[#roots+1] = {name="_G.RXPGuides", value=api, priority=true} end
    local ace = Navigator.Inspector.GetAceRXPAddon()
    if type(ace) == "table" and ace ~= api then roots[#roots+1] = {name="AceAddon:RXPGuides", value=ace, priority=true} end

    -- Forever exposes several RXP data roots globally. Prioritize these before
    -- the broad global scan because they are far more likely to back the live guide list.
    local priorityNames = {"RXPData", "RXPTrackingData", "RXPCData", "RXPClassicIcon"}
    for _, n in ipairs(priorityNames) do
        local v = rawget(_G, n)
        if type(v) == "table" and v ~= api and v ~= ace then
            roots[#roots+1] = {name="_G."..n, value=v, priority=true}
        end
    end

    local globals = Navigator.Inspector.IListRXPGlobals()
    for _, g in ipairs(globals) do
        if type(g.value) == "table" and g.value ~= api and g.value ~= ace then
            local exists = false
            for _, r in ipairs(roots) do if r.value == g.value then exists = true break end end
            if not exists then roots[#roots+1] = {name="_G."..g.name, value=g.value} end
            if #roots >= 20 then break end
        end
    end

    for _, r in ipairs(roots) do
        if r.priority then Navigator.Inspector.IDescribeRelevantRootKeys(r.value, r.name) end
    end

    local candidates = {}
    local totalNodes = 0
    for _, r in ipairs(roots) do
        local localOut = {}
        local maxDepth = r.priority and 7 or 5
        local maxNodes = r.priority and 1800 or 600
        local nodes = Navigator.Inspector.IScanRoot(r.value, r.name, maxDepth, maxNodes, localOut)
        totalNodes = totalNodes + nodes
        for _, c in ipairs(localOut) do
            local duplicate = false
            for _, existing in ipairs(candidates) do if existing.value == c.value then duplicate = true break end end
            if not duplicate then candidates[#candidates+1] = c end
            if #candidates >= 12 then break end
        end
        if #candidates >= 12 then break end
    end

    API:Print("Safe scan: " .. tostring(totalNodes) .. " Tabellen geprüft, " .. tostring(#candidates) .. " Step-Quellen gefunden")
    for i=1, math.min(#candidates, 5) do Navigator.Inspector.IDescribeStepsContainer(candidates[i].value, candidates[i].path) end
    if #candidates == 0 then
        API:Print("Keine Step-Tabelle gefunden. Prüfe sichtbare RestedXP-Frames...")
        Navigator.Inspector.ISafeInspectFrames()
    end
    API:Print("Tipp: /rxpnav inspectcopy öffnet die komplette Ausgabe zum Kopieren.")
    API:EndInspectorCapture()
end

function Navigator.Inspector.SafeInspectStep(wanted)
    wanted = tostring(wanted or "")
    if wanted == "" then API:Print("Usage: /rxpnav inspectstep 92") return end
    API:BeginInspectorCapture("inspectstep " .. wanted)
    local roots = {}
    local api = rawget(_G,"RXPGuides"); if type(api)=="table" then roots[#roots+1]={name="_G.RXPGuides",value=api} end
    local ace = Navigator.Inspector.GetAceRXPAddon(); if type(ace)=="table" and ace~=api then roots[#roots+1]={name="AceAddon:RXPGuides",value=ace} end
    local globals = Navigator.Inspector.IListRXPGlobals()
    for _,g in ipairs(globals) do if type(g.value)=="table" and #roots<15 then roots[#roots+1]={name="_G."..g.name,value=g.value} end end
    local candidates={}
    for _,r in ipairs(roots) do Navigator.Inspector.IScanRoot(r.value,r.name,5,700,candidates); if #candidates>=12 then break end end
    for _,c in ipairs(candidates) do
        local steps=Navigator.Inspector.IRaw(c.value,"steps"); if type(steps)~="table" then steps=c.value end
        local k=nil
        while true do
            local nk,step=Navigator.Inspector.ISafeNext(steps,k); if nk==nil then break end; k=nk
            if type(step)=="table" then
                local num=Navigator.Inspector.IRaw(step,"step") or Navigator.Inspector.IRaw(step,"stepNum") or Navigator.Inspector.IRaw(step,"stepNumber") or Navigator.Inspector.IRaw(step,"number") or nk
                if tostring(num)==wanted or tostring(nk)==wanted then
                    API:Print("=== Step "..wanted.." @ "..c.path.." ===")
                    Navigator.Inspector.IDescribeStepsContainer({[tonumber(nk) or 1]=step}, c.path..".single")
                    API:Print("Tipp: /rxpnav inspectcopy öffnet die komplette Ausgabe zum Kopieren.")
                    API:EndInspectorCapture()
                    return
                end
            end
        end
    end
    API:Print("Step "..wanted.." wurde im Safe Scan nicht gefunden.")
    API:Print("Tipp: /rxpnav inspectcopy öffnet die komplette Ausgabe zum Kopieren.")
    API:EndInspectorCapture()
end

function Navigator.Inspector.SafeInspectSave()
    local lines = Navigator.Debug and Navigator.Debug.logLines or {}
    if #lines == 0 then
        API:Print("Keine Inspector-Ausgabe vorhanden. Zuerst /rxpnav inspectsteps oder /rxpnav inspectstep N ausführen.")
        return
    end
    RXPNavigatorDebugDB = RXPNavigatorDebugDB or {}
    RXPNavigatorDebugDB.latest = {
        timestamp = (time and time() or 0),
        label = Navigator.Debug and Navigator.Debug.logLabel or "",
        lines = lines,
        text = API:GetInspectorExportText(),
    }
    API:Print("Inspector-Ausgabe in RXPNavigatorDebugDB.latest gespeichert. Nach /reload oder Logout steht sie in der SavedVariables-Datei.")
end

function Navigator.Inspector.SafeInspectCopy()
    API:ShowInspectorExport()
end



-- ---------------------------------------------------------------------------
-- Targeted active-guide inspector
-- Uses RXPCData.currentGuideGroup/currentGuideName/currentStep and the
-- RXPGuides GetGuideTable/GetGuideProgress APIs instead of broad table scans.
-- ---------------------------------------------------------------------------
function Navigator.Inspector.ICallRawFunction(t, key, ...)
    if type(t) ~= "table" then return false, nil end
    local fn = Navigator.Inspector.IRaw(t, key)
    if type(fn) ~= "function" then return false, nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return false, a end
    return true, a, b, c, d
end

function Navigator.Inspector.IFindNavigableElement(step)
    if type(step) ~= "table" then return nil end
    local elements = Navigator.Inspector.IRaw(step, "elements")
    if type(elements) ~= "table" then return nil end
    local fallback
    local k
    local guard = 0
    while guard < 80 do
        local nk, e = Navigator.Inspector.ISafeNext(elements, k)
        if nk == nil then break end
        k = nk; guard = guard + 1
        if type(e) == "table" then
            local zone = Navigator.Inspector.IRaw(e,"zone") or Navigator.Inspector.IRaw(e,"mapID") or Navigator.Inspector.IRaw(e,"map")
            local x = Navigator.Inspector.IRaw(e,"x") or Navigator.Inspector.IRaw(e,"zx")
            local y = Navigator.Inspector.IRaw(e,"y") or Navigator.Inspector.IRaw(e,"zy")
            local wx, wy = Navigator.Inspector.IRaw(e,"wx"), Navigator.Inspector.IRaw(e,"wy")
            local hasCoords = (zone ~= nil and x ~= nil and y ~= nil) or (wx ~= nil and wy ~= nil)
            if hasCoords then
                if Navigator.Inspector.IRaw(e,"arrow") == true and Navigator.Inspector.IRaw(e,"lowPrio") ~= true then return e, nk end
                if not fallback then fallback = {e=e, k=nk} end
            end
        end
    end
    return fallback and fallback.e, fallback and fallback.k
end

function Navigator.Inspector.TargetedGuideInspect()
    API:BeginInspectorCapture("guideinspect")
    API:Print("=== RestedXP Targeted Guide Inspector ===")

    local addon = Navigator.Inspector.GetAceRXPAddon()
    local rxpc = rawget(_G, "RXPCData")
    API:Print("AceAddon RXPGuides: " .. (type(addon)=="table" and "found" or "missing"))
    API:Print("RXPCData: " .. (type(rxpc)=="table" and "found" or "missing"))
    if type(addon) ~= "table" or type(rxpc) ~= "table" then
        API:Print("Aktiver Guide kann ohne AceAddon/RXPCData nicht gezielt aufgelöst werden.")
        API:EndInspectorCapture(); return
    end

    local group = Navigator.Inspector.IRaw(rxpc,"currentGuideGroup")
    local name = Navigator.Inspector.IRaw(rxpc,"currentGuideName")
    local savedStep = Navigator.Inspector.IRaw(rxpc,"currentStep")
    local savedStepId = Navigator.Inspector.IRaw(rxpc,"currentStepId")
    API:Print("RXPCData.currentGuideGroup = " .. Navigator.Inspector.ISafeValue(group))
    API:Print("RXPCData.currentGuideName = " .. Navigator.Inspector.ISafeValue(name))
    API:Print("RXPCData.currentStep = " .. Navigator.Inspector.ISafeValue(savedStep))
    API:Print("RXPCData.currentStepId = " .. Navigator.Inspector.ISafeValue(savedStepId))

    local guide = Navigator.Inspector.IRaw(addon,"currentGuide")
    local source = "addon.currentGuide"
    if type(guide) ~= "table" and group ~= nil and name ~= nil then
        local ok, g = Navigator.Inspector.ICallRawFunction(addon,"GetGuideTable",group,name)
        if ok and type(g)=="table" then guide=g; source="GetGuideTable(group,name)" end
    end
    API:Print("Guide source = " .. source .. " | " .. (type(guide)=="table" and "found" or "nil"))
    if type(guide) ~= "table" then
        API:Print("Guide konnte nicht aufgelöst werden. /rxpnav inspectcopy zum Kopieren.")
        API:EndInspectorCapture(); return
    end

    API:Print("Guide.group="..Navigator.Inspector.ISafeValue(Navigator.Inspector.IRaw(guide,"group")).." name="..Navigator.Inspector.ISafeValue(Navigator.Inspector.IRaw(guide,"name")).." key="..Navigator.Inspector.ISafeValue(Navigator.Inspector.IRaw(guide,"key")))
    local stepIndex = tonumber(savedStep)
    local okProg, progStep, progId = Navigator.Inspector.ICallRawFunction(addon,"GetGuideProgress",guide)
    if okProg and tonumber(progStep) then stepIndex = tonumber(progStep) end
    API:Print("GetGuideProgress step="..Navigator.Inspector.ISafeValue(progStep).." stepId="..Navigator.Inspector.ISafeValue(progId).." | resolved="..Navigator.Inspector.ISafeValue(stepIndex))

    local steps = Navigator.Inspector.IRaw(guide,"steps")
    if type(steps) ~= "table" then
        API:Print("guide.steps = nil")
        API:EndInspectorCapture(); return
    end
    API:Print("guide.steps = <table>")

    local start = math.max(1, (stepIndex or 1) - 1)
    local finish = (stepIndex or 1) + 8
    for i=start,finish do
        local step = Navigator.Inspector.IRaw(steps,i)
        if type(step)=="table" then
            local active = Navigator.Inspector.IRaw(step,"active")
            local stepId = Navigator.Inspector.IRaw(step,"stepId") or Navigator.Inspector.IRaw(step,"id")
            local txt = Navigator.Inspector.IFirstText(step)
            API:Print(string.format("Step[%d]%s active=%s stepId=%s | %s", i, i==(stepIndex or -1) and " CURRENT" or "", Navigator.Inspector.ISafeValue(active), Navigator.Inspector.ISafeValue(stepId), txt))
            local e, ek = Navigator.Inspector.IFindNavigableElement(step)
            if e then
                API:Print("  NAV E"..Navigator.Inspector.IKeyName(ek).." "..Navigator.Inspector.ICoordSummary(e)..(Navigator.Inspector.IFirstText(e)~="" and (" | "..Navigator.Inspector.IFirstText(e)) or ""))
            else
                API:Print("  NAV (keins)")
            end
        else
            API:Print("Step["..i.."] = nil")
        end
    end
    API:Print("Tipp: /rxpnav inspectcopy öffnet diese Ausgabe zum Kopieren.")
    API:EndInspectorCapture()
end


function Navigator.Inspector.FutureGuideDebug()
    API:BeginInspectorCapture("futureguide")
    API:Print("=== RestedXP Future Goals ===")
    local guide, stepIndex = API:ResolveActiveGuideAndStep()
    API:Print("Active guide: " .. (type(guide)=="table" and "found" or "nil") .. " | currentStep=" .. tostring(stepIndex))
    local db = API:GetDB()
    API:Print("Configured Future Goals: +" .. tostring(db and db.futureGoals or 0))
    local current = API:GetCurrentNavigationElement()
    local futures = API:GetSelectedFutureTargets(6, current)
    if #futures == 0 then
        API:Print("No future navigation targets selected.")
    else
        for i, e in ipairs(futures) do
            local mapID,x,y = API:GetTargetMap(e)
            API:Print(string.format("SELECT +%d = Step %s map=%s x=%s y=%s", i, tostring(e.rxpNavigatorStepIndex), tostring(mapID), tostring(x), tostring(y)))
        end
    end
    API:Print("Use /rxpnav inspectcopy to copy this output.")
    API:EndInspectorCapture()
end

function Navigator.Inspector.RenderFutureDebug()
    API:BeginInspectorCapture("renderfuture")
    API:Print("=== RestedXP Renderer Future Debug ===")
    local db = API:GetDB()
    API:Print("Configured Future Goals: +" .. tostring(db and db.futureGoals or 0))
    local displayMapID = API:GetDisplayedMapID()
    API:Print("Displayed mapID=" .. tostring(displayMapID))
    local targets = API:GetNavigationTargets(db and db.futureGoals or 0)
    API:Print("Renderer target count=" .. tostring(#targets) .. " (current + futures)")
    for ordinal = 2, #targets do
        local e = targets[ordinal]
        local mapID,x,y = API:GetTargetMap(e)
        local px,py
        if mapID and displayMapID then
            px,py = API:PositionInDisplayedMap(mapID,x,y,displayMapID,true)
        end
        API:Print(string.format("RENDER +%d Step %s srcMap=%s x=%s y=%s -> display x=%s y=%s", ordinal-1, tostring(e.rxpNavigatorStepIndex), tostring(mapID), tostring(x), tostring(y), tostring(px), tostring(py)))
    end
    API:Print("Use /rxpnav inspectcopy to copy this output.")
    API:EndInspectorCapture()
end


