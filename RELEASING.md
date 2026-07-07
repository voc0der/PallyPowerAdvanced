# Releasing to CurseForge

## TBC Anniversary Support

PallyPowerAdvanced targets TBC Anniversary Classic. The TOC file specifies:

```text
## Interface: 20506
```

## Workflow Prerequisites

Before automated release can work end-to-end, configure:

1. GitHub Actions secret `RELEASE_PAT`
   - Fine-grained token with repository `Contents: Read and write`
   - Needed so tag push can trigger the release workflow
2. GitHub Actions secret `CF_API_KEY`
   - CurseForge API token used by `BigWigsMods/packager`
3. CurseForge project metadata in addon TOC
   - `## X-Curse-Project-ID: 1543077`
   - Project page: `https://www.curseforge.com/wow/addons/pallypoweradvanced`

## Release Process

### Automated (GitHub Actions)

1. Update version in `PallyPowerAdvanced.toc`
2. Update `CHANGELOG.md` with release notes
3. Commit and push to `main`
4. CI automatically creates a tag from the TOC version and triggers the packager

### PR Build Artifacts

- Add the `build` label to a pull request when you want the PR packaging workflows to post a downloadable addon zip artifact comment for that PR head commit.

### Troubleshooting

- No new tag created:
  - Check `## Version:` in `PallyPowerAdvanced.toc` is bumped, for example `0.1.4`
  - If tag already exists, for example `v0.1.4`, workflow will skip by design
- Tag created but no CurseForge upload:
  - Confirm `CF_API_KEY` exists in repo secrets
  - Confirm `## X-Curse-Project-ID:` is set to a valid numeric project ID
- Tag workflow failing authentication:
  - Confirm `RELEASE_PAT` exists and has repo contents write permissions
  - If using org SSO, ensure the token is authorized for the org

### Manual Upload to CurseForge

1. Create a zip file:
   ```bash
   cd /home/vocoder/Code
   zip -r PallyPowerAdvanced-v0.1.X.zip PallyPowerAdvanced -x "*.git*" -x "*README.md"
   ```
2. Upload at the CurseForge project files page once the project exists.

## What Gets Released

Only runtime addon files should ship to players.

The PR package workflow stages files directly from `PallyPowerAdvanced.toc`, and the release workflow verifies that `.pkgmeta` produces the same runtime-only tree before uploading to GitHub and CurseForge.

For the current addon, the packaged game files are:

- `PallyPowerAdvanced.toc`
- `PallyPowerAdvanced.lua`

Non-game files such as `assets/`, `tests/`, docs, and repo metadata must stay out of the final addon archive.
