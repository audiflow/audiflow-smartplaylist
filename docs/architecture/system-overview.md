# System Overview

## Goal

Serve as the production source of truth for smart playlist configurations consumed by the audiflow mobile app. This repository is a static data store with CI-driven validation and deployment -- it contains no application logic.

## Context

This repository is part of:
- The audiflow podcast ecosystem (4 repos: app, editor, prod data, dev data)
- A data pipeline: Editor -> Git commit -> CI validation/bump -> GitHub Pages -> App fetch
- A schema contract: all JSON here must conform to schemas vendored in `schema/`

## High-level structure

- `patterns/`: All production configuration data
  - `meta.json`: Root index for pattern discovery
  - `{patternId}/meta.json`: Per-pattern feed matching and playlist ordering
  - `{patternId}/playlists/{playlistId}.json`: Individual playlist definitions
- `schema/`: Vendored JSON Schema files and validation tooling
  - `playlist-definition.schema.json`: Playlist definition schema
  - `pattern-index.schema.json`: Root index schema
  - `pattern-meta.schema.json`: Pattern meta schema
  - `scripts/validate.sh`: Local validation using check-jsonschema
  - `docs/`: Schema documentation (HTML, generated)
  - `examples/`: Reference playlist definitions per resolver type
- `.github/workflows/`: CI pipelines
  - `validate.yml`: PR validation using editor's sp_cli
  - `bump-deploy-pages.yml`: Version bump + GitHub Pages deploy on merge

## Main data flow

1. User edits configs in `audiflow-smartplaylist-editor` (local-first)
2. User commits and pushes changes to this repository
3. On PR: CI clones editor repo, runs `sp_cli validate.dart` against `patterns/`
4. On merge to main: CI runs `sp_cli bump_versions.dart` to auto-increment `dataVersion` fields in affected meta.json files
5. CI commits version bump, then deploys `patterns/` directory to GitHub Pages
6. App fetches `meta.json` -> pattern meta -> playlist definitions (lazy, cached)

## Primary interfaces

- **Input**: JSON files authored by the editor tool, committed via git
- **Output**: Static files served at `https://audiflow.github.io/audiflow-smartplaylist/`
- **External dependencies**:
  - `audiflow-smartplaylist-editor` (sp_cli): validation and version bumping
  - GitHub Pages: static hosting
  - GitHub Actions: CI/CD

## Design constraints

- No application code in this repository -- data and schema only
- All JSON must pass schema validation before merge
- `dataVersion` fields are managed by CI, not manually edited
- The `patterns/` directory is the deployment root (GitHub Pages serves it directly)
- Three schemas govern three file types: root index, pattern meta, playlist definition
- Current patterns: `coten_radio` (3 playlists), `news_connect` (2 playlists), `business-wars` (1 playlist)

## When to update

Update when: new CI workflows are added, deployment target changes, new schema files are vendored, or the relationship with the editor repo changes.
