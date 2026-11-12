local _, ns = ...

-- issecretvalue exists in clients with secret values; elsewhere nothing is secret.
local issecretvalue = issecretvalue or function()
    return false
end

local MODULE_KEY = "Tooltips"
local AURAS_KEY = "ShowAuras"

--------------------------------------------------------------------------------
-- Health bar above tooltip
--------------------------------------------------------------------------------

-- Blizzard anchors the health bar under the tooltip once, in XML
-- (Blizzard_GameTooltip/Mainline/GameTooltip.xml), and never re-anchors it
-- from Lua. So the bar stays where this tweak puts it, and turning the tweak off
-- restores the XML anchors. The bar stays Blizzard's own: this tweak never reads
-- unit health, which can be a secret value.
local function GetHealthBar()
    return GameTooltip.StatusBar or GameTooltipStatusBar
end

local healthBarAbove = false
local AnchorAuras -- defined below; the auras sit above the bar when it is above

local function SetHealthBarAboveTooltip(above)
    healthBarAbove = above
    local bar = GetHealthBar()
    bar:ClearAllPoints()
    if above then
        bar:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 2, 1)
        bar:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -2, 1)
    else
        bar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -1)
        bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -1)
    end
    AnchorAuras()
end

--------------------------------------------------------------------------------
-- Show auras
--------------------------------------------------------------------------------

-- Buffs the player can cast (filter RAID) on the tooltip's unit, in one or more
-- rows above the tooltip: the player's own first and larger (filter PLAYER),
-- like on the target frame, then the same buffs from others (filter !PLAYER).
-- The game's filters tell whose aura it is, so the addon never reads the aura's
-- caster, which can be a secret value.
local OWN_FILTER = "HELPFUL|RAID|PLAYER"
local OTHERS_FILTER = "HELPFUL|RAID|!PLAYER"

local SPACING = 2 -- between icons and between rows
local GAP = 2 -- between the tooltip (or the health bar above it) and the icons
local ICONS_PER_ROW = 8 -- when the tooltip's width is a secret value

local aurasActive = false
local aurasUnit -- unit token whose auras are shown
local container -- child of the tooltip, so it hides, fades and scales with it
local icons = {}

local function GetSetting(key)
    return ns.GetSetting(MODULE_KEY, AURAS_KEY, key)
end

-- Some unit tokens are restricted for addons; for them there are no auras.
local function GetAuras(unit, filter)
    local ok, auras = pcall(C_UnitAuras.GetUnitAuras, unit, filter)
    return ok and auras or {}
end

function AnchorAuras()
    if not container then
        return
    end
    container:ClearAllPoints()
    if healthBarAbove then
        container:SetPoint("BOTTOMLEFT", GetHealthBar(), "TOPLEFT", 0, GAP)
    else
        container:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 2, GAP)
    end
end

-- The time left darkens the icon clockwise, with a bright edge, as on the target
-- frame (TargetFrameAuraButton: CooldownFrame_Set with reverse and drawEdge).
local function CreateIcon()
    local icon = CreateFrame("Frame", nil, container)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon.cooldown:SetReverse(true)
    icon.cooldown:SetDrawEdge(true)
    icon.cooldown:SetDrawBling(false)
    icon.cooldown:SetHideCountdownNumbers(true)
    return icon
end

local function SetDurationObject(cooldown, unit, auraInstanceID)
    cooldown:SetCooldownFromDurationObject(C_UnitAuras.GetAuraDuration(unit, auraInstanceID))
end

-- Addon code may not pass secret times to a cooldown. When the aura's times
-- are secret, the game's duration object carries them instead; if even that
-- fails, the icon shows no time.
local function SetAuraDuration(cooldown, aura)
    local duration, expirationTime = aura.duration, aura.expirationTime
    if not issecretvalue(duration) and not issecretvalue(expirationTime) then
        if duration and expirationTime and duration > 0 then
            cooldown:SetCooldown(expirationTime - duration, duration)
        else
            cooldown:Clear()
        end
    elseif not (C_UnitAuras.GetAuraDuration and cooldown.SetCooldownFromDurationObject
        and pcall(SetDurationObject, cooldown, aurasUnit, aura.auraInstanceID)) then
        cooldown:Clear()
    end
end

