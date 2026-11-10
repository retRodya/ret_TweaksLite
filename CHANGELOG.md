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
- **Interface → Tooltips** module with the **Health bar above tooltip** tweak:
  shows the unit health bar above the tooltip instead of below it.
- **Interface → Nameplates** module with the **Enemy player names in red** tweak:
  colors the names of enemy players you can attack red on their nameplates.
- **Developer → Debug** module with test versions of hard-to-reach tweaks.
  **Enemy NPC names in red** checks the nameplate name coloring without PvP.
