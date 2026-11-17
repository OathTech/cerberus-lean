# Other generator structure worth preserving in CoreNice

Source assessment, 2026-11-17. These are proposals, not implemented features or
equivalence claims. Apply the [selection criterion](generation-invariants.md).

**The strongest small next candidate is explicit identity forwarding at labels.
The strongest complementary candidate is an explicit lifetime-transfer plan.**
Together they describe what a generated control edge carries and what operations
it performs before entering its destination. Neither asserts memory safety.

## Basis and ranking

Inspected executable sources: `feature/cerberus-nice` at
`36e50de3f37435f34b0af705de8eb9180e947a10`; the documentation branch descends from
`970a845d9`, which parks the conversion guard. Relative source links below name
the owned Lem definitions; identifiers are the stable anchors. No new executions,
proof checks or performance measurements were run for this documentation pass.

This reassesses the earlier parent proposal at `4c0616c9b`,
`docs/2026-11-17_CoreNice-proof-burden-proposals.md`. Its conversion-first ranking
predated the clarified criterion and is not the recommendation here. Core already
has explicit contexts, an environment stack, saved-label tables, label kinds,
arity checks and full-expression boundaries. A proposal must improve on those.

| Rank | Candidate | New structure exposed | Fit / cost |
|---|---|---|---|
| 1 | Named identity-forwarding label interfaces | Which object slot is forwarded to the same destination slot | Strong; small–medium, with binding/transport questions |
| 2 | Ordered lifetime-transfer plans | Exact retire/create/transfer recipe computed from visibility lists | Strong for the existing ordered helper; medium |
| 3 | Temporary-object envelopes | Full-expression temporary inventory and normal result/cleanup protocol | Strong narrow fallback; overlaps 2 |
| 4 | Generated-local references | Fresh temporary/binder identity distinct from external resolution | Conditional; static namespace argument, broader runtime changes |
| 5 | Shared, named continuation tails | The precise continuation composition that lowering constructed | Plausible larger project; closure/sharing work remains |
| 6 | Retained address/access recipes | Source-object and projection structure across lowering phases | Plausible but lower confidence; scheduling and value flow complicate it |

The ranks prioritize a bounded next experiment, not maximum eventual payoff.
Cases 4–6 need more design before an implementation commitment.

## 1. Named identity forwarding at labels

