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
is_elab_fuel_panic() { [[ "$1" -eq 134 ]] && grep -qE "$FUEL_ELAB_PANIC_LINE_RE" "$2"; }

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
check "ci_sweep/kill summary counts fuel" '^SWEEP SUMMARY .* total=1 .* lean_fuel=1 ' "$WORK/sweep_kill.log"
check "ci_sweep/panic summary counts fuel" '^SWEEP SUMMARY .* total=1 .* lean_fuel=1 ' "$WORK/sweep_panic.log"
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

# --- the REAL driver at translation and execution fuel boundaries -----------
#     The fuel is the caller's parameter (`--fuel N`, default Main.lean
#     `defaultFuel`). Wrappers run the REAL binary with `--fuel N`
#     prepended (through the same CERB_LEAN_BIN_OVERRIDE hook — banner on
#     every use; the freshness check is skipped for stubs, so the real
#     binary is asserted fresh first). Fixture 001 at fuel 1 witnesses the
#     direct TRANSLATION refusal (FUEL:panic, exit 134). Its raw stderr must
#     carry the failwithIImpl envelope; the lane's fixed suffix is insufficient.
#     The loop
#     below translates at fuel 8 but exhausts EXECUTION at fuel 128
#     (FUEL:kill, exit 1); both programs must MATCH at the default fuel.
#     Measurements: lean_frontend/docs/2026-10-18_translation-fuel-record.md.
#     Also the refusals: fuel 0 and a non-numeral exit 2 with the attributed
#     message; `--fuel` before the mode flag is refused as an unknown flag
#     (the positional contract, Z-24).
if [[ -z "${CERB_LEAN_BIN_OVERRIDE:-}" ]]; then
    "$PROJECT_ROOT/tools/check_driver_fresh.sh" --check-lean || { echo "PLANT FAIL [tiny-fuel]: the real Lean driver is not fresh" >&2; fail=1; }
    REAL_LEAN="$CERBERUS_LEAN_BIN"
    for fuel in 1 128; do
        cat > "$WORK/stub_fuel$fuel" <<EOS
#!/bin/sh
# real driver, --fuel $fuel spliced after the mode flag
mode="\$1"; shift
exec "$REAL_LEAN" "\$mode" --fuel $fuel "\$@"
EOS
        chmod +x "$WORK/stub_fuel$fuel"
    done
    log="$WORK/exec_fuel1.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_fuel1" "$SCRIPT_DIR/test_exec.sh" "$MIN" > "$log" 2>&1; echo "rc=$?" >> "$log"
    check "exec/real driver at --fuel 1 -> translation FUEL:panic" '^\[1/1\] FUEL 001-return-literal \(FUEL:panic, exit 134\): lem: fuel exhausted$' "$log"
    expect_nonzero "exec/real driver at --fuel 1" "$(sed -n 's/^rc=//p' "$log")"
    log="$WORK/exec_default.log"
    "$SCRIPT_DIR/test_exec.sh" "$MIN" > "$log" 2>&1; echo "rc=$?" >> "$log"
    check "exec/real driver at the default fuel -> MATCH" '^\[1/1\] MATCH 001-return-literal' "$log"
    cat > "$WORK/execution-loop.c" <<'EOS'
