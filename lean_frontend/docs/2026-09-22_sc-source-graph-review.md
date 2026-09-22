# SC source-order graph and boundary-policy checkpoint

2026-09-22. Parent implementation `3864dbb1f`. This slice records the user's
general fail-closed decision and supplies a checker prerequisite. Public SC
verdict checking and the SC-G02/03 guards are still unfinished.

## Decision and reference

[USER] retained pinned Cerberus/Cmm and generalized fail-closed handling of
evidenced unresolved semantic boundaries, requiring documentation of every case.
The [policy](2026-09-21_sc-upstream-gap-policy.md) and
[boundary register](2026-09-22_sc-boundary-register.md) supersede the earlier
CAS-only scope and pending mixed-size question. They distinguish semantic gaps
from unfinished mechanisms, narrower checker domains and protocol failures.
Original source audits, proposals and captures remain unchanged.

## Implementation

`frontend/model/sc_graph.lem` extracts a source-order graph from the actual
`Sc_runtime.sc_state`. Every completed effect is a vertex, including allocation,
deallocation and abstract varargs observations. Completed fences are vertices
with their own occurrence identities. Pending requests/receipts add no extra
vertex. Equal payloads do not collapse occurrences; memory values, pointers and
floating equality do not participate in graph identity.

The adapter separately retains the annotations' `sb`, `asw` and `dd` edges and
computes `transitiveClosure (sb union asw)` over the complete vertex graph.
Projection restricts endpoints only after that closure. This follows the
source-order relation in pinned `Cmm_csem.sbasw`; retaining intermediate effects
prevents the access-only projection from erasing ordering through lifetimes or
fences. The closure uses existing Lem relation/set operations, instantiated with
integer occurrence IDs. No new fuel limit, external state or axiom is added.

This closure is not full happens-before: atomic reads-from/synchronization and
the runtime gaps require their own integration. Journal order, increasing IDs,
the total SC order and data dependency alone do not introduce source-order
edges. The adapter supplies neither C locations nor Cmm RF/consistency, and
cannot by itself prove a conflicting pair unordered in full hb.

Protocol diagnostics identify duplicate IDs, missing predecessor vertices,
incorrect `sb` thread labels, cross-thread `sb`, same-thread `asw`, and cycles.
The thread constraints follow pinned `well_formed_threads`; diagnostics retain
all nodes and edges instead of silently repairing malformed input. They are
data for the checker, not C UB or new upstream semantic gaps. Prefixes with
diagnostics cannot be used to certify a supported graph.

The source graph is an inspectable, pure query over the existing operational
state. `Driver.drive` and the scheduler are unchanged; public SC completion
continues to return `SC_fault_checker_pending`. New shared Lem generation, Lean
library roots and the handwritten copy manifest expose the query to clients.

## Validation scope

The isolated draft generated for both targets. Twelve matched OCaml/Lean controls
exercise source-order paths through omitted intermediate vertices, independent
siblings, list permutation, dependency separation, malformed edges/cycles,
completed fences and occurrence identity. Five kernel laws preserve nodes,
occurrence counts and independence from observation payload/pending requests.

Eight real C recorder executions exercise the draft graph: six location
discriminators and parallel/sequential libc `fputc`. All retain their original
recorded outcomes, contain every recorded effect, and have no graph diagnostics.
An independent integer-edge reachability traversal agrees with each closure.
These runs are selected recorder traces, not complete Cmm candidates or public
SC verdicts. The first attempt omitted libc linking for the two stream programs;
its unresolved-symbol failures are retained, followed by the corrected attempt.
Generation and control-compilation failures are also retained.

Production `sc-graph-test` passes all 16 controls, including actual driver fence,
unsequenced-fence, nested spawn/join and failure-prefix cases. Its unit-script
gate suite also passes. The first production attempt had a test-only Lean `do`
syntax error; its failed build is retained. Three freshly compiled OCaml plants
omit fences, project before closure or erase diagnostics; each builds, exits 1
and fails its designated control with empty runtime stderr.

Fresh production generation and the fork-manifest check pass (98 source files,
32 differing existing generated modules, one additional `sc_graph.ml`). All
39 full Tier A/B lanes passed with source unchanged and no artifact issues.
The mandatory 864-row three-engine report retained every preceding per-case
classification and decoded token, including the same 40 Lean discrepancy IDs.
Those differences and undecodable cases remain explicitly classified. See the
[retained evidence](2026-09-21_sc-prototype-evidence/source-graph/README.md).
The new source/control modules and Makefile entries are explicit fork-manifest
additions, not an unreviewed oracle change.

## Next implementation

Use the graph alongside physical byte sources to construct source-backed
location/value/atomic synchronization adapters and prefix diagnostics. An absent
path in this graph alone is insufficient to trigger SC-G02 when atomic or other
synchronization may establish hb. SC-G03 needs stream/call identity before omitted
libc locking can be separated from caller races. Atomic frontend paths remain
implementation work. No customer source, build, cache or dependency was touched.
