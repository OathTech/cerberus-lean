#!/bin/bash
# check_proof_size.sh — arc-9 S2 (2026-08-20): THE PROOF-SIZE GATE
# (design docs/2026-08-20_arc9-s1-design.md §4; Tier A, fail-closed).
#
# Per registered slate proof file T<n>.lean (the COUNTED file: statement
# + spec + invariant family + side conditions + proof; the fixture file
# T<n>Fixture/T<n>File is NOT counted but IS checked fixture-clean rules
# below):
#   * total lines ≤ 250
#   * manual proof steps ≤ 40 — a manual step = any tactic line inside a
#     by-block that is not an `app_walk`/`app_walk_finish` invocation
#     (app_walk_step, refine, omega, simp, case splits ... all count).
# Line counts are ADVISORY per golean (a breach is a MISSING-RULE
# FINDING triggering stop-extract-redo), but the gate FAILS so the
# breach is never silent.
#
# Additionally FAIL (unconditional):
#   * debug-only walker surfaces in ANY committed relsem file:
#     `app_walk?`/`app_walk_norm?` (S2), and — arc-9 pre-merge audit
#     A-F5 (2026-08-21) — `app_defeq_diag` and `dnms_kwalk`.
#     POLICY DECISION (recorded here per the audit disposition): none
#     appear in any committed proof (T1AppEq/T5Prefix verified clean
#     at the time of the extension), so all are banned outright, same
#     policy as `app_walk?`. `app_walk_norm!` was on this list until
#     arc-11 S1 (F12-4): the surface is RETIRED — sealing is now
#     `app_walk_norm`'s default, so the token no longer parses and
#     the ban row is dropped (this comment is the recorded policy
#     change, same commit as the retirement).
#     Untracked session scratch (Probe*.lean etc.) is exempt via the
#     git-tracked filter below — the ban is on COMMITTED files; a
#     future legitimate committed use requires an explicit,
#     operator-visible gate-policy change here.
#     arc-11 S1 batch 2 (design §12.2 enforcement layer 2):
#     `app_walk_preview` is ADDED to the ban — preview output is
#     NEVER CI-authoritative; no committed relsem proof may invoke
#     it (its negative test lives in test/Unit/AppWalkTest.lean E9,
#     outside this gate's scan surface by design).
#   * fixture-symbol references inside Kit/*.lean — the MEGA-LEMMA
#     COUNTER: a "kit lemma" that names a fixture is bar-gaming by
#     construction.
#
# Tallies print verbatim (the results doc quotes them).

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELSEM="$SCRIPT_DIR/../lean_frontend/relsem/RelSem"

MAX_LINES=250
MAX_STEPS=40

# The registered slate proof files (extend per example; T1-T4 predate
# the bar and are measured by the arc records, not this gate).
SLATE_FILES=(
    "T5.lean"
)

fail=0

# --- the mega-lemma counter: Kit files must be fixture-free ----------
# fixture symbol classes: t<n>File / t<n>Fs / T<n>-namespaces / pinned
# fixture def names.
kit_hits=$(grep -nE 't[0-9]+File|t[0-9]+Fs|RelSem\.T[0-9]+\.|T[0-9]+Core' \
    "$RELSEM"/Kit/*.lean 2>/dev/null | grep -v 'Kit/Audit.lean' || true)
if [[ -n "$kit_hits" ]]; then
    echo "check_proof_size: FAIL — Kit files reference fixture symbols (mega-lemma counter):"
    echo "$kit_hits"
    fail=1
else
    echo "check_proof_size: Kit files fixture-free OK ($(ls "$RELSEM"/Kit/*.lean | wc -l | tr -d ' ') files)"
fi

# --- debug-surface ban in committed proofs ---------------------------
# app_walk?/app_walk_norm? (S2) + app_defeq_diag/dnms_kwalk (arc-9
# audit A-F5; app_walk_norm! retired arc-11 S1 F12-4 — policy note in
# the header). Hits are filtered to git-TRACKED files: the ban is on
# COMMITTED proofs; untracked session scratch (Probe*.lean) may use
# debug surfaces by design.
raw_dbg_hits=$(grep -rnE '^[^-]*\b(app_walk(_norm)?\?|dnms_kwalk|app_defeq_diag|app_walk_preview)' \
    "$RELSEM"/*.lean "$RELSEM"/Kit/*.lean 2>/dev/null \
    | grep -v 'Tactics/' || true)
dbg_hits=""
if [[ -n "$raw_dbg_hits" ]]; then
    while IFS= read -r hit; do
        [[ -z "$hit" ]] && continue
        hf="${hit%%:*}"
        if git -C "$SCRIPT_DIR/.." ls-files --error-unmatch "$hf" >/dev/null 2>&1; then
            dbg_hits+="$hit"$'\n'
        fi
    done <<< "$raw_dbg_hits"
fi
if [[ -n "$dbg_hits" ]]; then
    echo "check_proof_size: FAIL — debug-only walker surface in committed files:"
    printf '%s' "$dbg_hits"
    fail=1
else
    echo "check_proof_size: debug-surface ban OK (app_walk?/app_walk_norm?/dnms_kwalk/app_defeq_diag/app_walk_preview)"
fi

# --- per-slate-file line + manual-step tallies ------------------------
for f in "${SLATE_FILES[@]}"; do
    path="$RELSEM/$f"
    if [[ ! -f "$path" ]]; then
        echo "check_proof_size: $f — not present yet (registered, pending)"
        continue
    fi
    lines=$(wc -l < "$path" | tr -d ' ')
    # manual steps: tactic lines inside by-blocks that are not pure
    # walker invocations. Heuristic (the S4 audit reads the lines
    # themselves): count non-comment, non-blank lines that start with a
    # tactic-ish token after the first `by` of each declaration, minus
    # app_walk/app_walk_finish lines. We approximate by counting lines
    # whose stripped form begins with a known tactic head or a `·`/case
    # bullet, within the file.
    steps=$(awk '
        /^[[:space:]]*--/ { next }
        /^[[:space:]]*$/ { next }
        {
            line=$0
            sub(/^[[:space:]]+/, "", line)
            # walker invocations do not count as manual steps
            if (line ~ /^app_walk([[:space:]]|$)/) next
            if (line ~ /^app_walk_finish[[:space:]]/) next
            # tactic-looking lines
            if (line ~ /^(app_walk_step|refine|exact|apply|rw|simp|dsimp|omega|decide|constructor|cases|rcases|obtain|intro|have|show|subst|change|unfold|calc|conv|first|·|\.|case[[:space:]])/) {
                count++
            }
        }
        END { print count+0 }
    ' "$path")
    echo "check_proof_size: $f — $lines lines (bar $MAX_LINES), $steps manual steps (bar $MAX_STEPS)"
    if (( lines > MAX_LINES )); then
        echo "check_proof_size: FAIL — $f exceeds the line bar ($lines > $MAX_LINES): missing-rule finding, stop-extract-redo"
        fail=1
    fi
    if (( steps > MAX_STEPS )); then
        echo "check_proof_size: FAIL — $f exceeds the manual-step bar ($steps > $MAX_STEPS): missing-rule finding, stop-extract-redo"
        fail=1
    fi
done

if (( fail )); then
    exit 1
fi
echo "check_proof_size: OK"
