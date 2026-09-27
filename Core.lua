local ADDON_NAME = ...

OnPoint = OnPoint or {}
local OP = OnPoint

OP.name = ADDON_NAME or "OnPoint"
OP.version = "1.9"
OP.buildDate = "27.09.2026"
OP.status = "Beta"
OP.gameVersion = "WoW Forever 1.60.1"
OP.targetBuild = "70009"
OP.description = OP:T("DESCRIPTION")
OP.author = "TheRealDoubleG"
OP.discord = "the.real.double.g"
OP.github = "https://github.com/TheRealDoubleG/OnPoint"
OP.interface = 16001

function OP:GetClientBuildInfo()
    if type(GetBuildInfo) ~= "function" then
        return "?", "?", "?", nil
    end

    local version, build, buildDate, interface = GetBuildInfo()
    return tostring(version or "?"), tostring(build or "?"), tostring(buildDate or "?"), tonumber(interface)
end

function OP:GetCompatibilityStatus()
    local _, _, _, clientInterface = self:GetClientBuildInfo()
    if clientInterface and tonumber(clientInterface) == tonumber(self.interface) then
        return true, self:T("COMPAT_MATCH")
    end
    return false, self:T("COMPAT_UPDATE_REQUIRED")
end
OP.colors = {
    gold = {1.00, 0.82, 0.00},
    green = {0.20, 1.00, 0.20},
    red = {1.00, 0.25, 0.25},
    muted = {0.65, 0.65, 0.65},
}

local defaults = {
    enabled = true,
    followCursor = true,
    offsetX = 18,
    offsetY = 18,
    backgroundAlpha = 0.92,
    textAlpha = 1.00,
    showBorder = true,
    tooltipScale = 1.00,
    cursorAnchor = "TOPRIGHT",
    tooltipFadeEnabled = true,
    tooltipHoldTime = 0.10,
    tooltipFadeIn = 0.08,
    tooltipFadeOut = 0.12,
    minimap = {
        show = true,
        locked = false,
        angle = 220,
    },
    optionsWindow = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 360,
        y = -40,
    },
    contextProfile = {
        world = "Bevorzugt",
        combat = "Minimal",
        battleground = "Bevorzugt",
        dungeon = "Bevorzugt",
        raid = "Minimal",
    },
    useCombatProfile = {
        battleground = false,
        dungeon = false,
        raid = false,
    },
    customProfiles = {},
}

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do
        dst[k] = CopyTable(v)
    end
    return dst
end

OP.CopyTable = CopyTable

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function OP:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd200OnPoint:|r " .. tostring(msg))
end

function OP:IsSecret(value)
    if value == nil then return false end
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then return true end
    end
    return false
end

