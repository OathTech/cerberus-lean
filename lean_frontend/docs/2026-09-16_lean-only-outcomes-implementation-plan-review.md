# Review of the Lean-only outcomes implementation plan (2026-09-16)

**Status:** [AGENT] Follow-up design review requested by the user; recommendations,
not implementation or merge authorization. Reviewed the
[implementation plan](2026-09-16_lean-only-outcomes-implementation-plan.md) at
`bfca41724d43b526604a0f0f30b1f629eb8d8b92`, its checkpoint record, protocol
addendum, charter and errata, and preserved evidence. Source references use
mainline `721b1c2c7` unless explicitly identified as the S0 prototype
`8f8c4dfe7` or pinned Lem `f6542f8`. Selected consumer checks use
refined-cerberus `6be4b822b379f085233806fedb900db79d0bd453`.

**Assessment: retain B and the WP0 → WP1 → WP2 sequence, but revise the plan
before treating it as an implementation charter.** S0 substantially improves
the feasibility evidence. The remaining problem is not the datatype extension.
It is the proposed traversal contract and the inference from a Lean value
equality to unchanged native OCaml behavior. Both have concrete counterexamples.
WP0 also needs a precise, tested specification beyond adding a census flag.

| Priority | Finding | Needed before proceeding |
|---|---|---|
| P1 | An earlier `Undef`/`Error` hides a later stop in the proposed collector | Make an encountered stop survive the entire traversal, or explicitly weaken the outcome contract and justify that different design |
| P1 | The native traversal rewrite can change behavior without producing any stop | Account for eager callback evaluation and action construction; prove the applicable purity restriction or preserve those operations |
| P1 | WP0's general exclusion behavior does not follow from the cited tier-2 rule alone | Specify aliases, tier-1 types, containers, mutual blocks, and demand checking; test the promised outcomes |
| P2 | The protocol migration omits the shell prefilter and CLI action contract | Add those interfaces and mixed-stop classification to the work list |
| P2 | The declared fence omits an existing test that names the deleted atom | Include `NDFuelStabilityTest.lean` and the already-mentioned speclab tests explicitly |
| P2 | Gate acceptance is weaker than the intended structural guarantee | Test nested decoys and actual missing-arm detection, not only simple wrong reasons |

P1 means a contract or implementation approach should change before the affected
package is authorized as written. These are bounded repairs; they do not
justify abandoning the shared outcome design or implementing the entire parked
pure-failure project first.

## What S0 settles well

The production-type probes support the main representation decision. They also
correct the scope of the default hazard: it affects `Undefined.t` at an
unconstrained payload; `kill_reason` keeps its unconstrained primary
`Undef0 default default`. The `skip_instances` experiment establishes that the
particular proposed escape hatch does not work. A separate, explicit default
policy in Lem is a reasonable next step.

The 13 compiler-forced Lem arms, the additional `vsnprintf` wildcard, and the
newly discovered `core_peval.ml` and `driver_ocaml.mli` edits give implementation
a much better inventory. The distinction between generated Lean's synthesized
failure arms and genuine exhaustiveness checking is important and correctly
recorded. The consumer census likewise improves on counting sentinel names:
twelve constructor-match blocks are a real migration cost.

The staged landing, exact definitional fuel alias, exhaustion-specific `NoFuel`,
consumer build against the candidate, pristine-oracle comparison, and refusal
work deferred to WP2 are all sensible. Keep those decisions.

## F1 — The proposed traversal can still hide every kind of stop

