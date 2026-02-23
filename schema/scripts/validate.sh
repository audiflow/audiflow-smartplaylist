#!/usr/bin/env bash
set -euo pipefail

SCHEMA_DIR="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: schema/scripts/validate.sh [--playlist] <config.json> [config2.json ...]"
  echo ""
  echo "Validates JSON config files against the smart playlist schema."
  echo ""
  echo "Options:"
  echo "  --playlist  Validate as individual playlist definitions"
  echo "              (default validates as full config with version + patterns)"
  echo ""
  echo "Examples:"
  echo "  schema/scripts/validate.sh patterns/meta.json"
  echo "  schema/scripts/validate.sh --playlist schema/examples/rss-resolver.json"
  echo "  schema/scripts/validate.sh --playlist schema/examples/*.json"
}

SCHEMA="${SCHEMA_DIR}/schema.json"

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

if [ "$1" = "--playlist" ]; then
  SCHEMA="${SCHEMA_DIR}/playlist-definition.schema.json"
  shift
fi

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

errors=0
for file in "$@"; do
  echo "Validating: $file"
  if uv run --with check-jsonschema \
    check-jsonschema --schemafile "$SCHEMA" "$file" 2>&1; then
    echo "  ok"
  else
    errors=$((errors + 1))
  fi
  echo ""
done

if [ $errors -eq 0 ]; then
  echo "All files valid."
else
  echo "$errors file(s) failed validation."
  exit 1
fi
