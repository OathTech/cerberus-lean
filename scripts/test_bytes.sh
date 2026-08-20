#!/bin/bash
# test_bytes.sh — tests/bytes micro-lane (arc-10 S3b): the Lean pipeline
# checked against the corpus's COMMITTED expected files.
#
# ORACLE-INDEPENDENT REFERENCE: tests/bytes/*.exec are upstream
# diff-prog.py exec-mode records (tests/diff-prog.py:33-37 renders
# "return code: <rc>" + the program's captured stdout; mode config
# tests/bytes/exec.json = `cerberus --exec`, filter *.exec.c). The
# expecteds are committed files — the reference here is the RECORD, not
# the oracle binary (the oracle is only used to produce the Cabs-JSON
# input, the pipeline's standing parse boundary).
#
# Two legs, fail-closed:
#
#   EXEC leg (*.exec.c, 9 files): oracle --nolibc --cabs-json (input
#     production only) → cerberus-lean --batch → exactly one
#     `Defined {value: "Specified(N)", stdout: "", ...}` line →
#     rendered as "return code: (N mod 256)" (POSIX exit-status byte,
#     matching diff-prog.py's use of the process return code) and
#     byte-compared to the committed .exec expected. Program stdout is
#     required EMPTY (--nolibc corpus; a future non-empty expected
#     fails loudly here → extend the renderer then).
#
#   NEG leg (non-exec .c whose committed .elab records
#     "return code: 1", 5 files): the oracle front-end rejects these at
#     DESUGAR level BEFORE the Cabs-JSON boundary (verified 2026-08-20:
#     `--cabs-json` exits 1 with the same constraint-violation text as
#     the committed .elab body), so the Lean pipeline is UNREACHABLE
#     for them — the Lean desugar's own byte-typing rules are not
#     probed (recorded residual, arc-10 S3b record). The leg pins the
#     boundary: --cabs-json must FAIL for each (agreeing with the
#     expected rc 1). If a future oracle emits JSON here, this lane
#     FAILS LOUDLY → extend the leg to Lean-side desugar rejection.
#
# The 9 positives' .elab records (rc 0, `--typecheck-core`) are
# subsumed by the EXEC leg: the Lean pipeline desugars, typechecks and
# translates before executing.
#
# Usage: ./scripts/test_bytes.sh
# Exit: 0 iff every file is green; any mismatch/omission is fatal.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }

BYTES_DIR="$PROJECT_ROOT/tests/bytes"
[[ -d "$BYTES_DIR" ]] || { echo "Error: $BYTES_DIR not found" >&2; exit 1; }

build_cerberus
build_lean

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/bytes.XXXXXXXXXX") || { echo "mktemp failed" >&2; exit 1; }
register_cleanup "$OUTPUT_DIR"
cd "$PROJECT_ROOT" || exit 1

pass=0
fail=0
neg=0

echo ""
echo "bytes micro-lane (arc-10 S3b: Lean vs committed expecteds)"
echo "=========================================================="

# ---- EXEC leg -------------------------------------------------------
for src in "$BYTES_DIR"/*.exec.c; do
    name=$(basename "$src")
    expect_file="$src.exec"
    if [[ ! -f "$expect_file" ]]; then
        echo "[FAIL] $name: committed expected $expect_file missing"
        fail=$((fail + 1)); continue
    fi
    json="$OUTPUT_DIR/$name.json"
    # run_cerberus body inlined (common.sh:91-94) — timeout needs a command
    timeout "$TIMEOUT_SECS" opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" \
        --nolibc --cabs-json "$src" > "$json" 2> "$json.err"
    if [[ ! -s "$json" ]]; then
        echo "[FAIL] $name: cabs-json production failed: $(head -1 "$json.err" 2>/dev/null)"
        fail=$((fail + 1)); continue
    fi
    lean_out=$(timeout "$TIMEOUT_SECS" env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch "$json" 2>"$OUTPUT_DIR/$name.lean.err")
    lean_rc=$?
    # exactly one Defined line with a Specified integer and empty stdout
    n_lines=$(printf '%s\n' "$lean_out" | grep -c '^Defined\|^Undefined\|^Error\|^EXECUTION')
    val=$(printf '%s\n' "$lean_out" | sed -n 's/^Defined {value: "Specified(\(-\{0,1\}[0-9]*\))", stdout: "", stderr: "[^"]*", blocked: "false"}$/\1/p')
    if [[ "$n_lines" != "1" || -z "$val" ]]; then
        echo "[FAIL] $name: unexpected Lean output (rc=$lean_rc): $lean_out"
        fail=$((fail + 1)); continue
    fi
    rendered="return code: $(( ((val % 256) + 256) % 256 ))"
    expected=$(cat "$expect_file")
    if [[ "$rendered" == "$expected" ]]; then
        echo "[MATCH] $name: $rendered"
        pass=$((pass + 1))
    else
        echo "[MISMATCH] $name: lean rendered '$rendered' vs committed '$expected'"
        fail=$((fail + 1))
    fi
done

# ---- NEG leg --------------------------------------------------------
for src in "$BYTES_DIR"/*.c; do
    name=$(basename "$src")
    [[ "$name" == *.exec.c ]] && continue
    expect_file="$src.elab"
    if [[ ! -f "$expect_file" ]]; then
        echo "[FAIL] $name: committed expected $expect_file missing"
        fail=$((fail + 1)); continue
    fi
    exp_rc_line=$(head -1 "$expect_file")
    if [[ "$exp_rc_line" != "return code: 1" ]]; then
        echo "[FAIL] $name: unexpected .elab first line '$exp_rc_line' (extend the lane)"
        fail=$((fail + 1)); continue
    fi
    json="$OUTPUT_DIR/$name.json"
    if timeout "$TIMEOUT_SECS" opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" \
        --nolibc --cabs-json "$src" > "$json" 2>/dev/null && [[ -s "$json" ]]; then
        echo "[FAIL] $name: oracle now EMITS Cabs-JSON for an expected-reject file — extend the NEG leg to Lean-side desugar rejection"
        fail=$((fail + 1))
    else
        echo "[NEG_OK] $name: front-end reject pinned (committed .elab rc 1)"
        neg=$((neg + 1))
    fi
done

echo ""
echo "SUMMARY: exec_match=$pass neg_pinned=$neg fail=$fail"
if [[ $fail -gt 0 ]]; then
    echo "BYTES LANE FAILED"
    exit 1
fi
if [[ $pass -eq 0 ]]; then
    echo "BYTES LANE FAILED (zero exec comparisons — vacuous pass refused)"
    exit 1
fi
echo "ALL AT COMMITTED EXPECTEDS"
exit 0
