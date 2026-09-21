# SC prototype: progress and resumption record

Governing document: [SC prototype charter](2026-09-21_charter-sc-prototype.md).
This file records evidence and next actions; it does not replace the charter.

## Current status

**2026-09-21: worktree and charter prepared; implementation has not started.**
Branch `arc/sc-prototype`, worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype`.
Implementation base: `5407597d9eeba0259d65b728e86a860ad4614ab3`.

| Package | Status | Next evidence |
|---|---|---|
| S0 reference/baseline/instruments | Not started beyond worktree setup | Current baseline runs, operational contract, source-path inventory, repaired harness |
| S1 driver/scheduler/threads | Not started | Current-driver structured execution and sequential checks |
| S2 effects/representation/sequencing | Not started | Byte/helper/lifetime/order repairs and correspondence |
| S3 SC atomics/races/verdicts | Not started | Full atomic/fault paths and diagnostic families |
| S4 operational API/laws | Not started | Importable definitions and justified semantic lemmas |
| S5 integrated completion | Not started | Final inventory, fresh gates and reproducible report |

## Setup record

[USER] approved the SC prototype development plan, requested work in a worktree
and a charter for long-cycle work with minimal interaction. Fidelity overrides
reasoning convenience; customer logic is out of scope and the customer remains
strictly read-only.

[AGENT] created the worktree using:

```sh
/home/dev/projects/cerberus-lean-proj/scripts/new-worktree.sh \
  cerberus-lean arc/sc-prototype \
  5407597d9eeba0259d65b728e86a860ad4614ab3
```

Result: exit 0. The script copied local Lake/build/generated/native state,
created the shared-switch symlink, and built the worktree-local pristine oracle.
Its ensure step reported `BUILT+VALID` for
`.validation-foundations/independent-oracle-v2/manifest.json`, using Cerberus
`b9aeedcb4` and upstream Lem `3802cb0`. This is instrument setup evidence,
not an SC result or a full sequential test certification.

The two September 20 research documents were copied byte-for-byte from Git
commit `02a6adc9091f72cecac6c5ff15845f93fa81fa84`. No legacy implementation
was copied or merged. The mainline, parked donors and customer were not edited.

Fresh setup checks are retained in
[setup-checks.json](2026-09-21_sc-prototype-evidence/setup-checks.json).
OCaml/Lean Lem generation stamps, all 49 hand-written/generated seam copies,
both driver freshness checks, and pristine-oracle validation pass. Lem reports
`38f87d5`; Lean from the owning `lean_frontend` package reports `4.32.2`.

Two setup findings were resolved:

- The copied OCaml driver failed its source freshness check. It was rebuilt
  locally, with cache disabled, using the actual `build_cerberus` helper:

  ```sh
  DUNE_CACHE=disabled /home/dev/projects/cerberus-lean-proj/scripts/ce \
    bash -euo pipefail -c 'source scripts/common.sh
  build_cerberus'
  ```

  The helper exited 0, installed the runtime worktree-locally, and recorded a
  fresh stamp. No freshness override was used. The subsequent combined check
  passes; the already-fresh Lean driver did not require rebuilding.
- An initial `lean --version` from the repository root selected ambient Lean
  `4.33.1`. The owning-package check selected the pinned `4.32.2`. Both outputs
  are retained, with the ambient probe classified separately. Run Lean/Lake
  from the owning package under `scripts/capped`; no global toolchain was changed.

Documentation links, fences, whitespace and exact research-snapshot copies were
checked. The full sequential baseline and all SC implementation tests remain
for S0 onward; these setup checks do not claim those results.

## Next action

Begin S0 under the charter. Verify source/generated/driver/tool identities,
establish the current sequential baseline, and write the operational/effect
inventory from current Core/driver/memory sources and the retained audit.
Select the legacy validation repairs against the current observation codec
before trusting new concurrency comparisons. Continue through the charter's
packages without routine approval requests.

## Checkpoint template

For subsequent entries record:

- Date, package/task, source revision and relevant tool/artifact identities.
- Changes and rationale, with [AGENT]/[USER] provenance.
- Exact commands, original statuses, evidence locations and claim boundaries.
- Open semantic issues, port gaps and proof limitations as separate lists.
- Next concrete task and any specific decision/capability required.

Do not mark a package complete on historical measurements or copied artifacts.
