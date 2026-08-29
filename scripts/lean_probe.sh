#!/bin/bash
# lean_probe.sh — THE PROBE RECIPE (born 2026-08-27 as the FF-1 fix
# for the then-two-package RelSem prefix split; still the correct way
# to elaborate a package file with a fully-pinned module setup).
#
# Elaborate a single .lean file of a Lake package with a FULLY-PINNED
# module setup. Why `lake lean` cannot be the recipe for this repo's
# two-package layout (diagnosed at V0):
#
#   * `lake lean FILE` pins only the file's DIRECT imports in the
#     module setup; TRANSITIVE modules resolve via LEAN_PATH search.
#   * Lean's module-path search commits per ROOT COMPONENT: for any
#     `RelSem.*` module it selects the FIRST LEAN_PATH entry that
#     carries a `RelSem/` directory and never falls back. With the
#     RelSem prefix SPLIT across two packages (root RelSemCore:
#     Call/Machine/RunND/ExecModel/Cerberus/Threaded; relsem: the
#     proof layer), any transitive module living in the OTHER tree
#     fails with "object file ... does not exist" — whichever tree
#     is listed first loses the other's modules.
#   * `lake setup-file FILE` computes the COMPLETE per-module
#     artifact map (both trees, correctly attributed).
#
# So the recipe is: setup-file + lean --setup. Run from the PACKAGE
# DIRECTORY that owns the file (e.g. lean_frontend/relsem):
#
#   ../../scripts/lean_probe.sh RelSem/MyProbe.lean
#
# Memory-capped via scripts/capped (the D7 rule). Exit = lean's exit.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${1:?usage: lean_probe.sh <file.lean> [extra lean args...]}"
shift || true
# NOTE: the setup file lives in the CWD, not /tmp — sandboxed
# environments here are write-only on /tmp (readback fails).
SETUP="$(mktemp ".lean_probe.XXXXXX.json")"
trap 'rm -f "$SETUP"' EXIT
# setup-file may emit build noise on stdout before the JSON; the JSON
# is the last line. Build the deps first so the setup is complete.
if ! lake setup-file "$FILE" 2>/dev/null | tail -1 > "$SETUP"; then
    echo "lean_probe: lake setup-file failed for $FILE" >&2
    exit 1
fi
if [[ ! -s "$SETUP" ]]; then
    echo "lean_probe: empty setup for $FILE (lake setup-file produced no JSON)" >&2
    exit 1
fi
exec "$SCRIPT_DIR/capped" lean -DautoImplicit=false --setup "$SETUP" "$FILE" "$@"
