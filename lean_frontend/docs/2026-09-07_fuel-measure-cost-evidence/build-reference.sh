#!/usr/bin/env bash
# Run through the charter worktree scripts/capped with CERB_MEM_MAX=48G
# and timeout --signal=TERM --kill-after=15s 3300s, as recorded in D2.
set -euo pipefail
source /home/dev/projects/cerberus-lean-proj/scripts/env.sh
export PATH="/home/dev/projects/cerberus-lean-proj/worktrees/lem-lean-ref/3c88f0d:$PATH"
export DUNE_CACHE=disabled CERB_MEM_MAX=48G
export LEMLIB=/home/dev/projects/cerberus-lean-proj/worktrees/lem-lean-ref/3c88f0d/library
cd /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-ref/1b57bcf26
date -u
uptime
git rev-parse HEAD
command -v lem
lem -v
sha256sum /home/dev/projects/cerberus-lean-proj/worktrees/lem-lean-ref/3c88f0d/bin/lem
make prelude-src lean-prelude-src
tools/check_lem_sync.sh --check
tools/check_lem_sync.sh --check-lean
dune build backend/driver/main.exe cerberus-lib.install cerberus.install
dune install --prefix "$PWD/_build/local-install" cerberus-lib
tools/check_driver_fresh.sh --record-oracle
make lean-native-obj
(cd lean_frontend && lake build cerberus-lean)
tools/check_driver_fresh.sh --record-lean
sha256sum _build/default/backend/driver/main.exe lean_frontend/.lake/build/bin/cerberus-lean
git status --porcelain