function OP:SafeCall(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, a, b, c, d, e, f = pcall(func, ...)
    if not ok then return nil end
    if self:IsSecret(a) then return nil end
    return a, b, c, d, e, f
end

function OP:GetDB()
    return OnPointDB
end

function OP:ResetDB()
    OnPointDB = CopyTable(defaults)
    self.db = OnPointDB
end

function OP:InitializeDB()
    if type(OnPointDB) ~= "table" then
        OnPointDB = CopyTable(defaults)
    else
        ApplyDefaults(OnPointDB, defaults)
    end
    self.db = OnPointDB
    if self.NormalizeCustomProfiles then
        self:NormalizeCustomProfiles()
    end
end

function OP:GetCurrentContext()
    local inInstance, instanceType = self:SafeCall(IsInInstance)
    local special

    if inInstance then
        if instanceType == "pvp" or instanceType == "arena" then
            special = "battleground"
        elseif instanceType == "raid" then
            special = "raid"
        elseif instanceType == "party" or instanceType == "scenario" then
            special = "dungeon"
        end
    end

    local inCombat = self:SafeCall(UnitAffectingCombat, "player") and true or false

    if special then
        if inCombat and self.db.useCombatProfile[special] then
            return "combat"
        end
        return special
    end

    if inCombat then return "combat" end
    return "world"
end

function OP:GetActiveProfile()
    local context = self:GetCurrentContext()
    local name = self.db.contextProfile[context] or "Bevorzugt"
    local profile = self:GetProfile(name)
    if not profile then
        name = "Bevorzugt"
        profile = self:GetProfile(name)
    end
    return profile, name, context
end

function OP:GetTooltipUnit(tooltip)
    if not tooltip or type(tooltip.GetUnit) ~= "function" then return nil end
    local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
    if not ok or not unit then return nil end
    local exists = self:SafeCall(UnitExists, unit)
    if not exists then return nil end
    return unit
end

function OP:GetClassColor(unit)
    local isPlayer = self:SafeCall(UnitIsPlayer, unit)
    if not isPlayer then return nil end

    local _, classFile = self:SafeCall(UnitClass, unit)
    if not classFile then return nil end

    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if not color then return nil end

    return color.r, color.g, color.b
end

function OP:IsSpellKnownSafe(spellID)
    if type(IsPlayerSpell) == "function" then
        local value = self:SafeCall(IsPlayerSpell, spellID)
        if value ~= nil then return value and true or false end
    end
    if type(IsSpellKnown) == "function" then
        local value = self:SafeCall(IsSpellKnown, spellID)
        if value ~= nil then return value and true or false end
    end
    return true
end

local offensiveRangeSpells = {
    MAGE = {133, 116, 30451},            -- Fireball, Frostbolt, Arcane Blast
    PRIEST = {585, 589},                 -- Smite, Shadow Word: Pain
    HUNTER = {3044, 19434},              -- Arcane Shot, Aimed Shot
    WARLOCK = {686, 172},                -- Shadow Bolt, Corruption
    SHAMAN = {403, 8050},                -- Lightning Bolt, Flame Shock
    DRUID = {5176, 8921},                -- Wrath, Moonfire
    PALADIN = {20271},                   -- Judgment
    DEATHKNIGHT = {47541},               -- Death Coil
    EVOKER = {362969},                   -- Azure Strike (fallback if present)
}

local helpfulRangeSpells = {
    PRIEST = {2061, 17},                 -- Flash Heal, Power Word: Shield
    SHAMAN = {331},                      -- Healing Wave
    DRUID = {8936, 774},                 -- Regrowth, Rejuvenation
    PALADIN = {19750},                   -- Flash of Light
    EVOKER = {361469},                   -- Living Flame (if available)
    MAGE = {1459},                       -- Arcane Intellect
}

function OP:GetSpellNameSafe(spellID)
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local info = self:SafeCall(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" and info.name then return info.name end
    end
    if type(GetSpellInfo) == "function" then
        local name = self:SafeCall(GetSpellInfo, spellID)
        if name then return name end
    end
    return nil
end

function OP:GetRangeSpell(unit)
    local _, classFile = self:SafeCall(UnitClass, "player")
    if not classFile then return nil end

    local canAttack = self:SafeCall(UnitCanAttack, "player", unit)
    local list
    if canAttack then
        list = offensiveRangeSpells[classFile]
    else
        local canAssist = self:SafeCall(UnitCanAssist, "player", unit)
        if canAssist then list = helpfulRangeSpells[classFile] end
    end

    if not list then return nil end
    for _, spellID in ipairs(list) do
        if self:IsSpellKnownSafe(spellID) then
            return spellID
        end
    end
    return nil
end

function OP:GetRangeState(unit)
    if not unit then return nil end
    local spellID = self:GetRangeSpell(unit)
    if not spellID then return nil end

    if C_Spell and type(C_Spell.IsSpellInRange) == "function" then
        local value = self:SafeCall(C_Spell.IsSpellInRange, spellID, unit)
        if value == true then return true end
        if value == false then return false end
    end

    if type(IsSpellInRange) == "function" then
        local spellName = self:GetSpellNameSafe(spellID)
        if spellName then
            local value = self:SafeCall(IsSpellInRange, spellName, unit)
            if value == 1 or value == true then return true end
            if value == 0 or value == false then return false end
        end
    end

    return nil
end

function OP:GetSafeUnitNumber(func, unit, powerType)
    local value
    if powerType ~= nil then
        value = self:SafeCall(func, unit, powerType)
    else
        value = self:SafeCall(func, unit)
    end
    if self:IsSecret(value) or type(value) ~= "number" then return nil end
    return value
end

function OP:CreateBars()
    if self.healthBar then return end

    local function NewBar(name)
        local bar = CreateFrame("StatusBar", name, UIParent, "BackdropTemplate")
        bar:SetHeight(15)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)
        bar:SetFrameStrata("TOOLTIP")
        bar:SetFrameLevel(1000)
        if bar.SetBackdrop then
            bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            bar:SetBackdropColor(0.03, 0.03, 0.03, 0.90)
        end
        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bar.text:SetPoint("CENTER")
        bar:Hide()
        return bar
    end

    self.healthBar = NewBar("OnPointHealthBar")
    self.resourceBar = NewBar("OnPointResourceBar")
end

function OP:HideBars()
    if self.healthBar then self.healthBar:Hide() end
    if self.resourceBar then self.resourceBar:Hide() end
end

function OP:UpdateBars(tooltip, unit, profile)
    self:CreateBars()
    if not tooltip or not tooltip:IsShown() or not unit or not profile then
        self:HideBars()
        return
    end

    local showHealth = profile.healthBar
    local showResource = profile.resourceBar
    if not showHealth and not showResource then
        self:HideBars()
        return
    end

    local width = math.max(100, (tooltip:GetWidth() or 180) - 8)
    local anchorAbove = profile.barPosition == "TOP"
    local first, second

    if showHealth then first = self.healthBar end
    if showResource then
        if first then second = self.resourceBar else first = self.resourceBar end
    end

    if first then
        first:ClearAllPoints()
        first:SetWidth(width)
        if anchorAbove then
            first:SetPoint("BOTTOMLEFT", tooltip, "TOPLEFT", 4, 2)
        else
            first:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 4, -2)
        end
    end

    if second then
        second:ClearAllPoints()
        second:SetWidth(width)
        if anchorAbove then
            second:SetPoint("BOTTOMLEFT", first, "TOPLEFT", 0, 1)
        else
            second:SetPoint("TOPLEFT", first, "BOTTOMLEFT", 0, -1)
        end
    end

    if showHealth then
        local value = self:GetSafeUnitNumber(UnitHealth, unit)
        local maxValue = self:GetSafeUnitNumber(UnitHealthMax, unit)
        if value and maxValue and maxValue > 0 then
            self.healthBar:SetMinMaxValues(0, maxValue)
            self.healthBar:SetValue(value)
            self.healthBar:SetStatusBarColor(0.15, 0.85, 0.15, 1)
            if profile.barPercent then
                self.healthBar.text:SetText(string.format("%s  %d%%", _G.HEALTH or self:T("HEALTH"), math.floor((value / maxValue) * 100 + 0.5)))
            else
                self.healthBar.text:SetText("")
            end
            self.healthBar:Show()
        else
            self.healthBar:Hide()
        end
    else
        self.healthBar:Hide()
    end

    if showResource then
        local powerType, powerToken, r, g, b = self:SafeCall(UnitPowerType, unit)
        local value = powerType ~= nil and self:GetSafeUnitNumber(UnitPower, unit, powerType) or nil
        local maxValue = powerType ~= nil and self:GetSafeUnitNumber(UnitPowerMax, unit, powerType) or nil
        if value and maxValue and maxValue > 0 then
            self.resourceBar:SetMinMaxValues(0, maxValue)
            self.resourceBar:SetValue(value)
            local color = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
            if color then
                self.resourceBar:SetStatusBarColor(color.r or r or 0.2, color.g or g or 0.4, color.b or b or 1, 1)
            else
                self.resourceBar:SetStatusBarColor(r or 0.2, g or 0.4, b or 1, 1)
            end
            if profile.barPercent then
                local label = (powerToken and _G[powerToken]) or powerToken or self:T("RESOURCE")
                self.resourceBar.text:SetText(string.format("%s  %d%%", label, math.floor((value / maxValue) * 100 + 0.5)))
            else
                self.resourceBar.text:SetText("")
            end
            self.resourceBar:Show()
        else
            self.resourceBar:Hide()
        end
    else
        self.resourceBar:Hide()
    end
