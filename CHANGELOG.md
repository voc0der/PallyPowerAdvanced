## [Unreleased]

## [0.1.22] - 2026-05-17

### Fixed
- Paladin targets with Improved Wisdom now prefer Blessing of Wisdom over Kings even when role data is stale or missing.
- Unimproved paladin healers still prefer Kings over Wisdom.

### Tests
- Add coverage for improved-Wisdom paladin target priority and unimproved healer paladin fallback priority.

## [0.1.21] - 2026-05-17

### Added
- Add `/ppa trace on` assignment tracing to identify which external PallyPower sender changes any raid assignment row.
- Add automatic assignment conflict warnings when an external sender overwrites assignments twice within five seconds of a local Smart-Assign or Auto-Assign.

### Tests
- Add coverage for tracing assignment changes outside the local paladin's own row.
- Add coverage for suppressing the first external assignment burst and warning on the second burst.

## [0.1.20] - 2026-05-17

### Changed
- Bumped release metadata for the TBC Anniversary `20505` TOC target.

## [0.1.19] - 2026-05-17

### Changed
- Smart-Assign now detects battleground and arena contexts and adjusts blessing priorities for PvP.
- Blessing of Salvation is omitted from PvP assignments.
- Blessing of Sanctuary remains available in PvP, but is treated as the lowest-priority blessing and no longer gets forced by the PvE tank fallback when better blessings are assigned.

### Tests
- Add coverage for PvP priority filtering, PvP runtime context detection, skipping Salvation, avoiding forced Sanctuary fallbacks, and still assigning Sanctuary when it is the only castable option.

## [0.1.17] - 2026-05-15

### Fixed
- Prot paladin tanks with confirmed spec data and no Sanctity Aura no longer receive a personal Blessing of Sanctuary override from the tank fallback pass; they already prefer Kings and the override was incorrectly replacing it.
- Prot paladin tank priority now uses confirmed spec data exclusively when available, ignoring the pally-count heuristic: confirmed Sanctity Aura → Sanctuary first; confirmed no Sanctity Aura → Kings first regardless of raid size. The pally-count fallback remains for paladins with no PPA spec data.

### Added
- `GetUnitSpecData` helper consolidates local-player talent reads and peer spec cache lookups into one call.

### Tests
- Expand prot paladin priority test to cover all three cases: no spec data (pally-count heuristic), confirmed no Sanctity Aura (kings always first), confirmed Sanctity Aura (sanctuary always first).

## [0.1.16] - 2026-05-15

### Changed
- Prot paladins with confirmed Sanctity Aura talent (via PPA spec broadcast) who are also confirmed tanks (Holy Shield talent or tank role) now receive Blessing of Sanctuary as their top priority, with Blessing of Kings second. Without confirmed Sanctity Aura the existing pally-count logic is unchanged.
- Sanctity Aura and Holy Shield are now included in the spec broadcast so peers can detect this combination.

### Tests
- Add coverage for prot paladin priority with and without confirmed Sanctity Aura, at both low and high pally counts.

## [0.1.15] - 2026-05-15

### Added
- Paladins running PPA broadcast their active spec and exact improved blessing talent ranks (Improved Might, Improved Wisdom, Improved Sanctuary, Blessing of Kings) to raid/party peers via addon messaging. Received data overrides the talent fields inferred from PallyPower's AllPallys table, giving the planner exact knowledge of whether improved blessings are available rather than guessing from role and class. The local player's own talents are always read directly from the active talent group. Existing AllPallys-based behaviour is unchanged for paladins not running PPA.

## [0.1.14] - 2026-05-15

### Changed
- Add a post-planning simplification pass that swaps blessing assignments between paladins to reduce the number of distinct buffs each paladin must cast, without downgrading blessing rank or talent quality for any class.

### Tests
- Add coverage for the simplification pass: prot paladin consolidates toward kings while retaining improved sanctuary, and becomes a one-blessing specialist when sanctuary talent parity allows.

## [0.1.13] - 2026-05-15

### Fixed
- Avoid simulation-mode UI taint by no longer overriding Blizzard unit API globals in-game; simulated PallyPower roster refreshes now rely on seeded data and layout refreshes only.

### Tests
- Add coverage that simulation hooks do not replace live unit APIs and that the old simulation unit API shim fails closed in the WoW UI.

## [0.1.12] - 2026-05-15

### Fixed
- Restore Blessing of Light and Blessing of Sanctuary as useful late-slot options for DPS warriors and rogues when enough paladins are available, while still blocking Wisdom filler for those classes.
- Make simulated warrior and hybrid class names include role/spec context so tank warriors and caster/melee hybrid specs are clear in the assignment screen.

### Tests
- Add coverage for physical class late-slot Light/Sanctuary assignments and role/spec-aware simulation names.

## [0.1.11] - 2026-05-15

### Fixed
- Avoid assigning paladin-class Wisdom to Prot or Ret paladins when an Improved Wisdom Holy paladin can cover it.
- Optimize class blessing ownership across the whole class row so specialized paladins are reserved for the blessings they are best suited to cast.

### Tests
- Add coverage for preserving Improved Wisdom paladins for Wisdom while keeping assumed missing-class blessing coverage intact.

## [0.1.10] - 2026-05-15

### Changed
- Prefer Ret paladins with Improved Might for Might assignments instead of spending them on easy Salvation coverage.
- Let simulated Holy/Ret paladins provide non-improved Sanctuary so the fallback model can test plain Sanctuary coverage when improved Sanctuary is unavailable.
- Allow tank Sanctuary single-target fallbacks to use the best Sanctuary paladin even when that paladin already has a class-wide assignment.

### Tests
- Add coverage for Ret paladins being preferred for Might, plain Sanctuary fallback from non-Prot paladins, and every simulated tank receiving Sanctuary coverage.

## [0.1.9] - 2026-05-15

### Changed
- Stop using Wisdom as filler for warriors and rogues; extra paladin slots now stay blank for DPS warriors and rogues once useful blessings are covered.
- Prevent Might from being selected as filler for priests, mages, and warlocks.
- Ensure available Prot paladins provide Blessing of Sanctuary for tank coverage.
- Rename simulated paladins by role, such as `PpaSimProt1` and `PpaSimRet1`, instead of generic `PpaSimPally` names.

### Tests
- Add coverage for useless filler blessing exclusions, role-specific simulated paladin names, and Prot paladin Sanctuary assignment.

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
