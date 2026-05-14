## [Unreleased]

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
