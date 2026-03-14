# Editor versioning strategy

The data repo's CI clones the editor at a version-specific branch to ensure schema-compatible tooling.

## How it works

Data branches like `prod/v2` or `dev/v1` contain a version component (`v2`, `v1`). The deploy and validate workflows clone the editor repo at the matching branch:

```
data branch prod/v2  ->  editor branch v2
data branch dev/v1   ->  editor branch v1
```

This ensures:
- `validate.dart` uses the schema definition matching the data's version
- `bump_versions.dart` uses version-compatible logic
- The editor UI can edit configs for any active schema version

## Editor branch model

| Branch | Purpose |
|--------|---------|
| `main` | Latest development, may contain unreleased schema changes |
| `v1` | Stable tooling for schema v1 |
| `v2` | Stable tooling for schema v2 |

When a new schema version ships:
1. Create `v{N}` branch from `main` (or from `v{N-1}` if incremental)
2. Schema changes go to `main` first, then to the new version branch
3. Bug fixes to old versions are cherry-picked to the relevant `v{N}` branch

## What lives on version branches

- `crates/sp_core/assets/*.schema.json` -- schema definitions
- `crates/sp_core/` -- Rust models matching the schema
- `packages/sp_cli/` -- CLI tools (validate, bump_versions)
- `packages/sp_react/` -- Zod schemas for the editor UI

## Relationship to data repo

The data repo does NOT vendor the editor's schema anymore. Instead, the CI clones the editor at the correct version branch, which is the single source of truth for that schema version.