end

function OP:StoreTooltipDefaults(tooltip)
    if self.tooltipDefaultsStored then return end
    self.tooltipDefaultsStored = true

    if tooltip.GetBackdropColor then
        local r, g, b, a = tooltip:GetBackdropColor()
        self.defaultBackdrop = {r or 0.05, g or 0.05, b or 0.05, a or 0.95}
    else
        self.defaultBackdrop = {0.05, 0.05, 0.05, 0.95}
    end

    if tooltip.GetBackdropBorderColor then
        local r, g, b, a = tooltip:GetBackdropBorderColor()
        self.defaultBorder = {r or 0.45, g or 0.35, b or 0.20, a or 1}
    else
        self.defaultBorder = {0.45, 0.35, 0.20, 1}
    end
end

function OP:ApplyTooltipAppearance(tooltip)
    if not tooltip then return end
    self:StoreTooltipDefaults(tooltip)

    if not self.defaultTooltipScale and tooltip.GetScale then
        self.defaultTooltipScale = tooltip:GetScale() or 1
    end
    if tooltip.SetScale then
        pcall(tooltip.SetScale, tooltip, self.db.tooltipScale or 1)
    end

    local bg = self.defaultBackdrop
    local border = self.defaultBorder
    local alpha = self.db.backgroundAlpha or 0.92

    if tooltip.SetBackdropColor then
        pcall(tooltip.SetBackdropColor, tooltip, bg[1], bg[2], bg[3], alpha)
    end
    if tooltip.SetBackdropBorderColor then
        pcall(tooltip.SetBackdropBorderColor, tooltip, border[1], border[2], border[3], self.db.showBorder and border[4] or 0)
    end

    local nine = tooltip.NineSlice
    if nine then
        if nine.Center and nine.Center.SetAlpha then
            nine.Center:SetAlpha(alpha)
        end
        local borderPieces = {
            "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
            "TopEdge", "BottomEdge", "LeftEdge", "RightEdge"
        }
        for _, key in ipairs(borderPieces) do
            local piece = nine[key]
            if piece and piece.SetAlpha then piece:SetAlpha(self.db.showBorder and 1 or 0) end
        end
    end

    local textAlpha = self.db.textAlpha or 1
    local tooltipName = tooltip:GetName()
    if tooltipName then
        for i = 1, 40 do
            local left = _G[tooltipName .. "TextLeft" .. i]
            local right = _G[tooltipName .. "TextRight" .. i]
            if left then left:SetAlpha(textAlpha) end
            if right then right:SetAlpha(textAlpha) end
        end
    end
