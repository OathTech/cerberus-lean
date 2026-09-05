# Whole-project release-gate audit — lem-lean and cerberus-lean

Date: 2026-09-05. Author: Codex [AGENT]. Requested by the operator as a
major project gate, with permission to recommend substantial changes of
direction. This is an audit and proposed replacement sequencing, not an
authorization to change semantics or an implementation of its remedies.

## 1. Decision

**Do not declare the project stable under the current master plan. Keep
the shared-model architecture, but revise the critical path.** The project
has substantial useful engineering: executable generated semantics,
kernel-checked measure proofs, explicit supplies, concrete memory
operations, differential corpora, and a downstream Iris logic with
adequacy statements about the engine. Those are worth preserving.

The principal problem is that several different assurances are being
treated as interchangeable:

1. A proof has no additional axioms.
2. The function being proved has the intended failure and state behavior.
3. Its compiled execution agrees with the OCaml implementation.
4. That OCaml implementation agrees with pristine upstream and ISO C.
5. A downstream theorem covers the C program the customer supplied.

Each needs its own evidence. In particular, this audit reproduced a Lem
program whose OCaml execution fails, whose Lean execution succeeds even
with abort-on-panic enabled, and whose successful Lean result is proved
by `rfl` without any axioms. This is not a kernel inconsistency: it is a
translation and specification problem.

The immediate release blockers are:

| ID | Finding | Status | Goals affected |
|---|---|---|---|
| F1 | Unused pure failure is erased on Lean; OCaml fails | New runtime reproducer; underlying pure-failure problem previously identified | 2, 3, 4 |
| F2 | Fuel checker accepts unrelated/incorrect contracts | New compiled counterexamples; production policy returns success | 2, 4 |
| F3 | Main differential extractor ignores successful stdout/stderr | Reproduced; widening already owed by C-Z4 | 2, 3 |
| F4 | Fork-drift gate is red on this checkout; its coverage is weaker than the plan claims | Reproduced ordering failure; source inspection of coverage | 1, 2 |
| F5 | Oracle independence and legacy compatibility need separate gates | Architectural gap, supported by existing fork deltas | 1, 2 |
| F6 | Byte-string discrepancy remains outside the proposed critical path | Existing registered bug, confirmed in representations and probes | 1, 3, 4 |
| F7 | Semantic functions still read ambient state through pure signatures | Existing defects, confirmed in implementation | 2, 4 |
| F8 | Fuel residue/progress and well-formedness obligations are not closed | Existing limitations; master-plan remedy for `hack` is incomplete | 3, 4 |
| F9 | Current downstream proofs have not adopted current semantics | Confirmed pin and theorem statements | 4 |
| F10 | Stability criteria do not establish the stated ISO/verification goals | Plan-level gap | 3, 4 |

Goal numbers here mean the operator's current four goals: (1) minimal
impact through legacy OCaml interfaces; (2) minimal trust-surface change
and a usable Cerberus oracle; (3) ISO C accuracy; (4) iris-lean verification.
These are distinct from the differently numbered aims in VALIDATION.md.

## 2. Scope, method, and evidence limits

Inspected mainlines:

| Repository | Revision |
|---|---|
| cerberus-lean | `9a7f7ad31` (master-plan documentation head; plan identifies semantics head `56b3c9e90`) |
| lem-lean | `f6542f8e6860d12d4655e6648bc4c45dabd1d798` |
| refined-cerberus | `8eeaf92` |
| refined-cerberus's semantics pin | `f95ef8d9c317fa6b50cf6691216a8c37b1d3eabf` |
| deps/lem-pinned and Cerberus Lake LemLib pin | `f6542f8e6860d12d4655e6648bc4c45dabd1d798` |

All three mainline working trees were clean at the start. No implementation,
baseline, dependency pin, or master-plan edits were made for this review.
Build products were regenerated/rebuilt as necessary. Audit artifacts are
the additions under this docs directory. No branches were merged or pushed.

The review follows the four assurance chains through the model/backend,
runtime seams, gates, and consumer statements. It is a cross-project
architecture and implementation audit with targeted executable attacks,
not a claim to have inspected every line of either compiler or proved
ISO conformance. Earlier audits are inputs, not substitutes for the
checks reproduced here. No fresh-noodler convergence exercise or
concurrency-branch certification was performed.

