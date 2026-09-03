#!/bin/bash
# fuel_classify.sh — the ONE fuel-exhaustion classifier shared by every
# classifying lane (FUEL arc, 2026-09-03; design
# lean_frontend/docs/2026-09-02_fuel-arc-design.md §3). Sourced by
# scripts/common.sh (so test_exec.sh / test_csmith_corpus.sh,
# test_gcc_oracle.sh, test_ci_sweep.sh, test_cn_coverage.sh see it) and
# directly by tests/mem-scale-probes/measure.sh (which does not source
# common.sh). Pure function, no side effects, no env requirements.
#
# WHAT A FUEL DEATH LOOKS LIKE (design note §3.1):
#   * kill  — an ND-typed fueled worker (the driver-loop family, the
#             memory-model ND workers, the CerbND runners) exhausted: the
#             driver returns `Killed st CerbND.fuelExhaustedKill`, Main
#             prints, per execution,
#               batch:      Error {msg: "lem: fuel exhausted"}
#               non-batch:    result: Killed (error: lem: fuel exhausted)
#             and exits 1 like every Error kill (0 with >1 executions).
#   * panic — a PURE-return fueled worker (`hack` + the ~58 others)
#             exhausted: LemLib's opaque `fuelExhausted` sentinel panics —
#             the bare line `lem: fuel exhausted` on stderr, exit 134
#             under LEAN_ABORT_ON_PANIC=1 (never a kill, never a verdict).
#
# THE RULE: keyed on the EXACT printed message as a WHOLE LINE of the
# merged stdout+stderr capture — never the loose `fuel exhausted` regex on
# stdout. A test program's own output cannot forge it: program stdout is
# embedded quote-ESCAPED inside the `Defined {…, stdout: "…"}` line, so a
# whole-line match on the bare forms is unreachable from inside it (the
# third negative of the classifier selftest, scripts/test_fuel_classifier.sh).
# A genuine `Error {msg: "assert() failure"}` / any other message is NOT
# fuel (first negative); a PANIC without the exact marker is NOT fuel
# (second negative).
#
# REPORTING-ONLY: the string here is a COPY of CerbFuel.fuelExhaustedMsg
# (lean_frontend/CerbFuel.lean). It never enters a proof; a drift between
# the two degrades classification LOUDLY (fuel kills fall back to the
# FAIL-class rows — FAIL / SKIP_LEAN_FAIL / LEAN_FAIL — never to
# agreement) and is never a soundness matter. No drift gate is built
# (design note §3.2, R2 deleted R1's); the selftest is the discipline.
#
# Semantics of the class in every lane: fail-noisy (fatal in default mode
# exactly as LEAN_CRASH is), baselined rows honoured only by the
# --check-baseline machinery, NEVER counted as MATCH/AGREE, never as a
# completed run.
#
# classify_fuel_outcome <exit> <merged-capture-text>
#   prints FUEL:kill | FUEL:panic | "" (empty = not a fuel death)
FUEL_KILL_BATCH_LINE='Error {msg: "lem: fuel exhausted"}'
FUEL_KILL_HUMAN_LINE_RE='^ *result: Killed \(error: lem: fuel exhausted\)$'
FUEL_PANIC_LINE='lem: fuel exhausted'
classify_fuel_outcome() {
    local rc="$1" cap="${2:-}"
    if grep -qxF -- "$FUEL_KILL_BATCH_LINE" <<<"$cap" \
       || grep -qE -- "$FUEL_KILL_HUMAN_LINE_RE" <<<"$cap"; then
        echo "FUEL:kill"; return 0
    fi
    if [[ "$rc" -ge 128 ]] && grep -qxF -- "$FUEL_PANIC_LINE" <<<"$cap"; then
        echo "FUEL:panic"; return 0
    fi
    echo ""
}
