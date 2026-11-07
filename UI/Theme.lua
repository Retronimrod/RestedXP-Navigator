local Navigator = _G.RXPNavigator
if not Navigator then return end
local UI = {colors={background={.035,.043,.057,.99},card={.065,.079,.101,.98},border={.14,.19,.24,1},accent={.12,.72,1,1},muted={.62,.69,.77,1}}}
Navigator.UI = UI
local function Texture(parent,layer,color)
    local texture=parent:CreateTexture(nil,layer or 'BACKGROUND');texture:SetColorTexture(unpack(color));return texture
end
function UI:Panel(frame, color, border)
    local bg=Texture(frame,'BACKGROUND',color or self.colors.card);bg:SetAllPoints()
    for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
        local line=Texture(frame,'BORDER',border or self.colors.border)
        if side=='TOP' or side=='BOTTOM' then
            line:SetPoint(side..'LEFT');line:SetPoint(side..'RIGHT');line:SetHeight(1)
        else line:SetPoint('TOP'..side);line:SetPoint('BOTTOM'..side);line:SetWidth(1) end
    end
    return bg
end
function UI:Fit(frame,width,height)
    local scale=math.min(1,(UIParent:GetWidth()-32)/width,(UIParent:GetHeight()-32)/height)
    frame:SetScale(math.max(.1,scale))
    frame:SetClampedToScreen(true)
end
function UI:Window(frame,width,height)
    self:Panel(frame,self.colors.background)
    local header=Texture(frame,'BACKGROUND',{.055,.074,.098,1});header:SetPoint('TOPLEFT',1,-1);header:SetPoint('TOPRIGHT',-1,-1);header:SetHeight(64)
    local line=Texture(frame,'BORDER',self.colors.accent);line:SetPoint('TOPLEFT');line:SetPoint('TOPRIGHT');line:SetHeight(2)
    self:Fit(frame,width,height)
    frame:RegisterEvent('DISPLAY_SIZE_CHANGED');frame:RegisterEvent('UI_SCALE_CHANGED')
    frame:HookScript('OnEvent',function() UI:Fit(frame,width,height) end)
end
function UI:Label(parent,text,x,y,width,font)
    local label=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlight')
    label:SetPoint('TOPLEFT',x,y);label:SetWidth(width);label:SetJustifyH('LEFT');label:SetWordWrap(true)
    label:SetText(Navigator.API:Localize(text or ''));return label
end
function UI:Button(parent,text,width,height)
    local button=CreateFrame('Button',nil,parent)
    button:SetSize(width or 150,height or 28);button:SetNormalFontObject('GameFontHighlight')
    button:SetDisabledFontObject('GameFontDisable');button:SetHighlightFontObject('GameFontNormal')
    button.bg=self:Panel(button,{.09,.13,.18,1})
    button:SetText(Navigator.API:Localize(text))
    button:SetScript('OnEnter',function(self) self.bg:SetColorTexture(.12,.22,.30,1) end)
    button:SetScript('OnLeave',function(self) self.bg:SetColorTexture(.09,.13,.18,1) end)
    local label=button:GetFontString()
    if label then label:SetScale(math.min(1,((width or 150)-16)/math.max(1,label:GetStringWidth()))) end
    return button
end
function UI:Checkbox(parent)
    local button=CreateFrame('CheckButton',nil,parent)
    button:SetSize(310,32)
    -- All layers belong to the button itself: a child Frame would cover the
    -- checked texture even when that texture uses the ARTWORK draw layer.
    local background=button:CreateTexture(nil,'BACKGROUND')
    background:SetPoint('TOPLEFT',1,-1);background:SetSize(20,20);background:SetColorTexture(.035,.05,.07,1)
    for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
        local edge=Texture(button,'BORDER',self.colors.border)
        if side=='TOP' or side=='BOTTOM' then
            edge:SetPoint(side..'LEFT',background,side..'LEFT');edge:SetPoint(side..'RIGHT',background,side..'RIGHT');edge:SetHeight(1)
        else edge:SetPoint('TOP'..side,background,'TOP'..side);edge:SetPoint('BOTTOM'..side,background,'BOTTOM'..side);edge:SetWidth(1) end
    end
    button:SetScript('OnEnter',function() background:SetColorTexture(.08,.18,.26,1) end)
    button:SetScript('OnLeave',function() background:SetColorTexture(.035,.05,.07,1) end)
    local check=button:CreateTexture(nil,'ARTWORK');check:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
    check:SetPoint('CENTER',background,'CENTER');check:SetSize(24,24);button:SetCheckedTexture(check)
    return button
end
function UI:Slider(parent)
    local slider=CreateFrame('Slider',nil,parent);slider:SetHeight(18);slider:SetOrientation('HORIZONTAL')
    local track=Texture(slider,'BACKGROUND',{.13,.19,.25,1});track:SetPoint('LEFT',0,0);track:SetPoint('RIGHT',0,0);track:SetHeight(4)
    slider:SetThumbTexture('Interface\\Buttons\\WHITE8X8')
    local thumb=slider:GetThumbTexture();thumb:SetSize(10,18);thumb:SetVertexColor(.18,.75,1,1)
    return slider
end
