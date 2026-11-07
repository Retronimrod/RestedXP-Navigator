local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API then return end
local API = Navigator.API
local Layout = {frames = {}, proxies = {}}
Navigator.LayoutEditor = Layout
local definitions = {
    {id='HUD', title='Navigation Arrow', width=190, height=136},
    {id='Header', title='Target header', width=330, height=44},
    {id='Group', title='Group markers', width=330, height=28},
}
local working, baseline, owner, panel, selected, ui = nil, nil, nil, nil, 'HUD', {}
local applying, pending = false, false
local function T(text) return API:Localize(text) end
local function Combat() return InCombatLockdown and InCombatLockdown() end
local function Settings() return working or API:GetDB() or {} end
local function Key(id, field) return 'layout' .. id .. field end
function Layout:GetScale(id)
    local value=tonumber(Settings()[Key(id,'Scale')]) or 1
    if value~=value then value=1 end
    return math.max(.6,math.min(1.6,value))
end
local function Definition(id)
    for _, definition in ipairs(definitions) do if definition.id == id then return definition end end
end
local function Clamp(value, low, high) return math.max(low, math.min(high, value)) end
local function Copy(source)
    local result = {}
    for _, d in ipairs(definitions) do
        for _, field in ipairs({'X','Y','Scale'}) do result[Key(d.id,field)] = source[Key(d.id,field)] end
    end
    -- Legacy HUD coordinates are only read to preserve existing installations.
    for _, field in ipairs({'hudPoint','hudRelativePoint','hudX','hudY'}) do result[field] = source[field] end
    return result
end
local points = {BOTTOMLEFT={0,0},BOTTOM={.5,0},BOTTOMRIGHT={1,0},LEFT={0,.5},CENTER={.5,.5},RIGHT={1,.5},TOPLEFT={0,1},TOP={.5,1},TOPRIGHT={1,1}}
function Layout:GetGeometry(id, settings)
    local d = Definition(id)
    local w,h = UIParent:GetWidth(), UIParent:GetHeight()
    local target=self.frames[id]
    local width,height=d.width,d.height
    if target then width=target:GetWidth() or width;height=target:GetHeight() or height end
    local scale = tonumber(settings[Key(id,'Scale')]) or 1
    if scale ~= scale then scale = 1 end
    scale = Clamp(scale,.6,1.6)
    local x,y = tonumber(settings[Key(id,'X')]), tonumber(settings[Key(id,'Y')])
    if not x or not y or x ~= x or y ~= y or x < 0 or y < 0 then
        x,y = w/2, h-(id=='Header' and 64 or 104)
        if id=='HUD' then
            local relative = points[settings.hudRelativePoint or settings.hudPoint or 'TOP'] or points.TOP
            local anchor = points[settings.hudPoint or 'TOP'] or points.TOP
            x = w*relative[1]+(tonumber(settings.hudX) or 0)+(0.5-anchor[1])*width*scale
            y = h*relative[2]+(tonumber(settings.hudY) or -120)+(0.5-anchor[2])*height*scale
        end
    else x,y = x*w, y*h end
    local halfW,halfH = math.min(w/2,width*scale/2),math.min(h/2,height*scale/2)
    return Clamp(x,halfW,w-halfW),Clamp(y,halfH,h-halfH),scale
end
function Layout:ApplyFrame(id, frame)
    if not frame then return end
    if Combat() then pending=true; return end
    local x,y,scale = self:GetGeometry(id,Settings())
    frame:SetScale(scale)
    frame:SetClampedToScreen(true)
    frame:ClearAllPoints()
    frame:SetPoint('CENTER',UIParent,'BOTTOMLEFT',x/scale,y/scale)
end
function Layout:Register(id, frame)
    self.frames[id] = frame
    self:ApplyFrame(id,frame)