end

function OP:RestoreTooltipAppearance(tooltip)
    if not tooltip then return end
    if self.defaultTooltipScale and tooltip.SetScale then
        pcall(tooltip.SetScale, tooltip, self.defaultTooltipScale)
    end
    if self.defaultBackdrop and tooltip.SetBackdropColor then
        local bg = self.defaultBackdrop
        pcall(tooltip.SetBackdropColor, tooltip, bg[1], bg[2], bg[3], bg[4])
    end
    if self.defaultBorder and tooltip.SetBackdropBorderColor then
        local border = self.defaultBorder
        pcall(tooltip.SetBackdropBorderColor, tooltip, border[1], border[2], border[3], border[4])
    end
    local nine = tooltip.NineSlice
    if nine then
        if nine.Center and nine.Center.SetAlpha then nine.Center:SetAlpha(1) end
        local borderPieces = {
            "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
            "TopEdge", "BottomEdge", "LeftEdge", "RightEdge"
        }
        for _, key in ipairs(borderPieces) do
            local piece = nine[key]
            if piece and piece.SetAlpha then piece:SetAlpha(1) end
        end
    end
    local tooltipName = tooltip:GetName()
    if tooltipName then
        for i = 1, 40 do
            local left = _G[tooltipName .. "TextLeft" .. i]
            local right = _G[tooltipName .. "TextRight" .. i]
            if left then left:SetAlpha(1) end
            if right then right:SetAlpha(1) end
        end
    end
end

