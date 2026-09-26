OnPoint = OnPoint or {}
local OP = OnPoint

OP.contextNames = {
    world = OP:T("CONTEXT_WORLD"),
    combat = OP:T("CONTEXT_COMBAT"),
    battleground = OP:T("CONTEXT_BG"),
    dungeon = OP:T("CONTEXT_DUNGEON"),
    raid = OP:T("CONTEXT_RAID"),
}

OP.contextOrder = {"world", "combat", "battleground", "dungeon", "raid"}

OP.builtinProfiles = {
    ["Minimal"] = {
        classColor = true,
        guild = false,
        faction = false,
        factionPrefix = true,
        pvp = false,
        creatureType = false,
        petOwner = false,
        range = true,
        rangePrefix = true,
        healthBar = true,
        resourceBar = false,
        barPosition = "BOTTOM",
        barPercent = false,
    },
    ["Bevorzugt"] = {
        classColor = true,
        guild = true,
        faction = true,
        factionPrefix = true,
        pvp = true,
        creatureType = true,
        petOwner = true,
        range = true,
        rangePrefix = true,
        healthBar = true,
        resourceBar = true,
        barPosition = "BOTTOM",
        barPercent = true,
    },
    ["Komplett"] = {
        classColor = true,
        guild = true,
        faction = true,
        factionPrefix = true,
        pvp = true,
        creatureType = true,
        petOwner = true,
        range = true,
        rangePrefix = true,
        healthBar = true,
        resourceBar = true,
        barPosition = "TOP",
        barPercent = true,
    },
}

OP.builtinOrder = {"Minimal", "Bevorzugt", "Komplett"}

local builtinDisplay = {
    ["Minimal"] = "PRESET_MINIMAL",
    ["Bevorzugt"] = "PRESET_PREFERRED",
    ["Komplett"] = "PRESET_COMPLETE",
}

local profileDefaults = {
    classColor = true,
    guild = true,
    faction = true,
    factionPrefix = true,
    pvp = true,
    creatureType = true,
    petOwner = true,
    range = true,
    rangePrefix = true,
    healthBar = true,
    resourceBar = true,
    barPosition = "BOTTOM",
    barPercent = true,
}

function OP:GetProfileDisplayName(name)
    local key = builtinDisplay[name]
    if key then return self:T(key) end
    return name
end

function OP:IsBuiltinProfile(name)
    return self.builtinProfiles[name] ~= nil
end

function OP:GetProfile(name)
    if self.builtinProfiles[name] then return self.builtinProfiles[name] end
    if self.db and self.db.customProfiles then return self.db.customProfiles[name] end
    return nil
end

function OP:NormalizeCustomProfiles()
    if not self.db or type(self.db.customProfiles) ~= "table" then return end
    for _, profile in pairs(self.db.customProfiles) do
        if type(profile) == "table" then
            for key, value in pairs(profileDefaults) do
                if profile[key] == nil then profile[key] = value end
            end
        end
    end
end

function OP:GetAllProfileNames()
    local list = {}
    for _, name in ipairs(self.builtinOrder) do
        table.insert(list, {value = name, text = self:GetProfileDisplayName(name)})
    end
    local custom = {}
    if self.db and self.db.customProfiles then
        for name in pairs(self.db.customProfiles) do table.insert(custom, name) end
    end
    table.sort(custom)
    for _, name in ipairs(custom) do table.insert(list, {value = name, text = name}) end
    return list
end

function OP:MakeUniqueProfileName(base)
    base = tostring(base or "Custom Profile"):match("^%s*(.-)%s*$")
    if base == "" then base = "Custom Profile" end
    base = base:sub(1, 32)

    if not self:GetProfile(base) then return base end
    local i = 2
    while self:GetProfile(base .. " " .. i) do i = i + 1 end
    return base .. " " .. i
end

function OP:CreateCustomProfile(name, sourceProfileName)
    local unique = self:MakeUniqueProfileName(name)
    local source = self:GetProfile(sourceProfileName) or self.builtinProfiles["Bevorzugt"]
    self.db.customProfiles[unique] = self.CopyTable(source)
    return unique
end

function OP:DeleteCustomProfile(name)
    if self:IsBuiltinProfile(name) then return false end
    if not self.db.customProfiles[name] then return false end
    self.db.customProfiles[name] = nil
    for _, context in ipairs(self.contextOrder) do
        if self.db.contextProfile[context] == name then
            self.db.contextProfile[context] = "Bevorzugt"
        end
    end
    return true
end

function OP:EnsureEditableProfile(context)
    context = context or "world"
    local name = self.db.contextProfile[context] or "Bevorzugt"
    if not self:IsBuiltinProfile(name) then return self.db.customProfiles[name], name end

    local base = self:GetProfileDisplayName(name) .. " – " .. (self.contextNames[context] or context)
    local customName = self:CreateCustomProfile(base, name)
    self.db.contextProfile[context] = customName
    return self.db.customProfiles[customName], customName
end
