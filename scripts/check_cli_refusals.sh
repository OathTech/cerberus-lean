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
for pair in "--runtime=$RT --runtime=$RT" "--args a --args b"; do
    # shellcheck disable=SC2086
    out=$(env LEAN_ABORT_ON_PANIC=1 CERB_INSTALL_PREFIX="$RT" "$BIN" --batch $pair "$INPUT" 2>&1); rc=$?
    if [[ $rc -ne 2 || "$out" != *"cannot be repeated"* ]]; then
        echo "check_cli_refusals: FAIL — repeated option ($pair): expected exit 2 + 'cannot be repeated'; got rc=$rc: ${out:0:200}"
        fails=$((fails + 1))
    fi
done
[[ $fails -eq 0 ]] || exit 1
echo "check_cli_refusals: OK (3 refused flags pinned: --concurrency, --switches=PNVI_ae_udi, --switches=strict_pointer_arith; 2 repeated options refused: --runtime, --args; control not refused)"