Key durable reproducer artifacts are in
[the evidence directory](2026-09-05_whole-project-audit-evidence/README.md).
Full local command logs are under the container project's
`.review-evidence/2026-09-05/`. Source line references below are for these
revisions; many generated files are gitignored build artifacts.

## 3. Findings and required remedies

### F1 — Pure failure values do not preserve strict failure semantics

**Release blocker.** The following actual Lem input was generated for both
targets using the rebuilt `lem-lean` binary:

```lem
open import Pervasives_extra
let discarded (n : nat) : nat =
  let x : nat = failwith "review discarded failure" in n + 1
```

OCaml retains `let x = failwith ... in n + 1` and the compiled OCaml
program exits 2 with `Failure("review discarded failure")`. Lean emits
`let x : Nat := failwithI ...; n + 1`. Running its main with
`LEAN_ABORT_ON_PANIC=1` both through capped `lean --run` and as a
Lake-built native executable on Lean 4.32.2 prints `1` and exits 0.
The following theorem also checks:

```lean
theorem discarded_succeeds (n : Nat) : discarded n = n + 1 := rfl
-- does not depend on any axioms
```

This is an actual Lem runtime-parity discrepancy, not just a hypothetical
theorem about an unreachable C state. This audit has **not** established
a C-reachable example of this exact unused-let shape. The source and both
outputs are preserved in the evidence directory.

Cause: [LemLib.lean](../../../lem-lean/lean-lib/LemLib.lean), lines 154–191,
represents failure as an ordinary value behind `opaque`/`implemented_by`.
Opaque prevents unfolding; it does not impose strict evaluation or
propagate failure. A result that is unused need not be evaluated at all.
`never_extract` and the process's abort flag cannot repair the logical
equation above. Similar scrutiny is necessary for unused function
arguments, tuple projections, ignored monadic results, and instance calls.

The [typed-failure design](2026-09-05_typed-failure-outcomes-design.md)
already identifies discarded values as a problem (around line 565).
Its R1 approved scope deliberately leaves the pure group at interim
`panic!` → `failwithI` cleanup plus a register. That is an honest interim,
but **cannot be a completed release remedy** for this finding.

**Action:** introduce a Lean-target fallibility analysis and explicit
failure propagation, preserving the original OCaml target and evaluation
order. The first vertical slice should cover this small probe, ordinary
lets, applications, and tuples, before tackling the real `hack`/`finalize`
path. A generated `Except`-style internal worker plus bind-based sequencing
is a plausible mechanism; exact failure types must follow the approved
outcome design. A convenience wrapper may expose a value only under a
checked success/precondition contract. Do not wrap a failing computation
back into an arbitrary inhabitant and call the defect closed.

Until a construct is supported, reject affected Lean generation with a
specific diagnostic, or prove that failure cannot occur under the public
entry's actual preconditions. Refusal is an interim availability limit,
not full support. Merely registering a reachable failure is insufficient.

**Acceptance:** compiled two-target regressions for unused lets and
arguments, nested tuples, both branch orders, and failures inside supplied
callbacks; kernel theorems that failure propagates; successful programs
retain results; the nine-emitter non-Lean golden suite is unchanged.
Add the reproducer to Lem's normal failure-parity suite. No XFAIL is an
acceptable final closure for this case.

### F2 — Fuel classification is not checking the contracts it reports

**Release blocker for assurance claims.** In
[FuelFormsTool.lean](../test/Unit/FuelFormsTool.lean):

* `obligationShape` (lines 132–174) checks names and some binder occurrence,
  but does not require the worker and wrapper to receive corresponding
  inputs, nor establish that the lower bound is the wrapper's actual measure.
* The ABSORBING path (lines 284–298) examines constants mentioned anywhere
  on a theorem's RHS. It does not check the LHS names the worker at zero,
  require the RHS to have the correct semantic structure, or check this
  theorem's axiom cone in that branch.

Two compiled, axiom-free decoys were accepted:

1. `review_bad_lemFuel fuel := fuel`, with a theorem named
   `review_bad_lemFuel_zero` about **CerbND.runNDFuel**, was classified
   ABSORBING. The function actually returns a natural number.
2. `review_shift_lemFuel fuel x := x - fuel`, wrapper
   `review_shift x := 0 * x`, and a proved equation
   `review_shift_lemFuel lemFuel 0 = review_shift x` under `0 ≤ lemFuel`
   was classified MEASURED. The equation says nothing about the required
   worker input `x`; e.g. input 10 at fuel 0 is 10, not the wrapper's 0.

