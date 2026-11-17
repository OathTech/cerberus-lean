# Choosing CoreNice extensions: preserve generator structure

Design criterion, 2026-11-17. This governs candidate selection, not a new proof
gate. See the [candidate assessment](generator-structure-candidates.md) for
applications and the [integration index](README.md) for implemented features.

**Prefer facts that the AIL generator already establishes by construction,
but ordinary Core loses or makes expensive to recover. Give those facts
operational meaning in CoreNice syntax.**

The goal is to constrain the target language to expose the structure of generated
programs. A malformed Core program may have behaviors that a corresponding
well-formed Nice program rules out. Correctly generated Nice programs must retain
the original generated Core behaviors under the intended observation/erasure.
This is not a way to impose additional safety obligations on C applications.

## The test for a candidate

For each proposal, identify:

1. **Producer fact:** the exact generation rule and information it already has.
   Name the accepted producer image: typed/normalized AIL emitted by the selected
   frontend, its configuration, and any linked runtime support. Do not silently
   generalize this to arbitrary typed AIL or arbitrary Core.
2. **Lost structure:** what becomes implicit, or difficult to recover, after
   lowering. Say what exceeds the guarantees of existing Core syntax and rules.
3. **Executable restriction:** concrete AST forms and semantics that expose the
   fact. A check must constrain the executed operation; matching decorative tags
   attached to unrelated operands establish nothing.
4. **Generic justification:** why generation supplies the required information
   and linking, renaming, reduction and suspension preserve its meaning. This
   should be a reusable producer/transport argument, not a new value, heap or
   application invariant smuggled in as a premise.
5. **Reasoning benefit:** the recurring reconstruction or case analysis that
   clients can avoid. Moving the same expanded syntax into another table, or
   introducing a name for an existing check, may buy nothing.

The distinction is not that all desirable facts are purely syntactic or that
their proofs will be trivial. Some need a substantive generic semantics lemma.
The distinction is whether the fact follows from how the selected producer
constructs programs, without a fresh proof from each application.

## Two motivating examples

**Comesfrom** exposes the structural origins of transfers. Generation identifies
the permitted origins, and execution checks the actual jump occurrence against
the destination's declaration. The future no-new-fault argument concerns this
generated control structure and its transport, not a new application control-flow
assumption. It is not already a whole-program equivalence theorem.

**Breakpoints** expose selected composition boundaries as restricted AST syntax
and concrete pause/resume semantics. They retain where composition occurs rather
than recovering it from an arbitrary residual computation. Their useful fact is
the explicit decomposition point; they do not imply single-entry loops, lexical
residency, or any new heap property. The existing saturation experiment concerns
finite effectful control fragments, with the limits in its
[assessment](breakpoint-saturation.md).

Both make generated structure explicit in the execution language. Comesfrom
restricts transfers; breakpoints expose composition through restricted placement
and intended behavior-preserving pause/resume. Neither licenses changing
unsequenced evaluation into a fixed order.

## Failures, subsetting and evidence

An added check may reject a deliberately malformed Nice artifact. For ordinary
outputs of the accepted producer, a new `NiceFault` is a failed experiment to
diagnose, not an acceptable normal execution or a post-hoc domain restriction.
Original UB, errors, nondeterminism and finite failure prefixes remain part of
the correspondence question; “no new faults” does not mean “the C program is safe.”

An explicitly declared generation-time refusal is different: a first experiment
may decline to generate Nice for an unsupported output shape. Report that domain
and refusal directly. Do not infer that the excluded case is impossible or rare,
or silently replace refusal with a runtime assumption. The previously discussed
dummy-type boundary is one reason this distinction matters.

Differential evidence comes first: compare ordinary Core/Nice executions under
choice tapes, inspect intermediate observations, and inject malformed structure
to verify that the new semantics is exercised. Check failures and mismatches are
failures. Passing runs support a candidate but do not prove the generic
generation/transport argument or full trace equivalence.

The parked [integer-representability guard](conversion-guard.md) illustrates the
boundary. Knowing source and target types does not by itself establish that a
runtime integer lies in the required range. A guard justified only by an extra
value invariant does not meet this criterion.

[USER, 2026-11-17] Choose extensions that expose structural facts already
ensured by generation and support generic redundancy arguments; avoid adding
runtime restrictions whose justification creates new application obligations.
