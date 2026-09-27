OnPoint = OnPoint or {}
local OP = OnPoint

local selectedContext = "world"
local previewType = "friendly"
local controls = {}

local function SetLabel(check, text)
    local label = check.Text or check.text
    if not label then
        label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 3, 1)
        check.Text = label
    end
    label:SetText(text)
end

local function CreateCheck(parent, text, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    SetLabel(cb, text)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        OP:RefreshOptions()
    end)
    cb._getter = getter
    table.insert(controls, cb)
    return cb
end

local sliderIndex = 0
local function CreateSlider(parent, label, minValue, maxValue, step, x, y, getter, setter, formatter)
    sliderIndex = sliderIndex + 1
    local name = "OnPointSlider" .. sliderIndex
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(250)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    _G[name .. "Low"]:SetText(tostring(minValue))
    _G[name .. "High"]:SetText(tostring(maxValue))
    _G[name .. "Text"]:SetText(label)
    slider:SetScript("OnValueChanged", function(self, value)
        if self._refreshing then return end
        setter(value)
        if self.valueText then
            self.valueText:SetText(formatter and formatter(value) or tostring(value))
        end
        OP:UpdatePreview()
        if GameTooltip and GameTooltip:IsShown() then OP:ApplyTooltipAppearance(GameTooltip) end
    end)
    slider._getter = getter
    slider.valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    table.insert(controls, slider)
    return slider
end

local function CreateButton(parent, text, x, y, width, func)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", func)
    return button
end

local function DropdownSetText(dropdown, text)
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(dropdown, text or "") end
end

local function CreateDropdown(parent, x, y, width, getItems, getCurrent, onSelect)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(dd, width or 180) end

    UIDropDownMenu_Initialize(dd, function(self, level)
        local items = getItems()
        local current = getCurrent()
        for _, entry in ipairs(items) do
            local value, text
            if type(entry) == "table" then
                value, text = entry.value, entry.text
            else
                value, text = entry, entry
            end
            local info = UIDropDownMenu_CreateInfo()
            info.text = text
            info.value = value
            info.checked = (value == current)
            info.func = function()
                onSelect(value)
                CloseDropDownMenus()
                OP:RefreshOptions()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    dd._refresh = function()
        local current = getCurrent()
        local label = current
        for _, entry in ipairs(getItems()) do
            if type(entry) == "table" and entry.value == current then label = entry.text end
        end
        DropdownSetText(dd, label)
    end
    return dd
end

local function ShowProfileNamePopup(copyFrom)
    StaticPopupDialogs.ONPOINT_PROFILE_NAME = {
        text = copyFrom and OP:T("PROFILE_COPY_NAME") or OP:T("PROFILE_NEW_NAME"),
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = true,
        maxLetters = 32,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            if not name or name:match("^%s*$") then return end
            local source = OP.db.contextProfile[selectedContext] or "Bevorzugt"
            local created = OP:CreateCustomProfile(name, source)
            OP.db.contextProfile[selectedContext] = created
            OP:RefreshOptions()
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            StaticPopup_OnClick(parent, 1)
        end,
    }
    StaticPopup_Show("ONPOINT_PROFILE_NAME")
end

local function CurrentEditableProfile()
    local profile = OP:EnsureEditableProfile(selectedContext)
    return profile
end

local function CreatePreview(parent)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(440, 290)
    box:SetPoint("TOPLEFT", 38, -100)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    box:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    box:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)
    parent.previewBox = box

    box.lines = {}
    for i = 1, 8 do
        local fs = box:CreateFontString(nil, "ARTWORK", i == 1 and "GameTooltipHeaderText" or "GameTooltipText")
        fs:SetPoint("TOPLEFT", 14, -12 - (i - 1) * 19)
        fs:SetPoint("RIGHT", -14, 0)
        fs:SetJustifyH("LEFT")
        box.lines[i] = fs
    end

    local function NewBar(y)
        local bar = CreateFrame("StatusBar", nil, box, "BackdropTemplate")
        bar:SetPoint("BOTTOMLEFT", 12, y)
        bar:SetPoint("BOTTOMRIGHT", -12, y)
        bar:SetHeight(17)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(75)
        bar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        bar:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bar.text:SetPoint("CENTER")
        return bar
    end

    box.health = NewBar(34)
    box.power = NewBar(12)

    CreateButton(parent, OP:T("PREVIEW_FRIEND"), 25, -58, 125, function() previewType = "friendly" OP:UpdatePreview() end)
    CreateButton(parent, OP:T("PREVIEW_ENEMY"), 155, -58, 135, function() previewType = "enemy" OP:UpdatePreview() end)
    CreateButton(parent, OP:T("PREVIEW_NPC"), 295, -58, 105, function() previewType = "npc" OP:UpdatePreview() end)
    CreateButton(parent, OP:T("PREVIEW_PET"), 405, -58, 105, function() previewType = "pet" OP:UpdatePreview() end)
