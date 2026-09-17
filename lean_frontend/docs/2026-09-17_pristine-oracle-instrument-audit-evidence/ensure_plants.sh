#!/usr/bin/env bash
# Auditor's plants for scripts/ensure_independent_oracle.py (nothing in the standing build is touched).
set -u
W=/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument
CE=/home/dev/projects/cerberus-lean-proj/scripts/ce
P=$W/.tmp/audit/plants/ensure; rm -rf "$P"; mkdir -p "$P"
cd "$W"
ens(){ "$CE" python3 scripts/ensure_independent_oracle.py "$@"; echo "rc=$?"; }
echo "## E0 static: delete/overwrite primitives in the script"
/usr/bin/grep -nE "rmtree|unlink|remove\(|rename|replace\(|write_text|write_bytes|open\(" scripts/ensure_independent_oracle.py || echo "(none)"
echo "## E1 existing-but-EMPTY directory"; mkdir -p "$P/empty"; ens --out "$P/empty"; ls -la "$P/empty" | tail -1
echo "## E2 garbage manifest"; mkdir -p "$P/garbage"; printf 'not json\n' > "$P/garbage/manifest.json"; b=$(sha256sum "$P/garbage/manifest.json"); ens --out "$P/garbage"; a=$(sha256sum "$P/garbage/manifest.json"); [[ "$a" == "$b" ]] && echo "file intact" || echo "FILE CHANGED"
echo "## E3 corrupted COPY of the real manifest (status flipped)"; mkdir -p "$P/copy-status"; python3 - "$P/copy-status/manifest.json" <<'PY'
import json,sys; m=json.load(open('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument/.validation-foundations/independent-oracle-v2/manifest.json')); m['status']='incomplete'; json.dump(m,open(sys.argv[1],'w'))
PY
ens --out "$P/copy-status"; ls "$P/copy-status"
echo "## E4 corrupted COPY (pin doctored)"; mkdir -p "$P/copy-pin"; python3 - "$P/copy-pin/manifest.json" <<'PY'
import json,sys; m=json.load(open('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument/.validation-foundations/independent-oracle-v2/manifest.json')); m['sources']['cerberus']['commit']='0'*40; json.dump(m,open(sys.argv[1],'w'))
PY
ens --out "$P/copy-pin"
echo "## E5 verbatim COPY of the real manifest in another directory (archives absent there)"; mkdir -p "$P/copy-verbatim"; cp .validation-foundations/independent-oracle-v2/manifest.json "$P/copy-verbatim/"; ens --out "$P/copy-verbatim"
echo "## E6 --no-build on an ABSENT path"; ens --no-build --out "$P/absent-nobuild"; [[ -e "$P/absent-nobuild" ]] && echo "DIRECTORY CREATED" || echo "no directory created"
echo "## E7 bad --lem-repo"; ens --lem-repo /nonexistent --out "$P/absent-badlem"; [[ -e "$P/absent-badlem" ]] && echo "DIRECTORY CREATED" || echo "no directory created"
echo "## E8 CERB_LEM_REPO pointing at a dir without the commit"; CERB_LEM_REPO=/tmp ens --out "$P/absent-badenv"; [[ -e "$P/absent-badenv" ]] && echo "DIRECTORY CREATED" || echo "no directory created"
echo "## E9 CERB_CERBERUS_REPO pointing at a dir without the commit"; CERB_CERBERUS_REPO=/tmp ens --out "$P/absent-badenv2"; [[ -e "$P/absent-badenv2" ]] && echo "DIRECTORY CREATED" || echo "no directory created"
echo "## E10 CERB_INDEPENDENT_MANIFEST -> garbage (no --out)"; CERB_INDEPENDENT_MANIFEST="$P/garbage/manifest.json" ens
echo "## E11 the real standing build: VALID, idempotent (manifest mtime unchanged)"; m0=$(stat -c %Y .validation-foundations/independent-oracle-v2/manifest.json); ens; m1=$(stat -c %Y .validation-foundations/independent-oracle-v2/manifest.json); [[ "$m0" == "$m1" ]] && echo "manifest untouched" || echo "MANIFEST MTIME CHANGED"
echo "## E12 manifest path is a DIRECTORY named manifest.json"; mkdir -p "$P/dirmanifest/manifest.json"; ens --out "$P/dirmanifest"
echo "## E13 hook syntax + set -e"; bash -n /home/dev/projects/cerberus-lean-proj/scripts/new-worktree.sh && echo "bash -n OK"; /usr/bin/grep -n "set -euo pipefail\|CERB_SKIP_INDEPENDENT_ORACLE" /home/dev/projects/cerberus-lean-proj/scripts/new-worktree.sh
echo "## E14 recorded hook diff vs the live container script"; diff <(sed -n 86,90p /home/dev/projects/cerberus-lean-proj/scripts/new-worktree.sh) <(/usr/bin/grep '^+' lean_frontend/docs/2026-09-16_pristine-oracle-instrument-record-evidence/o3-new-worktree-hook.diff | /usr/bin/grep -v '^+++' | sed 's/^+//') && echo "hook lines identical to the recorded diff"
