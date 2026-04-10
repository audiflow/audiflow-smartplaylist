#!/usr/bin/env bash
set -euo pipefail

SCHEMA_DIR="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
REPO_ROOT="$(cd "$SCHEMA_DIR/.." >/dev/null && pwd)"
VERSION_FILE="$SCHEMA_DIR/VERSION"
CACHE_DIR="$REPO_ROOT/.cache/bin"

usage() {
  echo "Usage: schema/scripts/validate.sh [patterns_dir]"
  echo ""
  echo "Validates JSON config files using the audiflow-editor binary"
  echo "matched to the schema version in schema/VERSION."
  echo ""
  echo "Arguments:"
  echo "  patterns_dir  Path to patterns directory (default: patterns/)"
  echo ""
  echo "The script downloads the correct audiflow-editor binary if not"
  echo "already cached in .cache/bin/."
  echo ""
  echo "Examples:"
  echo "  schema/scripts/validate.sh"
  echo "  schema/scripts/validate.sh patterns/"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ ! -f "$VERSION_FILE" ]; then
  echo "error: schema/VERSION not found" >&2
  exit 1
fi

SCHEMA_VERSION="v$(cat "$VERSION_FILE" | tr -d '[:space:]')"
PATTERNS_DIR="${1:-$REPO_ROOT/patterns}"

if [ ! -d "$PATTERNS_DIR" ]; then
  echo "error: patterns directory not found: $PATTERNS_DIR" >&2
  exit 1
fi

# Detect platform
detect_binary_name() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux)
      case "$arch" in
        x86_64)  echo "audiflow-editor-x86_64-unknown-linux-gnu" ;;
        aarch64) echo "audiflow-editor-aarch64-unknown-linux-gnu" ;;
        *)       echo "error: unsupported architecture: $arch" >&2; exit 1 ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        x86_64)  echo "audiflow-editor-x86_64-apple-darwin" ;;
        arm64)   echo "audiflow-editor-aarch64-apple-darwin" ;;
        *)       echo "error: unsupported architecture: $arch" >&2; exit 1 ;;
      esac
      ;;
    *)
      echo "error: unsupported OS: $os" >&2
      exit 1
      ;;
  esac
}

BINARY_NAME="$(detect_binary_name)"
EDITOR_BIN="$CACHE_DIR/$SCHEMA_VERSION/$BINARY_NAME"

# Download if not cached
if [ ! -x "$EDITOR_BIN" ]; then
  echo "Downloading audiflow-editor $SCHEMA_VERSION..."
  mkdir -p "$CACHE_DIR/$SCHEMA_VERSION"
  gh release download "$SCHEMA_VERSION" \
    --repo audiflow/audiflow-smartplaylist-editor \
    --pattern "$BINARY_NAME" \
    --output "$EDITOR_BIN"
  chmod +x "$EDITOR_BIN"
  echo ""
fi

echo "Validating with audiflow-editor $SCHEMA_VERSION"
echo ""
exec "$EDITOR_BIN" validate "$PATTERNS_DIR"
