local _, ns = ...

-- issecretvalue exists in clients with secret values; elsewhere nothing is secret.
local issecretvalue = issecretvalue or function()
    return false
end

-- Both tweaks follow UnitFrame_Update (Blizzard_UnitFrame/Mainline/UnitFrame.lua),
-- which Blizzard calls whenever a unit frame shows a new unit. The target of target
-- frame calls it every frame from OnUpdate, so the hook stays cheap.
local UNITS = { target = true, targettarget = true, focus = true }

local classColorActive = false
local backgroundActive = false

--------------------------------------------------------------------------------
-- Player names in class color
--------------------------------------------------------------------------------

-- UnitFrame_Update sets the name's text but never its color, so the name keeps
-- its font's color unless recolored here.

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

--------------------------------------------------------------------------------
-- Name background on target of target
--------------------------------------------------------------------------------

-- The target frame has a name background (ReputationColor in TargetFrame.xml)
-- that TargetFrameMixin:CheckFaction colors; the target of target frame has none.
-- This adds one with the same atlas and the same color rule.
local nameBackground

local function GetFactionColor(unit)
    if not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        return 0.5, 0.5, 0.5
    end
    local r, g, b = UnitSelectionColor(unit)
    return r, g, b
end

-- Created on first use, on the target of target frame, so it shows and hides
-- with it. Above the frame art, below the name. The name's box (68 wide) is
-- narrower than the slot in the frame art, so the right edge follows the health
-- bar instead, which spans the slot; the top and left follow the name.
-- The atlas has a thin transparent margin, so the offsets reach a little past
-- the slot; they were fitted to in-game screenshots.
local function GetNameBackground(frame)
    if not nameBackground then
        local healthBar = frame.HealthBar or frame.healthbar
        nameBackground = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
        nameBackground:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Type")
        nameBackground:SetPoint("TOPLEFT", frame.name, "TOPLEFT", -3, 1)
        nameBackground:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", 2, 0)
    end
    return nameBackground
end

local function UpdateNameBackground(frame)
    GetNameBackground(frame):SetVertexColor(GetFactionColor(frame.unit))
end

--------------------------------------------------------------------------------
-- Hook and tweaks
--------------------------------------------------------------------------------

local function OnUnitFrameUpdate(frame)
    if not UNITS[frame.unit] or not frame.name then
        return
    end
    if classColorActive then
        UpdateName(frame)
    end
    if backgroundActive and frame.unit == "targettarget" then
        UpdateNameBackground(frame)
    end
end

local function SetPlayerNamesClassColor(on)
    classColorActive = on
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

local function SetTargetOfTargetNameBackground(on)
    backgroundActive = on
    local frame = TargetFrame and TargetFrame.totFrame
    if not frame then
        return
    end
    GetNameBackground(frame):SetShown(on)
    if on and UnitExists(frame.unit) then
        UpdateNameBackground(frame)
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
        {
            key = "TargetOfTargetNameBackground",
            title = "Name background on target of target",
            description = "Gives the target of target frame the name background the target frame "
                .. "has, in the same reaction color.",
            Apply = SetTargetOfTargetNameBackground,
        },
    },
})
