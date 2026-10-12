local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end
local API = Navigator.API
Navigator.ControlCenter = Navigator.ControlCenter or {}
local CC = Navigator.ControlCenter

local window
local pages = {}
local pageButtons = {}
local refreshers = {}
local activePage = 'general'
local db

local ACCENT = {0.12, 0.72, 1.00}
local PANEL = {0.050, 0.060, 0.078, 0.985}
local CARD = {0.080, 0.090, 0.115, 0.97}
local MUTED = {0.58, 0.63, 0.70}

local CURSEFORGE_PROFILE_URL = 'https://www.curseforge.com/members/nimri82/projects'

local function EnsureExternalLinkPopup()
    if not StaticPopupDialogs or StaticPopupDialogs['RXPNAV_EXTERNAL_LINK'] then return end
    StaticPopupDialogs['RXPNAV_EXTERNAL_LINK'] = {
        text = 'Open this link in your web browser:\n\n%s',
        button1 = CLOSE or 'Close',
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        hasEditBox = true,
        editBoxWidth = 440,
        OnShow = function(self, data)
            local url = tostring(data or CURSEFORGE_PROFILE_URL)
            self.editBox:SetText(url)
            self.editBox:SetFocus()
            self.editBox:HighlightText()
        end,
        EditBoxOnEnterPressed = function(self)
            self:HighlightText()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }
end

local function OpenExternalURL(url)
    url = tostring(url or '')
    if url == '' then return false end

    -- Some custom clients may expose an explicit arbitrary-URL launcher.
    -- Use it only when the client itself provides one.
    if C_Browser and type(C_Browser.OpenURL) == 'function' then
        local ok = pcall(C_Browser.OpenURL, url)
        if ok then return true end
    end
    if type(_G.OpenURL) == 'function' then
        local ok = pcall(_G.OpenURL, url)
        if ok then return true end
    end

    -- Standard Blizzard clients do not expose a general arbitrary-URL
    -- launcher to addons. Fall back to a selected/copyable URL dialog.
    EnsureExternalLinkPopup()
    if StaticPopup_Show then
        local popup = StaticPopup_Show('RXPNAV_EXTERNAL_LINK', url, nil, url)
        if popup and popup.editBox then
            popup.editBox:SetText(url)
            popup.editBox:SetFocus()
            popup.editBox:HighlightText()
        end
    end
    return false
end

local function SyncDB() db = API:GetDB(); return db end
local function RefreshAll()
    if API.SaveActiveProfile then API:SaveActiveProfile() end
    API:RefreshAll()
end

local function Version()
    return API.GetVersion and API:GetVersion() or "?"
end

local function Text(parent, font, text, x, y, width)
    local fs = parent:CreateFontString(nil, 'OVERLAY', font or 'GameFontHighlight')
    fs:SetPoint('TOPLEFT', x, y)
    if width then fs:SetWidth(width); fs:SetJustifyH('LEFT'); fs:SetWordWrap(true) end
    fs:SetText(text or '')
    return fs
end

local function Backdrop(frame,r,g,b,a,border)
    local bg=frame:CreateTexture(nil,'BACKGROUND'); bg:SetAllPoints(); bg:SetColorTexture(r,g,b,a)
    if border then
        local t
        t=frame:CreateTexture(nil,'BORDER'); t:SetColorTexture(unpack(border)); t:SetPoint('TOPLEFT'); t:SetPoint('TOPRIGHT'); t:SetHeight(1)
        t=frame:CreateTexture(nil,'BORDER'); t:SetColorTexture(unpack(border)); t:SetPoint('BOTTOMLEFT'); t:SetPoint('BOTTOMRIGHT'); t:SetHeight(1)
        t=frame:CreateTexture(nil,'BORDER'); t:SetColorTexture(unpack(border)); t:SetPoint('TOPLEFT'); t:SetPoint('BOTTOMLEFT'); t:SetWidth(1)
        t=frame:CreateTexture(nil,'BORDER'); t:SetColorTexture(unpack(border)); t:SetPoint('TOPRIGHT'); t:SetPoint('BOTTOMRIGHT'); t:SetWidth(1)
    end
    return bg
end

