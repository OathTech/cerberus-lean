#!/bin/bash
# AUDITOR negative control (b), re-taken with a saved output: the runtime witness's four cases + expectations on the
# compiled PRE-FIX CerbMem.allocator. Only the git-IGNORED build copy lean_frontend/generated/CerbMem.lean is swapped
# (to 6d9ba82f1's content) and restored byte-identically; no tracked file is touched.
set -uo pipefail
cd "$(dirname "$0")/../.."
E=lean_frontend/docs/2026-09-17_allocator-part-one-audit-evidence
echo "start $(date -u +%FT%TZ)"
git show 6d9ba82f1:lean_frontend/CerbMem.lean > lean_frontend/generated/CerbMem.lean
cmp <(git show 6d9ba82f1:lean_frontend/CerbMem.lean) lean_frontend/generated/CerbMem.lean && echo "generated/CerbMem.lean := 6d9ba82f1 (pre-fix) copy"
cd lean_frontend
echo "## probe on the pre-fix body (lake setup-file rebuilds CerbMem.olean from the swapped copy)"
../scripts/lean_probe.sh .tmp/AuditOldBodyProbe.lean 2>&1 | grep -v "^cerberus-lean-proj env\|warning\|^$\|Note:\|The binding\|instead of\|^  " | tee ../$E/negctrl_b_witness_on_old_body.out.txt
echo "## theorem module on the pre-fix body (again, saved): lake build CerbMemAllocatorProofs"
../scripts/capped lake build CerbMemAllocatorProofs > ../.tmp/audit/negctrl_a_lake_2.log 2>&1; echo "lake rc=$? (1 expected: unsolved goals)"; grep -c "unsolved goals" ../.tmp/audit/negctrl_a_lake_2.log | sed 's/^/unsolved-goals errors: /'
echo "## restore the copy byte-identically and rebuild"
cp CerbMem.lean generated/CerbMem.lean && cmp CerbMem.lean generated/CerbMem.lean && echo "generated/CerbMem.lean == hand-written (post-fix) again"
../tools/check_handwritten_sync.sh --quiet && echo "check_handwritten_sync: OK (quiet)"
( time ../scripts/capped lake build cerberus-lean allocator-soundness-test ) > ../.tmp/audit/restore_build.log 2>&1; echo "restore lake rc=$?"; grep -c "] Built " ../.tmp/audit/restore_build.log | sed 's/^/modules rebuilt: /'
./.lake/build/bin/allocator-soundness-test | tail -1
../tools/check_driver_fresh.sh --record-lean 2>&1 | tail -1
../tools/check_driver_fresh.sh --check 2>&1 | tail -2
sha256sum .lake/build/bin/cerberus-lean | cut -c1-16
echo "done $(date -u +%FT%TZ)"
