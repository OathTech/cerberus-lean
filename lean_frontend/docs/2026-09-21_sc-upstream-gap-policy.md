# SC prototype: upstream gaps fail closed

2026-09-21. [USER] clarification of the fidelity constraint:

> "This feels like a case where we should 'fail-closed' and match the Cerberus-upstream situation, until they have resolved this issue."

This initially resolved the decision about compare-exchange whose representation
comparison depends on unspecified padding. Keep an explicit upstream modeling
gap; do not invent nondeterministic padding-comparison semantics. The C17
representation-comparison correction itself is settled. The missing part here
is its implementation/composition with the pinned Cerberus object model.

2026-09-22. [USER] generalization, resolving the mixed-size reference proposal:

> "Agree, let's fail closed in general when we have such boundary cases, but make sure to document all such cases"

Retain the pinned Cerberus/Cmm reference. Apply this policy to evidenced,
unresolved semantic boundaries, including the mixed-size/location composition
and missing runtime stream synchronization. Do not silently adopt the published
mixed-size extension or invent stream synchronization. Record every case in the
[boundary register](2026-09-22_sc-boundary-register.md), including its evidence,
precise trigger, implementation status and condition for revisiting it.

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

Apply the general ruling when an execution requires an interpretation that the
selected references leave unresolved, supported by a source audit and concrete
reproducer. It does not authorize dropping other SC operations or refusing all
structs, character accesses, dynamic allocation or library calls. Keep distinct:

- An evidenced upstream modeling gap, with a reproducer and source reference.
- A port mechanism that remains to be implemented faithfully from available
  semantics; that remains prototype development work.
- A weak memory order outside the explicitly selected SC model.
- A checker adapter limitation or accidental host behavior, which is not a new
  restriction on C programs.
- A protocol invariant violation, whose diagnostic is not evidence of an
  upstream semantic gap.

The CAS guard is implemented: `SC_fault_unspecified_representation` retains
the preceding reads and failure-time state. The mixed-size and stream cases
still need precise guards and regression controls. This policy change does not
claim those guards exist. The current public SC entry still reports
`SC_fault_checker_pending` after recorded completion because checker integration
is unfinished; recorder success is not a supported SC verdict. The concrete C
struct-CAS probes also expose an earlier frontend cast defect; fixing that
defect does not resolve representation comparison.

A guard must explain why the unresolved interpretation is needed in this
execution, not just recognize a broad syntactic feature. In particular, the
scalar checker's narrower domain alone does not justify refusing ordered byte
operations. A diagnostic must identify the registered case and relevant
occurrences. Keep already established faults and unsupported alternatives
visible together; neither a gap nor an inconsistent candidate erases them.

Registration is mandatory before a new refusal is counted as an intentional
coverage limit. Use a stable case ID; name the operation, selected source/pin,
minimal reproducer, distinguishing controls, effects/state retained, client
consequence, and resolution criterion. Separate implemented behavior from a
proposed guard and from still-open trigger design. The register links historical
evidence without rewriting its original captures or claims.

Retain regression tests for the gap and revisit it against a pinned upstream
resolution. No speculative extension, silent UB classification, narrowing for
proof convenience, or claim of general CAS completeness is authorized.

Source analysis: [primary-source follow-up](2026-09-21_sc-primary-source-followup.md).
This clarification supplements the [charter](2026-09-21_charter-sc-prototype.md),
especially sections 2.1–2.2 and 6; it does not shrink its remaining work packages.