Importing the decoys using the existing instrument's extra-module hook
made the **actual production policy exit successfully**, reporting 83
workers, 55 MEASURED and 14 ABSORBING. These two added workers were
unreachable from the real driver. This result establishes unsound
classification/contract checking; it does **not** show the current 54
measure proofs are false or that a new bad worker entered the driver.
The unmodified instrument reports the recorded 81/54/13/8/6 counts.

Even a correctly checked zero equation is not itself a proof of fuel
monotonicity: a successor case can inspect or recover from a failed
subcall. “Returns the kill at zero” and “propagates exhaustion through
the whole computation” must be separate claims.

**Action:** emit typed metadata with each worker: worker/wrapper names,
argument mapping, measure, optional precondition, failure contract and
the exact proof obligation. Have the gate reconstruct that full type and
check definitional equality after telescope instantiation. Avoid
pretty-printed string equality as the ultimate identity of a proposition.
For hand-written workers, register the same typed contract. Verify axiom
cones for every contract, not only MEASURED contracts. Check reachable
declarations independently of `_lemFuel` name conventions.

Split the current label into `ZERO_IS_FAILURE` and genuinely proved
propagation/stability properties unless propagation is independently
certified. Prove the relevant monad bind laws and the actual worker
completion/stability theorems, or explicitly report them pending.

**Acceptance:** both attached decoys fail for their specific wrong
contract; add wrong fuel position, swapped arguments, misleading RHS
subterms, changed wrapper measure, hidden additional premises, and
renamed-worker plants. All existing real obligations still pass after
an independent review of their statement-to-worker correspondence.

### F3 — Successful output bytes are lost in the main differential lane

**Release blocker for whole-line agreement.**
[test_exec.sh](../../scripts/test_exec.sh), lines 362–366, extracts
`Defined {value: "..."` only. Lines 643–668 compare those tokens and report
MATCH. The extractor from the real script maps both of these to
`VAL:Specified(0)`:

```text
Defined {value: "Specified(0)", stdout: "GOOD", stderr: ""}
Defined {value: "Specified(0)", stdout: "BAD", stderr: "WRONG"}
```

Thus the master plan's blanket “whole-line verdicts ... stdout bytes”
description overstates this lane. Undefined-line widening does not fix
Defined lines. C-Z4 already owes this change; it must precede any
convergence result that relies on the affected lanes.

**Action:** compare complete successful verdicts now; subsequently use a
shared structured verdict codec that preserves byte payloads, outcome
order/multiplicity according to the lane's explicit contract, UB code
and location, and exit consistency. Keep raw captures for diagnosis.
Version the codec and identify every normalization. Do not silently
change sequence comparison into set comparison during this repair.

**Acceptance:** same-value/different-stdout and same-value/different-stderr
plants fail in each affected lane, including embedded NUL/high bytes,
escaping, multiple outcomes, output-before-failure, and print-then-crash.
Re-record affected baselines in a dedicated instrument change and triage
every newly exposed discrepancy before reusing “zero movement.”

### F4 — The current fork gate fails, and does not pin all oracle content

**Release blocker.** After a full successful Cerberus Lake build, all six
unit executables pass, and the suite reaches the fork-drift gate, which
fails at [check_fork_drift.sh](../../scripts/check_fork_drift.sh):91–100.
The live and manifested filename **sets are identical: 71 each**. The
manifest's `[files]` section is not byte-sorted (seven inverted adjacent
pairs), while the live list is sorted. Repeating under `LC_ALL=C` does
not fix it. `comm` also reports an unsorted input. This is a gate defect,
not evidence of seven actual new source changes.

An independent read-only comparison of the two generated OCaml trees
found identical file sets and exactly the 22 registered diff hashes,
with no hash mismatch. This supports the content status of the existing
trees; it does not make the failing production gate green, nor prove
that the pristine tree was freshly generated with pristine upstream Lem.

Two further scope problems are evident in the script:

* Layer 1 pins filenames, not the contents of hand-written oracle paths.
  Changing behavior inside an already-listed `util/cerb_fresh.ml` or
  `ocaml_frontend/fork_renumber.ml` need not move either that filename
  list or generated OCaml hashes. Driver freshness hashes show what
  was built; they do not approve its compatibility with upstream.
