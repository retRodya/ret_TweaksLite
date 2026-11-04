# ret_TweaksLite

World of Warcraft addon for Retail and Forever: a small set of quality-of-life tweaks
that other addons either lack or bury among too many options. One window, category
tabs on the left, one checkbox per tweak; changes apply after `/reload`.
Read `docs/VISION.md` before proposing or building features: it defines the scope
of the next version and records decisions. `docs/ROADMAP.md` shows where the project
stands and what comes next.

## Repository layout

- `ret_TweaksLite/` — the addon exactly as it ships. Only game files go here.
- `docs/` — planning and development documents.
- `references/` — third-party addons (Leatrix Plus, TipTac) kept locally for study
  and ignored by git. Mine them for knowledge (API usage, UI patterns, quirks),
  never copy their code.
- `CHANGELOG.md` — user-visible changes, Keep a Changelog format.

## Language

- Talk to the user in Russian. The user is learning to run a project: briefly
  explain the reasoning behind process and architecture choices.
- Code, comments, addon UI text, commit messages, CHANGELOG and README are English.
- Documents in `docs/` are Russian.

## Scope

- Build only what VISION.md lists for the current version. For anything else,
  suggest a GitHub issue instead of implementing it.
- New decisions go to the decision log in VISION.md. Committed rows are never
  rewritten; a new row supersedes an old one.

## Code

- One codebase for Retail and Forever. Guard APIs that differ between clients
  (`C_AddOns and C_AddOns.X or X`).
- Small files, one tweak per module file. The core (window, saved settings,
  module registry) knows nothing about specific tweaks; modules register themselves.
- A module's on/off state takes effect only after `/reload`. A disabled module
  creates no frames, registers no events, installs no hooks and runs no OnUpdate.
- Event-driven only: no polling, no timers that re-check state.
- Persistent game state a module changes (CVars) is restored when the module
  is turned off, even if the client crashed in between.
- Native Blizzard look: the window is built from Blizzard templates, with native
  fonts, tooltip styles and key bindings.

## Workflow

- One focused change per commit, Conventional Commits (`feat:`, `fix:`, `docs:`,
  `refactor:`, `chore:`).
- Add user-visible changes to `[Unreleased]` in CHANGELOG.md in the same commit.
- `## Version` in the TOC follows SemVer and changes only at release time.
- Claude cannot run the game: after a change, list what the user should check in-game.
- Commit and push only when the user asks.
