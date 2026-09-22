# SC unconditional atomic updates — validated slice

2026-09-22. Parent checkpoint `8427b42e785265de968e6c47d6d7f39fc10f3d87`.
The slice passed full integration and the mandatory three-engine comparison.
This document does not claim completion of SC-P02/the SC prototype. Component
and integration evidence is retained in the [evidence index](2026-09-21_sc-prototype-evidence/atomic-updates/README.md).

## Semantics and scope

[AGENT] Add an unconditional `AtomicUpdate` Core action with an explicit memory
order, update binder, pure update expression and old/new result selection. Its
SC request owns the checked read, update evaluation and checked store without
an intervening scheduler service. Each completed memory effect remains distinct;
the common request identifies the RMW. Their journal order does not create an
internal source-order edge. Ordinary `SeqRMW` and historical conditional `RMW`
retain their existing meanings.

The source basis is [N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)
6.5.2.4p2, 6.5.16.2p3 and 7.17.7.3: atomic increment/compound assignment use
seq_cst RMW; exchange returns the preceding value. Pure arithmetic/conversions
and checked memory operations come from the existing Cerberus implementation.
The current concrete object model is the charter instance; this is not a claim
of newly implemented PNVI/CHERI semantics.

Exchange evaluates object and desired arguments once with their permitted
argument ordering. The existing assignment-conversion helper converts desired
before the atomic object read. Exchange does not use CAS comparison/retry, so
unspecified old bytes do not themselves invoke the CAS representation gap.
Atomic postfix and compound assignment preserve result rules and ordinary
operator arithmetic; compound assignment evaluates its left operand once.

The update closure retains lexical context and receives current memory after
the checked read. Errors in update evaluation/store must preserve completed
reads and failure state. Valid non-SC orders have the existing explicit SC-model
refusal before the object read. Negative Core polarity and execution outside
the SC path are explicit failures; no default sequential execution is invented.

## Frontend and syntax repairs

Atomic postfix/compound typing removes atomic qualification from the result
and performs ordinary arithmetic checks on the corresponding non-atomic type.
Atomic qualification is applied to the declaration's base type before its
pointer/array declarator, including the delayed local initializer; this fixes
the earlier loss of `_Atomic int` and preserves pointer-to-atomic distinctions.
CAS's argument helper retains compatible structure/union values instead of
inserting an invalid C cast.

The atomic compound translator reuses ordinary binary lowering on fresh loaded
value binders. A structural converter retains lexical lets and explicitly
rejects effectful syntax. It does not assume that the old substitution-based
`to_pure` fuel bound applies to arbitrary expressions. No general equivalence
theorem for this converter is claimed.

New constructors are append-only. Substitution, free variables, copying,
rewriting, typing, printers, both Core parsers and the emission instrument have
explicit arms. The update binder scopes only the update expression. Legacy
Core_run/BMC paths explicitly report their unsupported new action. The customer
has binder/exhaustive-action adoption work, but was only inspected read-only.

## Validation

Both production targets now generate and compile. Four kernel equations compile;
17 control groups pass in each engine, covering five typing rules and twelve
operational groups. Existing ordinary SeqRMW scheduling controls also pass.
The new five Lean parser checks pass among 277 direct parser checks. That direct
run lacked runtime paths and skipped the runtime-file groups; it is not the full
unit gate.

The first operational attempt detected a real driver defect: passing an
unqualified object type to checked memory rejected the access to an atomic
allocation. AtomicUpdate now reconstructs the atomic object type, as the
existing CAS object phase does. Native and Lean controls pass after this repair.
Earlier compile/fixture failures and the failing operational output are retained.
One diagnostic run accidentally used the old test binary after a failed rebuild;
`atomic-lean-controls-run-2` is stale evidence and is not a validation result.

Thirty positive actual-C probes ran in selected-path mode on freshly linked
recording entries. Twenty-nine matched their original expectations; the parameter
probe's initial expectation was too narrow. In `100*update(&x)+x`, the read of
`x` may precede or follow the called function, by N1570 6.5.2.2p10. The corrected
expected set is 707/709, not just 709; both engines observed 707. This is an
expectation correction, not a semantic change or a new unsupported boundary.

All 35 actual-C journal probes executed, including the negative cases. Arithmetic
failures retain the atomic read with no update store; relaxed exchange is refused
before that read; padded struct CAS reaches SC-G01. Qualifier syntax produces
atomic types/orders in the actual journal. These selected traces are not complete
outcome sets or public SC verdicts. A bounded exhaustive attempt completed the
integer exchange case but hit the 12-second bound in both engines for the other
seven selected cases. Those timeouts remain incomplete, not agreement or safety.
Subsequent checks cover all 37 selected C journals, including six negative
cases. The two added fixtures check an actual negative-zero representation and
out-of-range floating argument conversion before the object read. The original
`-0.0` fixture supplies positive zero because of unchanged upstream unary-minus
lowering; the source comparison and journal bytes are retained, and SC-D05
records this limitation. Paired batch captures verify all six exact negative
outcome identities, separately from the journal's retained prefixes.

Five native Core parser cases pass; the old/new/binder-shadowing printed
expressions then parse in Lean with the intended binding structure. All four
law axiom cones were printed: the constructor equation has none, the binder
law uses only propext/Classical.choice/Quot.sound, and the two structural
converter equations use only propext. No custom axiom or proof shortcut is used.
A positive isolated native build and five compiled disconnection plants pass:
omit the store, swap the returned values, omit the binder insertion, admit weak
orders, or suspend between read/write. Every plant fails its designated
operational control; compilation failure is not treated as detection.

All 39 Tier A+B commands pass with frozen sources and no artifact issue.
The mandatory 864-row pristine/fork/Lean report preserves every preceding
classification and decoded token, including the same 40 Lean discrepancy IDs.
The full unit lane includes the runtime groups omitted by the earlier direct
parser invocation. Historical failures and bounded incomplete explorations
remain recorded; neither matching failures nor existing discrepancies count as
semantic agreement.

## Remaining obligations

Runtime-valued memory orders, integer fetch functions, atomic flags,
non-synchronizing `atomic_init`, signal fences and remaining argument-conversion
paths still need implementation/review. Source-backed semantics remain work,
not new fail-closed coverage exclusions. Public race/consistency checking and
the precise location/stream boundary guards also remain unfinished.

Pointer fetch needs careful reference handling. C11's generic-fetch applicability
paragraph lists integer types but its later address wording is inconsistent;
DR486 and later proposals are not automatically adopted C11 semantics.
[WG14 issue 1006](https://www9.open-std.org/JTC1/SC22/WG14/issues/c23/issue1006.html)
is now fixed in C2Y by February 2026 adoption of
[N3788](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3788.htm), which retains
integer fetch and removes the pointer/address wording. That does not add pointer
fetch or change this project's pinned C11/Cmm reference. Ordinary atomic pointer
operators remain distinct. No new pointer-fetch behavior/guard is claimed here.
