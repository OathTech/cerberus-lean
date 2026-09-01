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

# Fail-fast env guard ([USER] env-trap tweak, arc-13 audit-fix batch):
# every consumer of this file assumes the container env — the opam switch
# putting lem/dune on PATH and the GIT_CONFIG_GLOBAL offline redirects.
# A bare shell otherwise fails cryptically deep inside a lane
# ("Compilation requires [lem]", git exit-128). Refuse up front instead.
if [[ -z "${GIT_CONFIG_GLOBAL:-}" ]] || ! command -v lem >/dev/null 2>&1; then
    echo "env not loaded: run via scripts/ce or source scripts/env.sh" >&2
    exit 2
fi

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

# SKIP_BUILD freshness verification (effect-retirement C2; closes the
# C1-audit note-2 residue of the s-basket item-6 stamp gate):
# SKIP_BUILD=1 lanes previously asserted only that the binaries EXIST —
# a binary built from a stale generated tree over changed .lem sources
# would run differential lanes against the wrong semantics (the
# split-record finding-6 shape the stamps were built for). Every
# SKIP_BUILD entry point now also verifies BOTH lem-sync freshness
# stamps (OCaml + Lean generated trees vs the .lem sources).
# Fail-closed: a missing stamp or any drift is an error, never a skip.
verify_skip_build_freshness() {
    if ! "$PROJECT_ROOT/tools/check_lem_sync.sh" --check; then
        echo "Error: SKIP_BUILD=1 but the OCaml lem-sync stamp check failed (stale generated tree / stale driver hazard — rebuild, don't skip)" >&2
        exit 1
    fi
    if ! "$PROJECT_ROOT/tools/check_lem_sync.sh" --check-lean; then
        echo "Error: SKIP_BUILD=1 but the Lean lem-sync stamp check failed (stale generated tree / stale driver hazard — rebuild, don't skip)" >&2
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
    # cerberus-lib.install must be built EXPLICITLY (2026-08-22 hotfix):
    # `dune install cerberus-lib` below does NOT build it — after a
    # `dune clean` it fails ("The following <package>.install are
    # missing"), and building it is also what stages
    # _build/install/default/lib/cerberus-lib (std.core etc.), which
    # every --runtime=_build/install/default invocation needs.
    # Trust-basket item d follow-up: gate on dune's exit status (same
    # defect shape as build_lean's `| tail -3`); with the item-a
    # freshness stamp auto-recorded below, a swallowed build failure
    # would otherwise RECORD a stamp binding the old binary to the new
    # tree — fabricated freshness. Fail here instead.
    local _dlog="$TMP_DIR/build_cerberus.$$.log"
    if ! (cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        dune build backend/driver/main.exe cerberus-lib.install) > "$_dlog" 2>&1; then
        echo "Error: cerberus build FAILED (dune exit nonzero); last 40 lines:" >&2
        tail -40 "$_dlog" >&2
        rm -f "$_dlog"
        exit 1
    fi
    tail -3 "$_dlog"
    rm -f "$_dlog"
    if [[ ! -f "$CERBERUS_BIN" ]]; then
        echo "Error: Cerberus build failed" >&2
        exit 1
    fi
    # Ensure cerberus-lib is installed (for runtime files). Fail LOUDLY
    # (2026-08-22 hotfix): the old `2>/dev/null` masked the post-clean
    # "cerberus-lib.install missing" failure and let lanes proceed on a
    # half-staged tree.
    local _install_out
    if ! _install_out=$(cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        dune install cerberus-lib 2>&1); then
        echo "Error: dune install cerberus-lib failed:" >&2
        echo "$_install_out" | tail -4 >&2
        exit 1
    fi
    # Stage the `cerberus` PACKAGE's install tree (2026-08-22 hotfix,
    # docs/2026-08-22_libc-co-divergence-diagnosis.md): libc-mode oracle
    # runs (--runtime=_build/install/default, no --nolibc) load
    # _build/install/default/lib/cerberus/runtime/libc/libc.co — a path
    # created ONLY by the `cerberus` package's install stanzas
    # (runtime/libc/dune:159-173), never by cerberus-lib. Dune stages it
    # as a relative symlink into _build/default, so once present it is
    # permanently in sync with the build tree by construction. Without
    # this step a post-`dune clean` rebuild leaves the path missing and
    # every libc-mode oracle invocation dies at startup
    # (Failure("file libc.co not found"), exit 125).
    if ! (cd "$PROJECT_ROOT" && opam exec --switch="$PROJECT_ROOT" -- \
        dune build cerberus.install) > "$_dlog" 2>&1; then
        echo "Error: cerberus.install build FAILED (dune exit nonzero); last 40 lines:" >&2
        tail -40 "$_dlog" >&2
        rm -f "$_dlog"
        exit 1
    fi
    tail -3 "$_dlog"
    rm -f "$_dlog"
    local staged_co="$PROJECT_ROOT/_build/install/default/lib/cerberus/runtime/libc/libc.co"
    if [[ ! -e "$staged_co" ]]; then
        echo "Error: cerberus install staging failed: $staged_co missing" >&2
        echo "(dune trusts its incremental db over the filesystem: if _build was" >&2
        echo "manually altered it will not re-stage — run dune clean and rebuild" >&2
        echo "per the documented recipe, lean_frontend/CLAUDE.md Build)" >&2
        exit 1
    fi
    # Driver-freshness stamp (trust-basket item a): a successful build IS
    # the freshness witness — record it so SKIP_BUILD lanes can verify.
    "$PROJECT_ROOT/tools/check_driver_fresh.sh" --record-oracle || {
        echo "Error: driver freshness stamp recording failed (oracle)" >&2
        exit 1
    }
}