* Missing upstream ref/tree returns **exit 0** (lines 62–70, 117–123).
  The text says this is not a pass, but the unit caller only sees success.
  The attempted missing-tree plant here stopped at the earlier ordering
  defect, so the skip branch is a source-confirmed issue, not an executed
  skip-branch reproduction in this audit.

The master plan also calls the generated tree “byte-identical to
upstream's lem output” while the manifest explicitly has 11
`expected-semantic` and 11 `expected-cosmetic` deltas. The supported
claim is **unchanged reviewed deltas**, not identical generated trees.

**Action:** canonicalize both lists using a fixed locale and enforce
duplicate detection; pin normalized content deltas for every reviewed
oracle source/build/runtime surface; make absent comparison prerequisites
fatal in release mode. Permit a distinct development skip result only
where it cannot be consumed as release success. Clarify or validate the
manifest's stale `lem-pin=af5df71` metadata against the current pin.

**Acceptance:** the unmodified current tree passes after only the
instrument correction; missing ref/tree and a behavior change inside an
already-listed hand-written oracle file fail. Reviewed generated deltas
remain exactly the same. Never refresh the manifest indiscriminately to
make this failure disappear.

### F5 — Protect legacy clients and preserve an independent oracle

**Architecture release requirement.** VALIDATION.md explicitly defines
the working oracle as the **fork's** OCaml implementation. The manifest
and source show model changes and compensating OCaml target representations.
For example, `ocaml_frontend/fork_renumber.ml` restores upstream's ambient
symbol allocation on the OCaml target while Lean keeps explicit supplies.
`util/cerb_fresh.ml` explains the historical collision defect and repair.
These are useful reviewed repairs, but they are a real trust surface.

Sharing `.lem` source is valuable structural evidence. Target-specific
representations and transformations mean equivalence is not obtained
“by construction” merely from sharing that file. Comparing two targets
that share a changed model can miss a common semantic regression.

The freshly rebuilt Lem non-Lean regression suite passes **893 artifact
rows, 216 exit rows, nine emitters**, byte-identical to its goldens. That
is substantial compatibility evidence. It tests the existing corpus and
golden baseline, not all legacy source programs, all embedding APIs, or
the whole delta from upstream Lem. New grammar keywords and shared AST/
type-checking paths deserve explicit old-program compatibility tests.

**Action, now:** maintain three explicit comparisons:

1. Pristine Cerberus + its independently identified upstream Lem/toolchain.
2. Fork Cerberus OCaml + fork Lem.
3. Fork Cerberus Lean + exactly pinned LemLib.

Require 1↔2 for legacy/oracle compatibility, and 2↔3 for port parity.
Use compiler executions and standards evidence as additional checks with
different failure modes, not as a replacement for 1↔2. Classify oracle
failures separately from agreement. Exercise old command-line modes,
library compilation/linking, existing exported types/functions, other
memory backends, and mixed-target Lem generation in one process.

**Architectural direction:** freeze further shared `.lem` body changes
for Lean plumbing. Develop target-local lowering for state, readers,
failure, and termination where needed. Start with one real shared-model
delta and show that moving the transform into the Lean backend can remove
its OCaml compensation while preserving all three comparisons. If the
spike cannot preserve interfaces and behavior, keep the reviewed shim;
do not attempt an unbounded wholesale rewrite on principle.

**Acceptance:** a finite, reviewed oracle delta inventory, content-pinned
and covered by pristine-vs-fork execution/API checks; upstream-Lem
compatibility established separately from fork-golden invariance. A
change affecting both reference and candidate must trigger an independent
comparison rather than being accepted because their answers still match.

### F6 — Byte strings are a required correctness milestone

The existing [string representation design](../../../lem-lean/doc/lean-backend/2026-09-03_string-representation-design.md)
identifies the problem correctly: Lem's OCaml strings/chars carry bytes;
the current Lean representations use Unicode `String`/`Char`. The two
registered parity probes `p_str_bytes` and `p_str_escapes` cover actual
differences. For example, UTF-8 `é` has OCaml byte length 2 but Lean scalar
length 1, and a lone byte 0xC8 cannot round-trip through a Unicode scalar
representation as the same byte string.

L4 is listed in the plan but absent from its proposed sequence and its
stable definition. Consequently that definition can be satisfied with
a known ordinary Lem representation discrepancy still present.

