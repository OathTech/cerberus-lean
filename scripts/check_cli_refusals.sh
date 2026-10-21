#!/usr/bin/env bash
# check_cli_refusals.sh — contract enforcement witness (CONTRACT.md §4.1,
# 2026-09-28): every CLI-refused area has a pinned refusal. Each flag below
# must make the Lean driver exit 2 with structured REFUSAL records
# and their boundary, items and named feature (Main.lean refuseFlag). Control: the same argv
# without the flag must NOT be refused (so a driver that refuses everything,
# or exits 2 for another reason, cannot pass). Fail-closed.
#
# CLASS [AGENT, per [USER 2026-10-07] ruling that gates need not be adversarially robust
# unless they are trust surfaces]: a SPEEDBUMP — it pins the CLI's refusal metadata and details and the
# acceptance of `--switches=PNVI_ae_udi` (PNVI arc S4) so an accidental change is loud. The
# trust property behind the acceptance — agreement with the oracle under the switch — is
# the lane's (scripts/test_pnvi.sh, a trust surface); the one-program agreement witness
# below only shows the accepted switch reaches the semantics.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$SCRIPT_DIR/../lean_frontend/.lake/build/bin/cerberus-lean}"
[[ -x "$BIN" ]] || { echo "check_cli_refusals: FAIL — driver not built: $BIN"; exit 1; }
INPUT=/nonexistent/cli-refusal-probe.json   # never read: flags are refused first
mkdir -p "$SCRIPT_DIR/../.tmp"
W=$(mktemp -d "$SCRIPT_DIR/../.tmp/cli-refusals.XXXXXXXX") || exit 1
trap 'rm -rf "$W"' EXIT
capture() {
    env LEAN_ABORT_ON_PANIC=1 "$BIN" "$@" > "$W/stdout" 2> "$W/stderr"; rc=$?
    out=$(cat "$W/stdout" "$W/stderr")
}
check_refusal() {  # boundary, JSON item list (or null), required and forbidden detail
    python3 - "$SCRIPT_DIR" "$W/stdout" "$W/stderr" "$rc" "$@" <<'PY'
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from test_stops import assert_cli_refusals
assert_cli_refusals(Path(sys.argv[2]).read_bytes(), Path(sys.argv[3]).read_bytes(),
                    int(sys.argv[4]), sys.argv[5] or None, json.loads(sys.argv[6]),
                    sys.argv[7], sys.argv[8] if len(sys.argv) > 8 else '')
PY
}
check_flag_refusal() {  # flag, required detail
    local boundary=cli items
    case "$1" in
        --switches=*) boundary=switches
            items=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1].split("=",1)[1].split(",")))' "$1") ;;
        --iso) boundary=switches; items='["--iso"]' ;;
        --concurrency) boundary=concurrency; items='["--concurrency"]' ;;
        *) items=$(python3 -c 'import json,sys; print(json.dumps([sys.argv[1]]))' "$1") ;;
    esac
    check_refusal "$boundary" "$items" "$2"
}
fails=0
expect_refused() {  # $1=flag $2=feature substring
    local out rc
    capture --batch "$1" "$INPUT"
    if ! check_flag_refusal "$1" "$2"; then
        echo "check_cli_refusals: FAIL — $1: expected exit 2 + refusal naming '$2'; got rc=$rc: ${out:0:200}"
        fails=$((fails + 1))
    fi
}
expect_refused "--concurrency" "concurrency is not supported"
expect_refused "--switches=strict_pointer_arith" "semantics switch set is not supported"
# PNVI arc S1 (2026-10-05; design §D.3, §F.4, §F.13), S4 (2026-10-07): `--switches` is PARSED
# in both of the oracle's cmdliner forms; the accepted values are `PNVI_ae_udi` alone
# and `inner_arg_temps` alone
# (the acceptance witnesses below) — and every other value is refused, each element with its
# own reason. The `=` form, one row per oracle switch name (switches.ml:60-102) with its
# reason's distinguishing phrase, plus the oracle's two fail-OPEN cases (an unknown name and
# an override are ignored there, R-PNVI-12 / R-PNVI-11) and mixed sets:
expect_refused "--switches=PNVI" "\`PNVI\`: the PNVI-plain / PNVI-ae provenance variants"
expect_refused "--switches=PNVI_ae" "\`PNVI_ae\`: the PNVI-plain / PNVI-ae provenance variants"
expect_refused "--switches=permissive_pointer_arith" "the pointer-arithmetic mode switch"
expect_refused "--switches=strict_reads" "rm_unspecs Core pass"
expect_refused "--switches=forbid_nullptr_free" "its arm is a structured refusal in CerbMem"
expect_refused "--switches=zap_dead_pointers" "its arm is a structured refusal in CerbMem"
expect_refused "--switches=strict_pointer_equality" "its arm is a structured refusal in CerbMem"
expect_refused "--switches=strict_pointer_relationals" "its arm is a structured refusal in CerbMem"
expect_refused "--switches=zero_initialised" "its arm is a structured refusal in CerbMem"
expect_refused "--switches=inner_arg_temps,PNVI_ae_udi" "inner_arg_temps (switches.ml:84-85) is supported only as the WHOLE switch set"
expect_refused "--switches=PNVI_ae_udi,inner_arg_temps" "combinations, including PNVI_ae_udi, are not validated"
expect_refused "--switches=inner_arg_temps,inner_arg_temps" "would override a previous switch"
expect_refused "--switches=permissive_printf" "permissive printf"
expect_refused "--switches=CHERI" "cerberus-cheri executable"
expect_refused "--switches=copy_prop" "no counterpart in this port's lem model"
expect_refused "--switches=bogus" "unknown switch name"
expect_refused "--switches=PNVI_ae_udi,PNVI" "would override a previous switch"
expect_refused "--switches=PNVI_ae_udi,strict_reads" "\`strict_reads\`: strict reads"
expect_refused "--switches=PNVI_ae_udi,strict_reads" "\`PNVI_ae_udi\`: PNVI-ae-udi (switches.ml:82-83, SW_PNVI \`AE_UDI) is supported only as the WHOLE switch set"
expect_refused "--switches=PNVI_ae_udi,PNVI_ae_udi" "R-PNVI-11"
expect_refused "--switches=PNVI_ae_udi,bogus" "R-PNVI-12"
expect_refused "--switches=PNVI_ae_udi," "an empty switch name"
expect_refused "--switches=" "an empty switch name"
# the space form (`--switches V`, two argv words): the refusal names the flag as given
capture --batch --switches strict_reads "$INPUT"
if ! check_refusal switches '["strict_reads"]' "semantics switch set is not supported"; then
    echo "check_cli_refusals: FAIL — --switches strict_reads (space form): expected exit 2 + refusal; got rc=$rc: ${out:0:200}"
    fails=$((fails + 1))
