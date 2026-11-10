local _, ns = ...

-- Test versions of tweaks whose real situation is hard to reach (PvP, rare
-- events). Each test runs the tweak's own code on units that are easy to find.

-- Test for Nameplates > Enemy player names in red: the same coloring code,
-- applied to NPCs you can attack instead of players.
local function IsEnemyNPC(unit)
    return not UnitIsPlayer(unit) and UnitCanAttack("player", unit)
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
            key = "EnemyNPCNamesRed",
            title = "Enemy NPC names in red",
            description = "Test for Nameplates: Enemy player names in red. Colors the names "
                .. "of NPCs you can attack the same way, so the tweak can be checked without PvP.",
            Apply = function(enabled)
                ns.NameplateNames.SetRule(IsEnemyNPC, enabled)
            end,
        },
    },
})