local function Clamp01(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

function OP:SetTooltipCompositeAlpha(tooltip, alpha)
    if not tooltip then return end
    alpha = Clamp01(alpha)
    if tooltip.SetAlpha then tooltip:SetAlpha(alpha) end
    if self.healthBar and self.healthBar.SetAlpha then self.healthBar:SetAlpha(alpha) end
    if self.resourceBar and self.resourceBar.SetAlpha then self.resourceBar:SetAlpha(alpha) end
end

function OP:CancelTooltipFade(tooltip, restoreAlpha)
    if not tooltip then return end
    tooltip.__OnPointFadeMode = nil
    tooltip.__OnPointFadeStart = nil
    tooltip.__OnPointFadeDuration = nil
    tooltip.__OnPointFadeFrom = nil
    if restoreAlpha then
        self:SetTooltipCompositeAlpha(tooltip, 1)
    end
end

function OP:MarkUnitTooltipActive(tooltip)
    if not tooltip then return end

    local fadeEnabled = self.db and self.db.tooltipFadeEnabled
    local mode = tooltip.__OnPointFadeMode
    local wasUnit = tooltip.__OnPointWasUnit and true or false
    local wasLeaving = mode == "wait" or mode == "out"
    tooltip.__OnPointWasUnit = true

    if not fadeEnabled then
        self:CancelTooltipFade(tooltip, true)
        return
    end

    local duration = math.max(0, tonumber(self.db.tooltipFadeIn) or 0.08)
    local currentAlpha = tooltip.GetAlpha and tooltip:GetAlpha() or 1

    if not wasUnit then
        currentAlpha = 0
        self:SetTooltipCompositeAlpha(tooltip, 0)
    end

    if not wasUnit or wasLeaving then
        if duration <= 0 then
            self:CancelTooltipFade(tooltip, true)
        else
            tooltip.__OnPointFadeMode = "in"
            tooltip.__OnPointFadeStart = GetTime and GetTime() or 0
            tooltip.__OnPointFadeDuration = duration
            tooltip.__OnPointFadeFrom = Clamp01(currentAlpha)
        end
    elseif mode ~= "in" then
        self:SetTooltipCompositeAlpha(tooltip, 1)
    end
end

function OP:ScheduleTooltipFadeOut(tooltip)
    if not tooltip or not tooltip.__OnPointWasUnit then return end

    if not self.db or not self.db.tooltipFadeEnabled then
        self:CancelTooltipFade(tooltip, true)
        self:HideBars()
        return
    end

    local mode = tooltip.__OnPointFadeMode
    if mode == "wait" or mode == "out" then return end

    tooltip.__OnPointFadeMode = "wait"
    tooltip.__OnPointFadeStart = GetTime and GetTime() or 0
    tooltip.__OnPointFadeDuration = math.max(0, tonumber(self.db.tooltipHoldTime) or 0.10)
    tooltip.__OnPointFadeFrom = tooltip.GetAlpha and tooltip:GetAlpha() or 1
end

function OP:UpdateTooltipFade(tooltip)
    if not tooltip or not tooltip:IsShown() then return end

    if not self.db or not self.db.tooltipFadeEnabled then
        if tooltip.__OnPointFadeMode then self:CancelTooltipFade(tooltip, true) end
        return
    end

    local mode = tooltip.__OnPointFadeMode
    if not mode then return end

    local now = GetTime and GetTime() or 0
    local startTime = tooltip.__OnPointFadeStart or now
    local duration = math.max(0, tonumber(tooltip.__OnPointFadeDuration) or 0)

    if mode == "wait" then
        if type(UnitExists) == "function" and UnitExists("mouseover") then
            self:CancelTooltipFade(tooltip, true)
            return
        end
        if (now - startTime) < duration then return end

        tooltip.__OnPointFadeMode = "out"
        tooltip.__OnPointFadeStart = now
        tooltip.__OnPointFadeDuration = math.max(0, tonumber(self.db.tooltipFadeOut) or 0.12)
        tooltip.__OnPointFadeFrom = tooltip.GetAlpha and tooltip:GetAlpha() or 1
        mode = "out"
        startTime = now
        duration = tooltip.__OnPointFadeDuration
    end

    if mode == "in" or mode == "out" then
        local progress = duration <= 0 and 1 or math.min(1, math.max(0, (now - startTime) / duration))
        local from = Clamp01(tooltip.__OnPointFadeFrom or (mode == "in" and 0 or 1))
        local alpha

        if mode == "in" then
            alpha = from + ((1 - from) * progress)
        else
            alpha = from * (1 - progress)
        end

        self:SetTooltipCompositeAlpha(tooltip, alpha)

        if progress >= 1 then
            if mode == "in" then
                self:CancelTooltipFade(tooltip, true)
            else
                tooltip.__OnPointWasUnit = false
                self:CancelTooltipFade(tooltip, false)
                self:HideBars()
                self:SetTooltipCompositeAlpha(tooltip, 0)
                tooltip:Hide()
            end
        end
    end
end

function OP:ColorTooltipName(tooltip, unit, profile)
    if not profile.classColor then return end
    local r, g, b = self:GetClassColor(unit)
    if not r then return end

    local tooltipName = tooltip:GetName()
    local line = tooltipName and _G[tooltipName .. "TextLeft1"]
    if line and line.SetTextColor then
        line:SetTextColor(r, g, b)
    end
end

function OP:GetPetOwnerName(unit)
    if not unit or type(UnitOwnerGUID) ~= "function" then return nil end

    local ownerGUID = self:SafeCall(UnitOwnerGUID, unit)
    if type(ownerGUID) ~= "string" or ownerGUID == "" then return nil end

    if type(UnitNameFromGUID) == "function" then
        local name, realm = self:SafeCall(UnitNameFromGUID, ownerGUID)
        if type(name) == "string" and name ~= "" then
            if type(realm) == "string" and realm ~= "" then
                return name .. "-" .. realm
            end
            return name
        end
    end

    if type(GetPlayerInfoByGUID) == "function" then
        local _, _, _, _, _, name = self:SafeCall(GetPlayerInfoByGUID, ownerGUID)
        if type(name) == "string" and name ~= "" then
            return name
        end
    end

    return nil
end

function OP:FormatPetOwner(name)
    if not name or name == "" then return nil end
    return self:T("OWNER_PREFIX") .. ": " .. name
end

function OP:GetFactionLabel(faction)
    if faction == "Alliance" then return self:T("FACTION_ALLIANCE") end
    if faction == "Horde" then return self:T("FACTION_HORDE") end
    return faction
end

function OP:FormatFaction(faction, profile)
    local label = self:GetFactionLabel(faction)
    if profile and profile.factionPrefix == false then
        return label
    end
    return self:T("FACTION_PREFIX") .. ": " .. label
end

function OP:FormatRange(state, profile)
    local value = state and self:T("IN_RANGE") or self:T("OUT_OF_RANGE")
    if profile and profile.rangePrefix == false then
        return value
    end
    return self:T("RANGE_PREFIX") .. ": " .. value
end

function OP:AddUnitInfo(tooltip, unit, profile)
    if not unit or not profile then return end

    self:ColorTooltipName(tooltip, unit, profile)

    local isPlayer = self:SafeCall(UnitIsPlayer, unit)

    if profile.guild and isPlayer then
        local guild = self:SafeCall(GetGuildInfo, unit)
        if type(guild) == "string" and guild ~= "" then
            tooltip:AddLine("<" .. guild .. ">", 0.25, 0.85, 1.00)
        end
    end

    if profile.faction and isPlayer then
        local faction = self:SafeCall(UnitFactionGroup, unit)
        if type(faction) == "string" and faction ~= "" then
            tooltip:AddLine(self:FormatFaction(faction, profile), 0.90, 0.82, 0.55)
        end
    end

    if profile.pvp and isPlayer then
        local pvp = self:SafeCall(UnitIsPVP, unit)
        if pvp == true then
            tooltip:AddLine("PvP", 1.00, 0.30, 0.30)
        end
    end

    if profile.petOwner and not isPlayer then
        local ownerName = self:GetPetOwnerName(unit)
        if ownerName then
            tooltip:AddLine(self:FormatPetOwner(ownerName), 0.65, 0.82, 1.00)
        end
    end

    if profile.creatureType and not isPlayer then
        local creatureType = self:SafeCall(UnitCreatureType, unit)
        if type(creatureType) == "string" and creatureType ~= "" and creatureType ~= UNKNOWN then
            tooltip:AddLine(self:T("CREATURE_PREFIX") .. ": " .. creatureType, 0.82, 0.82, 0.82)
        end
    end

    if profile.range then
        local state = self:GetRangeState(unit)
        if state ~= nil then
            local index = tooltip:NumLines() + 1
            if state then
                tooltip:AddLine(self:FormatRange(true, profile), self.colors.green[1], self.colors.green[2], self.colors.green[3])
            else
                tooltip:AddLine(self:FormatRange(false, profile), self.colors.red[1], self.colors.red[2], self.colors.red[3])
            end
            tooltip.__OnPointRangeLine = index
        end
    end

    tooltip:Show()
end

function OP:RefreshUnitTooltip(tooltip)
    if not self.db or not self.db.enabled then return end
    local unit = self:GetTooltipUnit(tooltip)
    if not unit then
        self:HideBars()
        return
    end

    self:MarkUnitTooltipActive(tooltip)

    local guid = self:SafeCall(UnitGUID, unit) or unit
    local profile, profileName, context = self:GetActiveProfile()
    local signature = tostring(guid) .. "|" .. tostring(profileName) .. "|" .. tostring(context)

    if tooltip.__OnPointSignature ~= signature then
        tooltip.__OnPointSignature = signature
        tooltip.__OnPointRangeLine = nil
        self:AddUnitInfo(tooltip, unit, profile)
    else
        self:ColorTooltipName(tooltip, unit, profile)
    end

    self:ApplyTooltipAppearance(tooltip)
    self:UpdateBars(tooltip, unit, profile)
end

function OP:PositionTooltipAtCursor(tooltip)
    if not self.db or not self.db.enabled or not self.db.followCursor or not tooltip then
        return
    end

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale <= 0 then return end
    x, y = x / scale, y / scale

    local offsetX = self.db.offsetX or 18
    local offsetY = self.db.offsetY or 18
    local anchor = self.db.cursorAnchor or "TOPRIGHT"
    local tooltipPoint = "BOTTOMLEFT"
    local px, py = x + offsetX, y + offsetY

    if anchor == "TOPLEFT" then
        tooltipPoint = "BOTTOMRIGHT"
        px, py = x - offsetX, y + offsetY
    elseif anchor == "BOTTOMRIGHT" then
        tooltipPoint = "TOPLEFT"
        px, py = x + offsetX, y - offsetY
    elseif anchor == "BOTTOMLEFT" then
        tooltipPoint = "TOPRIGHT"
        px, py = x - offsetX, y - offsetY
    end

    tooltip:ClearAllPoints()
    tooltip:SetPoint(tooltipPoint, UIParent, "BOTTOMLEFT", px, py)
    tooltip:SetClampedToScreen(true)
end

function OP:UpdateDynamicTooltip(tooltip)
    if not self.db or not self.db.enabled or not tooltip:IsShown() then
        self:HideBars()
        return
    end

    self:PositionTooltipAtCursor(tooltip)
    self:ApplyTooltipAppearance(tooltip)

    local unit = self:GetTooltipUnit(tooltip)
    if not unit then
        if tooltip.__OnPointWasUnit then
            self:ScheduleTooltipFadeOut(tooltip)
        else
            self:HideBars()
        end
        return
    end

    self:MarkUnitTooltipActive(tooltip)
    local profile = self:GetActiveProfile()
    self:UpdateBars(tooltip, unit, profile)

    if profile and profile.range and tooltip.__OnPointRangeLine then
        local state = self:GetRangeState(unit)
        local tooltipName = tooltip:GetName()
        local line = tooltipName and _G[tooltipName .. "TextLeft" .. tooltip.__OnPointRangeLine]
        if line then
            if state == true then
                line:SetText(self:FormatRange(true, profile))
                line:SetTextColor(self.colors.green[1], self.colors.green[2], self.colors.green[3])
                line:Show()
            elseif state == false then
                line:SetText(self:FormatRange(false, profile))
                line:SetTextColor(self.colors.red[1], self.colors.red[2], self.colors.red[3])
                line:Show()
            else
                line:SetText("")
            end
        end
    end
end

function OP:InstallTooltipHooks()
    if self.tooltipHooksInstalled then return end
    self.tooltipHooksInstalled = true

    if type(GameTooltip_SetDefaultAnchor) == "function" and type(hooksecurefunc) == "function" then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip)
            if tooltip == GameTooltip and OP.db and OP.db.enabled and OP.db.followCursor then
                OP:PositionTooltipAtCursor(tooltip)
            end
        end)
    end

    -- Action buttons often call GameTooltip:SetOwner(..., "ANCHOR_...") directly.
    -- Hooking SetOwner removes the visible jump back to Blizzard's default action-bar anchor.
    if type(hooksecurefunc) == "function" and GameTooltip and GameTooltip.SetOwner then
        pcall(hooksecurefunc, GameTooltip, "SetOwner", function(tooltip)
            if tooltip == GameTooltip and OP.db and OP.db.enabled and OP.db.followCursor then
                OP:PositionTooltipAtCursor(tooltip)
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        if GameTooltip and GameTooltip:IsShown() and OP.db and OP.db.enabled and OP.db.followCursor then
                            OP:PositionTooltipAtCursor(GameTooltip)
                        end
                    end)
                end
            end
        end)
    end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip == GameTooltip then
                tooltip.__OnPointSignature = nil
                OP:RefreshUnitTooltip(tooltip)
                OP:PositionTooltipAtCursor(tooltip)
            end
        end)
    else
        pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", function(tooltip)
            tooltip.__OnPointSignature = nil
            OP:RefreshUnitTooltip(tooltip)
            OP:PositionTooltipAtCursor(tooltip)
        end)
    end

    pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipCleared", function(tooltip)
        local wasUnit = tooltip.__OnPointWasUnit or tooltip.__OnPointSignature ~= nil
        tooltip.__OnPointSignature = nil
        tooltip.__OnPointRangeLine = nil
        if wasUnit then
            OP:ScheduleTooltipFadeOut(tooltip)
        else
            OP:HideBars()
        end
    end)

    local function MarkNonUnitTooltip(tooltip)
        tooltip.__OnPointWasUnit = false
        OP:CancelTooltipFade(tooltip, true)
        OP:HideBars()
    end

    pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetItem", MarkNonUnitTooltip)
    pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetSpell", MarkNonUnitTooltip)

    GameTooltip:HookScript("OnShow", function(tooltip)
        if OP.db and OP.db.enabled then
            OP:ApplyTooltipAppearance(tooltip)
            OP:RefreshUnitTooltip(tooltip)
            if not OP:GetTooltipUnit(tooltip) then
                tooltip.__OnPointWasUnit = false
                OP:CancelTooltipFade(tooltip, true)
            end
            OP:PositionTooltipAtCursor(tooltip)
        end
    end)

    GameTooltip:HookScript("OnHide", function(tooltip)
        tooltip.__OnPointSignature = nil
        tooltip.__OnPointRangeLine = nil
        tooltip.__OnPointWasUnit = false
        OP:CancelTooltipFade(tooltip, true)
        OP:HideBars()
    end)

    local elapsed = 0
    GameTooltip:HookScript("OnUpdate", function(tooltip, delta)
        OP:UpdateTooltipFade(tooltip)

        -- Position every frame so action buttons cannot pull the tooltip back to their own anchor.
        if OP.db and OP.db.enabled and OP.db.followCursor then
            OP:PositionTooltipAtCursor(tooltip)
        end

        elapsed = elapsed + (delta or 0)
        if elapsed < 0.05 then return end
        elapsed = 0
        OP:UpdateDynamicTooltip(tooltip)
    end)
