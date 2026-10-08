local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.RXPBridge = Navigator.RXPBridge or {
    originalDisableArrow = nil,
    arrowHooked = false,
}

function Navigator:QueueRXPDrivenRefresh(reason)
    Navigator.RXPData:Invalidate()
    self._rxpEventRefreshPending = reason or true
end

function Navigator.RXPBridge:SetupEventBridge()
    if Navigator.rxpEventBridgeReady then return true end
    if not LibStub then return false end
    local aceEvent = LibStub("AceEvent-3.0", true)
    if not (aceEvent and type(aceEvent.Embed) == "function") then return false end

    local bridge = {}
    aceEvent:Embed(bridge)
    bridge.OnActiveSteps = function(_, ...) Navigator:QueueRXPDrivenRefresh("UpdateActiveSteps") end
    bridge.OnQuestData = function(_, ...) Navigator:QueueRXPDrivenRefresh("QuestDataLoaded") end
    bridge.OnGuideSteps = function(_, ...) Navigator:QueueRXPDrivenRefresh("GuideStepsChanged") end
    bridge.OnGuideWindow = function(_, ...) Navigator:QueueRXPDrivenRefresh("GuideWindowRefresh") end

    local ok = pcall(function()
        bridge:RegisterMessage("RXPGuidesV2_UpdateActiveSteps", "OnActiveSteps")
        bridge:RegisterMessage("RXPGuidesV2_QuestDataLoaded", "OnQuestData")
        bridge:RegisterMessage("RXPGuidesV2_GuideStepsChanged", "OnGuideSteps")
        bridge:RegisterMessage("RXPGuidesV2_GuideWindowRefresh", "OnGuideWindow")
    end)
    if not ok then return false end

    Navigator.RXPEventBridge = bridge
    Navigator.rxpEventBridgeReady = true
    return true
end

function Navigator.RXPBridge:HideOriginalArrow()
    local af = _G.RXPG_ARROW
    if not af then return end
    if not self.arrowHooked then
        self.arrowHooked = true
        local originalShow = af.Show
        af.__rxpnav_originalShow = originalShow
        af.Show = function(frame, ...)
            if type(originalShow) == "function" then originalShow(frame, ...) end
            if frame.SetAlpha then frame:SetAlpha(0) end
        end
        local originalSetShown = af.SetShown
        af.__rxpnav_originalSetShown = originalSetShown
        if type(originalSetShown) == "function" then
            af.SetShown = function(frame, shown)
                originalSetShown(frame, shown)
                if frame.SetAlpha then frame:SetAlpha(0) end
            end
        end
    end
    if af.SetAlpha then af:SetAlpha(0) end
end

function Navigator.RXPBridge:EnsureWaypointEngine()
    local rxp = API:GetRXPGuidesAddon()
    if type(rxp) ~= "table" then return false end
    local profile = rxp.settings and rxp.settings.profile
    if profile then
        if self.originalDisableArrow == nil then
            self.originalDisableArrow = profile.disableArrow and true or false
        end
        -- RestedXP only populates its active arrow element while the internal
        -- arrow engine is enabled. Keep the engine alive, hide only its visual.
        if profile.disableArrow then
            profile.disableArrow = false
            if type(rxp.UpdateMap) == "function" then pcall(rxp.UpdateMap, true) end
        end
    end
    self:HideOriginalArrow()
    return true
end

function Navigator.RXPBridge:RestoreArrowSetting()
    local rxp = API:GetRXPGuidesAddon()
    local profile = rxp and rxp.settings and rxp.settings.profile
    if profile and self.originalDisableArrow ~= nil then
        profile.disableArrow = self.originalDisableArrow
    end
end