**Action:** make L4 required before general-backend stability. Adopt the
already-designed byte-string/byte-char representation. Keep text decoding
explicit at JSON, diagnostics, filesystem names, and user-facing text
boundaries. Trace C literal, libc/printf, memory, and verdict paths rather
than assuming the entire C pipeline has the same exposure as generic
Lem strings. Integrate the byte-preserving verdict codec from F3.

**Acceptance:** remove both XFAILs after they pass; test every char byte,
embedded NUL, invalid UTF-8 sequences, ordering, indexing, concatenation,
and escape/JSON round trips; rerun Cerberus byte/libc/printf lanes and
downstream compilation. OCaml outputs and interfaces stay unchanged.

### F7 — Remove ambient state from the certified semantic interface

Confirmed in [CerberusImpl.lean](../CerberusImpl.lean):55–75, 268–285:
`enumRegistryRef` is a process-global `IO.Ref`, and pure-signature
`typeof_enum`/`register_enum` reach it through unsafe implementations.
`sizeof_ity` and memory/layout code depend on these operations. A theorem
about a pure function of a symbol cannot identify which runtime registry
that symbol will be looked up in. Clients authoring Core also do not
automatically execute the C frontend's registration phase.

Confirmed in [CerberusFresh.lean](../CerberusFresh.lean):110–120: `digest`
has a pure signature and an opaque witness but reads mutable native
state at runtime. `forceIO` and extraction barriers manage evaluation
ordering; they do not turn the runtime into a function of the public
arguments. The unsafe/opaque MemValue comparison in
[CerbMem.lean](../CerbMem.lean):224–240 is a separate executable/proof
boundary. The earlier reasoning-artifact audit already records these.

**Action:** carry enum interpretation as data with the semantic
environment; carry a TU digest through frontend reader/state lowering;
mint Core-text symbol numbers from the explicit supply with an interning
map. Remove the effectful read/barrier machinery when its last caller
migrates. Replace MemValue equality with a transparent recursive or
measured implementation and its correspondence laws. Actual I/O and
native primitives may remain outside the pure model under explicit
contracts; do not spend effort merely changing `axiom` into an opaque
inhabitant to reduce a count.

**Acceptance:** reentrant two-environment enum/digest tests, different TU
processing orders, repeated frontend/library calls, symbol uniqueness
and deterministic interning tests, kernel equations for layout/equality,
and differential output preservation. The semantic entry's transitive
closure contains no hidden mutable read, with a separate inventory for
real native/IO boundaries. Retain typed, attributed refusal for features
outside the supported profile.

### F8 — Finish fuel semantics, rather than only its census

The checked source register still contains eight reachable ambient
workers. Seven measured rows require hypotheses, six involving acyclic
tag environments. `fuel_hypotheses.txt` explicitly limits its frontend
argument to programs “accepted correctly” and records an accepted
`_Alignas` counterexample. This is not a machine-checked invariant for
every value the frontend can produce. It is appropriate to expose a
hypothesis, but consumers must establish it.

The plan's §3.3 groups `hack`, `many`, and `many1` under “they are
monadic/partial” and proposes typed absorption. **`hack` actually returns
the pure Core `value` type** (`generated/Driver.lean`:433–440), as the
failure design also records. Its caller `finalize` returns a pure
`driver_result`. A `failure_outcome` annotation restricted to existing
monadic result types cannot by itself close that path. This is a real
dependency on F1's pure failure lifting, a checked precondition, or a
separately justified transformation.

The `are_compatible` trio is registered as an upstream nontermination
problem on legal cross-TU recursive pointer types. Leaving it pending
may be faithful to the existing oracle, but cannot constitute complete
support for those valid inputs. The fresh-noodler exit must not hide
such a row just because both engines fail.

**Action:** distinguish and deliver three properties:

* Every finite execution returns either a legitimate semantic outcome or
  explicit exhaustion/failure, never an invented ordinary value.
* Once a particular execution completes, increasing fuel preserves its
  appropriate semantic result/trace observation. For nondeterminism,
  state the observation precisely; more fuel can resolve previously
  exhausted branches, so raw outcome-list equality is not automatic.
* For a terminating supported execution, a sufficient budget exists.
  Provide concrete bounds for the release examples and a compositional
  theorem where feasible. A universal “success or exhaustion” theorem
  alone does not prove that any budget succeeds.

