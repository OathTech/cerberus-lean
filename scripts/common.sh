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
# PLANT HOOK (mem-scale S0, 2026-09-02): substitute a stub for the Lean
# driver so a harness's failure CLASSIFICATION can be plant-tested
# (scripts/test_hang_plant.sh: a sleeping stub must read HANG, a
# busy-looping stub TIMEOUT). Loud on every use; results under an
# override are never evidence about the semantics. The SKIP_BUILD
# freshness check below is skipped for the overridden side — loudly.
if [[ -n "${CERB_LEAN_BIN_OVERRIDE:-}" ]]; then
    CERBERUS_LEAN_BIN="$CERB_LEAN_BIN_OVERRIDE"
    echo "==============================================================" >&2
    echo "CERB_LEAN_BIN_OVERRIDE ACTIVE: Lean driver replaced by $CERBERUS_LEAN_BIN" >&2
    echo "PLANT MODE — this run's rows are NOT evidence about the semantics" >&2
    echo "==============================================================" >&2
fi

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
    if [[ -n "${CERB_LEAN_BIN_OVERRIDE:-}" ]]; then
        echo "CERB_LEAN_BIN_OVERRIDE ACTIVE: Lean driver freshness check SKIPPED (plant stub, not the driver)" >&2
    elif [[ -f "$CERBERUS_LEAN_BIN" ]]; then
        "$PROJECT_ROOT/tools/check_driver_fresh.sh" --check-lean >&2 || exit 1
    fi
fi