int main(void) { int i = 0; while (i < 100) { i = i + 1; } return 0; }
EOS
    log="$WORK/exec_loop_fuel128.log"
    CERB_LEAN_BIN_OVERRIDE="$WORK/stub_fuel128" "$SCRIPT_DIR/test_exec.sh" "$WORK/execution-loop.c" > "$log" 2>&1; echo "rc=$?" >> "$log"
    check "exec/real loop at --fuel 128 -> execution FUEL:kill" '^\[1/1\] FUEL execution-loop \(FUEL:kill, exit 1\): lem: fuel exhausted$' "$log"
    expect_nonzero "exec/real loop at --fuel 128" "$(sed -n 's/^rc=//p' "$log")"
    log="$WORK/exec_loop_default.log"
    "$SCRIPT_DIR/test_exec.sh" "$WORK/execution-loop.c" > "$log" 2>&1; echo "rc=$?" >> "$log"
    check "exec/real loop at the default fuel -> MATCH" '^\[1/1\] MATCH execution-loop' "$log"
    # the refusals, on the real binary directly (LEAN_ABORT_ON_PANIC set as every harness does)
    json="$WORK/min.json"
    "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" --cabs-json "$MIN" > "$json" 2>/dev/null || { echo "PLANT FAIL [tiny-fuel]: cabs-json of $MIN failed" >&2; fail=1; }
    log="$WORK/direct_fuel1"
    LEAN_ABORT_ON_PANIC=1 "${CAPPED_TEST[@]}" timeout 30 "$REAL_LEAN" \
        --batch --fuel 1 --runtime="$CERB_INSTALL_PREFIX" "$json" > "$log.out" 2> "$log.err"; rc=$?
    if is_elab_fuel_panic "$rc" "$log.err"; then
        echo "PLANT OK   [real --fuel 1 stderr: failwithIImpl envelope, exit 134]"
        grep -E "$FUEL_ELAB_PANIC_LINE_RE" "$log.err"
    else
        echo "PLANT FAIL [real --fuel 1 stderr]: exit=$rc, expected failwithIImpl envelope" >&2
        cat "$log.out" "$log.err" >&2; fail=1
    fi
    # The bare sentinel has the same lane class and suffix but must fail the
    # very same raw-stderr predicate used for the real driver above.
    "$WORK/stub_panic" > "$WORK/bare_panic.out" 2> "$WORK/bare_panic.err"; rc=$?
    if [[ "$rc" -eq 134 ]] \
        && [[ "$(classify_fuel_outcome "$rc" "$(cat "$WORK/bare_panic.err")")" == FUEL:panic ]] \
        && ! is_elab_fuel_panic "$rc" "$WORK/bare_panic.err"; then
        echo "PLANT OK   [negative: bare FUEL:panic exit 134 rejected by envelope predicate]"
    else
        echo "PLANT FAIL [negative: bare panic must not satisfy envelope predicate]" >&2; fail=1
    fi
check_refusal() {  # boundary, JSON item list (or null), required and forbidden detail
    python3 - "$SCRIPT_DIR" "$WORK/cli.stdout" "$WORK/cli.stderr" "$rc" "$@" <<'PY'
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from test_stops import assert_cli_refusals
assert_cli_refusals(Path(sys.argv[2]).read_bytes(), Path(sys.argv[3]).read_bytes(),
                    int(sys.argv[4]), sys.argv[5] or None, json.loads(sys.argv[6]),
                    sys.argv[7], sys.argv[8] if len(sys.argv) > 8 else '')
PY
}
    for bad in 0 abc; do
        LEAN_ABORT_ON_PANIC=1 "$REAL_LEAN" --batch --fuel "$bad" "$json" > "$WORK/cli.stdout" 2> "$WORK/cli.stderr"; rc=$?
        out=$(cat "$WORK/cli.stdout" "$WORK/cli.stderr")
        if check_refusal fuel-arg "[\"$bad\"]" "--fuel $bad:"; then echo "PLANT OK   [--fuel $bad refused, exit 2]: $(head -c 120 <<<"$out")"
        else echo "PLANT FAIL [--fuel $bad]: rc=$rc out=$(head -c 200 <<<"$out")" >&2; fail=1; fi
    done
    LEAN_ABORT_ON_PANIC=1 "$REAL_LEAN" --fuel 5 --batch "$json" > "$WORK/cli.stdout" 2> "$WORK/cli.stderr"; rc=$?
    out=$(cat "$WORK/cli.stdout" "$WORK/cli.stderr")
    if check_refusal cli '["--batch"]' "known flag out of its canonical position"; then echo "PLANT OK   [--fuel before the mode flag refused (positional contract)]"
    else echo "PLANT FAIL [--fuel out of position]: rc=$rc out=$(head -c 200 <<<"$out")" >&2; fail=1; fi
    out=$(LEAN_ABORT_ON_PANIC=1 "$REAL_LEAN" --batch "$json" --fuel 2>&1); rc=$?
    if [[ $rc -eq 1 ]] && grep -q "require an argument" <<<"$out"; then echo "PLANT OK   [--fuel without an argument refused]"
    else echo "PLANT FAIL [--fuel without argument]: rc=$rc out=$(head -c 200 <<<"$out")" >&2; fail=1; fi
else
    echo "PLANT SKIP [tiny-fuel]: CERB_LEAN_BIN_OVERRIDE is set by the caller; the real-driver plant needs the real binary" >&2; fail=1
fi

echo ""
if [[ $fail -eq 0 ]]; then echo "test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; real translation at --fuel 1 reads FUEL:panic, real execution at --fuel 128 reads FUEL:kill, both at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)"; else echo "test_fuel_plant: PLANT FAILURES" >&2; fi
exit $fail
