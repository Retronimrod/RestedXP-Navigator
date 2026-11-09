local Navigator = _G.RXPNavigator
if not Navigator or not Navigator.API or not Navigator.UI then return end
local API,UI = Navigator.API,Navigator.UI
local Wizard = {}
Navigator.SetupWizard = Wizard
local VERSION = 1
local window,body,backButton,nextButton,stepLabel,preview
local profileMode,profileName,overwriteConfirmed,errorMessage,nameBusy
local profileEdit,overwriteCheck,overwriteLabel,profileMessage
local draft,step,furthest,suspended,pending = nil,1,1,false,false
local stepButtons={}
local steps={
    {title='Welcome',description='Set up your navigation in a few short steps.'},
    {title='Navigation',description='On-screen arrow, distance and ETA guidance.'},
    {title='World Marker',description='Uses the same artwork and settings as your personal world marker.'},
    {title='Group quest messages',description='Only sent to your group. Solo play stays silent.'},
    {title='Edit layout',description='Move and scale your HUD in edit mode.'},
    {title='Ready',description='Review your choices, then finish setup.'},
}
local keys={'enabled','profileUseGlobal','showHUDArrow','hudShowDistance','hudShowETA','showMinimap','showWorldMap','showMinimapButton',
    'showWorldMarkerNative','showWorldMarkerHeader','showWorldMarkerDistance','showWorldMarkerBeam','worldMarkerHideBlizzard',
    'questChatProgress','questChatCompletion','questChatAllQuests'}
local allowed={};for _,key in ipairs(keys) do allowed[key]=true end
local controls={}
local pools={text={},check={},button={}}
local indices={text=0,check=0,button=0}
local function T(text) return API:Localize(text) end
local function Combat() return InCombatLockdown and InCombatLockdown() end
local function Label(parent,text,x,y,width,font) return UI:Label(parent,text,x,y,width,font) end
local function Button(parent,text,x,y,width,fn)
    local button=UI:Button(parent,text,width,30);button:SetPoint('TOPLEFT',x,y);button:SetScript('OnClick',fn);return button
end
local function ClearBody()
    for _,control in ipairs(controls) do control:Hide() end
    controls={}
    indices={text=0,check=0,button=0}
    if preview then preview:Hide() end