end
function Layout:ApplyAll()
    if Combat() then pending=true; return end
    pending=false
    for id,frame in pairs(self.frames) do self:ApplyFrame(id,frame) end
    for id,frame in pairs(self.proxies) do
        local target=self.frames[id]
        if target then frame:SetSize(target:GetWidth(),target:GetHeight()) end
        self:ApplyFrame(id,frame)
    end
end
function Layout:IsEditing() return working ~= nil end
function Layout:SavePosition(id, frame)
    if Combat() then return end
    local target=working or API:GetDB()
    if not target then return end
    local ratio = frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y = frame:GetCenter()
    if not x or not y then return end
    target[Key(id,'X')] = Clamp(x*ratio/UIParent:GetWidth(),0,1)
    target[Key(id,'Y')] = Clamp(y*ratio/UIParent:GetHeight(),0,1)
    self:ApplyAll(); self:RefreshControls()
    if not working and API.SaveActiveProfile then API:SaveActiveProfile() end
end
local function Label(parent, text, x,y,width)
    local label=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    label:SetPoint('TOPLEFT',x,y);label:SetWidth(width);label:SetJustifyH('LEFT');label:SetWordWrap(true);label:SetText(T(text))
    return label
end
local function Button(parent,text,x,y,width,fn)
    local button=Navigator.UI and Navigator.UI:Button(parent,text,width,28) or CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    button:SetPoint('TOPLEFT',x,y);button:SetSize(width,26);button:SetText(T(text));button:SetScript('OnClick',fn)
    local label=button:GetFontString()
    if label then label:SetScale(math.min(1,(width-12)/math.max(1,label:GetStringWidth()))) end
    return button
end
function Layout:Select(id)
    selected=id
    for key,proxy in pairs(self.proxies) do proxy.bg:SetColorTexture(.03,.12,.18,key==id and .96 or .82) end
    self:RefreshControls()
end
function Layout:RefreshControls()
    if not panel or not working then return end
    applying=true
    local x,y,scale=self:GetGeometry(selected,working)
    ui.title:SetText(T(Definition(selected).title))
    ui.x:SetText(tostring(math.floor(x+.5)));ui.y:SetText(tostring(math.floor(y+.5)))
    ui.scale:SetValue(scale);ui.value:SetText(string.format('%d%%',math.floor(scale*100+.5)))
    applying=false
end
function Layout:ResetSelected()
    if not working then return end
    working[Key(selected,'X')],working[Key(selected,'Y')],working[Key(selected,'Scale')]=-1,-1,1
    if selected=='HUD' then working.hudPoint='TOP';working.hudRelativePoint='TOP';working.hudX=0;working.hudY=-120 end
    self:ApplyAll();self:RefreshControls()
end
function Layout:Commit()
    if not working or Combat() then return end
    local db=API:GetDB()
    if not db then return end
    for key,value in pairs(working) do db[key]=value end
    baseline=Copy(db)
    if API.SaveActiveProfile then API:SaveActiveProfile() end
end
function Layout:Revert()
    if not working then return end
    working=Copy(baseline);self:ApplyAll();self:RefreshControls()
end
function Layout:Finish(save)
    if not working then return end
    if save then self:Commit() end
    working,baseline,owner=nil,nil,nil
    for _,proxy in pairs(self.proxies) do proxy:StopMovingOrSizing();proxy:Hide() end
    if panel then panel:Hide() end
    self:ApplyAll()
    if not Combat() and API.RefreshAll then API:RefreshAll() end
    if Navigator.SetupWizard and Navigator.SetupWizard.OnLayoutClosed then Navigator.SetupWizard:OnLayoutClosed() end