**Already known by generation.** Loop lowering obtains `visible_syms` and uses
that same ordered list for label parameters and backedge `PEsym` operands.
`mk_run_with_lifetime_e` forwards the destination's `visibles_after`, followed by
any separate result arguments. Ordinary labels, case labels and default labels
likewise construct their parameters from the visible-object list. See
[`translation.lem`](../../../frontend/corenice/model/translation.lem#L3637),
`AilSwhile` at 4006 and `AilSlabel` at 4285.

**What is missing.** Core represents both an object slot forwarded unchanged
and an arbitrary computed argument as a pure expression in a positional list.
Its `Erun` rule already checks argument count. An additional arity check or
`LAloop` tag would add little. The useful stronger fact is the identity of each
forwarded slot, independently of its current value.

**Possible syntax/semantics.** A label declares an ordered object interface,
separate from ordinary value/result parameters. This interface is the relevant
part of its actual parameter binders, not an independently trusted metadata list;
if represented separately, equality with those binders must be checked. A schematic
`RunForward(label, [x, y], payloads)` uses restricted object references: its
operands for these slots are exactly the original lookups of `x` and `y`, not
arbitrary expressions accompanied by tags. Execution checks this ordered slot
list against the destination's declared object interface, then performs the
original argument evaluation and binding. Erasure reconstructs the corresponding
`Erun [..., PEsym x, PEsym y, ...]`. This remains an operational restriction even
if two slots happen to hold equal pointer values.

For example, a label declaring object slots `[x, y]` cannot accept a transfer
that swaps them to `[y, x]`, even though both are pointer-shaped and the arity is
correct. Value/result parameters remain separately supplied expressions; a return
value is not an object slot that must forward itself.

**Generic argument and benefit.** The list agreement gives clients a reusable
account of object-binding transfer, rather than rediscovering a positional
correspondence at each edge. Loops literally reuse one list. For ordinary gotos,
the generic generator argument also needs agreement, including order, between
the `collect_visibles` prepass and the `get_visible_objects` traversal at the
destination. These are separate traversals, not one shared computation. Preserve
slot identity through linking and every syntax transformation; do not append
unchecked tags to arbitrary operands and call that identity forwarding.

This does **not** yet establish literal equality of the whole environment.
[`PEsym` evaluation](../../../frontend/corenice/model/core_eval.lem#L570)
uses external resolution and searches environment frames, while
[`update_env`](../../../frontend/corenice/model/core_aux.lem#L2580) writes the top
frame. Keep those rules unchanged; the new node must not silently turn into a
direct local lookup or optimize away rebinding. The `Erun` evaluator reads its
arguments against the original environment while accumulating the updated
bindings. Preserve that distinction. The later environment-preservation lemma
will need generic symbol/binder discipline, not just list equality.

Ordinary entry through `Esave` also evaluates initializers and binds parameters;
it is not a jump. Preserve that path, including separate return-value defaults
and their possible original failures. Partial evaluation can turn an initializer
into a value, and `Ecase` still uses substitution in the active reducer. Retain
slot identity through these operations instead of demanding that every residual
operand still look like `PEsym`. The generic freshness/transport argument must
cover this; it is a concrete design question before implementation.

**First experiment.** Cover generated loop transfers and ordinary labels, then
goto transfers and return payload separation. Compare shadowed declarations,
multi-object interfaces, nested calls/recursion and jumps into blocks. Corrupt
slot order or identity without changing arity, and verify a typed fault carrying
procedure, jump, destination and expected/actual interfaces. Do not assert
pointer validity, initialization or C-type range; dummy label type metadata
cannot justify such checks. Runtime support labels need their own explicit
producer treatment before a whole-linked-program claim.

## 2. Ordered lifetime-transfer plans

**Already known by generation.**
[`mk_run_with_lifetime_e`](../../../frontend/corenice/model/translation.lem#L3637)
computes, in order:

1. Objects in `visibles_before` absent from `visibles_after`: emit kills in their
   original list order.
2. Objects in `visibles_after` absent from `visibles_before`: emit creates and
   bind their results, in their original list order.
3. Forward the destination's visible objects, then any result arguments.

The generator has object identities, types, creation preferences and destination
at this point. Core expands the recipe into ordinary sequence/binding syntax;
later reasoning must recognize and reconstruct the recipe.

**Possible syntax/semantics.** Retain the before/after descriptors and an explicit
ordered plan in a `LifetimeTransfer` node. Its operational phases execute exactly
the old kill, create/bind and transfer operations. Check that the plan matches the
ordered differences and that the destination interface agrees with `after`.
Alternatively derive the plan directly from those descriptors, making malformed
action lists unrepresentable. Neither choice checks the heap against the lists.

Preserve the original memory requests, annotations, choices, bindings and partial
progress. A failure midway through cleanup must remain a failure after the same
preceding effects. This is not an atomic transaction and does not add rollback.
An implementation that immediately expands the node and loses its phase/inventory
may validate erasure but give little improvement in symbolic execution.

**Generic argument and benefit.** Generation supplies the plan by list operations;
a reusable protocol lemma relates its execution to the existing helper. Clients
can reason about the finite edge recipe without recovering a create/kill spine.
The checks do not authenticate `before` as the actual live heap, or assert that a
kill succeeds. Dangling values, initialization, nonescape and ownership remain
separate semantic questions. This is a manageable alternative to reconstructing
a universal lexical-scope stack, including when control enters a block by goto.

**Important boundary.** Start with the ordered helper, used by goto and valued
returns. [`AilSreturnVoid`](../../../frontend/corenice/model/translation.lem#L4101)
uses an **unsequenced** kill group. It must retain that path or receive a distinct
plan semantics preserving its alternatives. One universal sequential cleanup
construct would change the semantics. Likewise, do not replace Core's dynamic
allocation with Caesium's flattened function-local allocation.

**First experiment.** Use forward/backward cross-scope jumps, shadowing, entry
past initializers, valued returns and failure-prefix probes. Compare memory
receipts, allocation identities and choice requests, not just exit values. Inject
missing/extra retire actions, changed create order and a mismatched destination
interface. Independently compare the original Core artifact so that corruption
of both a plan and its claimed descriptor cannot make the test vacuous.

## 3. Temporary-object envelopes

[`track_temporary_objects`](../../../frontend/corenice/model/translation_effect.lem#L256)
collects an exact inventory while translating an expression.
[`wrapped_translate_expression`](../../../frontend/corenice/model/translation.lem#L3690)
then emits creates, an `Ebound` body, a result binding, ordered kills and result
forwarding. This is another producer-known protocol.

Retain the inventory, result slot and operational phases as syntax, with exact
erasure to that expansion. The useful addition is the object inventory and its
connection to the result/cleanup operations: **`Ebound` already exposes the
full-expression boundary**. A new boundary marker alone is redundant.

This can be a smaller trial of the protocol representation in candidate 2.
It does not justify “these temporaries cannot escape” or automatic cleanup on
every exit. GNU statement expressions and abrupt control must preserve their
existing behavior, including bypassed continuations; do not add `finally`
semantics. An initial generator may explicitly refuse unsupported shapes.
Test inventory identity/order, result forwarding, normal cleanup and abrupt
exits; mutate inventory/phase associations. Choose this or ordered edges first,
not two independent implementations of nearly the same machinery.

## 4. Generated-local references, conditionally

[`wrapped_fresh_symbol`](../../../frontend/corenice/model/translation_effect.lem#L196)
constructs a fresh symbol, its binder and its reference together. Preserving
that generated-local identity could make local references distinct from externally
resolved names, reducing repeated freshness/resolution reasoning.

The candidate passes the criterion only after identifying a static namespace and
linker discipline that guarantees these symbols cannot be redirected externally.
Today `PEsym` consults `core_extern`; simply bypassing it changes the meaning for
arbitrary Core states. Start with compiler-generated temporaries, if justified,
not all C locals. An explicit local-reference constructor must preserve activation
and binding behavior, with mutations of class/owner caught by its semantics.

Core already has environments and first-order frames. The new fact would be
reference class/ownership, not their mere existence. It is not global SSA: the
same static temporary can execute repeatedly through loops and recursion. Neither
fresh naming nor lexical nesting by itself guarantees read-before-write safety
or dominance in the presence of arbitrary C control flow. Cost and semantic scope
make this a later candidate.

## 5. Shared, named continuation tails

Statement lowering knows the sequential tails it composes. Core later rebuilds
saved-label suffixes through
[`collect_saves_aux`](../../../frontend/model/core_aux.lem#L2278), including
distinct strong/weak sequence and parallel-closure rules. Preserve that
composition as named shared code/continuation references, with procedure
ownership, binders, incoming origins and pending breakpoint controls intact.

The gain would be structural continuation composition and sharing, avoiding
repeated reconstruction of expanded suffixes. **Core already has saved-label
tables and first-order execution contexts.** Another table containing the same
copied expressions does not deliver this gain. Filling a table with the old
collector can test a new representation but does not eliminate its proof burden.

This fits the direction but needs a real continuation-conversion design and
generic plugging/closure argument. Preserve unsequenced regions rather than
pretending the entire program is an ordered CFG. The historical enormous
saved-map proof has already been improved in the parent; performance gains must
be measured against the current compositional approach. Test shared suffixes,
unequal-depth jumps, equal-looking but distinct occurrences, calls and repeated
pauses; mutate an entry's suffix while leaving its incoming origins valid.

## 6. Address construction and access recipes

AIL retains local-object, field, index and dereference constructions.
[`translate_expression`](../../../frontend/corenice/model/translation.lem#L1953)
lowers these into references, primitives and temporary bindings; member cases
begin around 2983. Retaining the recipe and its actual operands could expose
which source object/projection an access follows without recovering it through
the whole lowered expression.

Core already has member/index primitives. A meaningful addition must preserve
their association with the generated slots and phases, not just attach a source
description. Its semantics would execute the existing recipe, preserving operand
effects, ordering, provenance and configuration-dependent operations. It must
not check that the computed address is live, in bounds or disjoint: those facts
are not supplied by the mere presence of an AIL lvalue.

Phased assignment is a related larger experiment: generation knows its operand,
deferred-action, store and result protocol, but reproducing its unsequenced and
negative-action behavior is delicate. Neither recipe proposal presently has a
small enough execution design to displace candidates 1–3. Tests would need
side-effecting operands, nested accesses, aliasing/conflicts and injected phase
reorderings, not only uncomplicated successful loads/stores.

## Proposals not justified by this criterion

- **Numeric fit, heap typing/liveness, initialization, nonescape or disjointness
  assertions:** not established by a generation rule merely knowing types or
  syntax. They need additional runtime preservation or application premises.
- **Single-entry loops, dominance or a mandatory lexical residency stack:** valid
  C control flow can enter regions through labels, including loop bodies. A
  generated loop's role does not prove these stronger properties.
- **Label-kind checks alone:** `LAloop`, `LAreturn`, case/default and source-label
  tags already exist in [`annot.lem`](../../../frontend/model/annot.lem#L35).
  Promote a role only with a specific new operational guarantee beyond comesfrom.
- **Sequentialized unsequenced work or atomic assignments:** generation does not
  provide the needed independence fact. A footprint certificate is a different
  project with an explicit proof obligation.

For the present experiment I recommend candidate 1, then candidate 2 if the
binding/transfer boundary is useful. The first gives the control edge an explicit
data interface; the second gives it an explicit memory-operation recipe. Their
eventual generic proofs remain work to do, but the information they expose is
already available at the exact generation sites.
