# Multi-environment deployment

This repo serves production, staging, and development environments from a single GitHub Pages deployment using branch-based isolation and schema-versioned paths.

## URL scheme

| Branch | Deploy directory | URL path |
|--------|-----------------|----------|
| `main` | `assets/v{N}/` | `/assets/v{N}/` |
| `staging` | `assets-stg/v{N}/` | `/assets-stg/v{N}/` |
| `dev` | `assets-dev/v{N}/` | `/assets-dev/v{N}/` |

`{N}` is the `schemaVersion` integer from `patterns/meta.json`.

## How it works

A single `gh-pages` branch holds all environments and schema versions side by side:

```
gh-pages branch:
  assets/v1/       <- main, schema v1 (frozen)
  assets/v2/       <- main, schema v2 (current)
  assets-stg/v2/   <- staging
  assets-dev/v2/   <- dev
```

When any environment branch receives a push to `patterns/`, the deploy workflow:

1. Runs version bump on the source branch
2. Reads `schemaVersion` from `patterns/meta.json`
3. Checks out `gh-pages` (or initializes it on first run)
4. Syncs `patterns/` into `{env}/v{schemaVersion}/` via `rsync --delete`
5. Commits and pushes to `gh-pages`

Only the current schema version's directory is updated. Old schema versions remain frozen at their last deployed state, allowing old app versions to continue fetching compatible configs.

Each branch has its own concurrency group, so deployments for different environments never block each other. Push conflicts (when two envs deploy simultaneously) are handled by retry-with-rebase -- safe because each env writes to its own directory.

## Branch flow

```
dev -> PR -> staging -> PR -> main
```

All three branches are protected: no direct push, PR approval from CODEOWNERS required.

## GitHub Pages configuration

Pages must be configured to deploy from the `gh-pages` branch at `/` (root). This is set in the repo's Settings > Pages.

The previous setup used `actions/deploy-pages` (GitHub Actions source). The new setup uses branch-based deployment, which requires changing the Pages source setting.
