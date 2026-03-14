#!/usr/bin/env bash
# Setup GitHub repository rulesets for branch protection.
# Requires: gh CLI authenticated with admin access.
#
# Usage: ./scripts/setup-github-rulesets.sh

set -euo pipefail

REPO="audiflow/audiflow-smartplaylist"

echo "=== Creating ruleset: base-branches ==="
gh api "repos/${REPO}/rulesets" \
  --method POST \
  --input - <<'EOF'
{
  "name": "base-branches",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/dev", "refs/heads/staging"],
      "exclude": []
    }
  },
  "bypass_actors": [],
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          {
            "context": "validate"
          }
        ]
      }
    }
  ]
}
EOF

echo ""
echo "=== Creating ruleset: governance-files ==="
gh api "repos/${REPO}/rulesets" \
  --method POST \
  --input - <<'EOF'
{
  "name": "governance-files",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/dev", "refs/heads/staging"],
      "exclude": []
    }
  },
  "bypass_actors": [],
  "rules": [
    {
      "type": "file_path_restriction",
      "parameters": {
        "restricted_file_paths": [
          ".github/CODEOWNERS",
          ".github/workflows/**"
        ]
      }
    }
  ]
}
EOF

echo ""
echo "=== Done ==="
echo ""
echo "Manual step required:"
echo "  Go to Settings > Pages and change source to:"
echo "    Deploy from a branch: gh-pages / (root)"
