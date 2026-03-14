# Multi-environment deployment

This repo serves production, staging, and development environments across multiple schema versions from a single GitHub Pages deployment.

## Branch model

`main` holds infrastructure (workflows, docs, schema, CODEOWNERS). Data lives on `{env}/v{N}` branches:

| Branch | Deploy directory | URL path |
|--------|-----------------|----------|
| `prod/v1` | `assets/v1/` | `/assets/v1/` |
| `prod/v2` | `assets/v2/` | `/assets/v2/` |
| `stg/v2` | `assets-stg/v2/` | `/assets-stg/v2/` |
| `dev/v2` | `assets-dev/v2/` | `/assets-dev/v2/` |

Branch flow per version: `dev/v{N}` -> PR -> `stg/v{N}` -> PR -> `prod/v{N}`

New version branches are created from `main` (to inherit the latest workflows and tooling).

## How it works

A single `gh-pages` branch holds all environments and versions side by side:

```
gh-pages branch:
  assets/v1/       <- from prod/v1
  assets/v2/       <- from prod/v2
  assets-stg/v2/   <- from stg/v2
  assets-dev/v2/   <- from dev/v2
```

When any env branch receives a push to `patterns/`, the deploy workflow:

1. Parses the branch name into env prefix and version (e.g., `prod/v2` -> `assets/v2`)
2. Runs version bump on the source branch
3. Checks out `gh-pages` (or initializes it on first run)
4. Syncs `patterns/` into the branch's deploy directory via `rsync --delete`
5. Commits and pushes to `gh-pages`

Each branch has its own concurrency group. Push conflicts are handled by retry-with-rebase -- safe because each branch writes to its own directory.

## Schema version lifecycle

1. Schema v2 is current: `dev/v2`, `stg/v2`, `prod/v2` are active
2. Schema v3 ships: create `dev/v3` from `main`, add patterns, promote through stg/prod
3. Bug fix for v2: commit to `dev/v2`, promote through `stg/v2` -> `prod/v2`
4. Both `/assets/v2/` and `/assets/v3/` are served concurrently
5. When v2 is sunset: delete `prod/v2` branch (frozen content remains on `gh-pages` until manually cleaned)

## Branch protection

All `prod/*`, `stg/*`, `dev/*`, and `main` branches are protected via GitHub rulesets:
- No direct push (PR required)
- CODEOWNERS review required
- Status checks must pass (validate workflow)
- No force push or deletion

## GitHub Pages configuration

Pages must be configured to deploy from the `gh-pages` branch at `/` (root). Set in Settings > Pages.
