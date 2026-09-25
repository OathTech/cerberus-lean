# WP0: independent audits and documentation follow-through

Date: 2026-09-25. [AGENT] Both independent reviews accept the sequential
`_Bool` repair and passive-receipt semantics. The second review requests
three documentation fixes before landing; those fixes have received a
separate bounded delta review. This record supersedes the pending-audit
status in the original [receipt record](2026-09-25_sc-wp0-passive-access.md)
and [repair record](2026-09-25_sc-wp0-bool-load-repair.md), preserving their
historical measurements. **Landing approval is still pending; WP1 has not
started.** This is useful observation infrastructure, not SC execution.

## Reviewed identities

Both reviews cover base `db5e1feb54226a6335aa89d0824aa9e313314020` through
`4e86ea091c58af3ea672f091022f8efd2b32649e`: isolated repair
`917961adf00fbb4ae4ed4aac8a3e0ee889d3aa08`, then passive receipts
`4e86ea091`. The original commits have not been rewritten.

The audit records and their evidence remain committed on their own branches:

| Review | Immutable record | Result |
|---|---|---|
| Fresh-context auditor, `audit/sc-wp0-independent-20260925` | `f2f6bb613366afd5ff1e7e780b8f1ef7d9b0b53c:lean_frontend/docs/2026-09-25_sc-wp0-independent-audit.md` | Both commits and composition pass within the declared concrete/default scope. |
| Separately commissioned auditor, `audit/sc-wp0-20260925` | `8e498636df834af516eaf9aad76a865fd8080c9d:lean_frontend/docs/2026-09-25_sc-wp0-audit.md` | Semantics accepted; D1–D3 documentation changes required. |
| Bounded documentation delta | `824b9b97e5890601e1d893489b77a2c78be0720d:lean_frontend/docs/2026-09-25_sc-wp0-independent-audit-addendum.md` | D1–D3 closed; exact four-file hashes recorded, no semantic change. |

Use `git show <commit>:<path>` to read those records without changing
worktrees. The addendum covers the four-file corrective diff, not this later
status/evidence record or the coordination update.

## Findings resolved

[AGENT] D1: the two original records now distinguish the user's semantics-only
MVP and independent-landing direction from agent implementation choices.
Receipt fields, placement, transport reuse, diagnostic expectations,
draining and repair/erasure separation are labelled. RR2 is agent review
advice, not a user ruling; the user scope points to the accepted master plan.

[AGENT] D2: `VALIDATION.md` §5 now names Tier A row 13, its actual fixtures,
full transcript/exit/stderr checks, state erasure, drain/re-enable controls,
six ND constructors, eight instrument controls and kernel proofs. It
distinguishes this primitive diagnostic from an oracle differential lane,
and the runtime comparator's annotation-insensitive type equality from the
stronger literal equality proved by the kernel.

[AGENT] D3: the `MemState` docstring again cites
`memory/concrete/impl_mem.ml:484–504`, including the 15-field count.
This single docstring is the only change to a Lean source file. No runtime
definition, proof, expected result, gate command or baseline changed.

[AGENT] D4 was informational. The reviewed commit identities are retained;
no model-specific coauthor trailer was added. Agent authorship is explicit
in the records.

## Evidence reconciliation and validation

The fresh-context reviewer independently regenerated and passed all 39
focused/cost runs, probed the exact original and repaired load bodies, checked
additional receipt cases and planted a producer defect. The other reviewer
ran the complete battery again on clean `4e86ea091`: **40/40 commands passed**,
source unchanged, no artifact issues. Its producer and proof plants failed
as intended and restored sources were rebuilt.

[AGENT] I independently verified that second full report's clean source
identity, all 40 successful lane statuses, all **80** raw stdout/stderr hashes,
its committed evidence manifest, unchanged compiler/runtime identities and
its recorded rebuilt native driver. The
[reconciliation record](sc-wp0-evidence/review-response-validation.json)
retains the report hash and those checks.

The fresh-context audit observed the native driver change from
`0870acaf…` to `a5dd159f…`. The separately commissioned audit's run began
at 07:04 UTC and rebuilt the candidate; its full-run `artifacts_after` and
rebuild-after-revert record both name the exact replacement. My readback
matched it. This accounts for the artifact change without attributing the
earlier run to a later binary.

The documentation/comment follow-through passed **17/17 Tier A commands**:

```
scripts/ce env DUNE_CACHE=disabled python3 scripts/release.py --mode fast
```

Here `scripts/ce` is the workspace wrapper, invoked by absolute path from the
candidate repository. Raw run: `.tmp/release/20260925T164049.010210Z`.
Source was unchanged during that run; complete tier selection and artifact
checks passed. The reconciliation record includes the four tested file
hashes, the raw report/log hashes, lane results, and compiler/binary identities.
Those four files also match the independent delta review's exact hashes.
This status record and its evidence serialization were written afterwards.

`release.py` derives membership from `scripts/LADDER.md` alone; adding the
`VALIDATION.md` explanatory row does **not** change `membership_sha256`.
The fast run verifies the documentation/comment candidate with the unchanged
lane membership. This corrects that incidental statement in the other audit's
landing recommendation.

## Landing scope and remaining limits

[AGENT] Propose the exact `arc/sc-wp0` head named in the master plan for an
ff-only landing from `db5e1feb5`: the two reviewed implementation commits plus
this documentation/comment follow-through. Proposed audit scope is the two
independent source/evidence reviews and the approved four-file delta, with
this record documenting their disposition and final gate. No runtime
remediation is needed.

Concrete/default memory remains the supported observation scope. Symbolic
and CHERI stubs were inspected but could not be compiled without their existing
missing dependencies. Storage is drainable, not unconditionally capped;
helper preemption, execution boundaries and SC correctness remain later work.
These limits were accepted within WP0 by both audits and are not expanded here.

No mainline merge or push has occurred. [USER] Early independent landings are
the intended work order; [AGENT] the workspace's explicit per-merge approval
rule still applies. Acceptance and landing close WP0; WP1 follows from that
landed base.
