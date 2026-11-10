local _, ns = ...

-- Test versions of tweaks whose real situation is hard to reach (PvP, rare
-- events). Each test runs the tweak's own code on units that are easy to find.

-- Test for Nameplates > Enemy player names in reaction color: the same coloring
-- code, applied to NPCs that are not friendly instead of players.
local function EnemyNPCColor(unit)
    if not UnitIsPlayer(unit) and not UnitIsFriend("player", unit) then
        return ns.NameplateNames.GetReactionColor(unit)
    end
end

ns.RegisterModule({
    key = "Debug",
    category = "Developer",
    title = "Debug",
    description = "Test versions of tweaks that are hard to check in the real situation.",
    Start = function()
        ns.NameplateNames.Hook()
    end,
    tweaks = {
        {
            key = "EnemyNPCNamesReactionColor",
            title = "Enemy NPC names in reaction color",
            description = "Test for Nameplates: Enemy player names in reaction color. Colors "
                .. "the names of NPCs that are not friendly the same way (hostile red, neutral "
                .. "yellow), so the tweak can be checked without PvP.",
            Apply = function(enabled)
                ns.NameplateNames.SetRule(EnemyNPCColor, enabled)
            end,
        },
    },
})
