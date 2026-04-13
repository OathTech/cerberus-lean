#!/bin/bash
# common.sh — shared helpers for cerberus-lean scripts
#
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
#
# Provides:
#   PROJECT_ROOT                — project root directory
#   CERBERUS_BIN                — path to built cerberus binary
#   CERBERUS_LEAN_BIN           — path to built cerberus-lean binary
#   RED, GREEN, YELLOW, NC      — color codes (auto-detect TTY)
#   TMP_DIR                     — project-local tmp directory
#   require_cerberus            — check OCaml prerequisites
#   require_lean                — check Lean prerequisites
#   build_cerberus              — build OCaml cerberus driver
#   build_lean                  — build Lean cerberus-lean executable
#   run_cerberus [args...]      — run cerberus with correct opam/runtime setup
#   run_cerberus_lean [args...] — run cerberus-lean

# Path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Binary paths
CERBERUS_BIN="$PROJECT_ROOT/_build/default/backend/driver/main.exe"
CERBERUS_LEAN_BIN="$PROJECT_ROOT/lean_frontend/.lake/build/bin/cerberus-lean"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

# Temp directory
TMP_DIR="$PROJECT_ROOT/.tmp/scripts"
mkdir -p "$TMP_DIR"

# Cleanup
_CLEANUP_PATHS=()
register_cleanup() { _CLEANUP_PATHS+=("$1"); }
_do_cleanup() { for p in ${_CLEANUP_PATHS[@]+"${_CLEANUP_PATHS[@]}"}; do rm -rf "$p"; done; }
trap _do_cleanup EXIT

# Check OCaml prerequisites
require_cerberus() {
    if [[ ! -d "$PROJECT_ROOT/_opam" ]]; then
        echo "Error: Local opam switch not found at $PROJECT_ROOT/_opam" >&2
        echo "Run: cd $PROJECT_ROOT && opam switch create . 5.4.0 --no-install" >&2
        exit 1
    fi
}

# Check Lean prerequisites
require_lean() {
    if ! command -v lake &>/dev/null; then
        echo "Error: lake not found. Install Lean 4 toolchain." >&2
        exit 1
    fi
}

# Build OCaml cerberus driver
build_cerberus() {
    require_cerberus
    echo "Building cerberus (OCaml)..."
    (cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        dune build backend/driver/main.exe 2>&1 | tail -3)
    if [[ ! -f "$CERBERUS_BIN" ]]; then
        echo "Error: Cerberus build failed" >&2
        exit 1
    fi
    # Ensure cerberus-lib is installed (for runtime files)
    (cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        dune install cerberus-lib 2>/dev/null)
}

# Build Lean cerberus-lean executable
build_lean() {
    require_lean
    echo "Building cerberus-lean (Lean)..."
    (cd "$PROJECT_ROOT/lean_frontend" && lake build cerberus-lean 2>&1 | tail -3)
    if [[ ! -f "$CERBERUS_LEAN_BIN" ]]; then
        echo "Error: cerberus-lean build failed" >&2
        exit 1
    fi
}

# Run cerberus with correct opam switch and runtime path
run_cerberus() {
    opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" "$@"
}

# Run cerberus-lean
run_cerberus_lean() {
    "$CERBERUS_LEAN_BIN" "$@"
}

# Produce an 8-character hash of a string (works on both macOS and Linux)
portable_hash() {
    if command -v md5sum &>/dev/null; then
        printf '%s' "$1" | md5sum | cut -c1-8
    else
        printf '%s' "$1" | md5 | cut -c1-8
    fi
}
