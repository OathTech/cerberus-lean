#!/bin/bash
# core_shape_census.sh — arc-17 S1 (2026-08-24): THE CORE SHAPE CENSUS
# (charter S1, the construct sweep's measuring instrument; Tier C —
# reporting only, never gating).
#
# Tallies the exec-relevant Core construct occurrences over the PINNED
# Core dumps (tests/verify + tests/speclab — the drift-gated oracle
# dumps behind the T1-T5 fixtures and the arc-15 spec-lab rungs).
# These dumps are the empirical shape vocabulary Cerberus elaboration
# actually emits for our corpus (the spec-lab vocabulary-saturation
# measurement's data source); the law-coverage mapping over this table
# lives in the S1 record (docs/2026-08-24_arc17-s1-equation-frontier.md)
# — the script counts, the record interprets (counts here would rot).
#
# Pattern notes (honest-counting caveats, verified against the dumps):
#   * `nd(` needs a lookbehind or it counts inside `bound(`;
#   * pure `let` (Elet) = total `let` minus `let weak` (Ewseq) minus
#     `let strong` (Esseq);
#   * `if`/`case` conflate the pure (PEif/PEcase) and effectful
#     (Eif/Ecase) forms — the pretty text does not distinguish them;
#   * memop is broken out per kind.
# Fail-closed: an empty corpus is an error.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

corpus=$(ls "$ROOT"/tests/verify/*.core "$ROOT"/tests/speclab/*.core 2>/dev/null)
nfiles=$(echo "$corpus" | grep -c . || true)
if [[ "$nfiles" -eq 0 ]]; then
    echo "core_shape_census: FAILED — no pinned .core dumps found (fail-closed)"
    exit 1
fi

echo "core_shape_census: $nfiles pinned Core dumps (tests/verify + tests/speclab)"
echo "construct                    occurrences   files"
echo "---------------------------------------------------"

count() { # $1 = label, $2 = perl regex
    local total files
    total=$(cat $corpus | grep -oP "$2" | wc -l)
    files=$(grep -lP "$2" $corpus | wc -l)
    printf "%-28s %11s %7s\n" "$1" "$total" "$files"
}

count "Epure (pure)"            '(?<![A-Za-z_])pure\('
count "Ewseq (let weak)"        'let weak'
count "Esseq (let strong)"      'let strong'
# pure Elet = let heads that are neither weak nor strong
lets_total=$(cat $corpus | grep -oP '(?<![A-Za-z_])let\s' | wc -l)
lets_ws=$(cat $corpus | grep -oP 'let (weak|strong)' | wc -l)
printf "%-28s %11s %7s\n" "Elet (pure let)" "$((lets_total - lets_ws))" "-"
count "Eif/PEif (if)"           '(?<![A-Za-z_])if\s'
count "Ecase/PEcase (case)"     '(?<![A-Za-z_])case\s'
count "Eunseq (unseq)"          '(?<![A-Za-z_])unseq\('
count "Ebound (bound)"          '(?<![A-Za-z_])bound\('
count "End (nd)"                '(?<![A-Za-z_])nd\('
count "Esave (save)"            '(?<![A-Za-z_])save\s'
count "Erun (run)"              '(?<![A-Za-z_])run\s'
count "Eccall (ccall)"          '(?<![A-Za-z_])ccall\('
count "Eproc (pcall)"           '(?<![A-Za-z_])pcall\('
count "Epar (par)"              '(?<![A-Za-z_])par\('
count "Ewait (wait)"            '(?<![A-Za-z_])wait\('
count "action: create"          '(?<![A-Za-z_])create\('
count "action: alloc"           '(?<![A-Za-z_])alloc\('
count "action: load"            '(?<![A-Za-z_])load\('
count "action: store"           '(?<![A-Za-z_])store\('
count "action: kill"            '(?<![A-Za-z_])kill\('
count "action: seq_rmw"         '(?<![A-Za-z_])seq_rmw'
count "memop: PtrValidForDeref" 'memop\(PtrValidForDeref'
count "memop: PtrEq"            'memop\(PtrEq'
count "memop: PtrNe"            'memop\(PtrNe'
count "memop: PtrWellAligned"   'memop\(PtrWellAligned'
count "memop: other kinds"      'memop\((?!PtrValidForDeref|PtrEq|PtrNe|PtrWellAligned)'
count "pexpr: array_shift"      'array_shift'
count "pexpr: member_shift"     'member_shift'
count "pexpr: undef"            '(?<![A-Za-z_])undef\('
echo "---------------------------------------------------"
echo "core_shape_census: done (reporting instrument; law mapping in the S1 record)"