end
local function Build()
    if panel then return end
    panel=CreateFrame('Frame','RXPNavigatorLayoutPanel',UIParent,'BackdropTemplate')
    panel:SetSize(430,300);panel:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-30,170)
    if Navigator.UI then Navigator.UI:Window(panel,430,300) end
    panel:SetFrameStrata('DIALOG');panel:SetClampedToScreen(true);panel:SetMovable(true);panel:EnableMouse(true);panel:RegisterForDrag('LeftButton')
    panel:SetScript('OnDragStart',panel.StartMoving);panel:SetScript('OnDragStop',panel.StopMovingOrSizing)
    if not Navigator.UI then local bg=panel:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.025,.035,.05,.98) end
    Label(panel,'RestedXP-Navigator',14,-12,395)
    Label(panel,'Drag the frames. Save or discard your changes here.',14,-35,395)
    for i,d in ipairs(definitions) do
        local id=d.id
        Button(panel,d.title,14+(i-1)*136,-75,130,function() Layout:Select(id) end)
        local proxy=CreateFrame('Frame',nil,UIParent,'BackdropTemplate');Layout.proxies[id]=proxy
        proxy:SetSize(d.width,d.height);proxy:SetFrameStrata('HIGH');proxy:SetFrameLevel(150)
        proxy:SetMovable(true);proxy:SetClampedToScreen(true);proxy:EnableMouse(true);proxy:RegisterForDrag('LeftButton')
        proxy.bg=proxy:CreateTexture(nil,'BACKGROUND');proxy.bg:SetAllPoints();proxy.bg:SetColorTexture(.03,.12,.18,.9)
        local outline=proxy:CreateTexture(nil,'OVERLAY');outline:SetAllPoints();outline:SetColorTexture(.1,.7,1,.12)
        local label=Label(proxy,d.title,6,-5,d.width-12)
        if id=='HUD' then
            local arrow=proxy:CreateTexture(nil,'ARTWORK');arrow:SetTexture('Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_HUDArrow2D_Classic.tga')
            arrow:SetSize(48,48);arrow:SetPoint('CENTER',0,9)
            Label(proxy,'1/8',6,-86,d.width-12)
            Label(proxy,'Preview',6,-110,d.width-12)
        elseif id=='Header' then Label(proxy,'Preview',6,-24,d.width-12) end
        proxy:SetScript('OnDragStart',function(self)
            if not Combat() then Layout:Select(id);self:StartMoving() end
        end)
        proxy:SetScript('OnDragStop',function(self) self:StopMovingOrSizing();Layout:SavePosition(id,self) end)
        proxy:SetScript('OnMouseDown',function() Layout:Select(id) end)
        proxy:Hide()
    end
    ui.title=Label(panel,'Navigation Arrow',14,-112,395)
    local function Coordinate(field,x,label)
        Label(panel,label,x,-140,180)
        local box=CreateFrame('EditBox',nil,panel,Navigator.UI and 'BackdropTemplate' or 'InputBoxTemplate')
        if Navigator.UI then Navigator.UI:Panel(box);box:SetFontObject('GameFontHighlight');box:SetTextInsets(8,8,0,0) end
        box:SetPoint('TOPLEFT',x,-160);box:SetSize(180,24);box:SetAutoFocus(false);box:SetMaxLetters(8)
        local function changed(self)
            local value=tonumber(self:GetText())
            if value and working and not Combat() then
                working[Key(selected,field)]=Clamp(value/(field=='X' and UIParent:GetWidth() or UIParent:GetHeight()),0,1)
                -- Set both coordinates when migrating from legacy anchors.
                local px,py=Layout:GetGeometry(selected,working)
                if (tonumber(working[Key(selected,'X')]) or -1)<0 then working[Key(selected,'X')]=px/UIParent:GetWidth() end
                if (tonumber(working[Key(selected,'Y')]) or -1)<0 then working[Key(selected,'Y')]=py/UIParent:GetHeight() end
                working[Key(selected,field)]=Clamp(value/(field=='X' and UIParent:GetWidth() or UIParent:GetHeight()),0,1)
                Layout:ApplyAll();Layout:RefreshControls()
            end
            self:ClearFocus()
        end
        box:SetScript('OnEnterPressed',changed);box:SetScript('OnEditFocusLost',changed)
        ui[field:lower()]=box
    end
    Coordinate('X',18,'Horizontal position');Coordinate('Y',230,'Vertical position')
    Label(panel,'Scale',18,-195,160)
    ui.value=Label(panel,'100%',330,-195,80)
    ui.scale=Navigator.UI and Navigator.UI:Slider(panel) or CreateFrame('Slider',nil,panel,'OptionsSliderTemplate');ui.scale:SetPoint('TOPLEFT',18,-222);ui.scale:SetWidth(390)
    ui.scale:SetMinMaxValues(.6,1.6);ui.scale:SetValueStep(.05)
    if ui.scale.SetObeyStepOnDrag then ui.scale:SetObeyStepOnDrag(true) end
    for _,part in ipairs({'Low','High','Text'}) do if ui.scale[part] then ui.scale[part]:SetText('') end end
    ui.scale:SetScript('OnValueChanged',function(_,value)
        if applying or not working or Combat() then return end
        working[Key(selected,'Scale')]=Clamp(math.floor(value*20+.5)/20,.6,1.6)
        Layout:ApplyAll();Layout:RefreshControls()
    end)
    Button(panel,'Reset position',14,-264,130,function() Layout:ResetSelected() end)
    Button(panel,'Save',150,-264,130,function() Layout:Commit();if owner=='native' then Layout:RefreshControls() else Layout:Finish(false) end end)
    Button(panel,'Cancel',286,-264,130,function() Layout:Finish(false) end)
    panel:SetScript('OnHide',function() if working then Layout:Finish(false) end end)
    if UISpecialFrames then table.insert(UISpecialFrames,'RXPNavigatorLayoutPanel') end
    panel:Hide()
