#!/bin/bash
set -uo pipefail
cd "$(dirname "$0")/../.."
echo "start $(date -u +%FT%TZ) load $(cut -d' ' -f1-3 /proc/loadavg)"
( time make lean-prelude-src ) 2>&1 | grep -E "COPY|check_handwritten_sync|check_lem_sync|real|Error|error" 
tools/check_handwritten_sync.sh --quiet && echo "check_handwritten_sync: OK (quiet)"
cd lean_frontend
( time ../scripts/capped lake build cerberus-lean allocator-soundness-test ) > ../.tmp/audit/delta_build.lake.log 2>&1; echo "lake rc=$?"; echo "modules Built: $(grep -c '] Built ' ../.tmp/audit/delta_build.lake.log)"; grep -n "error" ../.tmp/audit/delta_build.lake.log | head -3
./.lake/build/bin/allocator-soundness-test | tail -1
../tools/check_driver_fresh.sh --record-lean 2>&1 | tail -1
echo "done $(date -u +%FT%TZ)"
