local Navigator = _G.RXPNavigator
if not Navigator then return end

Navigator.HearthActions = {}

local function Clean(text)
    if type(text) ~= "string" then return "" end
    return text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
        :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|H.-|h(.-)|h", "%1"):lower()
end

function Navigator.HearthActions:Classify(element, model)
    if type(element) ~= "table" then return nil end
    local tag = model and (model.semanticTag or model.tag)
        or element.tag or element.action or element.type or element.command
    tag = tag and tostring(tag):lower():gsub("^%.", "") or ""
    -- Parsed commands are authoritative, independent of client language.
    if tag == "home" or tag == "bindlocation" then return "bind" end
    if tag == "hs" or tag == "hsbatching" then return "use" end

    local fields = {"text", "tooltipText", "mapTooltip", "rawtext", "hiddentext", "title", "label"}
    local texts = {}
    if model and model.instruction then texts[#texts + 1] = Clean(model.instruction) end
    for _, field in ipairs(fields) do texts[#texts + 1] = Clean(element[field]) end
    -- Check every binding description before use descriptions: "Set your
    -- Hearthstone to ..." also contains the generic "hearthstone to" phrase.
    for _, text in ipairs(texts) do
        if text:find("set your hearthstone", 1, true)
            or text:find("set hearthstone", 1, true)
            or text:find("bind your hearthstone", 1, true)
            or (text:find("ruhestein", 1, true) and
                (text:find("binde", 1, true) or text:find("binden", 1, true) or text:find("setzt", 1, true))) then
            return "bind"
        end
    end
    for _, text in ipairs(texts) do
        if text:find("hearth to ", 1, true) or text:find("use your hearthstone", 1, true)
            or text:find("hearthstone to ", 1, true)
            or text:find("nutze deinen ruhestein", 1, true)
            or text:find("benutze deinen ruhestein", 1, true) then
            return "use"
        end
    end
end
