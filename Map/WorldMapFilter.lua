local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API

-- RXP 4.11+ can render its own map-pin label as an objective counter (for
-- example "0/60") next to the pin. Navigator intentionally keeps quest
-- progress inside the target tooltip, so suppress only those native RXP
-- counter labels. Do not hide the RXP pin itself and do not change RXP data.
Navigator.WorldMapFilter = Navigator.WorldMapFilter or { revision = 1 }

function Navigator.WorldMapFilter:IsNativeRXPProgressCounter(text)
    if type(text) ~= "string" then return false end
    local clean = text
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("%s+", "")
    return clean:match("^%d+/%d+$") ~= nil
end

function Navigator.WorldMapFilter:SuppressNativeRXPWorldProgressLabels()
    if not (WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown()) then return end
    local root = (API and API.GetWorldMapCanvas and API:GetWorldMapCanvas()) or WorldMapFrame
    if not root then return end

    local seen, visited = {}, 0
    local function Scan(frame, depth)
        if not frame or depth > 4 or seen[frame] or visited > 600 then return end
        seen[frame] = true
        visited = visited + 1

        -- RestedXP map pins created by map.lua expose both `activeObject` and
        -- `text`. This signature lets us avoid touching Blizzard map labels or
        -- labels from unrelated addons.
        local okActive, activeObject = pcall(function() return frame.activeObject end)
        local okTextObj, textObject = pcall(function() return frame.text end)
        if okActive and okTextObj and type(activeObject) == "table" and activeObject.elements then
            -- RestedXP's white targeting circle is a purely visual child named
            -- `inner` on its world-map pin frame. Keep RXP's pin/data intact and
            -- suppress only that visual when requested by Navigator.
            local db = API and API.GetDB and API:GetDB()
            if db and not db.showRXPActivePinCircle then
                local okInner, inner = pcall(function() return frame.inner end)
                if okInner and inner and type(inner.Hide) == "function" then inner:Hide() end
            end

            if textObject and type(textObject.GetText) == "function" then
                local okText, value = pcall(textObject.GetText, textObject)
                if okText and self:IsNativeRXPProgressCounter(value) and type(textObject.Hide) == "function" then
                    textObject:Hide()
                end
            end
        end

        if type(frame.GetChildren) == "function" then
            local children = { frame:GetChildren() }
            for _, child in ipairs(children) do Scan(child, depth + 1) end
        end
    end

    Scan(root, 0)
end

