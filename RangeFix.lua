local OP = ComfyOnPoint or OnPoint
if not OP then return end

OP.version = "1.17"
OP.buildDate = "04.10.2026"

local originalAddUnitInfo = OP.AddUnitInfo
if type(originalAddUnitInfo) ~= "function" then return end

local function CopyProfileWithoutRange(profile)
    local copy = {}
    for k, v in pairs(profile or {}) do
        copy[k] = v
    end
    copy.range = false
    return copy
end

local function GetLineText(tooltip, index)
    local name = tooltip and tooltip.GetName and tooltip:GetName()
    if not name then return nil, nil end
    local line = _G[name .. "TextLeft" .. index]
    if not line or type(line.GetText) ~= "function" then return nil, line end
    local ok, text = pcall(line.GetText, line)
    if not ok then return nil, line end
    return text, line
end

local function Normalize(text)
    if type(text) ~= "string" then return "" end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text:lower()
end

local function FindExistingRangeLine(tooltip)
    if not tooltip or type(tooltip.NumLines) ~= "function" then return nil end
    local count = tonumber(tooltip:NumLines()) or 0
    for i = 1, count do
        local text = GetLineText(tooltip, i)
        local normalized = Normalize(text)
        if normalized:find("^reichweite%s*:")
            or normalized:find("^range%s*:")
            or normalized == "out of range"
            or normalized == "in range"
            or normalized == "außer reichweite"
            or normalized == "in reichweite" then
            return i
        end
    end
    return nil
end

local originalFormatRange = OP.FormatRange
function OP:FormatRange(state, profile)
    if type(GetLocale) == "function" and GetLocale() == "deDE" then
        local value = state and "In Reichweite" or "Außer Reichweite"
        if profile and profile.rangePrefix == false then
            return value
        end
        return "Reichweite: " .. value
    end
    if originalFormatRange then
        return originalFormatRange(self, state, profile)
    end
    return state and "In Range" or "Out of Range"
end

function OP:AddUnitInfo(tooltip, unit, profile)
    if not profile or not profile.range then
        return originalAddUnitInfo(self, tooltip, unit, profile)
    end

    local profileWithoutRange = CopyProfileWithoutRange(profile)
    originalAddUnitInfo(self, tooltip, unit, profileWithoutRange)

    local state = self:GetRangeState(unit)
    if state == nil then return end

    local r, g, b
    if state then
        r, g, b = self.colors.green[1], self.colors.green[2], self.colors.green[3]
    else
        r, g, b = self.colors.red[1], self.colors.red[2], self.colors.red[3]
    end

    local index = FindExistingRangeLine(tooltip)
    if index then
        local _, line = GetLineText(tooltip, index)
        if line then
            line:SetText(self:FormatRange(state, profile))
            line:SetTextColor(r, g, b)
            line:Show()
        end
    else
        tooltip:AddLine(self:FormatRange(state, profile), r, g, b)
        index = tooltip:NumLines()
    end

    tooltip.__ComfyOnPointRangeLine = index
    tooltip:Show()
end
