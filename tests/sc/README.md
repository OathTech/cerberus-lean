# SC integration inputs

`boundaries/README.md` maps preserved boundary inputs to the live semantic
register. `representation/` keeps same/cross-view value and array cases: these are
adapter work, not a blanket unsupported domain. `runtime/` keeps actual library
registration, explicit rand exceptions, indirect calls, source/name decoys and
parameter-overwrite controls needed by precise runtime guards.

These extracted inputs are not yet an automated public-SC acceptance claim.
The [single roadmap](../../lean_frontend/docs/2026-09-21_charter-sc-prototype.md)
tracks their production integration. Paired machine and adapter controls run
with `scripts/test_unit.sh sc-machine-test sc-adapter-test`; the public C lane
uses `scripts/test_litmus.sh --check` for very small exhaustive probes; larger
C cases use explicitly labelled selected executions under the charter’s
exploration scope. `runtime/global-init-main.c` checks that the public whole-
program entry finishes initialization before returning main’s result.
