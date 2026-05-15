## [Unreleased]

## [0.1.8] - 2026-05-15

### Fixed
- Fix `/ppa simulate` so PallyPower's class panes populate with simulated player names for per-player normal blessing overrides.

### Tests
- Add coverage for PallyPower's string raid roster indexes in the simulation unit API shim.

## [0.1.7] - 2026-05-15

### Added
- Add `/ppa simulate` to open the PallyPower assignment screen with a local-only 25-player simulated raid, including 2-3 tanks, 4-9 healers, DPS fill, all TBC classes, and fake paladin skill data for Smart-Assign testing.
- Add `/ppa simulate off` to restore the previous PallyPower assignment state after simulation testing.

### Changed
- Suppress PallyPower assignment broadcasts while simulation mode is active so simulated raids stay local.

### Tests
- Expand the Lua test suite to cover simulated raid composition, Smart-Assign planning against simulated raids, and local-only simulation plan application.

## [0.1.6] - 2026-05-14

### Changed
- Swapped the one-minute blessing warning from the Ready Check sound to a softer chime-style toast sound.

## [0.1.5] - 2026-05-14

### Fixed
- Smart-Assign now prefers Kings over unimproved Wisdom for healer targets when no paladin has Improved Wisdom.

## [0.1.4] - 2026-05-14

### Added
- Smart-Assign now assigns paladin auras by subgroup, preferring improved Devotion Aura, then Retribution Aura, then Concentration Aura.
- Infer unmarked paladin healer/tank roles from improved Wisdom and improved Sanctuary talents when PallyPower skill data is available.

### Fixed
- Two-paladin tank/healer groups now prefer Kings plus Wisdom for paladin blessings instead of spending a slot on Salvation.

## [0.1.3] - 2026-05-14

### Added
- Play a one-minute blessing warning sound for the local paladin's assigned buffs, including when game sound/SFX are muted.
- Fill Smart-Assign class-wide blessings for missing classes by assuming a full group and using the same class priority logic.

## [0.1.2] - 2026-05-14

### Added
- Alert the local paladin when another paladin changes their class-wide or single-target blessing assignments.
- Add CurseForge project metadata for project `1543077`.
- Add the project icon asset and README presentation.

## [0.1.1] - 2026-05-14

### Fixed
- Refresh PallyPower cooldown state after Smart-Assign roster scans so the blessing grid does not receive empty cooldown tables.

## [0.1.0] - 2026-05-14

### Added
- Initial PallyPowerAdvanced addon scaffold for TBC Anniversary Classic
- Smart-Assign button injected into PallyPower's blessing assignment panel
- Role/spec-aware assignment planning with per-player normal blessing overrides
- Manual role/spec popup for uncertain hybrid cases
- `/ppa debug` local reasoning output
