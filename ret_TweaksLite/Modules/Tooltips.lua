local _, ns = ...

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

local function SetHealthBarAboveTooltip(above)
    local bar = GetHealthBar()
    bar:ClearAllPoints()
    if above then
        bar:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 2, 1)
        bar:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -2, 1)
    else
        bar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -1)
        bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -1)
    end
end

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

ns.RegisterModule({
    key = "Tooltips",
    category = "Interface",
    title = "Tooltips",
    description = "Tweaks for the game tooltip.",
    tweaks = {
        {
            key = "HealthBarAboveTooltip",
            title = "Health bar above tooltip",
            description = "Shows the unit health bar above the tooltip instead of below it.",
            Apply = SetHealthBarAboveTooltip,
        },
    },
})
