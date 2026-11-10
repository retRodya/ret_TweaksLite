local _, ns = ...

-- issecretvalue exists in clients with secret values; elsewhere nothing is secret.
local issecretvalue = issecretvalue or function()
    return false
end

--------------------------------------------------------------------------------
-- Player names in class color
--------------------------------------------------------------------------------

-- UnitFrame_Update (Blizzard_UnitFrame/Mainline/UnitFrame.lua) sets the name's text
-- but never its color, so the name keeps its font's color. A post-hook colors
-- player names; the target of target frame calls it every frame from OnUpdate,
-- so the hook stays cheap.
local UNITS = { target = true, targettarget = true, focus = true }

local active = false
-- The color a name had before it was recolored, to restore it.
local originalColors = setmetatable({}, { __mode = "k" })

local function GetFrames()
    return { TargetFrame, TargetFrame and TargetFrame.totFrame, FocusFrame }
end

local function GetClassColor(unit)
    if not UnitIsPlayer(unit) then
        return
    end
    -- UnitClass returns a secret value while the unit's identity is restricted;
    -- then the name keeps its color.
    local _, classFile = UnitClass(unit)
    if classFile == nil or issecretvalue(classFile) then
        return
    end
    local color = RAID_CLASS_COLORS[classFile]
    if color then
        return color.r, color.g, color.b
    end
end

local function UpdateName(frame)
    local name = frame.name
    local r, g, b = GetClassColor(frame.unit)
    local original = originalColors[name]
    if r then
        if not original then
            originalColors[name] = { name:GetTextColor() }
        end
        name:SetTextColor(r, g, b)
    elseif original then
        name:SetTextColor(unpack(original))
        originalColors[name] = nil
    end
end

local function OnUnitFrameUpdate(frame)
    if active and UNITS[frame.unit] and frame.name then
        UpdateName(frame)
    end
end

local function SetPlayerNamesClassColor(on)
    active = on
    if on then
        for _, frame in pairs(GetFrames()) do
            OnUnitFrameUpdate(frame)
        end
    else
        for name, color in pairs(originalColors) do
            name:SetTextColor(unpack(color))
            originalColors[name] = nil
        end
    end
end

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

ns.RegisterModule({
    key = "UnitFrames",
    category = "Interface",
    title = "Unit Frames",
    description = "Tweaks for the target, target of target and focus frames.",
    Start = function()
        hooksecurefunc("UnitFrame_Update", OnUnitFrameUpdate)
    end,
    tweaks = {
        {
            key = "PlayerNamesClassColor",
            title = "Player names in class color",
            description = "Colors the names of players on the target, target of target and focus "
                .. "frames in their class color, allies and enemies alike. NPC names keep "
                .. "the game's color.",
            Apply = SetPlayerNamesClassColor,
        },
    },
})
