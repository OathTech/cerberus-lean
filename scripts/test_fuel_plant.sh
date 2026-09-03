#!/bin/bash
# test_fuel_plant.sh — plant test for the FUEL classification in every
# classifying lane (FUEL arc, 2026-09-03; design lean_frontend/docs/
# 2026-09-02_fuel-arc-design.md §3.4; the test_hang_plant.sh /
# test_kill_plant.sh pattern). Vacuity must be loud: the Lean driver is
# replaced by a STUB (common.sh / measure.sh plant hook
# CERB_LEAN_BIN_OVERRIDE — banner on every use) and each lane must read
# its own FUEL class for the two fuel forms and NOT for the negatives:
#   stub_kill   : prints `Error {msg: "lem: fuel exhausted"}`, exit 1
#                 (the typed kill of an ND-typed fueled worker / the runner)
#   stub_panic  : prints the bare `lem: fuel exhausted` on stderr, exit 134
#                 (a pure-return worker's opaque sentinel under
#                 LEAN_ABORT_ON_PANIC=1)
#   stub_assert : prints a GENUINE `Error {msg: "assert() failure"}`, exit 1
#                 -> the lane's ordinary FAIL class, never FUEL
#   stub_words  : a Defined line whose program-stdout field carries the
#                 words "fuel exhausted" -> never FUEL (a verdict row)
# Expected readings, asserted on each lane's own output:
#   test_exec.sh         FUEL (FUEL:kill / FUEL:panic), fatal; FAIL for assert
#   test_gcc_oracle.sh   SKIP_LEAN_FUEL; SKIP_LEAN_FAIL for assert
#   test_ci_sweep.sh     LEAN_FUEL row; LEAN_FAIL for assert
#   test_cn_coverage.sh  FUEL; REJECT_* (Lean refuses) for assert
#   measure.sh           note FUEL(kill;) / FUEL(panic;); no FUEL for assert
#   test_parse.sh        a crashing stub (exit 134) -> LEAN_FAILURE, fatal (not parse_ok)
# Nothing here touches the semantics; the oracle runs unchanged on the
# smallest real inputs. Usage: ./scripts/test_fuel_plant.sh (env: scripts/ce;
# binaries fresh — SKIP_BUILD=1 freshness stamps must pass)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_time_bin