**Relevant text:** [plan R2 and S1a](2026-09-16_lean-only-outcomes-implementation-plan.md#L21);
[record S0.3(b)](2026-09-16_lean-only-outcomes-S0-checkpoint-record.md#L221),
especially its explicit exclusion of earlier legacy failures at line 245.

`collectS` ends collection when it sees `Stopped`, but callers still run the
ordinary `Undefined.mapM id` over the collected prefix. That fold selects the
first non-`Defined` outcome. Consequently:

```text
callback results: Undef; Stopped Exhausted; Exception "later"
candidate result: Undef, with the state at the stop
```

The stop vanishes. `FailStop` and `Unsupported` vanish in exactly the same way,
and an earlier `Error` also hides them. The current candidate's `mapM'_stops`
theorem assumes an **all-Defined prefix**; the adopted acceptance language does
not make that restriction.

The new [PrefixStop.lean probe](2026-09-16_lean-only-outcomes-plan-review-evidence/PrefixStop.lean)
imports the unchanged S0 candidate and kernel-checks this for **arbitrary**
`sp : interp_stop`. It also checks two useful controls: the old production
layering reaches the later exception, and replacing the intermediate stop by
`Defined` makes the candidate reach that exception too. These are local
combinator counterexamples, not an executed C-program or whole-driver fuel
counterexample.

The record argues that making a stop win over a preceding legacy failure would
violate conservativity. That does not follow. The proposed conservativity law
assumes **no stop occurs**. A traversal containing a stop is outside that
premise, even if its prefix contains legacy outcomes. Preserving an earlier
failure is therefore an additional policy choice, not something required by
`mapM'_eq_mapM`.

For the stated design goals, that choice is undesirable. It allows a computation
that deliberately stopped collecting outcomes to report an ordinary outcome
without recording incompleteness. The batch rule cannot recover information
that an adapter erased. In particular, an exhaustion-specific predicate sees
no exhaustion in the returned outcome. This does not by itself invalidate a
consumer theorem, but it defeats the intended connection between explicit
stops, completed observations, and future fuel reasoning.

**Recommended repair:** distinguish completed collection from stopped
collection in the collector's internal result. For example, collect either
`Completed us` or `Halted sp`, with the outer state and exception layer retained.
Only `Completed us` runs the legacy inner fold. `Halted sp` returns
`Stopped sp` directly, including while unwinding earlier legacy results. This
is a local control result, not a new public interpreter outcome channel.

Prove both:

- With no encountered stop, the old ordering, state, legacy UB/error precedence,
  and outer exception result are preserved.
- After any prefix that permits collection to reach the next callback, an
  observed stop survives with its reason and state; the suffix is not run.
  The prefix need not consist solely of `Defined` results.

Test earlier `Undef` and earlier `Error` against all three stop reasons, followed
by both a state update and an outer exception. A different policy remains
possible, but it needs its own observation contract; it should not be described
as unconditional stop propagation.

## F2 — The conservativity theorem does not settle native evaluation behavior

**Relevant text:** [plan §2](2026-09-16_lean-only-outcomes-implementation-plan.md#L11)
calls OCaml conservativity “trivially true (no producer)”; S1c calls all generated
changes dead code. The R2 bodies change live evaluation structure.

The old `Exception.mapM` first constructs `List.map f xs`, then folds the
results. The new recursive collector calls `f` only as it visits entries and
returns immediately on an outer exception. These are equal as values for the
appropriate total, pure functions, but not for arbitrary native callbacks that
raise or perform effects during evaluation.

A [native probe](2026-09-16_lean-only-outcomes-plan-review-evidence/NativeOrder.ml)
using S0's generated `Exception` and `State_exception` definitions and the
installed Lem runtime produces:

```text
No stops, host-failure control: old=host failure: second; candidate=typed exception: first
No stops, state-action construction: old=host failure: second; candidate=typed exception: first
No stops, callback trace: old=[2,1,0]; candidate=[0,1,2]
```

No callback constructs `Stopped`. In the first control, callback 0 returns a
typed outer exception and callback 1 raises OCaml `Failure`. The old traversal
evaluates callback 1; the candidate skips it. The state control raises while
constructing the second state action, before that action receives a state.
The trace control returns ordinary values throughout. The observed reverse
order is specific to this pinned native runtime's `Lem_list.map`; it should not
be generalized into a portable OCaml evaluation-order promise.

The test uses a reduced `Undefined` payload and a proposed stateless collector;
it is not a C regression or a compiled final Lem implementation. It does
establish that “no stop producer” is insufficient as the native preservation
argument, for both kinds of traversal. The kernel theorem is useful and remains
valid; it does not model those native effects or abrupt failures.

This matters especially here because `SEU.runEU m` receives `m` eagerly.
[Core_reduction.E.eval_pexpr2](../../frontend/model/core_reduction.lem#L43)
constructs such a call from `Core_eval.eval_pexpr_aux2`. Some evaluation can
therefore occur while mapping `f`, before running the resulting state function.
The parked pure-failure axis does not license a new rewrite to erase existing
native failures.

**Recommended implementation path:**

1. Separate constructing callbacks/results from executing state actions. For
   SEU, prototype retaining the old eager `List.map f xs` construction, then
   using a stop-aware collector over the resulting state actions. This can
   preserve the old construction behavior while halting subsequent state
   actions. State exactly which work may already have happened before a stop
   is observed. Because construction can itself evaluate expressions, this is
   a narrower guarantee than stopping every later expression evaluation. If
   the latter is required, construction purity or a separately justified
   suspension/effect change is necessary; eager construction alone does not
   solve that stronger problem.
2. Treat EU separately. Its callbacks already return results rather than
   suspended state actions. Preserving eager evaluation and promising that no
   later callback is evaluated are incompatible for arbitrary effectful or
   raising callbacks. S0 reports no reachable structural stop in the current EU
   production sites under their measured contracts. It is reasonable to leave
   that traversal's body unchanged for S1 if this restriction is discharged and
   the public guarantee is explicitly limited. Otherwise, make callback purity
   or suspension an explicit prerequisite and validate the relevant callers.
3. Carry the frozen-old-body kernel theorem **and** native checks of callback
   construction, callback order, outer exceptions, and host failures. A generated
   shared Lem prototype must be exercised on both targets before declaring R2
   settled. Do not just transplant the existing Lean theorem and infer native
   parity.

The shared-body approach is still a reasonable destination. Being shared makes
the change visible; it does not establish that the change preserves behavior.
Describe generated diffs as datatype additions, transport arms, default changes,
and live traversal changes, with the evidence for each.

## F3 — WP0 needs a derivation policy, not just a negative census entry

**Relevant text:** [WP0](2026-09-16_lean-only-outcomes-implementation-plan.md#L33)
and its explicitly open questions at line 64. This is a feasible backend feature,
but “one prepass branch” is not yet a justified implementation bound.

For the actual direct field `Stopped of interp_stop`, the cited tier-2 mechanism
is the right one: an `Inh_none` entry makes that field underivable and removes
that constructor from the default candidates. The S0 failure of `skip_instances`
is well explained. It is a failure of the generated Lean build after successful
generation, however; correct R1's phrase “fails at the generator.”

The same argument does not automatically cover every enclosing type:

- **Aliases.** At `f6542f8`, `derive_field_bounds` examines source types and
  resolves a `Typ_app` directly through the census. Type abbreviations are
  omitted from that census; an unknown head is assumed unconditionally
  inhabitable. In contrast, `typ_inhabited_bounds`, used for failure-site
  demands, first head-normalizes types. These paths do not have the same alias
  behavior.
- **Tier-1 types.** Non-parameterized variants use a separate safe-constructor
  selection and are recorded as unconditionally inhabited. Selection does not
  consult the tier-2 field derivability rule. Encountering an excluded field
  later during rendering can cause generation to fail even if another
  constructor has a perfectly usable default.
- **Containers.** A pair with a required excluded component cannot supply a
  default. An empty list or `Nothing` can: `list interp_stop` need not construct
  an `interp_stop`. A sum can choose its other inhabited side. Exclusion should
  follow actual default demands, not syntactic occurrence of the type name.
- **Functions.** The codomain matters for a constant-function default; the
  domain ordinarily does not. Include these cases because the consumer has a
  function-typed `Inhabited` existential.

Two [small Lem controls](2026-09-16_lean-only-outcomes-plan-review-evidence/README.md)
confirm the first two mechanisms on the pinned generator. They use an existing
source of `Inh_none`, a recursively defined type with no derivable default;
they do **not** implement or test the future declaration itself.

```text
type alias = blocked nat
type outcome 'a = Defined of 'a | Error of string
                | Direct of blocked nat | ViaAlias of alias
```

Generation excludes `Direct` but emits `default := ViaAlias default`. The alias
has hidden the negative census entry. In a separate control,
`type mono = Bad of blocked nat | Good of nat` fails generation instead of
selecting `Good`. Both outcomes are preserved in the transcript.

**Revise WP0's acceptance matrix:**

| Shape or demand | Expected policy |
|---|---|
| Excluded leaf type | No generated `Inhabited`; explicit constructors remain usable; comparison instances unchanged |
| Existing Cerberus direct-field extensions | Exact old generic and concrete defaults retained |
| Alias to excluded type, including imported aliases | Cannot hide the exclusion or create an unusable fallback instance |
| Tuple or record requiring the excluded value | No fabricated default; documented generation-time refusal where required |
| List/option of excluded values; sum with an inhabited alternative | Empty/alternative defaults allowed when they do not construct the excluded value |
| Function returning excluded type versus taking it as an argument | Reject the required result demand; allow a default that does not require such a result |
| Non-parameterized variant with another usable constructor | Select the legitimate default, or explicitly document a narrower supported policy and fail at generation time |
| Mutual block and parameterized excluded type | Stable result independent of incidental prepass/emission order; define exclusion for all instantiations |
| Direct failure site, synthesized missing-pattern failure, polymorphic failure helper specialized to excluded type | Generation-time refusal; diagnostics identify an explicit policy exclusion |
| Combination with `skip_instances` or `target_rep` | Document precedence or reject the conflicting combination |

Use one consistent derivability policy for the census and emitted instances.
Do not expand WP0 into unrelated instance redesign, but do not advertise general
alias/tier-1 support without implementing it. The failure-site check is primarily
`typ_inhabited_bounds`/`lean_thread_demand` (`lean_backend.ml:1976,2541`), whereas
`inhabited_demand_check:7185` protects defaults emitted inside instance bodies.
Both belong in the tests.

Finally, exclusion is a code-generation policy, not a theorem that an inhabitant
cannot exist: `Exhausted` itself witnesses inhabitation, and handwritten Lean
can explicitly package it in an instance. Phrase the guarantee as absence of
**generated accidental defaults**, with the public default equalities pinned.
Do not substitute it for auditing explicit stop producers.

## F4 — Complete the protocol integration contract

The new records and whole-batch incompleteness rule are sound choices. Two
interfaces are missing from the addendum's claimed complete inventory:

- [scripts/observations.sh:53](../../scripts/observations.sh#L53) first greps for
  `^ModelFailure `, then calls the Python **action** `model-failure`. Broadening
  Python's policy or adding `Unsupported` to diagnostic greps does not change
  this prefilter. An unsupported-only capture never reaches the classifier.
  Add a general stop helper/action, update its callers, or explicitly retain
  this helper for fail-stop and add a separate one for the general class.
- [observations.py's CLI](../../scripts/observations.py#L348) has action names,
  policy choices, an action-specific policy override, the classification
  predicate, and message extraction. R5 names only the policy rename. Specify
  whether the action is renamed too and update `observations.sh`, CLI tests,
  and lane callers together.

The shell helper must remain a prefilter followed by validation of the entire
capture. Broad prefix matching alone must not certify a valid stop. Include
single-stop exit-1 and mixed-execution exit-0 plants through the **public shell
helper**, not only direct Python parsing.

The completion field also needs a mixed-kind definition. A valid batch can
contain `Exhausted`, `ModelFailure`, and `Unsupported` simultaneously; its
completion cannot simply be “the stop kind” without specifying which one.
Prefer a general incomplete/stopped flag plus the kinds retained in the
ordered verdict list, or define a deterministic summary precedence while
preserving all records. No summary choice may make such a batch comparable.

Add tests for different stop kinds together, a valid stop followed by malformed
output or a fatal diagnostic, mismatched or missing status, and all projections
and comparison policies. The original capture must remain available.

One factual correction: the addendum table says the current `compare` rejects
ordinary `Error`/`InternalError` as well as `ModelFailure`. The current
[comparison body](../../scripts/observations.py#L391) explicitly rejects
`model_failure`; admission of other kinds depends on parsing policy. Preserve
that existing policy rather than broadening rejection accidentally. The
addendum's legacy ordinary-error rule is compatible with this distinction.

## F5 — Make the implementation fence match the actual migration

Deleting `fuelExhaustedLoc` necessarily changes the existing
[NDFuelStabilityTest.ordinary_error_stable](../test/Unit/NDFuelStabilityTest.lean#L116).
That theorem intentionally uses the old atom as an ordinary error's location.
The test is missing from the fence's explicit unit-file list. Replace its
premise with constructor discrimination at an arbitrary ordinary location;
keep the ordinary-error stability check.

Add `scripts/observations.sh` and the five speclab test files explicitly as
well. The latter are named as deliverables but omitted from the fence's path
list. These are routine authorized migration edits to name in advance, not
reasons to weaken the fence on baselines, fuel hypotheses, or failure reach.

Resolve Q2 now: [core_reduction.lem:445](../../frontend/model/core_reduction.lem#L445)
calls `eval_pexpr pe` inside the `Esave` callback, then binds its result.
`step_ctx` binds that evaluator to `E.eval_pexpr2`, which calls
`Core_eval.eval_pexpr_aux2`. This is another structurally stoppable SEU traversal
after migration. There is no reason to carry “body not read” into the charter.

For `Driver.hack`, retain S0's explicit obligation to confirm the reachability
argument on the generated call graph and the applicable shape/measure contract.
Do not let “all arms found” silently discharge this bare-value boundary.

The consumer's exact alias condition is sufficient for the cited zero-budget
`rfl` proofs, provided the regenerated arms and their state components retain
their shapes. Keep the candidate build as the final check. Q3's existential is
not itself evidence of a default bug; nor does a successful build prove that
every consumer interpretation of defaults is unchanged. The provider's explicit
default pins and the consumer proof review address different obligations.

## F6 — Strengthen two specific gate checks without adding a new gate family

**Fuel recognition.** The current
[FuelFormsTool](../test/Unit/FuelFormsTool.lean#L434) classifies the right side by
whether its used constants include an absorbing head and a fuel atom.
Renaming those constants is not exact structural recognition. The plan says
“EXACTLY,” which is right; make the algorithm and plants enforce it.

Alongside the two proposed wrong-reason cases, include decoys such as a successful
`Defined (Stopped Exhausted)` payload or a state/diagnostic component containing
`Exhausted` beside an ordinary failure. A contains-constant test can accept these
without the outer result being exhaustion. Inspect the actual result path
through the approved wrappers, allowing the exact definitional fuel alias.
Preserve the existing theorem-shape and axiom checks.

**Missing arms.** The added log check should be demonstrated on a removed live
arm and should fail when regeneration or its expected log is missing. Do not
assume a prose phrase such as `missing patterns … Stopped` is a reliable
single-line regex. The preserved S0 list is a summarized inventory, not a
substitute for testing the chosen detector on the raw invocation. Warning 8
remains useful for the built OCaml configuration; a broader Lem exhaustiveness
change can stay separate from WP0.

## Contract wording and proposed next steps

The three-way contract structure is the right one, with two wording changes.
First, replace §1's “outcomes … for which the OCaml oracle has no value”:
exhaustion can interrupt a terminating reference execution, and unsupported
features often work in the reference. These are administrative observations of
the port, not necessarily missing oracle outcomes. Second, mark whole-driver
bounded correspondence as the objective supported by local proofs and
differential evidence; S1 does not prove the full port correct, especially while
the pure-failure axis remains outside the change.

Recommended sequence:

1. Amend R2 to decide the earlier-legacy-failure case and the distinction between
   callback construction and state-action execution. Strengthen the stop theorem
   and run the small shared Lem/native prototype before fixing S1's scope.
2. Charter WP0 with the explicit derivation matrix above. Verify the real
   Cerberus default pins before merging and repinning; retain the existing
   two-repository sequence.
3. Add the missing protocol interfaces, mixed-kind completion rule, and test
   files to WP1. Keep S1a/S1b/S1c internal to one coherent public landing.
4. Validate local propagation and conservativity on the actual generated
   definitions, then run the full provider battery and pristine lane, and build
   the consumer against that same candidate. Keep existing baseline rows fixed.
5. Leave typed refusal producers and the general pure-failure lifting design
   for their separately scoped work. S1 must still preserve how remaining native
   failures are observed.

R1 is a reasonable backend direction once specified; R2 needs the above revision;
R3/R4 are reasonable as proposed; R5 needs its shell/CLI and mixed-kind details;
R6 needs no legacy decoder; R7 should mirror `liftCore_run` and retain the
exhaustion-only consumer disjunct; R8 remains the right sequencing.

**Validation and limits.** The
[preserved evidence and reproduction instructions](2026-09-16_lean-only-outcomes-plan-review-evidence/README.md)
include an independent rerun of S0's 14 traversal lemmas, four additional kernel
lemmas (axioms limited to `propext`/`Quot.sound`), native callback controls, and
the two current-generator default-policy controls. The
[raw transcript](2026-09-16_lean-only-outcomes-plan-review-evidence/results.txt)
records versions, input/artifact hashes, outputs, and expected failures. These
are bounded design probes using the existing compiled S0 modules, not a fresh
production rebuild, a complete native correspondence proof, or an executed C
counterexample. No production implementation, full release ladder, downstream
candidate build, or merge was performed in this review.