For tag environments, add a checked validator or a proof-producing
frontend contract and require its evidence at certified entry points.
Prove linking/renaming preserves the property actually used by layout.
A validator may establish the acyclicity precondition; it is not a
substitute for repairing missing C diagnostics. For `are_compatible`,
prepare the upstream coinductive/visited-pair compatibility remedy with
both positive and negative recursive-type examples. A local semantic
fix still requires its own ruling; this audit recommends resolving it,
not silently granting an exception to the shared-body rule.

**Acceptance:** empty reachable fail-open register for the certified
profile; all hypotheses discharged at its actual entry; regression
tests for the legal recursive-type case; measured bounds for nontrivial
terminating driver examples; real propagation and stability proofs.
An explicitly unsupported profile can be an interim milestone, but is
not closure of the broader ISO goal.

### F9 — Make consumer integration a release gate

`refined-cerberus/scripts/semantics-pin.env` still pins `f95ef8d9c`, and
the inspected `Adequacy.lean`/`ProdLoop.lean` statements still mention
`lemDefaultFuel` and `CerbFuel.driverFuel`. The architecture document
openly describes this. Current consumer proofs therefore do not yet
validate the changed `[LemFuel]` interface, measured layout hypotheses,
or this mainline's configuration changes. This is integration work
owed, not a claim that those older proofs are invalid.

The consumer also deliberately proves a Core fragment, with production
exhibits wrapping authored Core as synthetic files. Its normative
architecture distinguishes those statements from C-source coverage.
This is a sound foundation for expansion; do not advertise it as an
end-to-end proof about arbitrary parsed C.

**Action:** establish a cross-repository candidate pin before calling
the semantics stable. Re-pin and port the consumer's generic adequacy,
total examples and layout proofs. Provide a small versioned public
proof interface: semantic environment, memory/map laws, fuel contracts,
entry/observation definitions, and failure classification. Keep proofs
over the existing shipped semantics, not a replacement trusted mirror.

Add at least two real C-source integration examples: one loop/call and
one allocated struct with layout and lifetime reasoning. Preserve
source, Cabs/Core artifacts and toolchain/configuration identity; prove
the exported theorem about that exact engine input. State the remaining
trusted frontend translation boundary explicitly. Include a negative
example that cannot be certified after a UB-inducing source change.

**Acceptance:** clean pinned builds and theorem audits across all three
repositories; the new API is exercised by the actual Iris consumer;
source-to-artifact identity is checked; no synthetic-Core-only example
is counted as a C-source proof; success examples have sufficient-budget
evidence, not solely permission to exhaust.

Include a toolchain compatibility matrix: Lem's own `lean-lib` and
comprehensive test package currently pin Lean **4.28.0**, while Cerberus
pins **4.32.2**. Both versions were exercised in this audit through their
respective packages; success on one is not a substitute for testing the
other. Either explicitly support both or align them deliberately, with
the failure/parity and proof suites run on the consumer's version.

### F10 — Define stability against a coverage contract and multiple evidence sources

No finite zero-discrepancy corpus, nor one fresh adversarial pass,
establishes total ISO C accuracy. Furthermore, the current plan can reach
its stable definition while strings, hidden state, pure failures and a
legal-input compatibility loop remain open. Upstream issue filing is
useful coordination but should not be confused with semantic closure;
conversely a delayed network filing should not be the sole blocker for
an otherwise completed technical release.

**Action:** retain ISO accuracy as the full project goal. Define an
explicit intermediate release profile: exact C standard/draft and defect
report policy, implementation/ABI, memory model/provenance policy,
library subset, configuration, frontend modes and concurrency support.
For each feature and exceptional case record implemented/validated,
unsupported with attributed refusal, upstream defect, or open port bug.
An unsupported item remains unfinished work toward the full goal.

Build a standards coverage matrix with clause/topic → model location →
positive/negative/boundary tests → independent evidence → known defect.
Prioritize integer conversions/overflow, character and byte behavior,
object lifetime and provenance, effective types/aliasing, alignment and
recursive types, evaluation order/unsequenced UB, floats, linking and
libc. Concurrency needs its own model-specific closure; SC-DRF work is
not all C concurrency. Shared parser mistakes need independent diagnostic
tests, since both candidate and working oracle use that parser.

For nondeterminism, validate outcome/trace coverage as well as individual
successful runs. `runND1` deliberately chooses branch zero; do not
interpret its agreement on an example as evidence of complete behavior.
Use exhaustive small tests and an explicit selection contract for sampled
traces. Compiler results are useful witnesses on defined programs under
matching implementation assumptions, not an authority for interpreting UB.

