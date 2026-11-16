# Roadmap: establish CoreNice, then modify it into Nice

Roadmap, 2026-11-14; [current implementation progress](README.md#current-evidence-and-next-experiment)
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

## After CoreNice: breakpoint syntax and checked jumps

Add the two genuine syntax features to the working interpreter, one at a time.
Define `StrongTail := Continue NExpr | Breakpoint id NExpr` and use it as the
continuation field of Nice strong sequence, as specified in the design. There
is no generic checkpoint expression. For tests, replace selected `Continue`
tails of existing strong sequences with `Breakpoint` tails. All other positions
remain unchanged; do not introduce new strong sequencing or reconstruct lexical
scopes to make a desired pause possible. Test that malformed input placing a
breakpoint as an ordinary operand/alternative is rejected by the AST decoder.

Add `run` and `resume` APIs that keep the suspended state in memory. Reaching
the breakpoint means the original left-completion rule has succeeded, including
pattern validation, environment update and `Eannot` propagation. Its annotated
right continuation has not executed. Preserve both completion cases in
`core_reduction.lem:437–462`. Breakpoints do not consume semantic choices or
become runnable alternatives. Retain underlying Core-like ND nodes;
breakpoint/pause/resume records have their own channel and are erased for
correspondence testing.

The suspension stores continuation, context and driver phase as data. In
particular, if the strong-sequence completion occurs during nonmemory
advancement, resume continues that phase; it does not restart scheduling or
repeat an already-consumed ND pick. If the original semantics would next
schedule another choice, that choice still happens once. Do not force the right
continuation ahead of its unsequenced siblings. This requires an explicit
resumable driver phase, not an opaque closure of the complete driver. The AST
restriction locates the boundary; retaining phase makes resumption faithful.

Include a strong sequence containing a breakpoint nested under an unsequenced
expression. Compare pause/no-pause runs for each tested choice path and verify
that candidate order, choice count and retained events do not change. Use a
right continuation and sibling containing C helper calls with visible effects
on disjoint objects, and first confirm the original run exposes a competing
choice at this point. Plain disjoint loads/stores may instead be advanced
greedily by `can_advance` (`driver.lem:918–944,1073–1101`); do not demand a
scheduler choice where the original has none. When the original offers both
alternatives, both must remain eligible at the corresponding decision after
resume. This is a
valid syntactic placement; an arbitrary breakpoint as an unsequenced operand
is not. If the driver cannot yet preserve the phase in this case, report a
failed milestone and resolve the machine design, rather than broadening erasure
or adding a generic placement validator.

Demonstrate a pointer-mutating helper, a loop with repeated breakpoint visits,
pauses at available strong-sequence boundaries around effects, and uninterrupted
versus every selected pause/resume schedule with the same choices. Failure/UB
before the boundary produces no breakpoint; failure/UB after resume remains
visible. Pattern-match failure must not be mistaken for reaching the boundary.
Carry `StrongTail` through contexts, `apply_ctx`, boundary splitting and
negative-action/RMW reconstruction (`core_reduction.lem:857–953,1303–1378`).
For saved labels (`core_aux.lem:2312–2320`), a label in the left operand retains
the pending breakpoint in its reconstructed suffix; a jump directly into a
label in the right body bypasses the boundary. Test both routes, so repeated
loop/back-edge visits neither drop nor spuriously replay a breakpoint.
The baseline observes exactly the same memory-event suffix and final outcome.
Do not require equal step/fuel counts across these machines.

For predecessor checks, retain a static origin per jump occurrence and a label's
allowed origin set, scoped to its procedure and runtime label binding. Initially
compute conservative allowed sets from all syntactic jumps resolving to that
label; do not assert control-flow reachability or lexical scoping. A broad set
is weaker information, not an invented proof. Test forward/backward jumps,
repeated label activation and calls/recursion. Mutation tests remove a genuine
predecessor, substitute a wrong origin and use an out-of-context label binding;
each must produce `NiceFault` at the check. Valid fixtures must retain their Core
traces under erasure. No incorrect annotation is silently trusted.

Pause/resume operates independently of predecessor-set precision. If static
label binding for a form cannot be established, refuse that translation rather
than making lexical scope recovery part of this milestone.

## Then demonstrate the first Nice change end to end

The full direct AIL-to-B producer already exists. Edit its appropriate
strong-sequence sites to emit selected `Breakpoint` tails, and its save/run
sites to emit checked predecessor declarations. Keep Nice identities separate
from the Cerberus fresh-symbol supply. Do not build a second narrow AIL compiler
or translate whole functions through Core as a fallback.

Existing sites include expression statements (`translation.lem:3857–3863`),
block sequencing (`3945–3950`), while bodies/back-edges (`3994–4019`) and
function-body completion (`4690`) at the inspected provider pin. These are
source-inspected opportunities, not new execution results.

A first Nice demo uses a C program with a loop, pointer-mutating helper and
visible memory effects. The two producer paths emit distinct artifacts; the B
path now contains a real breakpoint and at least one checked taken jump. The
same harness compares retained traces under the declared administrative erasure,
including pause/resume and deliberate incorrect annotations. Preserve ordinary
next scheduling, failures and explicit coverage limits.

Use the already established CoreNice C corpus/fuzzer, adding feature-specific
cases. After semantic changes, state any admission restrictions honestly; do
not transfer the unchanged baseline's coverage or success counts automatically.
The same source/build/test infrastructure remains in use. Further Nice
abstractions are deferred until this specific change is useful and testable.

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
