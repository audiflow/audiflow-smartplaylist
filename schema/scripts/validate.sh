#!/usr/bin/env bash
set -euo pipefail

SCHEMA_DIR="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"

usage() {
  echo "Usage: schema/scripts/validate.sh [--playlist | --index | --pattern-meta] <config.json> [config2.json ...]"
  echo ""
  echo "Validates JSON config files against the smart playlist schema."
  echo ""
  echo "Options:"
  echo "  --playlist      Validate as individual playlist definitions"
  echo "  --index         Validate as root pattern index (patterns/meta.json)"
  echo "  --pattern-meta  Validate as per-pattern meta ({patternId}/meta.json)"
  echo "  (default)       Auto-detects meta.json files; others validate as playlist"
  echo ""
  echo "Examples:"
  echo "  schema/scripts/validate.sh patterns/meta.json                          # auto-detects as index"
  echo "  schema/scripts/validate.sh --pattern-meta patterns/coten_radio/meta.json"
  echo "  schema/scripts/validate.sh --playlist schema/examples/rss-resolver.json"
  echo "  schema/scripts/validate.sh --playlist schema/examples/*.json"
}

MODE=""

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "${1:-}" in
  --playlist)
    MODE="playlist"
    shift
    ;;
  --index)
    MODE="index"
    shift
    ;;
  --pattern-meta)
    MODE="pattern-meta"
    shift
    ;;
esac

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

schema_for_mode() {
  case "$1" in
    index)        echo "${SCHEMA_DIR}/pattern-index.schema.json" ;;
    pattern-meta) echo "${SCHEMA_DIR}/pattern-meta.schema.json" ;;
    *)            echo "${SCHEMA_DIR}/playlist-definition.schema.json" ;;
  esac
}

detect_mode() {
  local file="$1"
  local basename
  basename="$(basename "$file")"

  if [ -n "$MODE" ]; then
    echo "$MODE"
    return
  fi

  if [ "$basename" = "meta.json" ]; then
    if python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
sys.exit(0 if 'schemaVersion' in data else 1)
" "$file" 2>/dev/null; then
      echo "index"
    else
      echo "pattern-meta"
    fi
  else
    echo "playlist"
  fi
}

errors=0
for file in "$@"; do
  file_mode="$(detect_mode "$file")"
  schema="$(schema_for_mode "$file_mode")"
  echo "Validating ($file_mode): $file"
  if uv run --with check-jsonschema \
    check-jsonschema --schemafile "$schema" "$file" 2>&1; then
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