**Acceptance:** every release claim maps to a reproducible check and its
limitations; every known failing/unsupported feature is visible; no
untriaged semantic discrepancies inside the declared release profile.
Retain the fresh-noodler pass as an additional challenge after the
instruments and obligations are repaired, not the definition of correctness.

## 4. Proposed path to success

The following sequencing replaces “declare consolidation first, then a
fresh-noodler pass, then stable.” Effort labels are planning estimates,
not commitments: S = days, M = a focused multi-day slice, L = an arc with
intermediate deliverables. Each phase has a concrete exit and can be
reviewed independently. No semantic implementation is authorized by
the mere presence of this proposal.

| Phase | Deliverable and owner role | Exit evidence | Size |
|---|---|---|---|
| P0 — trustworthy instruments | Cerberus gate maintainer fixes F2/F3/F4; document exact claims; add a release runner | All new plants red for the right reason; unmodified tree green; one machine-readable result manifest with pins, commands, caps, skips and exits | M |
| P1 — independent compatibility baseline | Lem/Cerberus maintainers establish pristine/fork/Lean comparison and legacy API/source tests (F5) | Nine-emitter invariance plus independently pinned upstream comparisons; reviewed content delta inventory | M |
| P2 — coherent failure interface | Lem maintainer implements pure-failure vertical slice; Cerberus maintainer migrates monadic sites and `hack`/`finalize` path (F1/F8) | Strictness probe fixed; transparent failure propagation; no reachable unaccounted failure value in certified profile; OCaml unchanged | L |
| P3 — pure, faithful representations | Finish L4 bytes; enum/digest/value-equality/symbol work (F6/F7); validate layout preconditions | Byte parity without XFAIL; reentrant environments; kernel contracts; pristine/fork/Lean checks unchanged except separately ruled fixes | L |
| P4 — prove the customer can use it | Re-pin actual refined-cerberus, port generic proofs, add real C examples and sufficient-fuel evidence (F8/F9) | All three pinned trees build and certify the examples; negative examples rejected; published theorem assumptions are discharged | L |
| P5 — profile release, then broader ISO closure | Standards matrix, remaining C-Z4 integrations, recursive-type remedy, full battery, independent adversarial review | Release profile passes the gates below; every remaining broader feature has a scoped implementation path | L |

P1 can begin once P0's observations are trustworthy. Design the byte and
environment migration interfaces before P2/P4 lock in a public API.
Use small cross-repository candidate pins during P2–P4 rather than a
single disruptive final re-pin. Run the relevant existing lanes at each
slice; reserve the whole expensive battery for semantic boundaries and
the final unchanged candidate.

### What to change in the current master plan

* **C-Z4 instrumentation moves first**, especially Defined-line widening,
  probe integration and the unclassified oracle/time/resource rows.
* **C-RM starts now as a baseline and repeats after surgery.** Waiting
  until after design choices misses its chance to influence those choices.
* **L1 is split.** Syntax consolidation and documentation are useful
  upstream preparation. Converting explicit readers into typeclass
  parameters and adding failure propagation are real API/semantic
  transformations, not just renaming. Freeze the consolidated vocabulary
  after the failure/environment vertical slice proves its requirements.
  Do not require byte-identical Lean output for a change that intentionally
  changes binder structure; require the stated correspondence and consumer
  tests instead. Continue requiring non-Lean invariance.
* **C-TF1's approved interim remains useful but cannot close F1.** Give
  pure-failure lifting a scheduled successor and a decisive executable
  test. Correct the `hack` task's type/route in §3.3.
* **L3 is decomposed:** typed contract checking, monad failure laws,
  actual worker completion/stability, then general automation. Do not
  block useful hand-proved engine contracts on a universal generator.
* **L4, C-B/C-C and relevant C-D/E/F/G/I work join the critical path**
  according to the release profile and consumer cone. A known ordinary
  representation bug cannot be omitted merely because another task is
  easier to schedule.
* **Consumer adoption becomes an explicit phase and exit**, not a
  hand-off mentioned under “other parties.” L5 laws should be delivered
  in the order the ported consumer actually requires them.
* **Concurrency stays separately gated.** This audit does not approve
  its branch, its known fixes, or a changed memory-model trust story.
* **C-N2 follows completed gates and the new consumer pin.** Findings
  return to the owning phase; absence of findings is bounded evidence.