fi
# ACCEPTANCE (PNVI arc S4): `--switches=PNVI_ae_udi` and `--switches PNVI_ae_udi` are NOT
# refused — with the runtime given, the driver gets past the CLI and fails at the input read,
# exactly like the control below
for form in "--switches=PNVI_ae_udi" "--switches PNVI_ae_udi" "--switches=inner_arg_temps" "--switches inner_arg_temps"; do
    # shellcheck disable=SC2086
    out=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$SCRIPT_DIR/../_build/install/default" $form "$INPUT" 2>&1); rc=$?
    if [[ "$out" == *"cerberus-lean stop"* || "$out" != *"cli-refusal-probe.json"* ]]; then
        echo "check_cli_refusals: FAIL — $form must be ACCEPTED (reach the input read); got rc=$rc: ${out:0:200}"
        fails=$((fails + 1))
    fi
done

out=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --switches=inner_arg_temps --call f "$INPUT" 2>&1); rc=$?
if [[ $rc -ne 2 || "$out" != *"cerberus-lean: refused — --call: inner_arg_temps"* || "$out" != *"Normal_callconv"* ]]; then
    echo "check_cli_refusals: FAIL — --call under inner_arg_temps must refuse before reading input; got rc=$rc: ${out:0:200}"
    fails=$((fails + 1))
fi

