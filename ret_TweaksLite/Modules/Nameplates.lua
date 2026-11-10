local _, ns = ...

--------------------------------------------------------------------------------
-- Name coloring
--------------------------------------------------------------------------------

-- Blizzard colors a nameplate's name in CompactUnitFrame_UpdateName
-- (Blizzard_UnitFrame/Shared/CompactUnitFrame.lua) with frame.name:SetVertexColor.
-- A post-hook recolors the name after every Blizzard update. Shared with the Debug
-- module, which tests the same code on NPCs.
local NameplateNames = {}
ns.NameplateNames = NameplateNames

-- Active rules: rule -> true. A rule is function(unit) that returns the name's
-- color r, g, b, or nothing to leave the name as Blizzard colored it.
local rules = {}
-- The color Blizzard gave a name before it was recolored, to restore it.
local originalColors = setmetatable({}, { __mode = "k" })
local hooked = false

-- The game's reaction color: the one Blizzard uses for the selection circle and,
-- with extended colors, for the names on Legacy-style nameplates.
-- UnitSelectionColor returns plain values, not secret ones.
function NameplateNames.GetReactionColor(unit)
    local r, g, b = UnitSelectionColor(unit, true)
    return r, g, b
end

local function IsNameplateUnitFrame(frame)
    if frame:IsForbidden() or not frame.name then
        return false
    end
    local unit = frame.unit
    return type(unit) == "string" and unit:find("^nameplate") ~= nil
end

local function GetRuleColor(unit)
    for rule in pairs(rules) do
        local r, g, b = rule(unit)
        if r then
            return r, g, b
        end
    end
end

local function ApplyColor(frame)
    local name = frame.name
    local original = originalColors[name]
    local r, g, b = GetRuleColor(frame.unit)
    if r then
        if not original then
            originalColors[name] = { name:GetVertexColor() }
        end
        name:SetVertexColor(r, g, b)
    elseif original then
        name:SetVertexColor(unpack(original))
        originalColors[name] = nil
    end
end

-- The Classic nameplate style highlights the name under the mouse with
-- optionTable.nameMouseoverColor, and that highlight stays. It is recognized
-- by its color: UnitIsUnit(unit, "mouseover") can return a secret value.
local function HasMouseoverHighlight(frame)
    local color = frame.optionTable and frame.optionTable.nameMouseoverColor
    if not color then
        return false
    end
    local r, g, b = frame.name:GetVertexColor()
    return math.abs(r - color.r) < 0.01 and math.abs(g - color.g) < 0.01 and math.abs(b - color.b) < 0.01
end

-- Runs after Blizzard has set the name's color, which makes any stored color stale.
-- Blizzard also calls CompactUnitFrame_UpdateName on UNIT_FACTION, so a player who
-- becomes attackable gets the new reaction color at once.
-- The function also serves raid and party frames; they are skipped.
local function OnUpdateName(frame)
    if not IsNameplateUnitFrame(frame) then
        return
    end
    originalColors[frame.name] = nil
    if HasMouseoverHighlight(frame) then
        return
    end
    ApplyColor(frame)
end

local function RefreshAll()
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = plate.UnitFrame
        if frame and IsNameplateUnitFrame(frame) then
            ApplyColor(frame)
        end
    end
end

-- Call from a module's Start: a hook cannot be removed, so it is installed
-- only by a running module, and only once.
function NameplateNames.Hook()
    if hooked then
        return
    end
    hooked = true
    hooksecurefunc("CompactUnitFrame_UpdateName", OnUpdateName)
end

-- Call from a tweak's Apply: takes effect on visible nameplates at once.
function NameplateNames.SetRule(rule, enabled)
    rules[rule] = enabled or nil
    RefreshAll()
end

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

-- Players who are not friendly: enemy faction, PvP-flagged or not.
-- UnitIsPlayer and UnitIsFriend return plain values, so this works in combat too.
local function EnemyPlayerColor(unit)
    if UnitIsPlayer(unit) and not UnitIsFriend("player", unit) then
        return NameplateNames.GetReactionColor(unit)
    end
end

ns.RegisterModule({
    key = "Nameplates",
    category = "Interface",
    title = "Nameplates",
    description = "Tweaks for unit nameplates.",
    Start = function()
        NameplateNames.Hook()
    end,
    tweaks = {
        {
            key = "EnemyPlayerNamesReactionColor",
            title = "Enemy player names in reaction color",
            description = "Colors the names of enemy players with the game's reaction color, "
                .. "the same as their selection circle: red means you can attack them. "
                .. "Tells them apart from NPCs whose health bars share a class color.",
            Apply = function(enabled)
                NameplateNames.SetRule(EnemyPlayerColor, enabled)
            end,
        },
    },
})
