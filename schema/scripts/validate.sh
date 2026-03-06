#!/usr/bin/env bash
set -euo pipefail

SCHEMA_DIR="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"

usage() {
  echo "Usage: schema/scripts/validate.sh [--playlist] <config.json> [config2.json ...]"
  echo ""
  echo "Validates JSON config files against the smart playlist schema."
  echo ""
  echo "Options:"
  echo "  --playlist  Validate as individual playlist definitions"
  echo "              (default validates as full config with dataVersion + schemaVersion + patterns)"
  echo ""
  echo "Examples:"
  echo "  schema/scripts/validate.sh patterns/meta.json"
  echo "  schema/scripts/validate.sh --playlist schema/examples/rss-resolver.json"
  echo "  schema/scripts/validate.sh --playlist schema/examples/*.json"
}

SCHEMA="${SCHEMA_DIR}/schema.json"
PLAYLIST_MODE=false

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

if [ "$1" = "--playlist" ]; then
  PLAYLIST_MODE=true
  shift
fi

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

errors=0
for file in "$@"; do
  echo "Validating: $file"
  if [ "$PLAYLIST_MODE" = true ]; then
    # Wrap playlist in a config envelope and validate against main schema
    if python3 -c "
import json, sys
playlist = json.load(open(sys.argv[1]))
envelope = {'dataVersion': 1, 'schemaVersion': 1, 'patterns': [{'id': 'validate', 'playlists': [playlist]}]}
json.dump(envelope, sys.stdout)
" "$file" | uv run --with check-jsonschema \
      check-jsonschema --schemafile "$SCHEMA" - 2>&1; then
      echo "  ok"
    else
      errors=$((errors + 1))
    fi
  else
    if uv run --with check-jsonschema \
      check-jsonschema --schemafile "$SCHEMA" "$file" 2>&1; then
      echo "  ok"
    else
      errors=$((errors + 1))
    fi
  fi
  echo ""
done

if [ $errors -eq 0 ]; then
  echo "All files valid."
else
  echo "$errors file(s) failed validation."
  exit 1
fi