end

function OP:UpdatePreview()
    local panel = self.optionsFrame
    if not panel or not panel.previewBox then return end
    local box = panel.previewBox
    local profile = self:GetProfile(self.db.contextProfile[selectedContext]) or self.builtinProfiles["Bevorzugt"]
    local textAlpha = self.db.textAlpha or 1

    box:SetScale(self.db.tooltipScale or 1)
    box:SetBackdropColor(0.05, 0.05, 0.05, self.db.backgroundAlpha or 0.92)
    box:SetBackdropBorderColor(0.55, 0.45, 0.25, self.db.showBorder and 1 or 0)

    for _, line in ipairs(box.lines) do
        line:SetText("")
        line:SetAlpha(textAlpha)
    end

    local line = 1
    local function Add(text, r, g, b)
        if line > #box.lines then return end
        box.lines[line]:SetText(text)
        box.lines[line]:SetTextColor(r or 1, g or 1, b or 1)
        line = line + 1
    end

    local isPlayer = previewType == "friendly" or previewType == "enemy"
    local isPet = previewType == "pet"
    local enemy = previewType == "enemy"

    if isPlayer then
        local playerName = enemy and OP:T("PREVIEW_ENEMY_NAME") or OP:T("PREVIEW_FRIEND_NAME")
        if profile.classColor then Add(playerName, 0.25, 0.78, 0.92) else Add(playerName) end
        if profile.guild then Add(OP:T("PREVIEW_GUILD"), 0.25, 0.85, 1.00) end
        if profile.faction then Add(OP:FormatFaction(enemy and "Horde" or "Alliance", profile), 0.9, 0.82, 0.55) end
        if profile.pvp and enemy then Add("PvP", 1, 0.3, 0.3) end
    elseif isPet then
        Add(OP:T("PREVIEW_PET_NAME"))
        if profile.petOwner then Add(OP:FormatPetOwner(OP:T("PREVIEW_PET_OWNER")), 0.65, 0.82, 1.00) end
        if profile.creatureType then Add(OP:T("CREATURE_PREFIX") .. ": " .. OP:T("PREVIEW_CREATURE"), 0.82, 0.82, 0.82) end
    else
        Add(OP:T("PREVIEW_NPC_NAME"))
        if profile.creatureType then Add(OP:T("CREATURE_PREFIX") .. ": " .. OP:T("PREVIEW_CREATURE"), 0.82, 0.82, 0.82) end
    end

    if profile.range then
        Add(OP:FormatRange(true, profile), 0.2, 1, 0.2)
    end

    box.health:SetShown(profile.healthBar)
    box.power:SetShown(profile.resourceBar and (isPlayer or isPet))
    box.health:SetStatusBarColor(0.15, 0.85, 0.15, 1)
    box.health:SetValue(82)
    box.health.text:SetText(profile.barPercent and ((_G.HEALTH or "Health") .. "  82%") or "")
    box.power:SetStatusBarColor(0.2, 0.45, 1, 1)
    box.power:SetValue(64)
    box.power.text:SetText(profile.barPercent and ((_G.MANA or "Mana") .. "  64%") or "")
end

local function SelectTab(index)
    local frame = OP.optionsFrame
    if not frame then return end
    for i, tab in ipairs(frame.tabs) do
        tab:SetEnabled(i ~= index)
        frame.pages[i]:SetShown(i == index)
    end
    if index == 3 then OP:UpdatePreview() end
end

