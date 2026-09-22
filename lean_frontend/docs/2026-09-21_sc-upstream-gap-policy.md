# SC prototype: upstream gaps fail closed

2026-09-21. [USER] clarification of the fidelity constraint:

> "This feels like a case where we should 'fail-closed' and match the Cerberus-upstream situation, until they have resolved this issue."

This resolves the pending decision about compare-exchange whose representation
comparison depends on unspecified padding. Keep an explicit upstream modeling
gap; do not invent nondeterministic padding-comparison semantics. The C17
representation-comparison correction itself is settled. The missing part here
is its implementation/composition with the pinned Cerberus object model.

## Meaning of a gap

An upstream gap is an explicit limit of the provider's operational model. It
does not state that ISO C forbids the program, that the program has undefined
behavior, or that CAS returns false. Reaching the unsupported operation stops
that execution with a distinct unsupported/modeling-gap outcome. Preserve
completed effects and the failure-time state; do not fabricate a continuation.

Faithfulness requires distinguishing this incomplete coverage from an incorrect
implemented behavior. We can faithfully report an upstream limitation without
implementing every ISO C behavior. We cannot claim complete ISO coverage for
that case. Matching the upstream situation means preserving the absence of a
supported result, not copying its OCaml assertion, abort signal or incidental
backtrace as the C semantics.

The gap must remain visible to reasoning clients. It is not an impossible
transition, an empty set of executions, normal termination or C undefined
behavior. A result that ignores such paths cannot certify whole-program support
or safety. A theorem may establish that its stated inputs never reach a gap;
that hypothesis must not become a provider runtime restriction. Previously
observed faults remain evidence even when another path is incomplete.

## Scope and implementation obligation

Apply this ruling to the evidenced unspecified-padding CAS gap. It does not
authorize dropping other SC operations or refusing all structs. Keep distinct:

- An evidenced upstream modeling gap, with a reproducer and source reference.
- A port mechanism that remains to be implemented faithfully from available
  semantics; that remains prototype development work.
- A weak memory order outside the explicitly selected SC model.

The CAS requests and their typed unsupported outcome are not implemented by
this documentation change. The current public SC entry still refuses success
because atomic/race/fence checking is unfinished. The concrete C struct-CAS
probes also expose an earlier frontend cast defect; fixing that defect does not
resolve representation comparison. All these limits retain separate entries.

Retain regression tests for the gap and revisit it against a pinned upstream
resolution. No speculative extension, silent UB classification, narrowing for
proof convenience, or claim of general CAS completeness is authorized.

Source analysis: [primary-source follow-up](2026-09-21_sc-primary-source-followup.md).
This clarification supplements the [charter](2026-09-21_charter-sc-prototype.md),
especially sections 2.1–2.2 and 6; it does not shrink its remaining work packages.
