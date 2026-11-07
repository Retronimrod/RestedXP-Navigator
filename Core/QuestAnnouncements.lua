local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end
local API = Navigator.API
local Announcer = {}
Navigator.QuestAnnouncements = Announcer

local snapshots, queue, scopeUntil = {}, {}, {}
local context, lastSent, nextScan = nil, -math.huge, 0
local dirty, baseline, elapsed = true, true, 0
local INTERVAL, SEND_INTERVAL, QUEUE_TTL, MAX_QUEUE = 0.25, 3, 20, 32

local function Channel()
    if not IsInGroup or not IsInGroup() then return nil end
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return 'INSTANCE_CHAT' end
    if IsInRaid and IsInRaid() then return 'RAID' end
    return 'PARTY'
end

local function Signature(db, channel)
    return tostring(channel) .. ':' .. tostring(db.enabled) .. ':' .. tostring(db.questChatProgress)
        .. ':' .. tostring(db.questChatCompletion) .. ':' .. tostring(db.questChatAllQuests)
end

local function Clean(text)
    return tostring(text or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
        :gsub('|H.-|h(.-)|h', '%1'):gsub('|T.-|t', ''):gsub('|A.-|a', '')
        :gsub('|', ''):gsub('[%c]', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')
end

local function Limit(text)
    text = Clean(text)
    if #text <= 240 then return text end
    local cut = 238
    -- Chat limits are byte-based. Do not split a UTF-8 continuation sequence.
    while cut > 0 and (text:byte(cut) or 0) >= 128 and (text:byte(cut) or 0) < 192 do cut = cut - 1 end
    return text:sub(1, cut - 1) .. '...'
end

local function Reset()
    snapshots, queue, scopeUntil = {}, {}, {}
    baseline, dirty = true, true
end

local function QuestIDs(node, ids, depth)
    if type(node) ~= 'table' or depth > 2 or node.skip then return end
    for _, key in ipairs({'questID', 'questId', 'quest', 'q', 'qid'}) do
        local id = tonumber(node[key])
        if id and id > 0 then ids[id] = true end
    end
    if type(node.elements) == 'table' then
        for _, element in pairs(node.elements) do QuestIDs(element, ids, depth + 1) end
    end
end

local function CurrentScope(now)
    local ids = {}
    local addon = API.GetRXPGuidesAddon and API:GetRXPGuidesAddon()
    local steps = addon and addon.RXPFrame and addon.RXPFrame.activeSteps
    if type(steps) == 'table' then
        for _, step in pairs(steps) do QuestIDs(step, ids, 0) end
    end
    if API.ResolveActiveGuideAndStep then
        local guide, index = API:ResolveActiveGuideAndStep()
        if guide and guide.steps and index then QuestIDs(guide.steps[index], ids, 0) end
    end
    if API.GetCurrentNavigationElement then QuestIDs(API:GetCurrentNavigationElement(), ids, 0) end
    -- RestedXP may advance its step before QUEST_LOG_UPDATE reaches us.
    for id in pairs(ids) do scopeUntil[id] = now + 4 end
    for id, expires in pairs(scopeUntil) do
        if now > expires then scopeUntil[id] = nil else ids[id] = true end
    end
    return ids
end

local function ReadQuest(id)
    local log = C_QuestLog
    local index = log.GetLogIndexForQuestID(id)
    if not index then return nil, true end
    local info = log.GetInfo(index)
    local objectives = log.GetQuestObjectives(id)
    if not info or not info.title or type(objectives) ~= 'table' then return nil, false end
    local state = {title = Clean(info.title), objectives = {}, complete = log.IsComplete(id) == true}
    for i, objective in ipairs(objectives) do
        state.objectives[i] = {
            text = Clean(objective.text), count = tonumber(objective.numFulfilled),
            required = tonumber(objective.numRequired), finished = objective.finished == true,
        }
    end
    return state, false
end

local function Put(entry)
    entry.time = GetTime()
    for i, pending in ipairs(queue) do
        if pending.key == entry.key then queue[i] = entry; return end
    end
    if #queue >= MAX_QUEUE then table.remove(queue, 1) end
    queue[#queue + 1] = entry
end

local function DropQuest(id)
    for i = #queue, 1, -1 do if queue[i].id == id then table.remove(queue, i) end end
end

local function ObjectiveText(objective)
    local text = objective.text
    if objective.required and objective.required > 0 and objective.count
        and not text:find('%d+%s*/%s*%d+') then
        text = text .. string.format(' (%d/%d)', objective.count, objective.required)
    end
    return text
end

local function Observe(id, old, new, db)
    for i, objective in ipairs(new.objectives) do
        local previous = old.objectives[i]
        if previous then
            local completed = objective.finished and not previous.finished
            local increased = objective.count and previous.count and objective.count > previous.count
            if (completed and db.questChatCompletion) or (increased and not objective.finished and db.questChatProgress) then
                Put({key = id .. ':' .. i, id = id, kind = 'objective', finished = objective.finished,
                    title = new.title, text = ObjectiveText(objective), index = i, count = objective.count, sourceText = objective.text})
            end
        end
    end
    if new.complete and not old.complete and db.questChatCompletion then
        -- An old 2/8 message must not be delivered after the quest is complete.
        for i = #queue, 1, -1 do
            if queue[i].id == id and not queue[i].finished then table.remove(queue, i) end
        end
        Put({key = id .. ':ready', id = id, kind = 'ready', title = new.title})
    end
end

function Announcer:Scan()
    local db = API:GetDB()
    if not db then return end
    local channel = Channel()
    local signature = Signature(db, channel)
    if context ~= signature then context = signature; Reset() end
    local log = C_QuestLog
    if not log or not log.GetInfo or not log.GetNumQuestLogEntries or not log.GetLogIndexForQuestID
        or not log.GetQuestObjectives or not log.IsComplete then return end
    local now, ids = GetTime(), {}
    local scope = CurrentScope(now)
    for id in pairs(scope) do ids[id] = true end
    for id in pairs(snapshots) do ids[id] = true end
    for index = 1, log.GetNumQuestLogEntries() do
        local info = log.GetInfo(index)
        if info and not info.isHeader and info.questID and info.questID > 0 then ids[info.questID] = true end
    end
    local enabled = channel and db.enabled and (db.questChatProgress or db.questChatCompletion)
        and not (Navigator.SetupWizard and Navigator.SetupWizard:IsOpen())
    for id in pairs(ids) do
        local state, removed = ReadQuest(id)
        if state then
            local old = snapshots[id]
            if not baseline and enabled and old and (db.questChatAllQuests or scope[id]) then Observe(id, old, state, db) end
            snapshots[id] = state
        elseif removed then snapshots[id] = nil; DropQuest(id) end
    end
    baseline = false
end

function Announcer:Flush()
    local db, channel, now = API:GetDB(), Channel(), GetTime()
    if not channel or not db or not db.enabled or (Navigator.SetupWizard and Navigator.SetupWizard:IsOpen()) then queue = {}; return end
    if context ~= Signature(db, channel) then Reset(); return end
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        queue = {}; return
    end
    for i = #queue, 1, -1 do
        local entry = queue[i]
        local permitted = (entry.kind == 'ready' or entry.finished) and db.questChatCompletion
            or (entry.kind == 'objective' and not entry.finished and db.questChatProgress)
        local state = snapshots[entry.id]
        local objective = state and state.objectives[entry.index]
        local current = state and ((entry.kind == 'ready' and state.complete)
            or (entry.kind == 'objective' and objective and objective.count == entry.count
                and objective.text == entry.sourceText and objective.finished == entry.finished
                and (entry.finished or not state.complete)))
        if now - entry.time > QUEUE_TTL or not permitted or not current then table.remove(queue, i) end
    end
    if #queue == 0 or now - lastSent < SEND_INTERVAL or now - queue[1].time < 0.75 then return end
    -- Use only the client's public chat API. A rejection is never retried
    -- through a different API, channel, macro, or protected-function wrapper.
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if type(send) ~= 'function' then queue = {}; return end
    local entry = table.remove(queue, 1)
    local text
    if entry.kind == 'ready' then text = string.format(API:Localize('Quest "%s" ready for turn-in.'), entry.title)
    else
        text = entry.title .. ': ' .. entry.text
        if entry.finished then text = text .. ' - ' .. API:Localize('Objective complete!') end
    end
    lastSent = now
    local ok, result = pcall(send, Limit(text), channel)
    if not ok or result == false then queue = {} end
end

local events = CreateFrame('Frame')
for _, event in ipairs({'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD', 'GROUP_ROSTER_UPDATE', 'QUEST_LOG_UPDATE',
    'QUEST_WATCH_UPDATE', 'QUEST_ACCEPTED', 'QUEST_REMOVED', 'QUEST_TURNED_IN'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_LOGIN' or event == 'PLAYER_ENTERING_WORLD' or event == 'GROUP_ROSTER_UPDATE' then Reset() end
    dirty = true
end)
events:SetScript('OnUpdate', function(_, dt)
    elapsed = elapsed + dt
    if elapsed < INTERVAL then return end
    elapsed = 0
    local now = GetTime()
    if dirty or now >= nextScan then
        dirty, nextScan = false, now + 1
        Announcer:Scan()
    end
    Announcer:Flush()
end)