function OP:RefreshOptions()
    if not self.optionsFrame or not self.db then return end

    for _, control in ipairs(controls) do
        if control._getter then
            local value = control._getter()
            if control:GetObjectType() == "CheckButton" then
                control:SetChecked(value and true or false)
            elseif control:GetObjectType() == "Slider" then
                control._refreshing = true
                control:SetValue(value)
                control._refreshing = false
                if control.valueText then
                    if control._format then control.valueText:SetText(control._format(value)) end
                end
            end
        end
    end

    if self.contextDropdown and self.contextDropdown._refresh then self.contextDropdown._refresh() end
    if self.profileDropdown and self.profileDropdown._refresh then self.profileDropdown._refresh() end
    if self.barPositionDropdown and self.barPositionDropdown._refresh then self.barPositionDropdown._refresh() end
    if self.cursorAnchorDropdown and self.cursorAnchorDropdown._refresh then self.cursorAnchorDropdown._refresh() end

    if self.combatFallbackCheck then
        local special = selectedContext == "battleground" or selectedContext == "dungeon" or selectedContext == "raid"
        self.combatFallbackCheck:SetShown(special)
        if special then self.combatFallbackCheck:SetChecked(self.db.useCombatProfile[selectedContext]) end
    end

    local currentName = self.db.contextProfile[selectedContext]
    if self.deleteProfileButton then self.deleteProfileButton:SetEnabled(not self:IsBuiltinProfile(currentName)) end
    if self.profileHint then
        if self:IsBuiltinProfile(currentName) then
            self.profileHint:SetText(self:T("PROFILE_HINT_BUILTIN"))
        else
            self.profileHint:SetText(self:T("PROFILE_HINT_CUSTOM"))
        end
    end

    self:UpdatePreview()
end