end

function OP:SetEnabled(enabled)
    self.db.enabled = enabled and true or false
    if not self.db.enabled then
        self:HideBars()
        if GameTooltip then
            self:RestoreTooltipAppearance(GameTooltip)
            if GameTooltip:IsShown() then GameTooltip:Hide() end
        end
    end
    if self.UpdateMinimapAppearance then self:UpdateMinimapAppearance() end
    if self.RefreshOptions then self:RefreshOptions() end
    self:Print(self.db.enabled and self:T("ENABLED_MSG") or self:T("DISABLED_MSG"))
end

function OP:ToggleEnabled()
    self:SetEnabled(not self.db.enabled)
end

function OP:OpenOptions()
    if self.ShowOptions then self:ShowOptions() end
end

function OP:RegisterSlashCommands()
    SLASH_ONPOINT1 = "/onpoint"
    SLASH_ONPOINT2 = "/op"
    SlashCmdList.ONPOINT = function(msg)
        msg = (msg or ""):lower():match("^%s*(.-)%s*$")
        if msg == "on" then
            OP:SetEnabled(true)
        elseif msg == "off" then
            OP:SetEnabled(false)
        elseif msg == "toggle" then
            OP:ToggleEnabled()
        elseif msg == "reset" then
            OP:ResetDB()
            if OP.UpdateMinimapPosition then OP:UpdateMinimapPosition() end
            if OP.RefreshOptions then OP:RefreshOptions() end
            OP:Print(OP:T("RESET_DONE"))
        elseif msg == "debug" then
            local profile, name, context = OP:GetActiveProfile()
            local _, _, _, build = GetBuildInfo()
            OP:Print(OP:T("DEBUG_VERSION") .. " " .. OP.version .. " | " .. OP:T("DEBUG_BUILD") .. " " .. tostring(build) .. " | " .. OP:T("DEBUG_CONTEXT") .. " " .. tostring(context) .. " | " .. OP:T("DEBUG_PROFILE") .. " " .. tostring(name))
            OP:Print("TooltipDataProcessor: " .. tostring(TooltipDataProcessor ~= nil) .. " | C_Spell.IsSpellInRange: " .. tostring(C_Spell and C_Spell.IsSpellInRange ~= nil))
        else
            OP:OpenOptions()
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == OP.name then
        OP:InitializeDB()
        OP:RegisterSlashCommands()
        OP:InstallTooltipHooks()
        if OP.InitializeMinimap then OP:InitializeMinimap() end
        if OP.InitializeOptions then OP:InitializeOptions() end
    elseif event == "PLAYER_LOGIN" then
        if OP.UpdateMinimapPosition then OP:UpdateMinimapPosition() end
    else
        if GameTooltip and GameTooltip:IsShown() then
            GameTooltip.__OnPointSignature = nil
            OP:RefreshUnitTooltip(GameTooltip)
        end
        if OP.RefreshOptions then OP:RefreshOptions() end
    end
end)