# Build Lean cerberus-lean executable
build_lean() {
    require_lean
    echo "Building cerberus-lean (Lean)..."
    # Arc-7 S5c (audit-1 F4): ALL lake/lean invocations run under the
    # cgroup memory cap (D7 rule; scripts/capped falls back loudly if
    # systemd-run is absent).
    # Trust-basket item d (gcc-lane audit note 6): gate on the BUILD'S
    # exit status, not just binary existence — the old
    # `... | tail -3` swallowed lake's failure and a broken incremental
    # build over a pre-existing stale binary passed silently (the lane
    # then ran STALE semantics). Full log kept for the failure path
    # (tail -3 would truncate real errors).
    local _log="$TMP_DIR/build_lean.$$.log"
    if ! (cd "$PROJECT_ROOT/lean_frontend" && "$SCRIPT_DIR/capped" lake build cerberus-lean) > "$_log" 2>&1; then
        echo "Error: cerberus-lean build FAILED (lake build exit nonzero); last 40 lines:" >&2
        tail -40 "$_log" >&2
        rm -f "$_log"
        exit 1
    fi
    tail -3 "$_log"
    rm -f "$_log"
    if [[ ! -f "$CERBERUS_LEAN_BIN" ]]; then
        echo "Error: cerberus-lean build failed" >&2
        exit 1
    fi
    # Driver-freshness stamp (trust-basket item a): see build_cerberus.
    "$PROJECT_ROOT/tools/check_driver_fresh.sh" --record-lean || {
        echo "Error: driver freshness stamp recording failed (lean)" >&2
        exit 1
    }
}

# Run cerberus with correct opam switch and runtime path
run_cerberus() {
    opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" "$@"
}

# Run cerberus-lean. LEAN_ABORT_ON_PANIC: a Lean `panic!` PRINTS and
# CONTINUES by default — a fuel-exhaustion sentinel would degrade to
# soft-with-stderr and a harness comparing stdout could miss it (arc-3
# audit F10). Abort makes sentinel panics fail-stop.
run_cerberus_lean() {
    LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" "$@"
}

# Driver-binary freshness gate (trust-basket item a, 2026-08-31;
# parity-detective §1: primed worktree binaries silently lag their
# checkout — a sweep against them fabricates results). When a lane is
# invoked with SKIP_BUILD=1 (the only common.sh path that USES a binary
# without rebuilding it), verify each PRESENT binary against its
# build-time stamp before anything runs. A missing binary is left to
# the lane's own fail-closed existence checks — it cannot fabricate
# results. Missing/mismatched stamp = loud fail (tools/
# check_driver_fresh.sh). Intentional cross-version runs only:
# CERB_DRIVER_FRESH_OVERRIDE=1 (loud on every use).
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
    if [[ -f "$CERBERUS_BIN" ]]; then
        "$PROJECT_ROOT/tools/check_driver_fresh.sh" --check-oracle >&2 || exit 1
    fi
    if [[ -f "$CERBERUS_LEAN_BIN" ]]; then
        "$PROJECT_ROOT/tools/check_driver_fresh.sh" --check-lean >&2 || exit 1
    fi
fi

# Produce an 8-character hash of a string (works on both macOS and Linux)
portable_hash() {
    if command -v md5sum &>/dev/null; then
        printf '%s' "$1" | md5sum | cut -c1-8
    else
        printf '%s' "$1" | md5 | cut -c1-8
    fi
}
