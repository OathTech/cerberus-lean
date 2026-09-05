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
# printf '%s', not echo: dash's echo turns the escaped "\n" inside the
# stdout field into a real newline, splitting the Defined line in two —
# the whole-line extractor (P0 F3, 2026-09-05) correctly refuses a
# truncated Defined line (HARNESS ERROR), so the stub must emit the
# line exactly as the driver does: one line, escapes kept literal.
printf '%s\n' 'Defined {value: "Specified(0)", stdout: "lem: fuel exhausted\n", stderr: "", blocked: "false"}'
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

# --- the REAL driver at a tiny fuel (fuel-parameter arc, 2026-09-04) -----------
#     The fuel is the caller's parameter (`--fuel N`, default Main.lean
#     `defaultFuel`). A stub that runs the REAL binary with `--fuel 1`
#     prepended (through the same CERB_LEAN_BIN_OVERRIDE hook — banner on
#     every use; the freshness check is skipped for stubs, so the real
#     binary is asserted fresh first) must make the lane read FUEL:kill —
#     the errno allocation's liftMem exhausts at fuel 1, before any
#     verdict — and the same program at the default must read MATCH. Also
#     the refusals: fuel 0 and a non-numeral exit 2 with the attributed
#     message; `--fuel` before the mode flag is refused as an unknown flag
#     (the positional contract, Z-24).
if [[ -z "${CERB_LEAN_BIN_OVERRIDE:-}" ]]; then
    "$PROJECT_ROOT/tools/check_driver_fresh.sh" --check-lean || { echo "PLANT FAIL [tiny-fuel]: the real Lean driver is not fresh" >&2; fail=1; }
    REAL_LEAN="$CERBERUS_LEAN_BIN"
    cat > "$WORK/stub_fuel1" <<EOS
#!/bin/sh
# real driver, --fuel 1 spliced after the mode flag
mode="\$1"; shift
exec "$REAL_LEAN" "\$mode" --fuel 1 "\$@"
EOS
    chmod +x "$WORK/stub_fuel1"
    log="$WORK/exec_fuel1.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_fuel1" "$SCRIPT_DIR/test_exec.sh" "$MIN" > "$log" 2>&1; echo "rc=$?" >> "$log"
    # (measured at C1: at fuel 1 the FRONT END's pure fuel'd workers exhaust first — the opaque
    #  sentinel, FUEL:panic exit 134 — before any ND kill; both sub-kinds are the lane's FUEL class)
    check "exec/real driver at --fuel 1 -> FUEL" '^\[1/1\] FUEL 001-return-literal \(FUEL:(kill|panic), exit (1|134)\): lem: fuel exhausted$' "$log"
    expect_nonzero "exec/real driver at --fuel 1" "$(sed -n 's/^rc=//p' "$log")"
    log="$WORK/exec_default.log"
    "$SCRIPT_DIR/test_exec.sh" "$MIN" > "$log" 2>&1; echo "rc=$?" >> "$log"
    check "exec/real driver at the default fuel -> MATCH" '^\[1/1\] MATCH 001-return-literal' "$log"
    # the refusals, on the real binary directly (LEAN_ABORT_ON_PANIC set as every harness does)
    json="$WORK/min.json"
    "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" --cabs-json "$MIN" > "$json" 2>/dev/null || { echo "PLANT FAIL [tiny-fuel]: cabs-json of $MIN failed" >&2; fail=1; }
    for bad in 0 abc; do
        out=$(LEAN_ABORT_ON_PANIC=1 "$REAL_LEAN" --batch --fuel "$bad" "$json" 2>&1); rc=$?
        if [[ $rc -eq 2 ]] && grep -q "cerberus-lean: refused — --fuel $bad:" <<<"$out"; then echo "PLANT OK   [--fuel $bad refused, exit 2]: $(head -c 120 <<<"$out")"
        else echo "PLANT FAIL [--fuel $bad]: rc=$rc out=$(head -c 200 <<<"$out")" >&2; fail=1; fi
    done
    out=$(LEAN_ABORT_ON_PANIC=1 "$REAL_LEAN" --fuel 5 --batch "$json" 2>&1); rc=$?
    if [[ $rc -eq 2 ]] && grep -q "refused — --batch: known flag out of its canonical position" <<<"$out"; then echo "PLANT OK   [--fuel before the mode flag refused (positional contract)]"
    else echo "PLANT FAIL [--fuel out of position]: rc=$rc out=$(head -c 200 <<<"$out")" >&2; fail=1; fi
    out=$(LEAN_ABORT_ON_PANIC=1 "$REAL_LEAN" --batch "$json" --fuel 2>&1); rc=$?
    if [[ $rc -eq 1 ]] && grep -q "require an argument" <<<"$out"; then echo "PLANT OK   [--fuel without an argument refused]"
    else echo "PLANT FAIL [--fuel without argument]: rc=$rc out=$(head -c 200 <<<"$out")" >&2; fail=1; fi
else
    echo "PLANT SKIP [tiny-fuel]: CERB_LEAN_BIN_OVERRIDE is set by the caller; the real-driver plant needs the real binary" >&2; fail=1
fi

echo ""
if [[ $fail -eq 0 ]]; then echo "test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)"; else echo "test_fuel_plant: PLANT FAILURES" >&2; fi
exit $fail
