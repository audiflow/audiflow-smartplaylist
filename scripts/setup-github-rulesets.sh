#!/usr/bin/env bash
# Setup GitHub repository rulesets for branch protection.
# Requires: gh CLI authenticated with admin access.
#
# Usage: ./scripts/setup-github-rulesets.sh
#
# NOTE: file_path_restriction (governance-files ruleset) requires
# GitHub Enterprise. On free/public repos, CODEOWNERS + require_code_owner_review
# provides equivalent protection since * @reedom covers all files.

set -euo pipefail

REPO="audiflow/audiflow-smartplaylist"

# Look up the bypass actor's GitHub user ID
OWNER_LOGIN="reedom"
OWNER_ID=$(gh api "users/${OWNER_LOGIN}" --jq '.id')
echo "Resolved @${OWNER_LOGIN} -> user ID ${OWNER_ID}"

echo ""
echo "=== Creating ruleset: base-branches ==="
gh api "repos/${REPO}/rulesets" \
  --method POST \
  --input - <<EOF
{
  "name": "base-branches",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/prod/*", "refs/heads/stg/*", "refs/heads/dev/*"],
      "exclude": []
    }
  },
  "bypass_actors": [
    {
      "actor_id": ${OWNER_ID},
      "actor_type": "User",
      "bypass_mode": "always"
    }
  ],
  "rules": [
    {
      "type": "creation"
    },
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
echo "=== Done ==="
echo ""
echo "Manual step required:"
echo "  Go to Settings > Pages and change source to:"
echo "    Deploy from a branch: gh-pages / (root)"
