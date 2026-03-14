# Multi-environment deployment

This repo serves production, staging, and development environments from a single GitHub Pages deployment using branch-based isolation.

## URL scheme

| Branch | Deploy directory | URL path |
|--------|-----------------|----------|
| `main` | `assets/` | `/assets/` |
| `staging` | `assets-stg/` | `/assets-stg/` |
| `dev` | `assets-dev/` | `/assets-dev/` |

## How it works

A single `gh-pages` branch holds all environments side by side:

```
gh-pages branch:
  assets/          <- from main
  assets-stg/      <- from staging
  assets-dev/      <- from dev
```

When any environment branch receives a push to `patterns/`, the deploy workflow:

1. Runs version bump on the source branch
2. Checks out `gh-pages` (or initializes it on first run)
3. Syncs `patterns/` into the branch's deploy directory via `rsync --delete`
4. Commits and pushes to `gh-pages`

Each branch has its own concurrency group, so deployments for different environments never block each other. Push conflicts (when two envs deploy simultaneously) are handled by retry-with-rebase — safe because each env writes to its own directory.

## Branch flow

```
dev -> PR -> staging -> PR -> main
```

All three branches are protected: no direct push, PR approval from CODEOWNERS required.

## GitHub Pages configuration

Pages must be configured to deploy from the `gh-pages` branch at `/` (root). This is set in the repo's Settings > Pages.

The previous setup used `actions/deploy-pages` (GitHub Actions source). The new setup uses branch-based deployment, which requires changing the Pages source setting.