# --iso (switches.ml:144-151 sets five refused switches + PNVI_ae_udi; design §F.12): refused
expect_refused "--iso" "the ISO switch set"
# S1 review L5 (deferred to PNVI arc S4 Part 1): a `--switches` value is judged by the switch
# parser wherever it appears — under `--parse-core`, and before a misplaced mode flag — never
# the generic "unknown flag" / position text; and a repeated UNKNOWN name is "failed to parse"
# each time (switches.ml:140-141), never "would override" (only known names enter the list)
expect_switch_verdict() {  # $1=label $2=required substring $3=forbidden substring; argv after
    local label="$1" want="$2" forbid="$3" boundary="$4" items="$5" out rc; shift 5
    capture "$@"
    if ! check_refusal "$boundary" "$items" "$want" "$forbid"; then
        echo "check_cli_refusals: FAIL — $label: expected exit 2 with '$want'${forbid:+ and without '$forbid'}; got rc=$rc: ${out:0:200}"
        fails=$((fails + 1))
    fi
}
expect_switch_verdict "--parse-core --switches=bogus" "\`bogus\`: unknown switch name" "unknown flag" switches '["bogus"]' --parse-core --switches=bogus "$INPUT"
expect_switch_verdict "--parse-core --switches bogus" "\`bogus\`: unknown switch name" "unknown flag" switches '["bogus"]' --parse-core --switches bogus "$INPUT"
expect_switch_verdict "--switches=bogus before --batch" "\`bogus\`: unknown switch name" "canonical position" switches '["bogus"]' --switches=bogus --batch "$INPUT"
expect_switch_verdict "--switches=bogus,bogus" "\`bogus\`: unknown switch name" "would override" switches '["bogus","bogus"]' --batch --switches=bogus,bogus "$INPUT"
expect_switch_verdict "--parse-core --switches=PNVI_ae_udi" "reads no switch set" "unknown flag" switches '["PNVI_ae_udi"]' --parse-core --switches=PNVI_ae_udi "$INPUT"
expect_switch_verdict "--switches=PNVI_ae_udi before --batch" "canonical position" "semantics switch set" cli '["--batch"]' --switches=PNVI_ae_udi --batch "$INPUT"
# control: no refused flag → not a refusal. The runtime is given explicitly
# (the driver refuses without one since bug-hunt BUG-2, 2026-09-29), so the
# control reaches the input read and fails there, unrefused.
out=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$SCRIPT_DIR/../_build/install/default" "$INPUT" 2>&1); rc=$?
if [[ "$out" == *"cerberus-lean stop"* ]]; then
    echo "check_cli_refusals: FAIL — control refused without a refused flag (rc=$rc): ${out:0:200}"
    fails=$((fails + 1))
fi
# repeated single-valued options the oracle's command line rejects (bug-hunt
# fixes pre-merge audit L3, 2026-09-30): exit 2 with the "cannot be repeated"
# message, never silently the last value
RT="$SCRIPT_DIR/../_build/install/default"
for pair in "--runtime=$RT --runtime=$RT" "--args a --args b" "--switches=PNVI_ae_udi --switches=PNVI_ae_udi" "--switches PNVI_ae_udi --switches=strict_reads"; do
    # shellcheck disable=SC2086
    CERB_INSTALL_PREFIX="$RT" capture --batch $pair "$INPUT"
    if ! check_refusal "" null "cannot be repeated"; then
        echo "check_cli_refusals: FAIL — repeated option ($pair): expected exit 2 + 'cannot be repeated'; got rc=$rc: ${out:0:200}"
        fails=$((fails + 1))
    fi
done
# AGREEMENT WITNESS (PNVI arc S4): one small program on which the switch changes the answer
# (a pointer rebuilt from an exposed address bit by bit: PVI loses the provenance, UB043;
# PNVI-ae-udi finds the exposed allocation) — Lean under --switches=PNVI_ae_udi must equal the
# oracle under the same switch, and Lean without the switch must equal the oracle without it
# and DIFFER from the switched answer (so the witness cannot pass with the switch ignored).
ORACLE="$SCRIPT_DIR/../_build/default/backend/driver/main.exe"
RT="$SCRIPT_DIR/../_build/install/default"
if [[ ! -x "$ORACLE" ]]; then
    echo "check_cli_refusals: FAIL — oracle not built (agreement witness): $ORACLE"; fails=$((fails + 1))
