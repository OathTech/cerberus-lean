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
#     "return code: 1", 5 files): these are desugar/Ail-typing-level
#     rejects. Until 2026-08-31, `--cabs-json` ran the full c_frontend
#     and so failed on them BEFORE emitting JSON; the leg pinned that
#     boundary and carried a recorded residual ("the Lean desugar's own
#     byte-typing rules are not probed"). The trust-basket item-c
#     parse-only `--cabs-json` (backend/driver/main.ml) now emits JSON
#     for them, so — per this leg's own original instruction — the leg
#     is EXTENDED to the Lean side, closing the residual: the Lean
#     pipeline must REJECT the JSON (rc 1, matching the committed .elab
#     rc) with a desugaring/typechecking Error at the same source line
#     as the committed oracle diagnostic. A Lean accept, crash, or
#     wrong-line rejection fails loudly.
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
        # Parse-only --cabs-json (2026-08-31): the rejection moved to
        # the Lean side — pin it there (see header).
        exp_line=$(sed -n '2s/^[^:]*\.c:\([0-9][0-9]*\):.*/\1/p' "$expect_file")
        if [[ -z "$exp_line" ]]; then
            echo "[FAIL] $name: cannot extract the pinned diagnostic line from $expect_file (extend the lane)"
            fail=$((fail + 1)); continue
        fi
        lean_out=$(timeout "$TIMEOUT_SECS" env LEAN_ABORT_ON_PANIC=1 \
            "$CERBERUS_LEAN_BIN" --batch "$json" 2>&1)
        lean_rc=$?
        if [[ "$lean_rc" == "1" ]] && printf '%s\n' "$lean_out" \
            | grep -qE "^Error \{msg: \"(desugaring|typechecking) failed at [^\"]*/$(basename "$src"):$exp_line:"; then
            echo "[NEG_OK] $name: Lean-side desugar/typing rejection at the committed diagnostic line $exp_line (rc 1)"
            neg=$((neg + 1))
        else
            echo "[FAIL] $name: JSON emitted but the Lean pipeline did not reject as pinned (rc=$lean_rc, wanted rc 1 + Error at line $exp_line): $(printf '%s\n' "$lean_out" | head -1)"
            fail=$((fail + 1))
        fi
    else
        echo "[FAIL] $name: --cabs-json no longer emits JSON for this file (parse-only export regressed, or the file now fails at PARSE level — re-pin the boundary)"
        fail=$((fail + 1))
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
