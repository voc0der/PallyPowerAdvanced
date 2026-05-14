# Contributing

Thanks for working on `PallyPowerAdvanced`.

This repo extends PallyPower for TBC Anniversary Classic. Changes should stay focused on role/spec-aware blessing assignment, the small amount of UI needed to make uncertain specs explicit, and release packaging.

## Local Setup

- Target client: TBC Anniversary Classic
- Addon install path: `World of Warcraft/_anniversary_/Interface/AddOns/`
- Runtime files are listed in [PallyPowerAdvanced.toc](PallyPowerAdvanced.toc)
- Requires the `PallyPower` addon to be installed and enabled

## Development

Keep a local Blizzard UI mirror at `../wow-ui-source`. If you do not already have it checked out:

```bash
git clone https://github.com/Gethe/wow-ui-source ../wow-ui-source
```

Refresh the Blizzard UI reference before you start work:

```bash
git -C ../wow-ui-source pull --ff-only
```

Use `../wow-ui-source` first for TOC, interface number, FrameXML, role APIs, popup/menu behavior, and Blizzard UI/API questions before changing addon code or guessing at client behavior.

Run the local test suite:

```bash
lua tests/run.lua
```

Run a syntax check before opening a PR:

```bash
luac -p PallyPowerAdvanced.lua tests/run.lua
```

If you change packaging or release behavior, verify the runtime-only package contents too:

```bash
bash ./.github/scripts/verify-release-package.sh
```

## Project Expectations

- Keep this addon as a focused extension of PallyPower rather than a fork of PallyPower source.
- Prefer source-verified TBC Anniversary APIs and PallyPower's existing assignment tables/messages over invented parallel state.
- If you add a new runtime file, include it in [PallyPowerAdvanced.toc](PallyPowerAdvanced.toc).
- Player-facing packages should only include files the game client actually needs.
- Validate UI behavior against TBC Anniversary whenever touching Blizzard templates, role APIs, or PallyPower frame anchoring.

## Pull Requests

- Use conventional commit titles such as `feat(...)`, `fix(...)`, `docs(...)`, or `ci(...)`.
- Include a short summary of what changed and how you verified it.
- If the change affects game UI, include screenshots or a brief description of the visible behavior.
- Add the `build` label when you want the PR package workflow to post a downloadable addon zip artifact on the PR.
- Keep PRs scoped to one logical change when possible.

## Releases

- Release-specific steps are documented in [RELEASING.md](RELEASING.md).
- Version bumps should update the addon version in [PallyPowerAdvanced.toc](PallyPowerAdvanced.toc), plus any matching references in [README.md](README.md) or [CHANGELOG.md](CHANGELOG.md).
- Packaging changes should keep working with both the PR artifact workflow and the GitHub/CurseForge release workflow.
