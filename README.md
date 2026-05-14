<p align="center">
  <img src="assets/pallypoweradvanced-icon.png" alt="PallyPowerAdvanced icon" width="180" />
</p>

# PallyPowerAdvanced

- Adds Smart-Assign blessing planning to PallyPower
- Handles class-wide greater blessings and per-player normal blessing overrides
- Prompts for uncertain hybrid role/spec cases instead of silently guessing
- Alerts you when another paladin changes your assignments

Current version: `0.1.2`

## Smart Assign

- Adds `Smart-Assign` beside PallyPower's existing `Auto-Assign` button
- Prioritizes Salvation, Kings, Might, Wisdom, Light, and Sanctuary by class, role, and selected hybrid spec
- Uses per-player normal blessings for tanks/healers who should not receive the class-wide greater blessing
- Prompts before guessing uncertain role/spec cases, including damage druids and shamans
- Prints local instructions for paladins in the group who do not have PallyPower enabled
- Provides `/ppa debug` for local reasoning output

## Assignment Alerts

- Prints a local chat alert when another paladin assigns you a class-wide blessing
- Prints a local chat alert when another paladin assigns you a single-target normal blessing
- Ignores assignment changes you make yourself

## Install

1. Install and enable `PallyPower`.
2. Download the latest release from [GitHub](https://github.com/voc0der/PallyPowerAdvanced/releases/latest) or [CurseForge](https://www.curseforge.com/wow/addons/pallypoweradvanced).
3. Extract the `PallyPowerAdvanced` folder into:
   `World of Warcraft/_anniversary_/Interface/AddOns/`
4. Start the game and make sure both addons are enabled.

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
- Requires `PallyPower`

## Contributing

Development and contribution notes are in [CONTRIBUTING.md](CONTRIBUTING.md).
Release workflow notes are in [RELEASING.md](RELEASING.md).

## Star History

<p align="center">
  <a href="https://star-history.com/#voc0der/PallyPowerAdvanced&Date">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=voc0der/PallyPowerAdvanced&type=Date&theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=voc0der/PallyPowerAdvanced&type=Date" />
      <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=voc0der/PallyPowerAdvanced&type=Date" />
    </picture>
  </a>
</p>