# ---------------------------------------------------------------------------
# Timed runs + the HANG classification (mem-scale S0, 2026-09-02; charter
# lean_frontend/docs/2026-09-01_mem-scale-design.md C9 / §6.1; the
# classification was first verified in tests/mem-scale-probes/measure.sh).
#
# THE DEFECT SHAPE: a process that stops consuming CPU long before the
# timeout fires — the >7 M-element front-end recursion parks every thread
# on a futex after ~3-4 s of CPU (profile §6.3.1: guard-page SIGSEGV, then
# FUTEX_WAIT_PRIVATE inside the overflow handler, forever). Every lane
# read that as TIMEOUT, indistinguishable from a slow-but-working run:
# fail-open by silence. The rule: exit 124 AND (User+System)/wall < 0.1
# is a HANG, a DISTINCT class that is never counted as a completed run,
# never a skip, never a plain timeout. The ratio is timeout-relative
# (a hang that burns 4 s of CPU before parking needs a timeout >= 40 s to
# fall under 0.1); a lane's TIMEOUT_SECS is therefore part of the
# instrument and is quoted in the note.
#
# Mechanism: every driver run is wrapped as
#   $TIME_BIN -v -o <timefile> timeout Ns <cmd>
# GNU time propagates the child's exit status unchanged (124 for
# timeout, 128+sig for signal deaths — verified 2026-09-02: 139/134/124/
# 70 all pass through), writes the rusage record to the -o file (so the
# captured stdout+stderr stream is untouched), and its User/System
# figures include the waited-for descendants (timeout waits for the
# child). NEVER a stack-size knob: a bumped budget only moves the silent
# ceiling (the registered-defect shape).
TIME_BIN=/usr/bin/time
# ---------------------------------------------------------------------------
# Per-test memory cap (mem-scale S2, 2026-09-02; Q2 RULED [USER 2026-09-02]
# "Q2 agree" — charter 2026-09-01_mem-scale-design.md §0/§6.4; LADDER.md
# "Conventions"). SUPERSEDES the arc-5 operator directive `ulimit -v
# 4000000`: `ulimit -v` limits VIRTUAL address space, and Lean's virtual
# footprint is ~2-3.6x its RSS, so the old cap killed Lean at ~1.7 GB RSS
# while the oracle ran to 3.1 GB (profile §2). The cap is now RESIDENT
# memory via a per-test cgroup (`scripts/capped`, the same mechanism every
# lake/lean build runs under), keeping the intended 4 GB blast radius per
# test on BOTH sides. On breach the kernel SIGKILLs inside the cgroup:
# the wrapped command exits 137 and `capped` prints its KILLED banner on
# stderr. Every harness classifies 137 as its own KILL class — never as
# agreement, never as a skip (see each harness's header).
#   CERB_TEST_MEM_MAX  per-test cap (default 4G; `none` = loud opt-out)
# Usage in a harness (replaces `( ulimit -v $ULIMIT_KB; exec timeout … )`):
#   "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" <cmd…>
CAPPED_BIN="$SCRIPT_DIR/capped"
TEST_MEM_MAX="${CERB_TEST_MEM_MAX:-4G}"
CAPPED_TEST=(env "CERB_MEM_MAX=$TEST_MEM_MAX" "$CAPPED_BIN")
[[ -x "$CAPPED_BIN" ]] || { echo "Error: $CAPPED_BIN missing or not executable (per-test memory cap; fail-closed)" >&2; exit 1; }
# kill_label <rc> [<stderr-file>]: the one-line reading of an exit 137
# (the cgroup kill / SIGKILL class), with the capped banner as witness.
kill_label() {
    local rc="$1" errf="${2:-}"
    if [[ -n "$errf" && -f "$errf" ]] && grep -q "capped: KILLED" "$errf"; then
        echo "KILLED (exit $rc; capped KILLED banner present — cgroup memory cap CERB_TEST_MEM_MAX=$TEST_MEM_MAX or SIGKILL)"
    else
        echo "KILLED (exit $rc — SIGKILL; memory cap CERB_TEST_MEM_MAX=$TEST_MEM_MAX or external kill)"
    fi
}
require_time_bin() {   # fail-closed: no /usr/bin/time = no HANG instrument
    if [[ ! -x "$TIME_BIN" ]]; then
        echo "Error: $TIME_BIN not found or not executable — the HANG classification needs GNU time (fail-closed, not skipped)" >&2
        exit 1
    fi
}
# time_record_cpu_wall <timefile>: prints "<cpu_s> <wall_s>" (2 decimals)
# from a `time -v -o` record; rc 1 (with a HARNESS ERROR line) if the
# record is missing or unparseable — callers must treat that as fatal.
time_record_cpu_wall() {
    local tf="$1" ut st_ w cpu wall
    if [[ ! -f "$tf" ]]; then
        echo "HARNESS ERROR: time record $tf missing" >&2; return 1
    fi
    ut=$(sed -n 's/.*User time (seconds): //p' "$tf")
    st_=$(sed -n 's/.*System time (seconds): //p' "$tf")
    w=$(sed -n 's/.*Elapsed (wall clock) time (h:mm:ss or m:ss): //p' "$tf")
    if [[ -z "$ut" || -z "$st_" || -z "$w" ]]; then
        echo "HARNESS ERROR: time record $tf unparseable (User/System/Elapsed missing)" >&2; return 1
    fi
    cpu=$(awk -v u="$ut" -v s="$st_" 'BEGIN{printf "%.2f", u+s}')
    # h:mm:ss.ss or m:ss.ss -> seconds
    wall=$(awk -F: -v w="$w" 'BEGIN{n=split(w,a,":"); s=0; for(i=1;i<=n;i++) s=s*60+a[i]; printf "%.2f", s}')
    echo "$cpu $wall"
}
# classify_exit124 <timefile> <timeout_secs>: for a run that exited 124,
# prints "HANG(cpu Xs of Ys wall; timeout Ns)" when cpu/wall < 0.1, else
# "TIMEOUT(cpu Xs of Ys wall; timeout Ns)". rc 1 = unreadable record
# (fatal for the caller — an unclassifiable timeout is never TIMEOUT by
# default).
classify_exit124() {
    local tf="$1" tsecs="$2" cw cpu wall
    cw=$(time_record_cpu_wall "$tf") || return 1
    cpu="${cw% *}"; wall="${cw#* }"
    if awk -v c="$cpu" -v w="$wall" 'BEGIN{exit !(w > 0 && c / w < 0.1)}'; then
        echo "HANG(cpu ${cpu}s of ${wall}s wall; timeout ${tsecs}s)"
    else
        echo "TIMEOUT(cpu ${cpu}s of ${wall}s wall; timeout ${tsecs}s)"
    fi
}

# Produce an 8-character hash of a string (works on both macOS and Linux)
portable_hash() {
    if command -v md5sum &>/dev/null; then
        printf '%s' "$1" | md5sum | cut -c1-8
    else
        printf '%s' "$1" | md5 | cut -c1-8
    fi
}
