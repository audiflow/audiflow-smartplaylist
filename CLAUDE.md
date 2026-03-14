# audiflow-smartplaylist

Smart playlist configuration data for all environments. Static JSON files deployed to GitHub Pages via CI. The app fetches configs from `https://audiflow.github.io/audiflow-smartplaylist/`.

## Environments

| Branch | Deploy path | URL |
|--------|------------|-----|
| `main` | `/assets/v{N}/` | `audiflow.github.io/audiflow-smartplaylist/assets/v{N}/` |
| `staging` | `/assets-stg/v{N}/` | `audiflow.github.io/audiflow-smartplaylist/assets-stg/v{N}/` |
| `dev` | `/assets-dev/v{N}/` | `audiflow.github.io/audiflow-smartplaylist/assets-dev/v{N}/` |

`{N}` is read from `patterns/meta.json#schemaVersion` at deploy time. Old schema versions remain frozen on `gh-pages` — only the current version's directory is updated.

Branch flow: `dev` -> PR -> `staging` -> PR -> `main`

## Ecosystem context

The single data repo in the audiflow ecosystem (formerly split into prod and dev repos). The `audiflow-smartplaylist-editor` web tool reads/writes these files locally; users commit and push. Schema SSoT lives in `audiflow-smartplaylist-editor/crates/sp_core/assets/`.

## Responsibilities

- Playlist configurations for all environments (JSON under `patterns/`)
- CI deployment to GitHub Pages (via `.github/workflows/deploy-pages.yml`)
- Schema vendoring for local validation (`schema/`)

## Non-responsibilities

- Schema definitions (owned by `audiflow-smartplaylist-editor`)
- Config editing workflow (owned by editor)
- App-side consumption logic (owned by `audiflow`)

## File layout

```
patterns/
  meta.json                    # Root index: dataVersion, schemaVersion, pattern summaries
  {patternId}/
    meta.json                  # Pattern: feedUrls, playlists list, flags
    playlists/
      {playlistId}.json        # PlaylistDefinition (one per playlist)
schema/                        # Vendored schemas + validation tooling
```

## Validation

```bash
# Local schema validation (requires uv)
schema/scripts/validate.sh patterns/**/*.json

# CI validates on PR via editor's sp_cli
# See .github/workflows/validate.yml
```

## Key references

- docs/overview.md -- purpose, concepts, entry points
- docs/architecture/system-overview.md -- data flow and design constraints
- docs/specs/file-structure.md -- three-level JSON hierarchy spec
- docs/development/change-workflow.md -- how to add/modify patterns

## When changing this repository

- All JSON must conform to schemas in `schema/`
- Changes to `patterns/` deploy automatically on merge to the target branch
- Schema SSoT is in the editor repo; vendor updated schemas into `schema/`
- Check whether docs/specs/file-structure.md needs updating