else
    cat > "$W/w.c" <<'CEOF'
#include <stdint.h>
int x = 7;
int main(void) {
  uintptr_t i = (uintptr_t)&x, j = 0;
  for (int k = 0; k < 64; k++)
    if (i & ((uintptr_t)1 << k)) j |= (uintptr_t)1 << k;
  return *(int *)j;
}
CEOF
    if ! env NO_COLOR=1 TERM=dumb "$ORACLE" --runtime="$RT" --cabs-json "$W/w.c" > "$W/w.json" 2> "$W/w.json.err"; then
        echo "check_cli_refusals: FAIL — oracle --cabs-json failed: $(head -c 200 "$W/w.json.err")"; fails=$((fails + 1))
    else
        osw=$(env NO_COLOR=1 TERM=dumb "$ORACLE" --runtime="$RT" --nolibc --exec --batch --mode=exhaustive --switches=PNVI_ae_udi "$W/w.c" 2>/dev/null)
        odf=$(env NO_COLOR=1 TERM=dumb "$ORACLE" --runtime="$RT" --nolibc --exec --batch --mode=exhaustive "$W/w.c" 2>/dev/null)
        lsw=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$RT" --switches=PNVI_ae_udi "$W/w.json" 2>"$W/pnvi.stderr")
        ldf=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$RT" "$W/w.json" 2>"$W/default.stderr")
        if [[ -z "$osw" || "$lsw" != "$osw" || "$ldf" != "$odf" || "$lsw" == "$ldf" || "$osw" != Defined* ]]; then
            echo "check_cli_refusals: FAIL — PNVI_ae_udi agreement witness: oracle(sw)=${osw:0:120} lean(sw)=${lsw:0:120} oracle(default)=${odf:0:120} lean(default)=${ldf:0:120}"
            fails=$((fails + 1))
        fi
        if [[ "$(<"$W/pnvi.stderr")" != 'cerberus-lean switches: [PNVI_ae_udi]' || "$(<"$W/default.stderr")" != 'cerberus-lean switches: []' ]]; then
            echo "check_cli_refusals: FAIL — completed runs must report their switch set on stderr"
            fails=$((fails + 1))
        fi
    fi
    cat > "$W/inner.c" <<'CEOF'
int f(_Bool b) { return b; }
int main(void) { int x = 0; return f(&x); }
CEOF
    if ! env NO_COLOR=1 TERM=dumb "$ORACLE" --runtime="$RT" --cabs-json "$W/inner.c" > "$W/inner.json" 2> "$W/inner.bridge.stderr"; then
        echo "check_cli_refusals: FAIL — inner_arg_temps witness bridge failed"
        fails=$((fails + 1))
    else
        osw=$(env NO_COLOR=1 TERM=dumb "$ORACLE" --runtime="$RT" --nolibc --exec --batch --mode=exhaustive --switches=inner_arg_temps "$W/inner.c" 2> "$W/inner.oracle.stderr"); orc=$?
        lsw=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$RT" --switches=inner_arg_temps "$W/inner.json" 2> "$W/inner.stderr"); lrc=$?
        if [[ $orc -ne 0 || $lrc -ne 0 || "$osw" != "$lsw" || "$osw" != 'Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}' || "$(<"$W/inner.stderr")" != 'cerberus-lean switches: [inner_arg_temps]' ]]; then
            echo "check_cli_refusals: FAIL — inner_arg_temps agreement/report witness: oracle($orc)=$osw lean($lrc)=$lsw stderr=$(<"$W/inner.stderr")"
            fails=$((fails + 1))
        fi
    fi
fi
[[ $fails -eq 0 ]] || exit 1
echo "check_cli_refusals: OK (unsupported switch sets, mixtures, duplicates, unknown names, placement and repeated options refused; PNVI_ae_udi and inner_arg_temps accepted alone in both forms and agree with their matched-mode oracle witnesses; --call refused under inner_arg_temps; completed runs report the complete switch set on stderr without changing verdict stdout; default control not refused)"
