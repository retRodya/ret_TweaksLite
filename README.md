# ret_TweaksLite

Small quality-of-life tweaks for World of Warcraft, without the bloat.

ret_TweaksLite collects tweaks that other addons either lack or bury among hundreds
of options. Tweaks are grouped into modules. A module turns on or off after a UI
reload, and a module you leave off does nothing at all. Inside a running module,
each tweak is one checkbox that applies at once.

The same files work in WoW Retail and WoW Forever.

> **Status:** early development, nothing is released yet.

## Planned for 0.1.0

- **Interface → Tooltips**
  - **Health bar above tooltip:** shows the unit health bar above the tooltip
    instead of below it.
- **Interface → Nameplates**
  - **Enemy player names in reaction color:** colors the names of enemy players
    on their nameplates with the game's reaction color, the same as their
    selection circle; red means you can attack them. Useful when health bars
    are class-colored and an enemy mage looks like a caster NPC.
- **Interface → Unit Frames**
  - **Player names in class color:** colors the names of players, allies and
    enemies, on the target, target of target and focus frames in their class color.
  - **Name background on target of target:** gives the target of target frame
    the reaction-colored name background the target frame has.

## Installation

Copy the `ret_TweaksLite` folder into your client's `Interface/AddOns` folder:

- Retail: `_retail_/Interface/AddOns/ret_TweaksLite/`
- Forever: `_forever_/Interface/AddOns/ret_TweaksLite/`

## Usage

1. Open the addon window with `/rettl` or `/rettweakslite`, from the Addon
   Compartment, or from Settings → AddOns → ret_TweaksLite.
2. Tick the checkbox next to a module and reload the UI.
3. Select the module and tick the tweaks you want. They apply at once.
   Some tweaks have settings, which appear under them while they are ticked.

Modules and tweaks are off by default. An undo button next to a module, tweak
or setting marks what you changed since the last reload; click it to set
the change back.