end
local function Keep(control) controls[#controls+1]=control;return control end
local function Text(text,x,y,width,font)
    indices.text=indices.text+1
    local label=pools.text[indices.text]
    if not label then label=Label(body,'',x,y,width,font);pools.text[indices.text]=label end
    label:ClearAllPoints();label:SetPoint('TOPLEFT',x,y);label:SetWidth(width)
    label:SetFontObject(font or 'GameFontHighlight');label:SetTextColor(1,1,1)
    label:SetText(T(text));label:Show();return Keep(label)
end
local function BodyButton(text,x,y,width,fn)
    indices.button=indices.button+1
    local button=pools.button[indices.button]
    if not button then button=UI:Button(body,'',width,30);pools.button[indices.button]=button end
    button:ClearAllPoints();button:SetPoint('TOPLEFT',x,y);button:SetSize(width,36)
    button:SetText(T(text));button:SetScript('OnClick',fn)
    button:Show();return Keep(button)
end
local function Toggle(key,text,x,y)
    indices.check=indices.check+1
    local check=pools.check[indices.check]
    if not check then check=UI:Checkbox(body);pools.check[indices.check]=check end
    check.optionKey=key
    Keep(check);check:ClearAllPoints();check:SetPoint('TOPLEFT',x,y);check:SetSize(285,34);check:SetChecked(draft[key]==true);check:Show()
    Text(text,x+29,y-3,248)
    check:SetScript('OnClick',function(self) Wizard:SetOption(key,self:GetChecked() and true or false) end)
end
function Wizard:GetOption(key) return draft and draft[key] end
function Wizard:SetOption(key,value)
    if not draft or not allowed[key] then return false end
    if type(value) ~= 'boolean' then return false end
    draft[key]=value
    for _,check in ipairs(pools.check) do if check.optionKey then check:SetChecked(draft[check.optionKey]==true) end end
    if preview and step==3 then Navigator.WorldMarkerVisual:RefreshPreview(preview,draft) end
    return true
end
function Wizard:IsOpen() return draft~=nil end
local function Target()
    return profileMode=='general' and 'Default' or tostring(profileName or ''):gsub('^%s+',''):gsub('%s+$','')
end
local function NeedsConfirmation()
    local db=API:GetDB() or {}
    local exists=API.ProfileExists and API:ProfileExists(Target()) or (db.profileStore and db.profileStore[Target()])~=nil
    local fresh=Navigator.isNewInstallation==true and not db.setupVersion and db.setupStatus=='pending' and profileMode=='general'
    return exists and not fresh
end
function Wizard:UpdateProfileControls()
    if not draft or step~=6 then return end
    local message=errorMessage
    local name=Target()
    if not message and profileMode=='personal' then
        if name=='' then message=T('Profile name is empty.')
        elseif name=='Default' then message=T('Choose a personal profile name other than Default.')
        elseif name:find('[%c|]') then message=T('Profile name contains invalid characters.')
        else local _,length=name:gsub('[%z\1-\127\194-\244]','');if length>32 then message=T('Profile names may contain up to 32 characters.') end end
    end
    local required=NeedsConfirmation()
    if overwriteCheck then overwriteCheck:SetEnabled(required);overwriteCheck:SetChecked(required and overwriteConfirmed or false) end
    if overwriteLabel then overwriteLabel:SetTextColor(required and 1 or .55,required and 1 or .6,required and 1 or .65) end
    if not message and required and not overwriteConfirmed then message=T('Profile already exists. Confirm replacement or choose another name.') end
    if profileMessage then profileMessage:SetText(message or '');profileMessage:SetTextColor(1,.76,.35) end
    nextButton:SetEnabled(not message)
end
function Wizard:ChooseProfile(mode)
    if not draft or (mode~='general' and mode~='personal') then return false end
    if mode~=profileMode then draft.profileUseGlobal=mode=='general' end
    profileMode,overwriteConfirmed,errorMessage=mode,false,nil
    self:Render();return true
end
function Wizard:SetProfileName(name)
    if not draft then return end
    profileName=tostring(name or '');overwriteConfirmed=false;errorMessage=nil;self:UpdateProfileControls()
end
function Wizard:SetOverwrite(value)
    overwriteConfirmed=value==true;errorMessage=nil;self:UpdateProfileControls()
end
local function Summary(label,enabled,y)
    Text(label,24,y,420)
    local value=Text(enabled and 'On' or 'Off',460,y,130)
    value:SetTextColor(enabled and .30 or .68,enabled and .88 or .72,enabled and .58 or .77)
end
function Wizard:Render()
    if not draft or not window then return end
    ClearBody()
    stepLabel:SetText(string.format(T('Step %d of %d'),step,#steps))
    for index,button in ipairs(stepButtons) do
        button:SetEnabled(index<=furthest)
        button.bg:SetColorTexture(index==step and .10 or .055,index==step and .24 or .075,index==step and .34 or .10,1)
    end
    Text(steps[step].title,24,-22,565,'GameFontNormalLarge')
    Text(steps[step].description,24,-56,565,'GameFontHighlightSmall')
    if step==1 then
        Text('Changes are applied only when you finish setup.',24,-116,565)
        Text('You can reopen this wizard from the settings at any time.',24,-158,565)
        Toggle('enabled','Enable RestedXP-Navigator',24,-226)
        Text('Choose where to save your profile in the final step.',24,-284,565,'GameFontHighlightSmall')
    elseif step==2 then
        Toggle('showHUDArrow','Show HUD arrow',24,-116)
        Toggle('hudShowDistance','Show distance',318,-116)
        Toggle('hudShowETA','Show ETA',24,-174)
        Toggle('showMinimap','Show on minimap',318,-174)
        Toggle('showWorldMap','Show on world map',24,-232)
        Toggle('showMinimapButton','Show minimap button',318,-232)
    elseif step==3 then
        if not preview then
            preview=Navigator.WorldMarkerVisual:CreatePreview(body)
            preview:ClearAllPoints();preview:SetPoint('CENTER',body,'TOPLEFT',138,-226)
        end
        Navigator.WorldMarkerVisual:RefreshPreview(preview,draft)
        Toggle('showWorldMarkerNative','Enable world marker',294,-114)
        Toggle('showWorldMarkerHeader','Show target header',294,-166)
        Toggle('showWorldMarkerDistance','Show distance',294,-218)
        Toggle('showWorldMarkerBeam','Show close-range beam',294,-270)
        Toggle('worldMarkerHideBlizzard','Hide duplicate Blizzard marker',294,-322)
        local navEnabled=true
        if C_CVar and C_CVar.GetCVar then local ok,value=pcall(C_CVar.GetCVar,'showInGameNavigation');navEnabled=not ok or tostring(value)=='1' end
        if not navEnabled then
            Text('World Marker: Blizzard In-Game Navigation is disabled. Enable it in the game settings to use in-world markers.',24,-380,565,'GameFontHighlightSmall')
        end
    elseif step==4 then
        Toggle('questChatProgress','Announce quest progress',24,-116)
        Toggle('questChatCompletion','Announce completed objectives and quests',24,-182)
        Toggle('questChatAllQuests','Include all quests in your quest log',24,-248)
        Text('By default, only quests from your current RestedXP step are announced.',24,-314,565,'GameFontHighlightSmall')
    elseif step==5 then
        Text('Position the target header, navigation arrow and group markers.',24,-116,565)
        Text('Layout changes are saved separately in the layout editor.',24,-172,565,'GameFontHighlightSmall')
        BodyButton('Edit layout',24,-242,260,function()
            if Combat() then return end
            suspended=true;window:Hide()
            if not Navigator.LayoutEditor:Open() then Wizard:OnLayoutClosed() end
        end)
    else
        Summary('Navigation Arrow',draft.showHUDArrow,-102)
        Summary('World Marker',draft.showWorldMarkerNative,-136)
        Summary('Announce quest progress',draft.questChatProgress,-170)
        Summary('Announce completed objectives and quests',draft.questChatCompletion,-204)
        local general=BodyButton('General profile',24,-244,274,function() Wizard:ChooseProfile('general') end)
        local personal=BodyButton('Personal profile',314,-244,274,function() Wizard:ChooseProfile('personal') end)
        general.bg:SetColorTexture(.08,.18,profileMode=='general' and .4 or .18,1)
        personal.bg:SetColorTexture(.08,.18,profileMode=='personal' and .4 or .18,1)
        if profileMode=='personal' then
            Text('New profile name',24,-298,152)
            if not profileEdit then
                profileEdit=CreateFrame('EditBox','RXPNavigatorSetupProfileName',body,'BackdropTemplate')
                UI:Panel(profileEdit);profileEdit:SetFontObject('GameFontHighlight');profileEdit:SetTextInsets(8,8,0,0)
                profileEdit:SetAutoFocus(false);profileEdit:SetMaxLetters(32)
                profileEdit:SetScript('OnTextChanged',function(self) if not nameBusy then Wizard:SetProfileName(self:GetText()) end end)
                profileEdit:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
            end
            Keep(profileEdit);profileEdit:ClearAllPoints();profileEdit:SetPoint('TOPLEFT',184,-292);profileEdit:SetSize(404,28)
            nameBusy=true;profileEdit:SetText(profileName or '');nameBusy=false;profileEdit:Show()
            Toggle('profileUseGlobal','Use one profile for all characters',24,-328)
        else Text('Shared by all characters.',24,-298,565) end
        indices.check=indices.check+1;overwriteCheck=pools.check[indices.check]
        if not overwriteCheck then overwriteCheck=UI:Checkbox(body);pools.check[indices.check]=overwriteCheck end
        overwriteCheck.optionKey=nil;Keep(overwriteCheck);overwriteCheck:Show();overwriteCheck:ClearAllPoints();overwriteCheck:SetPoint('TOPLEFT',24,-366);overwriteCheck:SetSize(565,32)
        overwriteLabel=Text('Replace existing profile',53,-369,520)
        overwriteCheck:SetScript('OnClick',function(self) Wizard:SetOverwrite(self:GetChecked()) end)
        profileMessage=Text('',24,-404,565,'GameFontHighlightSmall')
    end
    backButton:SetEnabled(step>1)
    nextButton:SetText(T(step==#steps and 'Finish setup' or 'Continue'))
    local text=nextButton:GetFontString()
    if text then text:SetScale(math.min(1,124/math.max(1,text:GetStringWidth()))) end
    if step==6 then self:UpdateProfileControls() else nextButton:Enable() end
end
function Wizard:GoTo(index)
    if not draft then return end
    step=math.max(1,math.min(#steps,index));furthest=math.max(furthest,step);self:Render()
end
function Wizard:Skip()
    if not draft then return end
    local db=API:GetDB()
    if db then db.setupVersion=VERSION;db.setupStatus='skipped' end
    draft=nil;suspended=false
    if window then window:Hide() end
    if preview then preview:Hide() end
end
function Wizard:Complete()
    if not draft then return false end
    if Combat() then API:Print(T('Setup is unavailable during combat.'));return false end
    local db=API:GetDB();if not db then return false end
    local name=Target()
    if profileMode=='personal' and name=='Default' then errorMessage=T('Choose a personal profile name other than Default.');self:Render();return false end
    local values={};for _,key in ipairs(keys) do if key~='profileUseGlobal' then values[key]=draft[key] end end
    local global=profileMode=='general' or draft.profileUseGlobal==true
    local ok,message=API:SaveSetupProfile(values,name,global,overwriteConfirmed or not NeedsConfirmation())
    if not ok then errorMessage=message;self:Render();return false end
    db=API:GetDB();db.setupVersion=VERSION;db.setupStatus='completed'
    draft=nil;suspended=false;window:Hide();if preview then preview:Hide() end
    if API.SaveActiveProfile then API:SaveActiveProfile() end
    API:RefreshAll()
    API:Print(T('Setup complete. Your settings have been saved.'))
    if Navigator.ControlCenter then Navigator.ControlCenter:Open('general') end
    return true
end
local function Build()
    if window then return end
    window=CreateFrame('Frame','RXPNavigatorSetupWizard',UIParent,'BackdropTemplate')
    window:SetSize(860,620);window:SetPoint('CENTER');window:SetFrameStrata('DIALOG');UI:Window(window,860,620)
    window:SetMovable(true);window:EnableMouse(true);window:RegisterForDrag('LeftButton')
    window:SetScript('OnDragStart',window.StartMoving);window:SetScript('OnDragStop',window.StopMovingOrSizing)
    local logo=window:CreateTexture(nil,'ARTWORK');logo:SetSize(36,36);logo:SetPoint('TOPLEFT',20,-16)
    logo:SetTexture('Interface\\AddOns\\RXP_Navigator\\Media\\RXPNav_IconRound.tga')
    Label(window,'RestedXP-Navigator',68,-18,650,'GameFontNormalLarge')
    Label(window,'Setup wizard',68,-42,650,'GameFontHighlightSmall')
    local close=CreateFrame('Button',nil,window,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-7,-8);close:SetScript('OnClick',function() Wizard:Skip() end)
    stepLabel=Label(window,'',212,-87,620,'GameFontNormal')
    body=CreateFrame('Frame',nil,window);body:SetPoint('TOPLEFT',210,-114);body:SetSize(626,430);UI:Panel(body)
    for index,entry in ipairs(steps) do
        local target=index
        local button=Button(window,entry.title,16,-114-(index-1)*56,176,function() if target<=furthest then Wizard:GoTo(target) end end)
        button:SetHeight(42);stepButtons[index]=button
    end
    Button(window,'Skip setup',16,-570,176,function() Wizard:Skip() end)
    backButton=Button(window,'Back',210,-570,140,function() Wizard:GoTo(step-1) end)
    nextButton=Button(window,'Continue',696,-570,140,function() if step==#steps then Wizard:Complete() else Wizard:GoTo(step+1) end end)
    if UISpecialFrames then table.insert(UISpecialFrames,'RXPNavigatorSetupWizard') end
    window:Hide()
    window:SetScript('OnHide',function() if draft and not suspended then Wizard:Skip() end end)
end
function Wizard:Open()
    if Combat() then API:Print(T('Setup is unavailable during combat.'));return false end
    if draft then if not suspended then window:Show() end;return true end
    if Navigator.LayoutEditor and Navigator.LayoutEditor:IsEditing() then Navigator.LayoutEditor:Finish(false) end
    local cc=_G.RXPNavigatorControlCenter;if cc then cc:Hide() end
    local db=API:GetDB();if not db then return false end
    Build();UI:Fit(window,860,620)
    draft={}
    for key,value in pairs(API:GetDefaults() or {}) do if type(value)~='table' then draft[key]=value end end
    for key,value in pairs(db) do if type(value)~='table' then draft[key]=value end end
    local active=API.GetActiveProfileName and API:GetActiveProfileName() or 'Default'
    profileMode=active=='Default' and 'general' or 'personal'
    profileName=active~='Default' and active or (UnitName and UnitName('player')) or (API.GetCharacterProfileKey and API:GetCharacterProfileKey() or '')
    overwriteConfirmed,errorMessage=false,nil
    step,furthest,suspended=1,1,false
    window:Show();self:Render();return true
end
function Wizard:OnLayoutClosed()
    if not draft or not suspended then return end
    if Combat() then pending=true;return end
    suspended=false;window:Show();self:Render()
end
function Wizard:MaybeStart()
    local db=API:GetDB();if not db then return end
    if (tonumber(db.setupVersion) or 0)>=VERSION then return end
    if Navigator.isNewInstallation~=true and db.setupStatus~='pending' then db.setupVersion=VERSION;db.setupStatus='existing';return end
    db.setupStatus='pending'
    if Combat() then pending=true;return end
    pending=false;self:Open()
end
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_LOGIN');events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:SetScript('OnEvent',function(_,event)
    if event=='PLAYER_LOGIN' then C_Timer.After(1,function() Wizard:MaybeStart() end)
    elseif pending then pending=false;if suspended then Wizard:OnLayoutClosed() else Wizard:MaybeStart() end end
end)
