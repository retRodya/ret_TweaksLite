local _, ns = ...

--------------------------------------------------------------------------------
-- Name coloring
--------------------------------------------------------------------------------

-- Blizzard colors a nameplate's name in CompactUnitFrame_UpdateName
-- (Blizzard_UnitFrame/Shared/CompactUnitFrame.lua) with frame.name:SetVertexColor.
-- A post-hook recolors the name after every Blizzard update. Shared with the Debug
-- module, which tests the same code on enemy NPCs.
local NameplateNames = {}
ns.NameplateNames = NameplateNames

-- Blizzard's own hostile name color.
local RED_R, RED_G, RED_B = 1, 0, 0

-- Active rules: rule -> true. A rule is function(unit) that returns true
-- when the unit's name should be red.
local rules = {}
-- The color Blizzard gave a name before it was recolored, to restore it.
local originalColors = setmetatable({}, { __mode = "k" })
local hooked = false

local function IsNameplateUnitFrame(frame)
    if frame:IsForbidden() or not frame.name then
        return false
    end
    local unit = frame.unit
    return type(unit) == "string" and unit:find("^nameplate") ~= nil
end

local function ShouldColor(unit)
    for rule in pairs(rules) do
        if rule(unit) then
            return true
        end
    end
    return false
end

local function ApplyColor(frame)
    local name = frame.name
    local original = originalColors[name]
    if ShouldColor(frame.unit) then
        if not original then
            originalColors[name] = { name:GetVertexColor() }
        end
        name:SetVertexColor(RED_R, RED_G, RED_B)
    elseif original then
        name:SetVertexColor(unpack(original))
        originalColors[name] = nil
    end
end

-- Runs after Blizzard has set the name's color, which makes any stored color stale.
-- CompactUnitFrame_UpdateName also serves raid and party frames; they are skipped.
local function OnUpdateName(frame)
    if not IsNameplateUnitFrame(frame) then
        return
    end
    originalColors[frame.name] = nil
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

-- UnitIsPlayer and UnitCanAttack return plain booleans, not secret values,
-- so this works in combat too.
local function IsEnemyPlayer(unit)
    return UnitIsPlayer(unit) and UnitCanAttack("player", unit)
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
            key = "EnemyPlayerNamesRed",
            title = "Enemy player names in red",
            description = "Colors the names of enemy players you can attack red, so they stand out "
                .. "from NPCs whose health bars share a class color.",
            Apply = function(enabled)
                NameplateNames.SetRule(IsEnemyPlayer, enabled)
            end,
        },
    },
})
