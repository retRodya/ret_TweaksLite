# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Addon window. On the left: a General page and collapsible groups of modules,
  each module with a checkbox to turn it on. A group's page lists its modules,
  enabled ones in white and disabled ones in grey. On the right: the selected
  module's tweaks.
- Modules are off by default and turn on or off after a UI reload; until then
  the module's page says so and a Reload UI button appears. Tweaks apply at once.
- An undo button next to every module and tweak changed since the last UI reload
  shows what you changed and sets it back with one click.
- `/rettl` and `/rettweakslite` open the window. It also opens from
  the Addon Compartment and from the addon's page in Settings → AddOns.
- Tweaks can have settings: sliders under the tweak, shown while it is checked,
  with an undo button like everything else.
- **Interface → Tooltips** module with the **Health bar above tooltip** tweak:
  shows the unit health bar above the tooltip instead of below it.
  The **Show auras** tweak shows the buffs you can cast that are on the unit,
  above its tooltip: yours first and larger, then the same buffs from other
  players. Each icon darkens clockwise as its buff runs out, as on the target
  frame. It sits above the health bar when that is above the tooltip too.
  Its settings are the icon size for others' buffs and for your own.
- **Interface → Nameplates** module with the **Enemy player names in reaction color**
  tweak: colors the names of enemy players on their nameplates with the game's
  reaction color, the same as their selection circle (red means you can attack them).
- **Interface → Unit Frames** module with the **Player names in class color** tweak:
  colors the names of players, allies and enemies, on the target, target of target
  and focus frames in their class color. The **Name background on target of target**
  tweak gives the target of target frame the reaction-colored name background
  the target frame has.
- **Developer → Debug** module with test versions of hard-to-reach tweaks.
  **Enemy NPC names in reaction color** checks the nameplate name coloring
  without PvP.
