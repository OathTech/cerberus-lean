# Run-digest independent audit evidence

[AGENT] Evidence for `2026-09-22_run-digest-audit.md`. Reviewed implementation:
`24f19d6f5a63204afff1991e3fc1fcf5b28ad420`, based on
`df85e95b7b37826dfb3f2ac97a41473580f1e0b9`. This bundle was assembled after
validation; the audit documentation commit is deliberately later than the source
identity recorded by the runners. No source or baseline was edited during the
runs. Reports retain their original absolute paths; those paths are provenance,
not live dependencies of the bundle verifier.

Verify from any location with Python 3:

```sh
python3 verify_evidence.py
```

`SHA256SUMS` inventories every bundle file except itself. The verifier checks the
inventory and hashes, archive member safety, all 39 command statuses and raw
stdout/stderr hashes, frozen source/external-input/recorded-artifact identities,
focused checks, pristine counts, and the exact 40 historical Lean difference IDs
and classes. It also checks the retained pristine/three-engine raw stdout,
stderr, and exit statuses against every capture record in their reports.
It does not rerun the semantics or claim the runner inventories every possible
build artifact.

## Contents

- `release-report.json`, `release-summary.txt`: unmodified full Tier A+B report
  and summary from the independent audit worktree.
- `lane-receipts.tar.gz`: all 39 commands' exact stdout and stderr, under lane IDs.
- `pristine-reports.tar.gz`: full/plant/chvalid pristine-oracle reports and the
  mandatory C5 three-engine report. Its summary is the final three console lines,
  copied verbatim by the bundle assembly script.
- `pristine-captures.tar.gz`: raw stdout/stderr/status and available command JSON
  for every capture referenced by those reports, including Cabs bridge outputs.
  Archive paths remove the original `.tmp/run-digest-audit/` prefix and, for full
  battery reports, the `full/` prefix. Stage files and duplicate bridge-input
  copies are omitted; the capture bytes and source inventories are retained.
- `expected-lean-differences.json`: the 40 IDs/classes derived from the worker's
  committed final three-engine report. These are existing discrepancies and
  undecodable rows, not 40 newly accepted agreements. Owning differential lanes
  remain the gates for Lean versus fork.
- `focused-evidence.tar.gz`: independent regeneration/build recipe and logs;
  queue record; focused Lean package sources, manifest and build/runtime logs;
  optional-backend call checks; raw reviewed implementation diff; review-surface
  inventory; full/three-engine console logs; and the bundle assembly script.
- `preflight.json`: generated-tree stamps, driver source/binary hashes compared
  with the worker, and the audit's native assertion count/start timestamp.
- `reviewed-files.json`: reviewed base/head and SHA-256 inventory of the 60
  changed files.
- `worker-evidence-review.txt`: derived checks on the supplied evidence,
  including its 16 changed recorded artifacts. This is kept distinct from our
  independently rebuilt/frozen source validation.

## Reproduction

Use a fresh worktree at the reviewed implementation with the repository's normal
project-scoped environment and pinned dependencies. The retained `rebuild.sh`
re-derives both generated trees, forces the OCaml build with the Dune cache
turned off, builds Lean under the memory cap, and ensures the worktree-local
pristine oracle. The full runner and C5 commands were:

```sh
DUNE_CACHE=disabled CERB_MEM_MAX=32G /home/dev/projects/cerberus-lean-proj/scripts/ce \
  python3 scripts/release.py --mode full --out .tmp/run-digest-audit/full
DUNE_CACHE=disabled CERB_MEM_MAX=32G /home/dev/projects/cerberus-lean-proj/scripts/ce \
  python3 scripts/test_upstream_oracle.py --with-lean \
  --out .tmp/run-digest-audit/three-engine
```

Outputs must go to fresh directories. Builds/probes ran sequentially. The long
battery was justified in advance as required corpus measurement and instrument
failure injection. The build queue log records the wait for two other workers'
pre-existing batteries; it is not validation evidence for this branch.

To repeat the focused checks, extract `focused-evidence.tar.gz` into the
worktree's `.tmp/run-digest-audit/`, then build in its `native/` directory through
`../../../scripts/capped lake build` with `CERB_MEM_MAX=8G` and the project `ce`
wrapper. Run `../../../scripts/capped .lake/build/bin/run-digest-audit` there,
with `LEAN_ABORT_ON_PANIC=1`, the same cap and environment. The package imports
the worktree's actual generated semantics. Its kernel dependency checker is a
conservative source-level closure walk, not a theorem about compiled code.

`native-build-attempt1.log` and `native-build-attempt2.log` record two corrected
reviewer-probe authoring errors (`when` syntax and record type inference).
`native-build.log` and `native-run.log` are the successful final runs; no failed
product gate was hidden or replaced. The optional-entry checks use isolated
OCaml expressions against freshly built modules; they do not certify full
optional web/runtime backend builds. Consumer re-pin/proof adoption is outside
this provider audit.
