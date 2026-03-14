# audiflow-smartplaylist

Production smart playlist configuration data. Static JSON files deployed to GitHub Pages via CI on merge to main. The app fetches configs from `https://audiflow.github.io/audiflow-smartplaylist/`.

## Ecosystem context

One of two data repos in the audiflow ecosystem (this is prod; `audiflow-smartplaylist-dev` is dev/staging). The `audiflow-smartplaylist-editor` web tool reads/writes these files locally; users commit and push. Schema SSoT lives in `audiflow-smartplaylist-dev/schema/`.

## Responsibilities

- Production playlist configurations (JSON under `patterns/`)
- CI deployment to GitHub Pages (via `.github/workflows/bump-deploy-pages.yml`)
- Schema vendoring for local validation (`schema/`)

## Non-responsibilities

- Schema definitions (owned by `audiflow-smartplaylist-dev`)
- Config editing workflow (owned by editor)
- Dev/staging data (owned by `audiflow-smartplaylist-dev`)
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
- Changes to `patterns/` deploy automatically on merge to main
- Coordinate schema changes with `audiflow-smartplaylist-dev` first
- Check whether docs/specs/file-structure.md needs updating