local function Card(parent,title,subtitle,x,y,w,h)
    local f=CreateFrame('Frame',nil,parent); f:SetPoint('TOPLEFT',x,y); f:SetSize(w,h)
    Backdrop(f,CARD[1],CARD[2],CARD[3],CARD[4],{0.14,0.16,0.20,1})
    local t=Text(f,'GameFontNormalLarge',title,16,-14,w-32); t:SetTextColor(.96,.98,1)
    if subtitle then
        local s=Text(f,'GameFontHighlightSmall',subtitle,16,-39,w-32); s:SetTextColor(unpack(MUTED))
    end
    return f
end

local function AddRefresh(control,fn)
    control.Refresh=fn; refreshers[#refreshers+1]=control; return control
end

local function Toggle(parent,label,x,y,getter,setter,description)
    local b=CreateFrame('CheckButton',nil,parent,'UICheckButtonTemplate'); b:SetPoint('TOPLEFT',x,y); b:SetSize(24,24)
    Text(parent,'GameFontHighlight',label,x+30,y-3,275)
    if description then
        local d=Text(parent,'GameFontDisableSmall',description,x+30,y-21,280); d:SetTextColor(unpack(MUTED))
    end
    b:SetScript('OnClick',function(self) setter(self:GetChecked() and true or false); RefreshAll() end)
    return AddRefresh(b,function(self) self:SetChecked(getter() and true or false) end)
end

local function Slider(parent,label,x,y,w,minv,maxv,step,getter,setter,formatter)
    Text(parent,'GameFontNormal',label,x,y,w)
    local value=Text(parent,'GameFontHighlightSmall','',x+w-75,y,75); value:SetJustifyH('RIGHT')
    local s=CreateFrame('Slider',nil,parent,'OptionsSliderTemplate'); s:SetPoint('TOPLEFT',x,y-28); s:SetWidth(w)
    s:SetMinMaxValues(minv,maxv); s:SetValueStep(step); if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    if s.Low then s.Low:SetText('') end; if s.High then s.High:SetText('') end; if s.Text then s.Text:SetText('') end
    local busy=false
    s:SetScript('OnValueChanged',function(self,v)
        if busy then return end
        v=math.floor(v/step+0.5)*step; setter(v); value:SetText(formatter and formatter(v) or tostring(v)); RefreshAll()
    end)
    return AddRefresh(s,function(self)
        busy=true; local v=getter(); self:SetValue(v); busy=false; value:SetText(formatter and formatter(v) or tostring(v))
    end)
end

local function Button(parent,label,x,y,w,onclick)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate'); b:SetPoint('TOPLEFT',x,y); b:SetSize(w or 150,27); b:SetText(label)
    b:SetScript('OnClick',onclick); return b
end

local function EditBox(parent,x,y,w,placeholder)
    local e=CreateFrame('EditBox',nil,parent,'InputBoxTemplate'); e:SetPoint('TOPLEFT',x,y); e:SetSize(w,26); e:SetAutoFocus(false)
    e:SetMaxLetters(32)
    if placeholder then e:SetText(''); e.placeholder=placeholder end
    return e
end

local function ColorButton(parent,label,x,y,getter,setter)
    Text(parent,'GameFontNormal',label,x,y,180)
    local b=CreateFrame('Button',nil,parent); b:SetPoint('TOPLEFT',x+190,y+3); b:SetSize(42,20)
    b.swatch=b:CreateTexture(nil,'ARTWORK'); b.swatch:SetAllPoints(); b.swatch:SetColorTexture(1,1,1,1)
    Backdrop(b,0,0,0,0,{.3,.3,.3,1})
    local function open()
        local r,g,bv=getter()
        local function changed()
            local nr,ng,nb=ColorPickerFrame:GetColorRGB()
            setter(nr,ng,nb); b.swatch:SetColorTexture(nr,ng,nb,1); RefreshAll()
        end
        ColorPickerFrame:SetupColorPickerAndShow({r=r,g=g,b=bv,swatchFunc=changed,cancelFunc=function(prev) setter(prev.r,prev.g,prev.b); RefreshAll() end})
    end
    b:SetScript('OnClick',open)
    return AddRefresh(b,function(self) local r,g,bv=getter(); self.swatch:SetColorTexture(r,g,bv,1) end)
end

local function Dropdown(parent,x,y,w,getItems,getter,setter)
    local d=CreateFrame('Frame',nil,parent,'UIDropDownMenuTemplate'); d:SetPoint('TOPLEFT',x-16,y); UIDropDownMenu_SetWidth(d,w)
    UIDropDownMenu_Initialize(d,function(self,level)
        local current=getter()
        for _,item in ipairs(getItems()) do
            local info=UIDropDownMenu_CreateInfo()
            info.text=item; info.value=item; info.checked=(item==current)
            info.func=function()
                setter(item); UIDropDownMenu_SetSelectedValue(d,item); UIDropDownMenu_SetText(d,item); RefreshAll()
            end
            UIDropDownMenu_AddButton(info,level)
        end
    end)
    return AddRefresh(d,function(self)
        local v=getter(); UIDropDownMenu_SetSelectedValue(self,v); UIDropDownMenu_SetText(self,v or '')
    end)
end

local function NewPage(key,title,subtitle)
    local p=CreateFrame('Frame',nil,window.content); p:SetAllPoints(window.content); p:Hide(); pages[key]=p
    local h=Text(p,'GameFontNormalHuge',title,4,-2,700); h:SetTextColor(.95,.97,1)
    local s=Text(p,'GameFontHighlightSmall',subtitle,4,-34,700); s:SetTextColor(unpack(MUTED))
    return p
end

local previewKit='OnMyWay'
local function WorldMarkerPreview(parent)
    local preview=CreateFrame('Frame',nil,parent); preview:SetPoint('TOPLEFT',16,-62); preview:SetSize(300,155)
    Backdrop(preview,.035,.045,.06,.96,{.12,.15,.20,1})
    Text(preview,'GameFontDisableSmall','LIVE PREVIEW',12,-10,120):SetTextColor(unpack(MUTED))

    local marker=CreateFrame('Frame',nil,preview); marker:SetSize(110,125); marker:SetPoint('CENTER',preview,'CENTER',0,-5)
    local ring=marker:CreateTexture(nil,'BACKGROUND'); ring:SetTexture('Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_GroundRing.tga'); ring:SetBlendMode('ADD'); ring:SetPoint('BOTTOM',marker,'BOTTOM',0,12)
    local stem=marker:CreateTexture(nil,'ARTWORK'); stem:SetPoint('BOTTOM',ring,'CENTER',0,0)
    local bg=marker:CreateTexture(nil,'ARTWORK'); bg:SetPoint('BOTTOM',stem,'TOP',0,-7)
    local stroke=marker:CreateTexture(nil,'ARTWORK'); stroke:SetPoint('CENTER',bg)
    local icon=marker:CreateTexture(nil,'OVERLAY'); icon:SetPoint('CENTER',bg)
    local dist=marker:CreateFontString(nil,'OVERLAY','GameFontNormal'); dist:SetPoint('LEFT',bg,'RIGHT',5,0); dist:SetText('63 yd')

    preview.Refresh=function()
        local kit=previewKit
        pcall(stem.SetAtlas,stem,'Ping_GroundMarker_Pin_'..kit,false); stem:SetSize(12,58)
        pcall(bg.SetAtlas,bg,'Ping_GroundMarker_BG_'..kit,false); bg:SetSize(42,42)
        pcall(stroke.SetAtlas,stroke,'Ping_GroundMarker_Stroke_'..kit,false); stroke:SetSize(42,42); stroke:SetAlpha(.35)
        pcall(icon.SetAtlas,icon,'Ping_Marker_Icon_'..kit,false); icon:SetSize(24,24)

        local colors={
            Assist={db.markerAssistR or .23,db.markerAssistG or .95,db.markerAssistB or .34},
            OnMyWay={db.markerTravelR or .18,db.markerTravelG or .72,db.markerTravelB or 1},
            Attack={db.markerAttackR or 1,db.markerAttackG or .62,db.markerAttackB or .10},
            NonThreat={db.markerDefaultR or .22,db.markerDefaultG or .68,db.markerDefaultB or 1},
        }
        local c=colors[kit] or colors.NonThreat
        if db.worldMarkerCustomColors then
            bg:SetVertexColor(unpack(c)); stroke:SetVertexColor(unpack(c)); icon:SetVertexColor(unpack(c)); stem:SetVertexColor(unpack(c))
        else
            bg:SetVertexColor(1,1,1); stroke:SetVertexColor(1,1,1); icon:SetVertexColor(1,1,1); stem:SetVertexColor(1,1,1)
        end
        dist:SetTextColor(unpack(c))
        stem:SetShown(db.showWorldMarkerBeam ~= false)
        dist:SetShown(db.showWorldMarkerDistance ~= false)
        ring:SetShown(db.showWorldMarkerGroundRing ~= false)
        ring:SetSize(48*(db.worldMarkerGroundRingScale or 1),17*(db.worldMarkerGroundRingScale or 1))
        ring:SetAlpha(db.worldMarkerGroundRingAlpha or .72)
        local rr,rg,rb=unpack(c)
        if db.worldMarkerGroundRingUseMarkerColor == false then rr,rg,rb=db.worldMarkerGroundRingR or rr,db.worldMarkerGroundRingG or rg,db.worldMarkerGroundRingB or rb end
        ring:SetVertexColor(rr,rg,rb,1)
        marker:SetScale(db.worldMarkerScale or 1)
    end
    refreshers[#refreshers+1]=preview
    return preview
end

local function BuildPages()
    local p,c,c2

    p=NewPage('general','General','Core behavior and RestedXP integration.')
    c=Card(p,'Navigator','Master switches for the navigation layer.',4,-70,700,145)
    Toggle(c,'Enable RestedXP-Navigator',16,-58,function() return db.enabled end,function(v) db.enabled=v end,'Turns the complete navigation layer on or off.')
    Toggle(c,'Keep navigation while dead',360,-58,function() return db.keepGhostNavigation end,function(v) db.keepGhostNavigation=v end,'Keeps corpse-run guidance available as a ghost.')
    c2=Card(p,'Upcoming goals','Choose how much upcoming RestedXP context is displayed.',4,-230,700,150)
    Slider(c2,'Future steps',16,-58,300,0,6,1,function() return db.futureGoals or 3 end,function(v) db.futureGoals=v; db.showMinimapFutureGoals=v>0 end,function(v) return '+'..v end)
    Toggle(c2,'Show minimap button',360,-58,function() return db.showMinimapButton ~= false end,function(v) db.showMinimapButton=v end)
    Toggle(c2,'Animate routes',360,-98,function() return db.animation ~= false end,function(v) db.animation=v end)

    p=NewPage('profiles','Profiles','Use one setup across all characters or maintain your own named presets.')
    c=Card(p,'Active profile','Profiles store your Navigator appearance and behavior settings.',4,-70,700,190)
    Toggle(c,'Use one profile for all characters',16,-58,function() return db.profileUseGlobal ~= false end,function(v) API:SetGlobalProfileMode(v); SyncDB() end,
        'On: every character uses the same selected profile. Off: each character can select its own profile.')
    Text(c,'GameFontNormal','Selected profile',16,-108,160)
    Dropdown(c,170,-113,230,function() return API:GetProfileNames() end,function() return API:GetActiveProfileName() end,function(name) API:ApplyProfile(name); SyncDB() end)
    local char=Text(c,'GameFontHighlightSmall','Character: '..(API:GetCharacterProfileKey() or '?'),420,-112,250); char:SetTextColor(unpack(MUTED))

    c2=Card(p,'Profile management','Create snapshots, overwrite the active profile, or remove profiles you no longer need.',4,-275,700,210)
    Text(c2,'GameFontNormal','New profile name',16,-62,150)
    local profileName=EditBox(c2,170,-57,225,'Profile name')
    Button(c2,'Create from current',410,-56,170,function()
        local name=profileName:GetText()
        local ok,msg=API:SaveProfile(name)
        if ok then profileName:SetText(''); SyncDB(); CC:Refresh() else API:Print(msg or 'Could not create profile.') end
    end)
    Button(c2,'Save current profile',16,-115,185,function()
        API:SaveActiveProfile(); API:Print('Profile saved: '..tostring(API:GetActiveProfileName()))
    end)
    Button(c2,'Delete selected profile',215,-115,185,function()
        local ok,msg=API:DeleteProfile(API:GetActiveProfileName())
        if not ok then API:Print(msg or 'Profile could not be deleted.') end
        SyncDB(); CC:Refresh(); RefreshAll()
    end)
    Text(c2,'GameFontDisableSmall','Tip: create profiles such as “Leveling”, “Minimal HUD”, “Large UI” or “Streamer”. Switching a profile immediately applies the stored settings.',16,-163,650):SetTextColor(unpack(MUTED))

    p=NewPage('navigation','Navigation HUD','On-screen arrow, distance and ETA guidance.')
    c=Card(p,'HUD Arrow','Configure the primary direction arrow.',4,-70,700,235)
    Toggle(c,'Show HUD arrow',16,-58,function() return db.showHUDArrow end,function(v) db.showHUDArrow=v end)
    Toggle(c,'Show distance',360,-58,function() return db.hudShowDistance end,function(v) db.hudShowDistance=v end)
    Toggle(c,'Show ETA',16,-98,function() return db.hudShowETA end,function(v) db.hudShowETA=v end)
    Toggle(c,'Lock position',360,-98,function() return db.hudLocked end,function(v) db.hudLocked=v end)
    Slider(c,'Arrow size',16,-155,300,.55,2,.05,function() return db.hudSize or 1 end,function(v) db.hudSize=v end,function(v) return string.format('%d%%',v*100) end)
    Slider(c,'Text size',360,-155,300,.65,1.8,.05,function() return db.hudTextSize or 1 end,function(v) db.hudTextSize=v end,function(v) return string.format('%d%%',v*100) end)
    c2=Card(p,'HUD appearance','Color used by the primary navigation arrow.',4,-320,700,125)
    ColorButton(c2,'HUD arrow color',16,-60,function() return db.hudColorR or .08,db.hudColorG or .74,db.hudColorB or 1 end,function(r,g,b) db.hudColorR=r;db.hudColorG=g;db.hudColorB=b end)

    p=NewPage('worldmarker','World Marker','Blizzard PingUI markers with an optional RestedXP-Navigator floor ring.')
    c=Card(p,'Preview','Preview is isolated from the settings controls and uses fixed dimensions.',4,-70,700,235)
    WorldMarkerPreview(c)
    Toggle(c,'Enable world marker',335,-60,function() return db.showWorldMarkerNative == true end,function(v) db.showWorldMarkerNative=v end)
    Toggle(c,'Show distance',335,-100,function() return db.showWorldMarkerDistance ~= false end,function(v) db.showWorldMarkerDistance=v end)
    Toggle(c,'Show close-range beam',335,-140,function() return db.showWorldMarkerBeam ~= false end,function(v) db.showWorldMarkerBeam=v end)
    Toggle(c,'Hide duplicate Blizzard marker',335,-180,function() return db.worldMarkerHideBlizzard ~= false end,function(v) db.worldMarkerHideBlizzard=v end)

    c2=Card(p,'Marker behavior','Size, beam distance, NPC attachment and floor contact.',4,-320,700,240)
    Slider(c2,'Marker scale',16,-58,300,.60,1.60,.05,function() return db.worldMarkerScale or 1 end,function(v) db.worldMarkerScale=v end,function(v) return string.format('%d%%',v*100) end)
    Slider(c2,'Beam activation range',360,-58,300,20,150,5,function() return db.worldMarkerBeamDistance or 65 end,function(v) db.worldMarkerBeamDistance=v end,function(v) return v..' yd' end)
    Toggle(c2,'Automatic NPC anchoring',16,-125,function() return db.worldMarkerNPCAutoAnchor ~= false end,function(v) db.worldMarkerNPCAutoAnchor=v end)
    Slider(c2,'NPC anchor range',360,-125,300,20,150,5,function() return db.worldMarkerNPCMaxDistance or 75 end,function(v) db.worldMarkerNPCMaxDistance=v end,function(v) return v..' yd' end)
    Toggle(c2,'Ground ring',16,-190,function() return db.showWorldMarkerGroundRing ~= false end,function(v) db.showWorldMarkerGroundRing=v end)
    Slider(c2,'Ground ring size',360,-190,300,.50,1.75,.05,function() return db.worldMarkerGroundRingScale or 1 end,function(v) db.worldMarkerGroundRingScale=v end,function(v) return string.format('%d%%',v*100) end)

    p=NewPage('appearance','Appearance','Fine-tune marker colors and floor-ring presentation.')
    c=Card(p,'Marker colors','By default the original Blizzard PingUI colors are used. Enable custom tinting only if you want your own palette.',4,-70,700,260)
    Toggle(c,'Use custom marker colors',16,-58,function() return db.worldMarkerCustomColors == true end,function(v) db.worldMarkerCustomColors=v end)
    ColorButton(c,'Interaction / NPC',16,-108,function() return db.markerAssistR,db.markerAssistG,db.markerAssistB end,function(r,g,b) db.markerAssistR=r;db.markerAssistG=g;db.markerAssistB=b end)
    ColorButton(c,'Travel / movement',360,-108,function() return db.markerTravelR,db.markerTravelG,db.markerTravelB end,function(r,g,b) db.markerTravelR=r;db.markerTravelG=g;db.markerTravelB=b end)
    ColorButton(c,'Combat / kill',16,-158,function() return db.markerAttackR,db.markerAttackG,db.markerAttackB end,function(r,g,b) db.markerAttackR=r;db.markerAttackG=g;db.markerAttackB=b end)
    ColorButton(c,'Default / other',360,-158,function() return db.markerDefaultR,db.markerDefaultG,db.markerDefaultB end,function(r,g,b) db.markerDefaultR=r;db.markerDefaultG=g;db.markerDefaultB=b end)

    c2=Card(p,'Ground ring','The floor ring is the only custom artwork used by the world marker.',4,-345,700,205)
    Toggle(c2,'Match marker color',16,-58,function() return db.worldMarkerGroundRingUseMarkerColor ~= false end,function(v) db.worldMarkerGroundRingUseMarkerColor=v end)
    ColorButton(c2,'Custom ring color',360,-58,function() return db.worldMarkerGroundRingR,db.worldMarkerGroundRingG,db.worldMarkerGroundRingB end,function(r,g,b) db.worldMarkerGroundRingR=r;db.worldMarkerGroundRingG=g;db.worldMarkerGroundRingB=b end)
    Slider(c2,'Ring opacity',16,-125,300,.10,1,.05,function() return db.worldMarkerGroundRingAlpha or .72 end,function(v) db.worldMarkerGroundRingAlpha=v end,function(v) return string.format('%d%%',v*100) end)
    Slider(c2,'Ring size',360,-125,300,.50,1.75,.05,function() return db.worldMarkerGroundRingScale or 1 end,function(v) db.worldMarkerGroundRingScale=v end,function(v) return string.format('%d%%',v*100) end)

    p=NewPage('maps','Maps','Minimap and world-map route presentation.')
    c=Card(p,'Minimap','Current route and upcoming targets.',4,-70,700,205)
    Toggle(c,'Show on minimap',16,-58,function() return db.showMinimap end,function(v) db.showMinimap=v end)
    Toggle(c,'Show distance',360,-58,function() return db.showDistance end,function(v) db.showDistance=v end)
    Slider(c,'Marker size',16,-120,300,8,32,1,function() return db.minimapTargetSize or 14 end,function(v) db.minimapTargetSize=v end,function(v) return v..' px' end)
    Slider(c,'Animation speed',360,-120,300,.2,2,.1,function() return db.minimapAnimationSpeed or .5 end,function(v) db.minimapAnimationSpeed=v end,function(v) return string.format('%.1fx',v) end)
    c2=Card(p,'World Map','Route lines, target marker and objective overlays.',4,-290,700,205)
    Toggle(c2,'Show on world map',16,-58,function() return db.showWorldMap end,function(v) db.showWorldMap=v end)
    Toggle(c2,'Quest object markers',360,-58,function() return db.showObjectMarkers ~= false end,function(v) db.showObjectMarkers=v end)
    Slider(c2,'Marker size',16,-120,300,8,32,1,function() return db.worldTargetSize or 14 end,function(v) db.worldTargetSize=v end,function(v) return v..' px' end)
    Slider(c2,'Animation speed',360,-120,300,.2,2,.1,function() return db.worldAnimationSpeed or .5 end,function(v) db.worldAnimationSpeed=v end,function(v) return string.format('%.1fx',v) end)

    p=NewPage('corpse','Corpse Run','Visual guidance while dead or ghosted.')
    c=Card(p,'Corpse navigation','Dedicated corpse visuals keep normal navigation readable.',4,-70,700,220)
    Slider(c,'HUD skull size',16,-58,300,12,64,2,function() return db.corpseHudSkullSize or 24 end,function(v) db.corpseHudSkullSize=v end,function(v) return v..' px' end)
    Slider(c,'Route skull size',360,-58,300,8,36,1,function() return db.corpseRouteSkullSize or 14 end,function(v) db.corpseRouteSkullSize=v end,function(v) return v..' px' end)
    Slider(c,'Skull opacity',16,-130,300,.1,1,.05,function() return db.corpseSkullAlpha or .3 end,function(v) db.corpseSkullAlpha=v end,function(v) return string.format('%d%%',v*100) end)
    Slider(c,'Animation speed',360,-130,300,.2,2,.1,function() return db.corpseAnimationSpeed or .5 end,function(v) db.corpseAnimationSpeed=v end,function(v) return string.format('%.1fx',v) end)

    p=NewPage('advanced','Advanced','Diagnostics and explicit test tools. No protected API bypasses.')
    c=Card(p,'Diagnostics','Troubleshooting tools that do not alter Blizzard nameplate CVars.',4,-70,700,215)
    Button(c,'NPC Anchor Test',16,-62,160,function() if Navigator.WorldMarkerVisual then Navigator.WorldMarkerVisual:StartNPCTest('target') end end)
    Button(c,'Stop NPC Test',190,-62,150,function() if Navigator.WorldMarkerVisual then Navigator.WorldMarkerVisual:StopNPCTest() end end)
    Button(c,'Map Diagnostics',355,-62,160,function() if API.PrintMapDiagnostics then API:PrintMapDiagnostics(true) end end)
    Button(c,'Bug Report',530,-62,140,function() if API.GenerateBugReport then API:GenerateBugReport() end end)
    Text(c,'GameFontDisableSmall','Safety: no automated combat, no protected API bypasses, no restricted nameplate geometry reads, and no automatic nameplate-CVar changes.',16,-125,650):SetTextColor(unpack(MUTED))

    p=NewPage('info','Info','About RestedXP-Navigator, its creator and recent changes.')
    c=Card(p,'RestedXP-Navigator','Navigation companion for RestedXP Guides on WoW Forever.',4,-70,700,235)
    Text(c,'GameFontNormal','Created by',16,-62,110)
    local author=Text(c,'GameFontHighlight','Fabian aka Nimri',125,-62,260); author:SetTextColor(.35,.85,1)
    Text(c,'GameFontNormal','Version',16,-94,110)
    Text(c,'GameFontHighlight','v'..Version(),125,-94,220)

    Text(c,'GameFontNormal','CurseForge',16,-126,110)
    local cfText=Text(c,'GameFontHighlightSmall',CURSEFORGE_PROFILE_URL,125,-127,410)
    cfText:SetTextColor(.55,.82,1.00)
    Button(c,'Open CurseForge',545,-121,135,function()
        OpenExternalURL(CURSEFORGE_PROFILE_URL)
    end)

    Text(c,'GameFontHighlightSmall','Built as a focused navigation layer: HUD guidance, minimap/world-map routes, Blizzard-style in-world markers and corpse-run navigation.',16,-168,650):SetTextColor(.82,.85,.90)

    c2=Card(p,"What's New",'Recent changes in the current development line.',4,-320,700,250)

    local scroll=CreateFrame('ScrollFrame',nil,c2,'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT',16,-62)
    scroll:SetPoint('BOTTOMRIGHT',-34,16)

    local scrollChild=CreateFrame('Frame',nil,scroll)
    scrollChild:SetSize(630,1)
    scroll:SetScrollChild(scrollChild)

    local whats=Text(scrollChild,'GameFontHighlight',
[[v1.6.11
• What's New is now scrollable and stays inside the Info panel.
• CurseForge button renamed to “Open CurseForge”.
• Uses a client-provided URL opener when one is available; otherwise shows a safe copyable-link fallback.

v1.6.10
• Info page now shows “Fabian aka Nimri” as creator.
• Added the CurseForge profile link for nimri82.

v1.6.9
• Redesigned Control Center with a fixed World Marker preview.
• New profile system: one profile for all characters or per-character selection.
• Create, save and delete custom profiles.
• Expanded marker customization: scale, beam range, NPC range, ring size and opacity.
• Optional custom colors for interaction, travel, combat and default markers.
• Separate custom floor-ring color.
• Added this Info / What's New page.

v1.6.8
• Returned to Blizzard-native PingUI marker assets.
• Green Assist markers for interactions, blue travel arrow, orange combat sword and blue default diamond.
• Kept the RestedXP-Navigator ground ring for visual floor contact.]],0,0,610)
    whats:SetJustifyH('LEFT')
    whats:SetJustifyV('TOP')

    local function UpdateWhatsNewHeight()
        local h=math.max(1,whats:GetStringHeight()+12)
        scrollChild:SetHeight(h)
    end
    scrollChild:SetScript('OnShow',UpdateWhatsNewHeight)
    C_Timer.After(0,UpdateWhatsNewHeight)
end

local function SelectPage(key)
    activePage=key
    for k,p in pairs(pages) do p:SetShown(k==key) end
    for k,b in pairs(pageButtons) do
        if k==key then b.bg:SetColorTexture(ACCENT[1],ACCENT[2],ACCENT[3],.20); b.label:SetTextColor(.65,.90,1)
        else b.bg:SetColorTexture(0,0,0,0); b.label:SetTextColor(.75,.78,.84) end
    end
end

local function SidebarButton(parent,key,label,index)
    local b=CreateFrame('Button',nil,parent); b:SetPoint('TOPLEFT',12,-78-(index-1)*41); b:SetSize(188,36)
    b.bg=b:CreateTexture(nil,'BACKGROUND'); b.bg:SetAllPoints()
    b.label=Text(b,'GameFontHighlight',label,14,-10,160)
    b:SetScript('OnEnter',function(self) if key~=activePage then self.bg:SetColorTexture(1,1,1,.04) end end)
    b:SetScript('OnLeave',function(self) if key~=activePage then self.bg:SetColorTexture(0,0,0,0) end end)
    b:SetScript('OnClick',function() SelectPage(key) end)
    pageButtons[key]=b
end

local function BuildWindow()
    if window then return window end
    SyncDB(); if API.EnsureProfiles then API:EnsureProfiles() end
    local f=CreateFrame('Frame','RXPNavigatorControlCenter',UIParent,'BackdropTemplate')
    f:SetSize(980,720); f:SetPoint('CENTER'); f:SetFrameStrata('DIALOG'); f:SetClampedToScreen(true)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart',f.StartMoving); f:SetScript('OnDragStop',f.StopMovingOrSizing)
    Backdrop(f,PANEL[1],PANEL[2],PANEL[3],PANEL[4],{.16,.18,.23,1}); table.insert(UISpecialFrames,'RXPNavigatorControlCenter')

    local top=f:CreateTexture(nil,'ARTWORK'); top:SetPoint('TOPLEFT'); top:SetPoint('TOPRIGHT'); top:SetHeight(3); top:SetColorTexture(unpack(ACCENT))
    local title=Text(f,'GameFontNormalHuge','RestedXP-Navigator',20,-18,500); title:SetTextColor(.95,.97,1)
    local ver=Text(f,'GameFontDisableSmall','v'..Version(),20,-48,120); ver:SetTextColor(unpack(MUTED))
    local close=CreateFrame('Button',nil,f,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-8,-8)

    f.sidebar=CreateFrame('Frame',nil,f); f.sidebar:SetPoint('TOPLEFT',0,-64); f.sidebar:SetPoint('BOTTOMLEFT'); f.sidebar:SetWidth(212)
    local sb=f.sidebar:CreateTexture(nil,'BACKGROUND'); sb:SetAllPoints(); sb:SetColorTexture(.035,.042,.055,.96)
    local div=f:CreateTexture(nil,'BORDER'); div:SetPoint('TOPLEFT',212,-64); div:SetPoint('BOTTOMLEFT',212,0); div:SetWidth(1); div:SetColorTexture(.16,.18,.22,1)

    f.content=CreateFrame('Frame',nil,f); f.content:SetPoint('TOPLEFT',232,-78); f.content:SetPoint('BOTTOMRIGHT',-28,22)

    local nav={
        {'general','General'},{'profiles','Profiles'},{'navigation','Navigation'},
        {'worldmarker','World Marker'},{'appearance','Appearance'},{'maps','Maps'},
        {'corpse','Corpse Run'},{'advanced','Advanced'},{'info','Info'}
    }
    for i,v in ipairs(nav) do SidebarButton(f.sidebar,v[1],v[2],i) end
    window=f; BuildPages(); SelectPage('general')
    f:SetScript('OnShow',function()
        SyncDB(); if API.EnsureProfiles then API:EnsureProfiles() end
        for _,r in ipairs(refreshers) do if r and r.Refresh then r:Refresh() end end
        SelectPage(activePage)
    end)
    f:Hide()
    return f
end

function CC:Open(page)
    local f=BuildWindow(); SyncDB()
    if page and pages[page] then activePage=page end
    f:Show(); for _,r in ipairs(refreshers) do if r and r.Refresh then r:Refresh() end end; SelectPage(activePage)
end
function CC:Toggle() local f=BuildWindow(); if f:IsShown() then f:Hide() else self:Open() end end
function CC:Refresh() if window and window:IsShown() then SyncDB(); for _,r in ipairs(refreshers) do if r and r.Refresh then r:Refresh() end end end end

if Navigator.Options then
    Navigator.Options.Open=function() CC:Open() end
    Navigator.Options.Refresh=function() CC:Refresh() end
end
