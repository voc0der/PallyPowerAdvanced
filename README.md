# PallyPowerAdvanced

Smart blessing assignment for PallyPower on WoW TBC Anniversary Classic.

PallyPowerAdvanced adds a `Smart-Assign` button to PallyPower's blessing assignment panel. It uses Blizzard group roles, PallyPower's known paladin skill data, and explicit role/spec choices for uncertain hybrid players to build class-wide greater blessing assignments plus per-player normal blessing overrides.

Current version: `0.1.0`

## What It Does

- Adds `Smart-Assign` beside PallyPower's existing `Auto-Assign` button
- Prioritizes Salvation, Kings, Might, Wisdom, Light, and Sanctuary by class, role, and selected hybrid spec
- Uses per-player normal blessings for tanks/healers who should not receive the class-wide greater blessing
- Prompts before guessing uncertain role/spec cases, including damage druids and shamans
- Prints local instructions for paladins in the group who do not have PallyPower enabled
- Provides `/ppa debug` for local reasoning output

## Install

1. Install and enable `PallyPower`.
2. Extract the `PallyPowerAdvanced` folder into:
   `World of Warcraft/_anniversary_/Interface/AddOns/`
3. Start the game and make sure both addons are enabled.

## Usage

- Open PallyPower's blessing assignment panel and click `Smart-Assign`
- `/ppa smart`: Run Smart Assign
- `/ppa debug`: Toggle local debug reasoning
- `/ppa debug on`: Enable debug reasoning
- `/ppa debug off`: Disable debug reasoning
- `/ppa specs`: Reopen the manual role/spec assignment popup
- `/ppa help`: Show command help

## Scope

- Target client: TBC Anniversary Classic
- TOC interface: `20505`
- Requires PallyPower

## Contributing

Development and contribution notes are in [CONTRIBUTING.md](CONTRIBUTING.md).
Release workflow notes are in [RELEASING.md](RELEASING.md).
