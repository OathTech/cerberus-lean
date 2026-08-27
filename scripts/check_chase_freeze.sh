#!/bin/bash
# check_chase_freeze.sh — arc-16 S0 (2026-08-24): THE CHASE FREEZE GATE
# (charter docs/2026-08-24_arc16-iris-refounding-charter.md, slice S0a).
#
# The chase-era proof machinery (the app_walk walker + trace/replay:
# RelSem.Tactics.AppWalk, RelSem.Tactics.WalkTrace and the tactic
# surfaces app_walk / app_walk_norm / app_walk_rec / app_walk_replay)
# is FROZEN pending retirement: the Iris refounding (arc 16/17) has
# re-proved the flagship theorems threaded through the per-step
# language + evaluator route; the arc-18 C5 EXTENDED PURGE deletes
# the chase surfaces in one commit (retirement inventory:
# lean_frontend/docs/2026-08-25_reasoning-layer-contracts.md §7).
# Until then the
# existing consumers below are grandfathered as the LEGACY ALLOWLIST,
# and any NEW dependence on the chase — an import of either module, or
# a use of any of the four tactic tokens, in a file not on the list —
# is a build-fatal regression: new proof work goes through the Iris
# machinery, not the walker.
#
# Semantics (fail-closed):
#   * Scan surface: every .lean file in the repo that is git-tracked
#     OR untracked-but-not-ignored (so brand-new files are caught
#     before they are ever committed; .lake trees and other ignored
#     artifacts are out of scope). Stricter than the proof-size gate's
#     committed-files-only policy ON PURPOSE: during the freeze even
#     session scratch must not grow new chase dependence.
#   * An allowlisted file that has DISAPPEARED is fine (that is the
#     purge working as intended; the list empties in part 2).
#   * A hit in a non-allowlisted file is FATAL, printed file:line.
#   * An empty scan list or a git failure is FATAL (fail-closed).
#
# THE LEGACY ALLOWLIST (verified by grep at S0, 2026-08-24; this list
# is also the purge's work inventory). Direct importers of
# RelSem.Tactics.{AppWalk,WalkTrace}:
#   relsem/RelSemAll.lean            (lib aggregator)
#   relsem/RelSem/T1AppEq.lean       (T1 round-chain; walk-driven)
#   (relsem/RelSem/T5Prefix.lean — the T5 prefix walks — DELETED at
#    arc-18 R4 with T5Fixture/T5Iter: T5 is proved through the
#    segment layer; allowlist entry removed in the deleting commit.)
#   relsem/RelSem/Tactics/AppWalk.lean (the walker itself; imports WalkTrace)
#   relsem/test/Unit/AppWalkTest.lean  (E1-E10 contract table)
# Tactic-token users beyond those:
#   (relsem/bench/WalkBench.lean — the arc-11 metrics bench — DELETED
#    at arc-18 R3: zero importers, never a build target; allowlist
#    entry removed in the deleting commit. Record:
#    lean_frontend/docs/2026-08-27_arc18-r3-early-purge.md)
#   relsem/RelSem/Tactics/AppEqAttr.lean (docstring mentions only.
#     Truth about @[app_eq] — corrected arc-18 C0: the proved LEMMAS
#     under the attribute survive by re-registration in the arc-18 C1
#     unified registry (today's law layer consumes them by NAME, not
#     through the attribute index); the DiscrTree attribute MECHANISM
#     is consumed only by the frozen walker (appEqMatches appears only
#     in AppWalk.lean) and is the C1 registry's in-house donor — its
#     disposition, evolve-or-delete, is decided at C1)
# NOT on the list (verified: no direct import, no tactic token):
#   T2AppEq/T3AppEq/T4AppEq/T4Defs — they consume T1AppEq's proved
#   lemmas, not the walker. (T5Fixture/T5Iter — formerly in this
#   note — deleted at arc-18 R4.)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Paths relative to the repo root.
ALLOWLIST=(
    "lean_frontend/relsem/RelSemAll.lean"
    "lean_frontend/relsem/RelSem/T1AppEq.lean"
    "lean_frontend/relsem/RelSem/Tactics/AppWalk.lean"
    "lean_frontend/relsem/RelSem/Tactics/AppEqAttr.lean"
    "lean_frontend/relsem/RelSem/Tactics/WalkTrace.lean"
    "lean_frontend/relsem/test/Unit/AppWalkTest.lean"
)

is_allowlisted() {
    local f
    for f in "${ALLOWLIST[@]}"; do
        [[ "$f" == "$1" ]] && return 0
    done
    return 1
}

# The frozen surfaces.
IMPORT_RE='^[[:space:]]*(public[[:space:]]+)?import[[:space:]]+RelSem\.Tactics\.(AppWalk|WalkTrace)([^A-Za-z0-9_].*)?$'
TOKEN_RE='\bapp_walk(_norm|_rec|_replay)?\b'

# Scan list: tracked + untracked-not-ignored .lean files.
scan_files=$( { git ls-files -- '*.lean' \
                && git ls-files --others --exclude-standard -- '*.lean'; } \
              | sort -u )
if [[ -z "$scan_files" ]]; then
    echo "check_chase_freeze: FAILED — empty scan list (git enumeration broke; fail-closed)"
    exit 1
fi

fail=0
present_allow=0
while IFS= read -r f; do
    [[ -f "$f" ]] || continue   # racy delete: nothing to scan
    if is_allowlisted "$f"; then
        present_allow=$((present_allow + 1))
        continue
    fi
    hits=$(grep -nE "$IMPORT_RE" "$f" || true)
    if [[ -n "$hits" ]]; then
        echo "check_chase_freeze: NEW chase-surface IMPORT in non-allowlisted file:"
        echo "$hits" | sed "s|^|  $f:|"
        fail=1
    fi
    hits=$(grep -nE "$TOKEN_RE" "$f" || true)
    if [[ -n "$hits" ]]; then
        echo "check_chase_freeze: chase tactic surface used in non-allowlisted file:"
        echo "$hits" | sed "s|^|  $f:|"
        fail=1
    fi
done <<< "$scan_files"

if [[ $fail -ne 0 ]]; then
    echo "check_chase_freeze: FAILED — the chase is FROZEN (arc-16 S0a);"
    echo "  new proof work goes through the Iris machinery. If a legacy"
    echo "  file was legitimately renamed, update the allowlist here in"
    echo "  the same commit (operator-visible)."
    exit 1
fi

echo "check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (${present_allow}/${#ALLOWLIST[@]} allowlisted files present)"
