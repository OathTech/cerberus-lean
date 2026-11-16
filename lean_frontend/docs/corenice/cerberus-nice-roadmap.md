# Roadmap: establish CoreNice, then modify it into Nice

Roadmap, updated 2026-11-16; [current implementation progress](README.md#current-evidence-and-next-experiment)
is tracked separately. The
[CoreNice baseline scope](corenice-baseline-scope.md) is the detailed, authoritative
first step; the [design](cerberus-nice-design.md) gives the subsequent purpose.
The earlier driver-only twin and later-from-scratch interpreter/producer stages
are superseded. CoreNice is the complete future Nice target path from the outset.

## First milestone: unchanged CoreNice and its infrastructure

Develop in the independent cerberus-lean clone, using milestone worktrees on
research branches of the existing fork. The installed provider and both consumer
repositories remain unchanged.
The baseline scope specifies repository ownership, source duplication,
generation/type separation, runtime loading, common typed AIL, bidirectional
choice tapes, compact observations, C fuzzing, injected differences and exit
criteria. Its work sequence is:

1. Establish nominally distinct ASTs and reliable generation/name resolution.
2. Complete B's own AIL lowering, evaluator, control, runtime and driver path.
3. Make observation and choice record/replay work in either direction.
4. Fuzz a declared C slice and detect source-level B mutations with the harness.
5. Review and freeze the unchanged baseline before semantic changes.

No breakpoint or other Nice behavior is introduced to make the baseline work.
Successful tests of two executables sharing the original AST/reducer do not
complete this milestone. The useful outcome is an editable B path, not just a
comparison report. The implementation size and risks are accounted for in the
individual scope; its estimate replaces the earlier 2–4-day driver-only estimate.

## Current milestone: breakpoints for compositional simulation

The [comesfrom checkpoint](comesfrom-checkpoint.md) implements checked incoming
jumps and structural tightening, with reviewed differential evidence. Its local
proof proposals remain available; the next development step is the
[breakpoint charter](breakpoints-charter.md), before the broad correspondence
proof effort.

That charter is the plan of record for placement, AST/driver semantics,
AIL-to-Caesium handoff considerations, testing and exit criteria. Its sequence is:

1. Inspect one real block and loop across AIL and both target lowerings; choose
   existing strong-sequence boundaries and specify useful midpoint relations.
2. Implement the restricted breakpoint AST and explicit resumable driver phase,
   including unsequenced contexts and saved-continuation reconstruction.
3. Emit source-origin sites from the owned lowering and demonstrate actual
   midpoint states, residuals and the intended sequence-rule premises.
4. Differentially test ordinary Core, automatic-continuation Nice and paused/
   resumed Nice, including injected defects; review the resulting checkpoint.

Breakpoints do not imply lexical scope, dominance, atomicity or a proved source
state relation. Source-aligned composition sites and internal machine cuts have
separate roles and coverage. No whole-state serialization or additional source
compiler is required. The initial goal is a useful, testable design for later
compositional proofs; broad proof generation and general equivalence remain
separate work.

## Work and adoption

Use milestone branches/worktrees against the research integration branch in
cerberus-lean. Develop and review there; the parent planning branch is not the
implementation base. A future consumer adoption follows the existing exact-pin
chain through refinedc-lean, with validation of the adopted interfaces. There
is no temporary dependency override or simultaneous work in installed sources.

Run focused builds and behavior/instrumentation checks during construction.
Draft integration is not a mainline landing or general theorem claim. Full
relevant trust checks apply at an actual landing/shipping/claim point. Pushing
requires explicit approval at the point of action.

## What to reuse from the archive

Archive in the cerberus-caesium parent repository:
`archive/cerberus-nice-driver-prototype-20261114` at
`1b1994876c0eb42a71dea27b16f54bac1f2712a4`. Its combined diff against main has
about 7,400 implementation/test lines, plus documentation. None of those runtime
results establishes the AST/driver requested here. Keep Git history for recovery;
do not carry raw captures, reports or old build directories into the new work.

| Old component | Disposition and reason |
|---|---|
| Development policy changes | Carried over on the parent planning branch; the same agreed distinction between iteration and shipped proof trust governs this experiment. |
| `QuotePipeline.lean` typed-AIL/supply split | Reference for the common typed-AIL/supply boundary. Prefer the provider's complete frontend recipe; copy only a justified small helper, not the old Nice stack. |
| Four C fixtures in `tests/cerberus-nice` | Reuse useful inputs/expectations with attribution. Loop/helper and jump fixtures remain useful without claiming their old scope interpretations. |
| `Nice/Metadata.lean` origin/predecessor ideas | Reference for later Nice checks; adapt selected logic only after the new syntax/binding contract exists. Not a complete correctness argument. |
| `Nice/Driver.lean` and `Entry.lean` | Sequencing/reference material only. CoreNice starts from the complete pinned provider path, not these already altered wrappers. |
| `DriverCutpoints.Program`, Nice runtime/explorer/checkpoint wrappers | Do not import as the program AST or execution foundation. The cutpoint abstraction also predates this prototype and is not a new result from it. |
| `Nice/Structure.lean` | Discard as architecture; it is an inspection tree, not the executable language. |
| Full-state `State`/`Observe`, `nice-compare.py`, serialization tests | Replace. Some malformed/missing-completion test cases are useful ideas; the protocol and state dumps are not. |
| Scope tags/frontier/residency and associated runners | Park in archive. They do not establish general lexical-scope recovery or justify runtime scope checks. |
| Corpus inventory/process management | Selectively reuse simple enumeration, timeout and explicit-outcome accounting. Replace the comparison and recipe policy. Avoid importing the old reporting framework wholesale. |
| Old architecture assessment and dummy-type report | Reference material in the archive; recheck technical claims before republishing. The type-metadata refusal option remains in the new design. |
| Old smoke/corpus numbers and blanket build results | Historical evidence for the old program only. Never transplant them as validation of this restart. |

Default is **no implementation cherry-picks**. Recover a small piece only when a
milestone needs it and its assumptions have been checked. Archiving preserves
useful knowledge without making the old architecture a dependency.
