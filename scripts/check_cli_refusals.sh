#!/usr/bin/env bash
# check_cli_refusals.sh — contract enforcement witness (CONTRACT.md §4.1,
# 2026-09-28): every CLI-refused area has a pinned refusal. Each flag below
# must make the Lean driver exit 2 with `cerberus-lean: refused — <flag>:`
# and its named feature (Main.lean refuseFlag). Control: the same argv
# without the flag must NOT be refused (so a driver that refuses everything,
# or exits 2 for another reason, cannot pass). Fail-closed.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$SCRIPT_DIR/../lean_frontend/.lake/build/bin/cerberus-lean}"
[[ -x "$BIN" ]] || { echo "check_cli_refusals: FAIL — driver not built: $BIN"; exit 1; }
INPUT=/nonexistent/cli-refusal-probe.json   # never read: flags are refused first
fails=0
expect_refused() {  # $1=flag $2=feature substring
    local out rc
    out=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch "$1" "$INPUT" 2>&1); rc=$?
    if [[ $rc -ne 2 || "$out" != *"cerberus-lean: refused — $1:"* || "$out" != *"$2"* ]]; then
        echo "check_cli_refusals: FAIL — $1: expected exit 2 + refusal naming '$2'; got rc=$rc: ${out:0:200}"
        fails=$((fails + 1))
    fi
}
expect_refused "--concurrency" "concurrency is not supported"
expect_refused "--switches=PNVI_ae_udi" "semantics switches"
expect_refused "--switches=strict_pointer_arith" "semantics switches"
# PNVI arc S1 (2026-10-05; design §D.3, §F.4, §F.13): `--switches` is PARSED in both of the
# oracle's cmdliner forms and EVERY value is refused, each element with its own reason (the
# switch set is a parameter of the semantics, but this binary runs only the default `[]`).
# The `=` form, one row per oracle switch name (switches.ml:60-102) with its reason's
# distinguishing phrase, plus the oracle's two fail-OPEN cases (an unknown name and an
# override are ignored there) and a mixed set:
expect_refused "--switches=PNVI_ae_udi" "\`PNVI_ae_udi\`: the PNVI-ae-udi provenance model"
expect_refused "--switches=PNVI" "\`PNVI\`: the PNVI-plain / PNVI-ae provenance variants"
expect_refused "--switches=PNVI_ae" "\`PNVI_ae\`: the PNVI-plain / PNVI-ae provenance variants"
expect_refused "--switches=permissive_pointer_arith" "the pointer-arithmetic mode switch"
expect_refused "--switches=strict_reads" "rm_unspecs Core pass"
expect_refused "--switches=forbid_nullptr_free" "its arm is a loud kill in CerbMem"
expect_refused "--switches=zap_dead_pointers" "its arm is a loud kill in CerbMem"
expect_refused "--switches=strict_pointer_equality" "its arm is a loud kill in CerbMem"
expect_refused "--switches=strict_pointer_relationals" "its arm is a loud kill in CerbMem"
expect_refused "--switches=zero_initialised" "its arm is a loud kill in CerbMem"
expect_refused "--switches=inner_arg_temps" "std_inner_arg_temps.core"
expect_refused "--switches=permissive_printf" "permissive printf"
expect_refused "--switches=CHERI" "cerberus-cheri executable"
expect_refused "--switches=copy_prop" "no counterpart in this port's lem model"
expect_refused "--switches=bogus" "unknown switch name"
expect_refused "--switches=PNVI_ae_udi,PNVI" "would override a previous switch"
expect_refused "--switches=PNVI_ae_udi,strict_reads" "\`strict_reads\`: strict reads"
expect_refused "--switches=" "an empty switch name"
# the space form (`--switches V`, two argv words): the refusal names the flag as given
out=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --switches PNVI_ae_udi "$INPUT" 2>&1); rc=$?
if [[ $rc -ne 2 || "$out" != *"cerberus-lean: refused — --switches PNVI_ae_udi:"* || "$out" != *"semantics switches"* ]]; then
    echo "check_cli_refusals: FAIL — --switches PNVI_ae_udi (space form): expected exit 2 + refusal; got rc=$rc: ${out:0:200}"
    fails=$((fails + 1))
fi
# --iso (switches.ml:144-151 sets five refused switches + PNVI_ae_udi; design §F.12): refused
expect_refused "--iso" "the ISO switch set"
# control: no refused flag → not a refusal. The runtime is given explicitly
# (the driver refuses without one since bug-hunt BUG-2, 2026-09-29), so the
# control reaches the input read and fails there, unrefused.
out=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$SCRIPT_DIR/../_build/install/default" "$INPUT" 2>&1); rc=$?
if [[ "$out" == *"cerberus-lean: refused"* ]]; then
    echo "check_cli_refusals: FAIL — control refused without a refused flag (rc=$rc): ${out:0:200}"
    fails=$((fails + 1))
fi
# repeated single-valued options the oracle's command line rejects (bug-hunt
# fixes pre-merge audit L3, 2026-09-30): exit 2 with the "cannot be repeated"
# message, never silently the last value
RT="$SCRIPT_DIR/../_build/install/default"
for pair in "--runtime=$RT --runtime=$RT" "--args a --args b" "--switches=PNVI_ae_udi --switches=PNVI_ae_udi" "--switches PNVI_ae_udi --switches=strict_reads"; do
    # shellcheck disable=SC2086
    out=$(env LEAN_ABORT_ON_PANIC=1 CERB_INSTALL_PREFIX="$RT" "$BIN" --batch $pair "$INPUT" 2>&1); rc=$?
    if [[ $rc -ne 2 || "$out" != *"cannot be repeated"* ]]; then
        echo "check_cli_refusals: FAIL — repeated option ($pair): expected exit 2 + 'cannot be repeated'; got rc=$rc: ${out:0:200}"
        fails=$((fails + 1))
    fi
done
[[ $fails -eq 0 ]] || exit 1
echo "check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)"