function OP:InitializeOptions()
    if self.optionsFrame then return end

    local frame = CreateFrame("Frame", "OnPointOptions", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(760, 620)
    local savedPos = self.db and self.db.optionsWindow or nil
    local point = savedPos and savedPos.point or "CENTER"
    local relativePoint = savedPos and savedPos.relativePoint or point
    frame:SetPoint(point, UIParent, relativePoint, savedPos and savedPos.x or 360, savedPos and savedPos.y or -40)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(20)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:Hide()
    frame.TitleText:SetText("OnPoint")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnMouseDown", function(self) self:Raise() end)
    frame:SetScript("OnDragStart", function(self)
        self:Raise()
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        if OP.db and p then
            OP.db.optionsWindow = OP.db.optionsWindow or {}
            OP.db.optionsWindow.point = p
            OP.db.optionsWindow.relativePoint = rp or p
            OP.db.optionsWindow.x = x or 0
            OP.db.optionsWindow.y = y or 0
        end
    end)
    table.insert(UISpecialFrames, frame:GetName())
    self.optionsFrame = frame

    frame.tabs = {}
    frame.pages = {}
    local tabNames = {self:T("TAB_GENERAL"), self:T("TAB_PROFILES"), self:T("TAB_PREVIEW"), self:T("TAB_INFO")}
    for i, label in ipairs(tabNames) do
        local tab = CreateButton(frame, label, 18 + (i - 1) * 120, -35, 110, function() SelectTab(i) end)
        frame.tabs[i] = tab
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 12, -70)
        page:SetPoint("BOTTOMRIGHT", -12, 12)
        frame.pages[i] = page
    end

    -- General
    local general = frame.pages[1]
    local title = general:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -10)
    title:SetText(self:T("GENERAL"))

    CreateCheck(general, self:T("ADDON_ENABLED"), 20, -45,
        function() return OP.db.enabled end,
        function(v) OP:SetEnabled(v) end)

    CreateCheck(general, self:T("FOLLOW_CURSOR"), 20, -78,
        function() return OP.db.followCursor end,
        function(v) OP.db.followCursor = v end)

    local anchorLabel = general:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    anchorLabel:SetPoint("TOPLEFT", 20, -118)
    anchorLabel:SetText(self:T("CURSOR_ANCHOR"))

    self.cursorAnchorDropdown = CreateDropdown(general, 5, -132, 180,
        function()
            return {
                {value = "TOPRIGHT", text = OP:T("ANCHOR_TOPRIGHT")},
                {value = "TOPLEFT", text = OP:T("ANCHOR_TOPLEFT")},
                {value = "BOTTOMRIGHT", text = OP:T("ANCHOR_BOTTOMRIGHT")},
                {value = "BOTTOMLEFT", text = OP:T("ANCHOR_BOTTOMLEFT")},
            }
        end,
        function() return OP.db.cursorAnchor or "TOPRIGHT" end,
        function(value) OP.db.cursorAnchor = value end)

    local xSlider = CreateSlider(general, self:T("OFFSET_X"), -50, 80, 1, 35, -205,
        function() return OP.db.offsetX or 18 end,
        function(v) OP.db.offsetX = math.floor(v + 0.5) end,
        function(v) return tostring(math.floor(v + 0.5)) end)
    xSlider._format = function(v) return tostring(math.floor(v + 0.5)) end

    local ySlider = CreateSlider(general, self:T("OFFSET_Y"), -50, 80, 1, 35, -275,
        function() return OP.db.offsetY or 18 end,
        function(v) OP.db.offsetY = math.floor(v + 0.5) end,
        function(v) return tostring(math.floor(v + 0.5)) end)
    ySlider._format = function(v) return tostring(math.floor(v + 0.5)) end

    local scaleSlider = CreateSlider(general, self:T("TOOLTIP_SCALE"), 50, 150, 1, 35, -345,
        function() return math.floor((OP.db.tooltipScale or 1) * 100 + 0.5) end,
        function(v) OP.db.tooltipScale = v / 100 end,
        function(v) return string.format("%d%%", v) end)
    scaleSlider._format = function(v) return string.format("%d%%", v) end

    CreateCheck(general, self:T("TOOLTIP_FADE"), 20, -405,
        function() return OP.db.tooltipFadeEnabled end,
        function(v)
            OP.db.tooltipFadeEnabled = v
            if not v and GameTooltip then OP:CancelTooltipFade(GameTooltip, true) end
        end)

    local holdSlider = CreateSlider(general, self:T("TOOLTIP_HOLD"), 0, 2, 0.05, 35, -455,
        function() return OP.db.tooltipHoldTime or 0.10 end,
        function(v) OP.db.tooltipHoldTime = math.floor(v * 100 + 0.5) / 100 end,
        function(v) return string.format("%.2f s", v) end)
    holdSlider._format = function(v) return string.format("%.2f s", v) end

    local bgSlider = CreateSlider(general, self:T("BG_ALPHA"), 0, 100, 1, 390, -65,
        function() return math.floor((OP.db.backgroundAlpha or 0.92) * 100 + 0.5) end,
        function(v) OP.db.backgroundAlpha = v / 100 end,
        function(v) return string.format("%d%%", v) end)
    bgSlider._format = function(v) return string.format("%d%%", v) end

    local textSlider = CreateSlider(general, self:T("TEXT_ALPHA"), 25, 100, 1, 390, -135,
        function() return math.floor((OP.db.textAlpha or 1) * 100 + 0.5) end,
        function(v) OP.db.textAlpha = v / 100 end,
        function(v) return string.format("%d%%", v) end)
    textSlider._format = function(v) return string.format("%d%%", v) end

    CreateCheck(general, self:T("SHOW_BORDER"), 375, -195,
        function() return OP.db.showBorder end,
        function(v) OP.db.showBorder = v end)

    CreateCheck(general, self:T("MINIMAP_SHOW"), 375, -240,
        function() return OP.db.minimap.show end,
        function(v) OP.db.minimap.show = v OP:UpdateMinimapPosition() end)

    CreateCheck(general, self:T("MINIMAP_LOCK"), 375, -273,
        function() return OP.db.minimap.locked end,
        function(v) OP.db.minimap.locked = v end)

    local miniHelp = general:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    miniHelp:SetPoint("TOPLEFT", 400, -308)
    miniHelp:SetWidth(290)
    miniHelp:SetJustifyH("LEFT")
    miniHelp:SetText(self:T("MINIMAP_HELP"))

    local fadeInSlider = CreateSlider(general, self:T("TOOLTIP_FADE_IN"), 0, 1, 0.05, 390, -375,
        function() return OP.db.tooltipFadeIn or 0.08 end,
        function(v) OP.db.tooltipFadeIn = math.floor(v * 100 + 0.5) / 100 end,
        function(v) return string.format("%.2f s", v) end)
    fadeInSlider._format = function(v) return string.format("%.2f s", v) end

    local fadeOutSlider = CreateSlider(general, self:T("TOOLTIP_FADE_OUT"), 0, 1, 0.05, 390, -445,
        function() return OP.db.tooltipFadeOut or 0.12 end,
        function(v) OP.db.tooltipFadeOut = math.floor(v * 100 + 0.5) / 100 end,
        function(v) return string.format("%.2f s", v) end)
    fadeOutSlider._format = function(v) return string.format("%.2f s", v) end

    CreateButton(general, self:T("DEFAULTS"), 375, -505, 150, function()
        StaticPopupDialogs.ONPOINT_RESET = {
            text = OP:T("RESET_CONFIRM"),
            button1 = YES,
            button2 = NO,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function()
                OP:ResetDB()
                if OP.NormalizeCustomProfiles then OP:NormalizeCustomProfiles() end
                OP:UpdateMinimapPosition()
                OP:UpdateMinimapAppearance()
                OP:RefreshOptions()
            end,
        }
        StaticPopup_Show("ONPOINT_RESET")
    end)

    -- Profiles
    local profiles = frame.pages[2]
    local ptitle = profiles:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ptitle:SetPoint("TOPLEFT", 20, -10)
    ptitle:SetText(self:T("PROFILES"))

    local contextLabel = profiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    contextLabel:SetPoint("TOPLEFT", 20, -48)
    contextLabel:SetText(self:T("GAME_CONTEXT"))

    self.contextDropdown = CreateDropdown(profiles, 5, -62, 210,
        function()
            local items = {}
            for _, key in ipairs(OP.contextOrder) do table.insert(items, {value = key, text = OP.contextNames[key]}) end
            return items
        end,
        function() return selectedContext end,
        function(value) selectedContext = value end)

    local profileLabel = profiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", 270, -48)
    profileLabel:SetText(self:T("ASSIGNED_PROFILE"))

    self.profileDropdown = CreateDropdown(profiles, 255, -62, 210,
        function() return OP:GetAllProfileNames() end,
        function() return OP.db.contextProfile[selectedContext] end,
        function(value) OP.db.contextProfile[selectedContext] = value end)

    self.combatFallbackCheck = CreateCheck(profiles, self:T("COMBAT_FALLBACK"), 500, -72,
        function() return OP.db.useCombatProfile[selectedContext] end,
        function(v) OP.db.useCombatProfile[selectedContext] = v end)

    self.profileHint = profiles:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.profileHint:SetPoint("TOPLEFT", 20, -118)
    self.profileHint:SetWidth(430)
    self.profileHint:SetJustifyH("LEFT")

    CreateButton(profiles, self:T("NEW"), 20, -150, 90, function() ShowProfileNamePopup(false) end)
    CreateButton(profiles, self:T("DUPLICATE"), 118, -150, 110, function() ShowProfileNamePopup(true) end)
    self.deleteProfileButton = CreateButton(profiles, self:T("DELETE"), 236, -150, 90, function()
        local name = OP.db.contextProfile[selectedContext]
        if OP:IsBuiltinProfile(name) then return end
        StaticPopupDialogs.ONPOINT_DELETE_PROFILE = {
            text = string.format(OP:T("PROFILE_DELETE_CONFIRM"), tostring(name)),
            button1 = DELETE,
            button2 = CANCEL,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function()
                OP:DeleteCustomProfile(name)
                OP:RefreshOptions()
            end,
        }
        StaticPopup_Show("ONPOINT_DELETE_PROFILE")
    end)

    local optionsTitle = profiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    optionsTitle:SetPoint("TOPLEFT", 20, -198)
    optionsTitle:SetText(self:T("PROFILE_CONTENT"))

    local function ProfileCheck(text, x, y, key)
        return CreateCheck(profiles, text, x, y,
            function()
                local p = OP:GetProfile(OP.db.contextProfile[selectedContext])
                return p and p[key]
            end,
            function(v)
                local p = CurrentEditableProfile()
                p[key] = v
            end)
    end

    ProfileCheck(self:T("CLASS_COLOR"), 20, -230, "classColor")
    ProfileCheck(self:T("SHOW_GUILD"), 20, -263, "guild")
    ProfileCheck(self:T("SHOW_FACTION"), 20, -296, "faction")
    ProfileCheck(self:T("SHOW_FACTION_PREFIX"), 20, -329, "factionPrefix")
    ProfileCheck(self:T("SHOW_PVP"), 20, -362, "pvp")
    ProfileCheck(self:T("SHOW_CREATURE"), 20, -395, "creatureType")
    ProfileCheck(self:T("SHOW_PET_OWNER"), 20, -428, "petOwner")

    ProfileCheck(self:T("SHOW_RANGE"), 365, -230, "range")
    ProfileCheck(self:T("SHOW_RANGE_PREFIX"), 365, -263, "rangePrefix")
    ProfileCheck(self:T("SHOW_HEALTH"), 365, -296, "healthBar")
    ProfileCheck(self:T("SHOW_RESOURCE"), 365, -329, "resourceBar")
    ProfileCheck(self:T("BAR_PERCENT"), 365, -362, "barPercent")

    local barLabel = profiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    barLabel:SetPoint("TOPLEFT", 365, -410)
    barLabel:SetText(self:T("BAR_POSITION"))

    self.barPositionDropdown = CreateDropdown(profiles, 345, -425, 170,
        function() return {{value = "BOTTOM", text = OP:T("BELOW_TOOLTIP")}, {value = "TOP", text = OP:T("ABOVE_TOOLTIP")}} end,
        function()
            local p = OP:GetProfile(OP.db.contextProfile[selectedContext])
            return p and p.barPosition or "BOTTOM"
        end,
        function(value)
            local p = CurrentEditableProfile()
            p.barPosition = value
        end)

    local rangeNote = profiles:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    rangeNote:SetPoint("TOPLEFT", 365, -485)
    rangeNote:SetWidth(320)
    rangeNote:SetJustifyH("LEFT")
    rangeNote:SetText(self:T("RANGE_NOTE"))

    -- Vorschau
    local preview = frame.pages[3]
    local vtitle = preview:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    vtitle:SetPoint("TOPLEFT", 20, -10)
    vtitle:SetText(self:T("PREVIEW_TITLE"))
    local vtext = preview:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    vtext:SetPoint("TOPLEFT", 20, -34)
    vtext:SetText(self:T("PREVIEW_TEXT"))
    CreatePreview(preview)
    frame.previewBox = preview.previewBox

    -- Info
    local infoPage = frame.pages[4]
    local ititle = infoPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ititle:SetPoint("TOPLEFT", 20, -10)
    ititle:SetText(self:T("INFO_TITLE"))

    local infoBox = CreateFrame("Frame", nil, infoPage, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT", 20, -52)
    infoBox:SetSize(680, 455)
    infoBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8},
    })

    local addonName = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    addonName:SetPoint("TOPLEFT", 28, -26)
    addonName:SetText("OnPoint")

    local familyBadge = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    familyBadge:SetPoint("TOPRIGHT", -28, -30)
    familyBadge:SetText("Comfy Suite")
    familyBadge:SetTextColor(1.00, 0.82, 0.00)

    local tagline = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tagline:SetPoint("TOPLEFT", addonName, "BOTTOMLEFT", 0, -7)
    tagline:SetWidth(620)
    tagline:SetJustifyH("LEFT")
    tagline:SetText(OP.description or self:T("DESCRIPTION"))

    local function InfoRow(label, value, y)
        local l = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        l:SetPoint("TOPLEFT", 28, y)
        l:SetText(label)

        local v = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        v:SetPoint("TOPLEFT", 185, y)
        v:SetWidth(455)
        v:SetJustifyH("LEFT")
        v:SetText(value or "-")
        return l, v
    end

    local clientVersion, clientBuild, _, clientInterface = OP:GetClientBuildInfo()
    local compatible, compatibilityText = OP:GetCompatibilityStatus()

    InfoRow(self:T("INFO_VERSION"), OP.version or "1.7", -100)
    InfoRow(self:T("INFO_BUILD_DATE"), OP.buildDate or "27.09.2026", -122)
    InfoRow(self:T("INFO_STATUS"), OP.status or "Beta", -144)
    InfoRow(
        self:T("INFO_CLIENT"),
        "WoW Forever " .. tostring(clientVersion) .. " / Build " .. tostring(clientBuild) .. " / Interface " .. tostring(clientInterface or "?"),
        -166
    )
    InfoRow(
        self:T("INFO_TESTED_TARGET"),
        tostring(OP.gameVersion or "WoW Forever 1.60.1") .. " / Build " .. tostring(OP.targetBuild or "70009") .. " / Interface " .. tostring(OP.interface or 16001),
        -188
    )
    local _, compatibilityValue = InfoRow(self:T("INFO_COMPAT_STATUS"), compatibilityText, -210)
    if compatible then
        compatibilityValue:SetTextColor(0.20, 1.00, 0.20)
    else
        compatibilityValue:SetTextColor(1.00, 0.35, 0.20)
    end
    InfoRow(self:T("INFO_AUTHOR"), OP.author or "TheRealDoubleG", -232)

    local discordLabel = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    discordLabel:SetPoint("TOPLEFT", 28, -257)
    discordLabel:SetText(self:T("INFO_DISCORD"))

    local discordBox = CreateFrame("EditBox", nil, infoBox, "InputBoxTemplate")
    discordBox:SetSize(275, 30)
    discordBox:SetPoint("TOPLEFT", 180, -248)
    discordBox:SetAutoFocus(false)
    discordBox:SetText(OP.discord or "the.real.double.g")
    discordBox:SetCursorPosition(0)
    discordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discordBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    discordBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    discordBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText() ~= (OP.discord or "the.real.double.g") then
            self:SetText(OP.discord or "the.real.double.g")
            self:HighlightText()
        end
    end)

    local copyHint = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHint:SetPoint("TOPLEFT", 470, -255)
    copyHint:SetWidth(165)
    copyHint:SetJustifyH("LEFT")
    copyHint:SetText(self:T("INFO_COPY"))

    local githubLabel = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    githubLabel:SetPoint("TOPLEFT", 28, -292)
    githubLabel:SetText(self:T("INFO_GITHUB") or "GitHub")

    local githubBox = CreateFrame("EditBox", nil, infoBox, "InputBoxTemplate")
    githubBox:SetSize(395, 30)
    githubBox:SetPoint("TOPLEFT", 180, -283)
    githubBox:SetAutoFocus(false)
    githubBox:SetText(OP.github or "https://github.com/TheRealDoubleG/OnPoint")
    githubBox:SetCursorPosition(0)
    githubBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    githubBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    githubBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    githubBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText() ~= (OP.github or "https://github.com/TheRealDoubleG/OnPoint") then
            self:SetText(OP.github or "https://github.com/TheRealDoubleG/OnPoint")
            self:HighlightText()
        end
    end)

    InfoRow(self:T("INFO_COMMANDS"), "/onpoint  ·  /op", -328)

    local uiNotice = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    uiNotice:SetPoint("TOPLEFT", 28, -360)
    uiNotice:SetWidth(620)
    uiNotice:SetJustifyH("LEFT")
    uiNotice:SetText(self:T("INFO_NOTICE"))

    local copyright = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyright:SetPoint("BOTTOMLEFT", 28, 68)
    copyright:SetText("© 2026 TheRealDoubleG")

    local thanks = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    thanks:SetPoint("BOTTOMLEFT", 28, 28)
    thanks:SetWidth(620)
    thanks:SetJustifyH("LEFT")
    thanks:SetText(self:T("INFO_THANKS"))

    frame:SetScript("OnShow", function()
        OP:RefreshOptions()
    end)

    SelectTab(1)

    -- Zusätzlich unter ESC -> Optionen -> AddOns registrieren, falls die moderne Settings-API vorhanden ist.
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local canvas = CreateFrame("Frame")
        local info = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        info:SetPoint("TOPLEFT", 16, -16)
        info:SetText("OnPoint")
        local desc = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        desc:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -12)
        desc:SetWidth(520)
        desc:SetJustifyH("LEFT")
        desc:SetText(self:T("SETTINGS_DESC"))
        CreateButton(canvas, self:T("SETTINGS_OPEN"), 16, -90, 220, function() OP:ShowOptions() end)
        local category = Settings.RegisterCanvasLayoutCategory(canvas, "OnPoint")
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    end
end

function OP:ShowOptions()
    if not self.optionsFrame then self:InitializeOptions() end
    self.optionsFrame:Show()
    self.optionsFrame:Raise()
    self:RefreshOptions()
end
