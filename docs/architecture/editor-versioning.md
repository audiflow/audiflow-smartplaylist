# Editor versioning strategy

The data repo's CI uses pre-compiled editor CLI binaries for validation and version bumping. Binaries are published as GitHub Releases with mutable major-version tags.

## Binary release model

The editor publishes `sp-cli` binaries via GitHub Releases using two tag types:

| Tag | Type | Example | Purpose |
|-----|------|---------|---------|
| `v2.1.0` | immutable | specific release | Reproducibility, changelogs |
| `v2` | mutable | always points to latest v2.x | CI consumption |

This follows the same convention as GitHub Actions (e.g., `actions/checkout@v4`).

### Editor release workflow

1. `dart compile exe` produces `sp-cli` for linux-x64
2. Create GitHub Release for the immutable tag (`v2.1.0`) with binary attached
3. Move the mutable `v2` tag to the new commit
4. Update the `v2` release to attach the latest binary

### Data repo CI consumption

The data repo's deploy and validate workflows download the binary from the mutable tag:

```yaml
- run: |
    gh release download v2 \
      --repo audiflow/audiflow-smartplaylist-editor \
      --pattern 'sp-cli-linux-x64' \
      --output sp-cli
    chmod +x sp-cli
- run: ./sp-cli validate patterns/
- run: ./sp-cli bump-versions patterns/ HEAD~1
```

No Dart SDK, no clone, no `pub get` required.

## Version branch model

The editor also maintains version branches for development:

| Branch | Purpose |
|--------|---------|
| `main` | Latest development, may contain unreleased schema changes |
| `v1` | Stable tooling for schema v1 |
| `v2` | Stable tooling for schema v2 |

When a new schema version ships:
1. Create `v{N}` branch from `main` (or from `v{N-1}` if incremental)
2. Schema changes go to `main` first, then to the new version branch
3. Bug fixes to old versions are cherry-picked to the relevant `v{N}` branch
4. Each cherry-pick triggers a minor release (e.g., `v2.1.0` -> `v2.2.0`)

## What lives on version branches

- `crates/sp_core/assets/*.schema.json` -- schema definitions (SSoT)
- `crates/sp_core/` -- Rust models matching the schema
- `packages/sp_cli/` -- CLI tools (validate, bump_versions)
- `packages/sp_react/` -- Zod schemas for the editor UI
