#!/bin/bash
# AUDITOR: the hand-written copy step (the Makefile recipe, the ONE authority) then the Lean rebuild — the one heavy job.
set -uo pipefail
cd "$(dirname "$0")/../.."
echo "start $(date -u +%FT%TZ) load $(cut -d' ' -f1-3 /proc/loadavg) head $(git rev-parse HEAD)"
echo "## make lean-prelude-src"
( time make lean-prelude-src ) 2>&1 | tail -12
echo "make rc=${PIPESTATUS[0]}"
tools/check_handwritten_sync.sh --quiet && echo "check_handwritten_sync: OK (quiet)" || echo "check_handwritten_sync: FAILED"
cmp lean_frontend/CerbMem.lean lean_frontend/generated/CerbMem.lean && echo "generated/CerbMem.lean == hand-written (post-fix)"
echo "## lake build cerberus-lean allocator-soundness-test (capped)"
cd lean_frontend
( time ../scripts/capped lake build cerberus-lean allocator-soundness-test ) > ../.tmp/audit/lean_build.lake.log 2>&1
echo "lake rc=$?"
grep -c "Building" ../.tmp/audit/lean_build.lake.log | sed 's/^/modules built: /'
grep -n "error" ../.tmp/audit/lean_build.lake.log | head -5
tail -4 ../.tmp/audit/lean_build.lake.log
ls -la .lake/build/bin/cerberus-lean .lake/build/bin/allocator-soundness-test .lake/build/lib/lean/CerbMemAllocatorProofs.olean 2>&1
echo "## runtime witness"
./.lake/build/bin/allocator-soundness-test; echo "exit=$?"
echo "## check_driver_fresh --record-lean (as common.sh build_lean does)"
../tools/check_driver_fresh.sh --record-lean 2>&1 | tail -2
echo "done $(date -u +%FT%TZ) load $(cut -d' ' -f1-3 /proc/loadavg)"