* **L7/upstream filing is a parallel delivery milestone.** Prepare an
  upstream-reviewable series and filed reports, but distinguish source
  correctness, API stability, and network/publication completion.

### Replacement technical release gate

The project can make an honest stable-profile claim when all of these hold:

1. Rebuild all relevant generated code from identified compiler binaries;
   cleanly build the three pinned projects. Unit, proof and freshness
   gates pass without skipped prerequisites. No historical “green” claim
   substitutes for this run.
2. Legacy source/API tests and pristine-vs-fork OCaml checks pass; every
   intended delta has evidence and a reviewed content pin.
3. All supported failure/exhaustion paths have semantic outcomes or
   proved entry preconditions. Correctly typed contracts certify the
   measured and propagating paths. Registered fail-open sites are not
   counted as closed.
4. Bytes, mutable-state removal and well-formedness requirements are
   exercised end to end; all entry assumptions of the certified profile
   have evidence.
5. The actual Iris consumer builds against this candidate and proves
   meaningful positive/negative C-artifact examples with fuel adequacy.
6. The corrected full Tier A/B battery and required Tier C artifacts
   are current at the same candidate. All semantic differences and
   incomplete rows are accounted for by the explicit profile; a skip,
   timeout, kill or common failure is not agreement.
7. An independent adversarial pass examines both C behavior and the
   statement/implementation correspondence of the proof interface.
   New findings are resolved and the affected battery rerun.

This gate is a path to a dependable usable semantics and verification
platform. Broader ISO coverage then advances feature by feature through
the same gate, rather than requiring another redesign of the trust story.

## 5. Verification performed in this audit

The final results and commands are recorded in the evidence directory.

| Check | Result in this run |
|---|---|
| Lem `make`, then `make nonlean-regress` | Exit 0; 893 artifact rows / 216 exit rows / 9 emitters |
| Lem comprehensive `make lean` after rebuild | Exit 0; 54 generation inputs pass; 36 parity probes, with 4 registered deviations: 2 numeric runtime-limit rulings and 2 byte-string bugs |
| Cerberus full capped `lake build` | Exit 0 |
| Cerberus `test_unit.sh` after full build | Exit 1 at fork-drift ordering; all 6 executables pass; preceding fuel selftest and policy pass |
| Minimal / coverage / debug / float baselines | Exit 0 each; 106 / 212 / 90 / 69 inputs; oracle skips 3 / 13 / 4 / 0 respectively, never counted as matches |
| Bytes / multi-TU / libc / CN | Exit 0 each; bytes 9 exec + 5 negative pins; multi-TU 2; libc 12; CN 213 (207 MATCH + 6 UB_MATCH) |
| Independent generated-OCaml hash comparison | Identical file sets; exactly 22 registered deltas; no diff-hash mismatch |
| New strict-failure probe | OCaml exit 2; Lean interpreted and native exit 0, print 1; success theorem has no axioms |
| New fuel decoys | Both misclassified; actual policy exits 0 with extra modules |
| Verdict extractor plant | Different stdout/stderr collapse to identical token |

Two initial failures were artifact-preparation problems: the existing
Lem executable could not parse newer test syntax; the existing Cerberus
auxiliary artifacts did not expose newly added proof constants. Rebuilding
Lem and the full Cerberus Lake package resolved those issues. They are
not reported as current semantic defects. The fork-manifest ordering
failure persists after the rebuild.

This audit does not certify the full Tier A/B/C ladder. In particular,
the full csmith corpus, gcc second-oracle sweep, libxml2 batteries,
complete CI sweep, consumer rebuild/re-pin and concurrency review were
not part of this run. Running those before repairing demonstrated blind
spots would not close the findings above. The final release must run
them under the corrected instruments.

## 6. Decisions proposed for the operator

Approve the replacement technical gate and sequencing in §4; keep
upstream publication as a separate milestone. Schedule a pure-failure
lowering vertical slice and the actual consumer adoption before backend
syntax cleanup is considered complete. Retain the current no-unreviewed
OCaml/shared-model-change rule, with a separately reviewed path for true
upstream ISO defects such as recursive compatibility.

The recommendation is to strengthen the existing generated-semantics
approach, not replace Cerberus or trust a new handwritten C semantics.
Concentrate proof effort on the correspondence and entry contracts the
customer relies on, while protecting the independent upstream oracle
and making each new release claim directly testable.
