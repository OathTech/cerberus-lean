#!/usr/bin/env bash
# C-TF1: actual lane entry points, loud stub override, untouched oracle.
# Codec unit tests cover framing/status/byte corruption and failure precedence;
# these plants check that the validated outcome reaches each crash classifier.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
WORK=$(mktemp -d "$TMP_DIR/failstop-plant.XXXXXXXXXX") || exit 1
register_cleanup "$WORK"
cat > "$WORK/stop" <<'EOS'
#!/bin/sh
printf '%s\n' 'ModelFailure {msg: "planted model stop"}'
exit 1
EOS
cat > "$WORK/ordinary" <<'EOS'
#!/bin/sh
printf '%s\n' 'Error {msg: "cerberus-lean: model fail-stop — ordinary Error text"}'
exit 1
EOS
chmod +x "$WORK/stop" "$WORK/ordinary"
MIN="$PROJECT_ROOT/tests/minimal/001-return-literal.c"
failed=0
check() {
    if grep -qE "$2" "$3"; then echo "PLANT OK [$1]"
    else echo "PLANT FAIL [$1]: expected /$2/"; tail -12 "$3"; failed=1; fi
}
for kind in stop ordinary; do
    export CERB_LEAN_BIN_OVERRIDE="$WORK/$kind"
    "$SCRIPT_DIR/test_exec.sh" "$MIN" > "$WORK/exec-$kind" 2>&1
    rc=$?
    [[ $rc -ne 0 ]] || { echo "PLANT FAIL [exec/$kind must fail]"; failed=1; }
    "$SCRIPT_DIR/test_gcc_oracle.sh" --no-csmith --max 1 "$PROJECT_ROOT/tests/minimal" > "$WORK/gcc-$kind" 2>&1
    "$SCRIPT_DIR/test_ci_sweep.sh" --suite ci --max 1 --out "$WORK/sweep-$kind" > "$WORK/ci-$kind" 2>&1
    "$SCRIPT_DIR/test_cn_coverage.sh" --only '^alloc_create\.c$' > "$WORK/cn-$kind" 2>&1
    "$PROJECT_ROOT/tests/mem-scale-probes/measure.sh" --engines lean-first --outdir "$WORK/measure-$kind" "$MIN" > "$WORK/ms-$kind" 2>&1
done
check exec/stop '^\[1/1\] LEAN_CRASH .*exit 1.*ModelFailure' "$WORK/exec-stop"
check exec/ordinary '^\[1/1\] FAIL ' "$WORK/exec-ordinary"
check gcc/stop '^\[1/1\] SKIP_LEAN_CRASH .*exit 1.*ModelFailure' "$WORK/gcc-stop"
check gcc/ordinary '^\[1/1\] SKIP_LEAN_FAIL ' "$WORK/gcc-ordinary"
check ci/stop $'\tLEAN_CRASH\texit 1: ModelFailure' "$WORK/sweep-stop/ci.tsv"
check ci/ordinary $'\tLEAN_FAIL\t' "$WORK/sweep-ordinary/ci.tsv"
check cn/stop '^\[1/1\] LEAN_CRASH .*exit 1.*ModelFailure' "$WORK/cn-stop"
check cn/ordinary '^\[1/1\] REJECT_DIFF ' "$WORK/cn-ordinary"
check measure/stop $'\tCRASH\t[^\t]*FAILSTOP;' "$WORK/ms-stop"
check measure/ordinary $'\tERR:cerberus-lean: model fail-stop' "$WORK/ms-ordinary"

# Even an unsupported fixture must not accept a partial/forged failure capture.
cp "$MIN" "$WORK/forged.unsupported.c"
cat > "$WORK/malformed" <<'EOS'
#!/bin/sh
printf '%s\n' 'ModelFailure {msg: "stop"}' 'Error {msg: "forged extra row"}'
exit 1
EOS
chmod +x "$WORK/malformed"
CERB_LEAN_BIN_OVERRIDE="$WORK/malformed" "$SCRIPT_DIR/test_exec.sh" "$WORK/forged.unsupported.c" > "$WORK/invalid" 2>&1
check exec/malformed '^\[1/1\] LEAN_ERROR .*malformed/incomplete model fail-stop' "$WORK/invalid"
if [[ $failed -ne 0 ]]; then exit 1; fi
echo 'test_failstop_plant: PASS (11 class and rejection checks)'