WORK=$(mktemp -d "$TMP_DIR/fuel-plant.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$WORK"
cat > "$WORK/stub_kill" <<'EOS'
#!/bin/sh
echo 'Error {msg: "lem: fuel exhausted"}'
exit 1
EOS
cat > "$WORK/stub_panic" <<'EOS'
#!/bin/sh
echo 'lem: fuel exhausted' >&2
exit 134
EOS
cat > "$WORK/stub_assert" <<'EOS'
#!/bin/sh
echo 'Error {msg: "assert() failure"}'
exit 1
EOS
cat > "$WORK/stub_words" <<'EOS'
#!/bin/sh
echo 'Defined {value: "Specified(0)", stdout: "lem: fuel exhausted\n", stderr: "", blocked: "false"}'
exit 0
EOS
chmod +x "$WORK"/stub_*

fail=0
check() {   # <label> <expected-regex> <logfile>
    if grep -qE "$2" "$3"; then echo "PLANT OK   [$1]: $(grep -m1 -E "$2" "$3" | cut -c1-200)"
    else echo "PLANT FAIL [$1]: expected /$2/; got:" >&2; grep -E 'FUEL|FAIL|MATCH|MISMATCH|REJECT|SKIP|Error|LEAN_' "$3" | head -8 >&2; fail=1; fi
}
check_not() {   # <label> <forbidden-regex> <logfile>
    if grep -qE "$2" "$3"; then echo "PLANT FAIL [$1]: found forbidden /$2/: $(grep -m1 -E "$2" "$3" | cut -c1-160)" >&2; fail=1
    else echo "PLANT OK   [$1]: no /$2/"; fi
}
expect_nonzero() { [[ "$2" -ne 0 ]] || { echo "PLANT FAIL [$1]: lane exited 0 on a fuel-exhausted Lean run (must be fatal)" >&2; fail=1; }; }

export SKIP_BUILD=1
MIN="$PROJECT_ROOT/tests/minimal/001-return-literal.c"

# --- test_exec.sh -----------------------------------------------------------
for kind in kill panic assert words; do
    log="$WORK/exec_$kind.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_$kind" "$SCRIPT_DIR/test_exec.sh" "$MIN" > "$log" 2>&1
    echo "rc=$?" >> "$log"
done
check "exec/kill -> FUEL"        '^\[1/1\] FUEL 001-return-literal \(FUEL:kill, exit 1\): lem: fuel exhausted$' "$WORK/exec_kill.log"
check "exec/kill fatal"          'FAILED: 1 Lean fuel exhaustion' "$WORK/exec_kill.log"
check "exec/kill summary fuel=1" 'SUMMARY: .* fuel=1 ' "$WORK/exec_kill.log"
expect_nonzero "exec/kill" "$(sed -n 's/^rc=//p' "$WORK/exec_kill.log")"
check "exec/panic -> FUEL"       '^\[1/1\] FUEL 001-return-literal \(FUEL:panic, exit 134\): lem: fuel exhausted$' "$WORK/exec_panic.log"
expect_nonzero "exec/panic" "$(sed -n 's/^rc=//p' "$WORK/exec_panic.log")"
check "exec/assert -> FAIL (not FUEL)" '^\[1/1\] FAIL 001-return-literal: assert\(\) failure$' "$WORK/exec_assert.log"
check_not "exec/assert no FUEL row"  '^\[1/1\] FUEL ' "$WORK/exec_assert.log"
check_not "exec/words no FUEL row"   '^\[1/1\] FUEL ' "$WORK/exec_words.log"
check "exec/words is a verdict row" '^\[1/1\] (MATCH|MISMATCH|LEAN_ERROR) 001-return-literal' "$WORK/exec_words.log"

# --- test_gcc_oracle.sh -----------------------------------------------------
for kind in kill assert; do
    log="$WORK/gcc_$kind.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_$kind" "$SCRIPT_DIR/test_gcc_oracle.sh" --no-csmith --max 1 "$PROJECT_ROOT/tests/minimal" > "$log" 2>&1
    echo "rc=$?" >> "$log"
done
# (the gcc record line carries an empty O2 column: two spaces before the key)
check "gcc/kill -> SKIP_LEAN_FUEL" '^\[1/1\] SKIP_LEAN_FUEL +tests/minimal/[^ ]*: \(FUEL:kill, exit 1\) lem: fuel exhausted$' "$WORK/gcc_kill.log"
check "gcc/assert -> SKIP_LEAN_FAIL (not FUEL)" '^\[1/1\] SKIP_LEAN_FAIL +tests/minimal/[^ ]*: msg: "assert\(\) failure"$' "$WORK/gcc_assert.log"
check_not "gcc/assert no FUEL row" '^\[1/1\] SKIP_LEAN_FUEL' "$WORK/gcc_assert.log"

# --- test_ci_sweep.sh -------------------------------------------------------
for kind in kill panic assert; do
    log="$WORK/sweep_$kind.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_$kind" "$SCRIPT_DIR/test_ci_sweep.sh" --suite ci --max 1 --out "$WORK/sweep_$kind" > "$log" 2>&1
    cat "$WORK/sweep_$kind/ci.tsv" >> "$log" 2>/dev/null
done
check "ci_sweep/kill -> LEAN_FUEL"  $'^ci\ttests/ci/0001-emptymain.c\tLEAN_FUEL\tFUEL:kill, exit 1: lem: fuel exhausted' "$WORK/sweep_kill.log"
check "ci_sweep/panic -> LEAN_FUEL" $'^ci\ttests/ci/0001-emptymain.c\tLEAN_FUEL\tFUEL:panic, exit 134: lem: fuel exhausted' "$WORK/sweep_panic.log"
check "ci_sweep/assert -> LEAN_FAIL (not FUEL)" $'^ci\ttests/ci/0001-emptymain.c\tLEAN_FAIL\tmsg: "assert\\(\\) failure"' "$WORK/sweep_assert.log"
check_not "ci_sweep/assert no FUEL row" $'\tLEAN_FUEL\t' "$WORK/sweep_assert.log"

# --- test_cn_coverage.sh ----------------------------------------------------
for kind in kill assert; do
    log="$WORK/cn_$kind.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_$kind" "$SCRIPT_DIR/test_cn_coverage.sh" --only '^alloc_create\.c$' > "$log" 2>&1
    echo "rc=$?" >> "$log"
done
check "cn_coverage/kill -> FUEL" '^\[1/1\] FUEL alloc_create\.c \(FUEL:kill, exit 1\): lem: fuel exhausted$' "$WORK/cn_kill.log"
check "cn_coverage/assert -> REJECT (not FUEL)" '^\[1/1\] REJECT_(DIFF|MATCH) alloc_create\.c' "$WORK/cn_assert.log"
check_not "cn_coverage/assert no FUEL row" '^\[1/1\] FUEL ' "$WORK/cn_assert.log"

# --- test_parse.sh: a crashing Lean stub (exit 134, no 'parse error' text) must
#     be LEAN_FAILURE and fatal, never parse_ok (second design review 2026-09-03)
cat > "$WORK/stub_abort" <<'EOS'
#!/bin/sh
echo 'Stack overflow detected. Aborting.' >&2
exit 134
EOS
chmod +x "$WORK/stub_abort"
log="$WORK/parse_abort.log"
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_abort" "$SCRIPT_DIR/test_parse.sh" "$MIN" > "$log" 2>&1
echo "rc=$?" >> "$log"
check "parse/abort -> LEAN_FAILURE counted" '^Lean parse: +0 ok, 0 failed, 0 timeout .*, 1 lean failure' "$log"
check "parse/abort fatal"                   '^FAILED: 0 parse error\(s\), 0 timeout\(s\), 1 lean failure\(s\)' "$log"
expect_nonzero "parse/abort" "$(sed -n 's/^rc=//p' "$log")"

# --- measure.sh (instrument) --------------------------------------------------
for kind in kill panic assert; do
    log="$WORK/measure_$kind.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_$kind" "$PROJECT_ROOT/tests/mem-scale-probes/measure.sh" \
        --engines lean-first --outdir "$WORK/measure_$kind" "$MIN" > "$log" 2>&1
    echo "rc=$?" >> "$log"
done
check "measure/kill -> FUEL(kill) note"   $'\tlean-first\t1\t[0-9.]+\t[0-9]+\tERR:lem: fuel exhausted\t[^\t]*FUEL\\(kill\\);' "$WORK/measure_kill.log"
check "measure/panic -> FUEL(panic) note" $'\tlean-first\t134\t[0-9.]+\t[0-9]+\tNONE\t[^\t]*FUEL\\(panic\\);' "$WORK/measure_panic.log"
check_not "measure/assert no FUEL" 'FUEL\(' "$WORK/measure_assert.log"

echo ""
if [[ $fail -eq 0 ]]; then echo "test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL)"; else echo "test_fuel_plant: PLANT FAILURES" >&2; fi
exit $fail