-- Rows fill from the bottom up and wrap at the tooltip's width; icons in a row
-- line up at the bottom.
local function LayoutAuras()
    local ownSize, otherSize = GetSetting("OwnAuraSize"), GetSetting("AuraSize")
    local width = GameTooltip:GetWidth()
    if issecretvalue(width) then
        width = ICONS_PER_ROW * (otherSize + SPACING)
    else
        width = width - 4
    end

    local count, x, y, rowHeight = 0, 0, 0, 0
    local function Place(aura, size)
        if x > 0 and x + size > width then
            x, y, rowHeight = 0, y + rowHeight + SPACING, 0
        end
        count = count + 1
        local icon = icons[count]
        if not icon then
            icon = CreateIcon()
            icons[count] = icon
        end
        icon.texture:SetTexture(aura.icon)
        icon:SetSize(size, size)
        icon:ClearAllPoints()
        icon:SetPoint("BOTTOMLEFT", x, y)
        icon:Show()
        SetAuraDuration(icon.cooldown, aura)
        x = x + size + SPACING
        rowHeight = math.max(rowHeight, size)
    end

    for _, aura in ipairs(GetAuras(aurasUnit, OWN_FILTER)) do
        Place(aura, ownSize)
    end
    for _, aura in ipairs(GetAuras(aurasUnit, OTHERS_FILTER)) do
        Place(aura, otherSize)
    end
    for index = count + 1, #icons do
        icons[index]:Hide()
    end
end

local function HideAuras()
    aurasUnit = nil
    if container then
        container:Hide()
    end
end

-- While the auras show, a buff cast on the unit appears at once.
local function OnAuraEvent(_, _, unit)
    if not aurasUnit or not UnitExists(aurasUnit) then
        return
    end
    local same = UnitIsUnit(unit, aurasUnit)
    if issecretvalue(same) or same then
        LayoutAuras()
    end
end

local function CreateContainer()
    container = CreateFrame("Frame", nil, GameTooltip)
    container:SetSize(1, 1)
    container:Hide()
    container:SetScript("OnShow", function(self)
        self:RegisterEvent("UNIT_AURA")
    end)
    container:SetScript("OnHide", function(self)
        self:UnregisterEvent("UNIT_AURA")
    end)
    container:SetScript("OnEvent", OnAuraEvent)
    AnchorAuras()
end

-- Shown with every unit tooltip, even without auras, so that a buff cast while
-- the tooltip is open still appears.
local function ShowAuras()
    if not aurasActive or not GameTooltip:IsShown() then
        return
    end
    local _, unit = GameTooltip:GetUnit()
    if issecretvalue(unit) or not unit then
        HideAuras()
        return
    end
    if not container then
        CreateContainer()
    end
    aurasUnit = unit
    container:Show()
    LayoutAuras()
end

local function SetShowAuras(on)
    aurasActive = on
    if on then
        ShowAuras()
    else
        HideAuras()
    end
end

-- The tooltip calls Show after it has its lines, so its width is final here.
-- Clearing comes first whenever the tooltip changes to something else.
local function HookTooltip()
    hooksecurefunc(GameTooltip, "Show", ShowAuras)
    GameTooltip:HookScript("OnTooltipCleared", HideAuras)
end

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

ns.RegisterModule({
    key = MODULE_KEY,
    category = "Interface",
    title = "Tooltips",
    description = "Tweaks for the game tooltip.",
    Start = HookTooltip,
    tweaks = {
        {
            key = "HealthBarAboveTooltip",
            title = "Health bar above tooltip",
            description = "Shows the unit health bar above the tooltip instead of below it.",
            Apply = SetHealthBarAboveTooltip,
        },
        {
            key = AURAS_KEY,
            title = "Show auras",
            description = "Shows the buffs you can cast that are on the unit, above its tooltip. "
                .. "Yours come first and are larger, as on the target frame. "
                .. "Each icon darkens clockwise as its buff runs out. "
                .. "With the health bar above the tooltip, they sit above the bar.",
            Apply = SetShowAuras,
            settings = {
                {
                    key = "AuraSize",
                    title = "Aura size",
                    description = "Size of the icons of buffs from other players, in pixels.",
                    min = 10,
                    max = 40,
                    default = 17,
                },
                {
                    key = "OwnAuraSize",
                    title = "Your aura size",
                    description = "Size of the icons of your own buffs, in pixels.",
                    min = 10,
                    max = 40,
                    default = 21,
                },
            },
        },
    },
})
