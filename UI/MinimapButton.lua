local Navigator = _G.RXPNavigator
if not Navigator then return end
local API = Navigator.API
if not API then return end

Navigator.MinimapButton = Navigator.MinimapButton or { revision = 7 }
local button

local function ApplyPosition(db)
    if not button or not Minimap then return end
    local angle = math.rad(tonumber(db.minimapButtonAngle) or 220)
    local w = (Minimap.GetWidth and Minimap:GetWidth()) or 140
    local h = (Minimap.GetHeight and Minimap:GetHeight()) or w
    -- Same visual placement principle as Blizzard minimap edge buttons:
    -- the center of the button rides directly on the minimap rim.
    local radius = math.min(w, h) / 2 + 1
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function Navigator.MinimapButton:Update()
    if not Minimap then return end
    local db = API:GetDB()

    if not button then
        button = CreateFrame("Button", "RXPNavigatorMinimapButton", Minimap)
        button:SetSize(28, 28)
        button:SetFrameStrata("MEDIUM")
        button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:RegisterForDrag("LeftButton")

        -- Static neutral minimap button: no gold, no glow, no hover animation.
        local bg = button:CreateTexture(nil, "BACKGROUND", nil, 0)
        bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
        bg:SetSize(24, 24)
        bg:SetPoint("CENTER", 0, 0)
        bg:SetVertexColor(0.06, 0.06, 0.07, 1.0)
        button.bg = bg

        local ring = button:CreateTexture(nil, "BORDER", nil, 1)
        ring:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_MinimapButtonRing.tga")
        ring:SetSize(30, 30)
        ring:SetPoint("CENTER", 0, 0)
        ring:SetVertexColor(0.78, 0.80, 0.84, 1)
        button.ring = ring

        local icon = button:CreateTexture(nil, "ARTWORK", nil, 2)
        icon:SetTexture("Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_IconRound.tga")
        icon:SetSize(20, 20)
        icon:SetPoint("CENTER", 0, 0)
        button.icon = icon

        -- No HIGHLIGHT texture, no OnUpdate hover effect, no scaling animation.

        button:SetScript("OnDragStart", function(self)
            self._dragging = true
            self._didDrag = false
            self:SetScript("OnUpdate", function(frame)
                local dbNow = API:GetDB()
                if not dbNow or not Minimap then return end
                local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                local cx, cy = Minimap:GetCenter()
                local mx, my = GetCursorPosition()
                if not cx or not cy or not mx or not my then return end
                mx, my = mx / scale, my / scale
                local dx, dy = mx - cx, my - cy
                if math.abs(dx) + math.abs(dy) < 2 then return end
                local angle = math.deg(math.atan2(dy, dx))
                if angle < 0 then angle = angle + 360 end
                dbNow.minimapButtonAngle = angle
                frame._didDrag = true
                ApplyPosition(dbNow)
            end)
        end)

        button:SetScript("OnDragStop", function(self)
            self._dragging = false
            self:SetScript("OnUpdate", nil)
            local dbNow = API:GetDB()
            if dbNow then ApplyPosition(dbNow) end
        end)

        button:SetScript("OnClick", function(self, mouseButton)
            if self._didDrag then self._didDrag = false; return end
            if mouseButton == "RightButton" then
                if SlashCmdList and SlashCmdList.RXPNAV then SlashCmdList.RXPNAV("toggle") end
            else
                if SlashCmdList and SlashCmdList.RXPNAV then SlashCmdList.RXPNAV("options") end
            end
        end)

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("RestedXP-Navigator")
            GameTooltip:AddLine("Left Click: Open settings", 1, 1, 1)
            GameTooltip:AddLine("Drag: Move around the minimap", 0.75, 0.90, 1.00)
            GameTooltip:AddLine("Right Click: Toggle navigator", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    if not db or db.showMinimapButton == false then
        button:Hide()
        return
    end

    ApplyPosition(db)
    button:Show()
end