end
function Layout:Begin(mode)
    if Combat() then API:Print(T('Layout editing is unavailable during combat.'));return false end
    if working then return true end
    local db=API:GetDB();if not db then return false end
    Build()
    baseline=Copy(db);working=Copy(db);owner=mode or 'addon'
    self:ApplyAll();panel:Show()
    for _,frame in pairs(self.frames) do frame:Hide() end
    for _,proxy in pairs(self.proxies) do proxy:Show() end
    self:Select('HUD')
    return true
end
function Layout:Open()
    local cc=_G.RXPNavigatorControlCenter
    if cc then cc:Hide() end
    return self:Begin('addon')
end
-- Public edit-mode events, not insertion into Blizzard's internal system list.
if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback('EditMode.Enter',function() Layout:Begin('native') end,Layout)
    EventRegistry:RegisterCallback('EditMode.SavedLayouts',function() if owner=='native' then Layout:Commit() end end,Layout)
    EventRegistry:RegisterCallback('EditMode.Exit',function() if owner=='native' then Layout:Finish(false) end end,Layout)
end
local hookedManager
local function HookNativeRevert()
    local manager=_G.EditModeManagerFrame
    if manager and manager~=hookedManager and type(manager.RevertAllChanges)=='function' and hooksecurefunc then
        hookedManager=manager
        hooksecurefunc(manager,'RevertAllChanges',function() if owner=='native' then Layout:Revert() end end)
    end
end
HookNativeRevert()
local events=CreateFrame('Frame')
for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','DISPLAY_SIZE_CHANGED','UI_SCALE_CHANGED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event)
    if event=='ADDON_LOADED' then HookNativeRevert();return end
    if event=='PLAYER_REGEN_DISABLED' then Layout:Finish(false);return end
    if event=='PLAYER_LOGIN' then
        if _G.RXPNavigatorHUDArrow then Layout:Register('HUD',_G.RXPNavigatorHUDArrow) end
        if _G.RXPNavigatorWorldMarkerHeader then Layout:Register('Header',_G.RXPNavigatorWorldMarkerHeader) end
        if _G.RXPNavigatorGroupMarkers then Layout:Register('Group',_G.RXPNavigatorGroupMarkers) end
    end
    Layout:ApplyAll()
    if working then Layout:RefreshControls() end
end)
