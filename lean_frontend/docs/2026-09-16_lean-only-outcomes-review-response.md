**Response to the Lean-only outcomes scoping note — feasibility and implementation advice (2026-09-16)**

**Status and scope.** [AGENT] Design review requested by the user. This responds
to the [scoping note](2026-09-16_lean-only-outcomes-scoping-note.md) at
`6c065eefb`, whose implementation base is
`a15da65f8e6c014c6c03d9ff375e3a007ab2e43d`. Recommendations here are not operator
rulings or approval to implement or merge the proposed semantic change. The
review examined the current source, selected consumer contracts at
refined-cerberus `6be4b822b379f085233806fedb900db79d0bd453`, and bounded,
reproducible probes using Lem `f6542f8`, OCaml 5.4.0, and Lean 4.32.2.

**Recommendation: adopt the direction of B, with a short feasibility checkpoint
before fixing the implementation charter.** A shared `interp_stop` and one
`Stopped` constructor in each outcome channel put the distinction in the right
place. This is technically feasible with the existing generator. It gives
consumers useful constructor discrimination without location side conditions,
keeps the kill polymorphic in the ordinary error type, and avoids introducing
target-specific datatype machinery solely to keep OCaml source text unchanged.

The note understates the work needed to make the new outcomes absorbing. Two
specific mechanisms need attention: generated `Inhabited` defaults and
traversals that collect outer results before inspecting inner outcomes. The
compiler does not establish the desired contracts for either. These are
bounded design questions, not reasons to return to the location-atom design.

My assessment is:

| Part | Feasibility | Qualification |
|---|---|---|
| Shared stop vocabulary and both datatype extensions | High; generated and compiled in the probe | Resolve the diagnostic payload and generated default policy |
| Constructor discrimination and elementary bind/lift laws | High; kernel-checked in the probe | Prove the corresponding laws for production combinators |
| Conservative treatment of existing outcomes | Plausible and locally provable | Preserve evaluation order, ordinary-error behavior, and state |
| End-to-end stop propagation | Feasible, with more work than the note budgets | Include state/exception adapters, formatting, wildcards, and traversals |
| Batch protocol and classifier migration | Feasible, moderate integration work | Mixed executions, remaining pure panics, and exit statuses matter |
| Consumer migration | Likely small at the public interface | Build the consumer against the candidate before provider landing |
| Full pure-failure correspondence | Not delivered by this change | Keep that gap explicit; a new result constructor does not lift pure functions |

**1. Tighten the correspondence contract before changing the types.**

P1 currently says that results are identical on every input the oracle answers.
That cannot literally hold for a finite-fuel evaluator: at fuel zero, Lean
exhausts even on a program the oracle immediately finishes. `Unsupported` is
also often produced precisely where the oracle *does* have a result, such as a
filesystem operation omitted from this port. It is not intrinsically an
outcome for which the oracle has no value.

Use three separate obligations:

- **Conservative extension of existing outcomes.** On legacy inputs and
  computations that do not construct administrative stops, the modified
  combinators preserve existing values, UB, model errors, ordering, and state.
- **Bounded observation of supported executions.** For the declared supported
  profile, completed observations at adequate budgets should correspond to the
  reference execution. Exhaustion records incomplete observation; it neither
  proves divergence nor supplies a C behavior. Quantification must include
  budgets captured by generated computations, not just the runner's budget.
- **Explicit incomplete or unavailable observations.** An unsupported feature
  records a coverage limitation. A fail-stop records an identified interpreter
  failure. Neither is ordinary semantic agreement or proof of source safety.

These are the intended correspondence obligations, not a claim that this
slice can prove the whole port correct. D2 can establish the local preservation
and propagation laws, retain the existing differential evidence, and make the
remaining whole-driver obligations easier to state.

Similarly, replace "Lean is total, so it must have a value where OCaml has
none" with the narrower statement that *this fuel-bounded executable interface*
needs an explicit result when its budget runs out. Lean can also describe
unbounded or diverging execution relationally. The choice of a bounded observer
does not turn exhaustion into a behavior of C.

The doctrine worth ratifying is therefore: administrative outcomes are explicit
at the layer they interrupt; extensions preserve the legacy fragment; the
reference-observation relation is stated separately. It need not decree that
every future cancellation, host failure, or unsupported CLI request must be a
constructor of the shared operational semantics.

**2. Keep B's basic shape; finish its payload and dependency design.**

One shared reason type and one additional constructor per channel are a good
fit. In schematic Lem:

```text
type unsupported_feature = UF_filesystem | UF_concurrency | UF_switches

type interp_stop =
  | Exhausted
  | FailStop of string
  | Unsupported of unsupported_feature * string

(* Existing constructors remain unchanged. *)
type kill_reason 'err = ... | Stopped of interp_stop
type t 'a = ... | Stopped of interp_stop
```

The added string on `Unsupported` resolves an inconsistency in §4: the proposed
type carries only a feature, while `unsupportedKill feature msg` and the batch
record both carry a message. Either include that payload, as above, or remove
the promised message from the API. Do not recover it through a hidden registry
or a location sentinel. Diagnostic strings are fine; the constructor and
feature enumeration, rather than the string, determine meaning.

Keep `Exhausted` nullary for this migration. Changing it to carry a worker,
budget, or location would also change the equality used by existing fuel
contracts. Additional diagnostic context can be designed separately if needed.
Retain the existing outer failure-time state; there is no reason to duplicate
it in `interp_stop`.

Put the shared vocabulary in a low-level Lem module, for example
`interp_stop.lem`, imported by the outcome modules. It must not depend on
`Nondeterminism` or a Lean helper that imports `Nondeterminism`. The generated
zero-fuel arm of `Nondeterminism` cannot import `CerbND.fuelExhaustedKill` from a
module above itself. Construct the low-level outcome there and keep the
existing high-level alias definitionally equal to it. `CerbStop` helpers that
return ND computations belong above the generated ND module.

The probe generated `Stopped` for the pure channel and `Stopped0` for the kill
channel on **both** targets. This is normal existing Lem name disambiguation,
not an obstacle. Inspect the actual generated names before freezing gate
patterns. Consumer APIs should use stable provider aliases rather than suffixes
chosen by the generator.

The initial feature enumeration is adequate. Extending an enumeration should
be an ordinary reviewed API change, not a new semantic theory. `UF_filesystem`
can have an operation-specific diagnostic without pretending that every
filesystem operation has the same support status.

B-err is less attractive here, but not mathematically impossible:
`Other (Left Exhausted)` can be polymorphic when the error parameter is
`either interp_stop 'err`. That alternative would change error instantiations
and lifting throughout the model and still leave the pure evaluator channel
to address. B is preferable because it preserves existing ordinary-error
parameters and puts the shared distinction directly in the existing outcome
types. An outer result wrapper has similar signature and lifting costs. The
comparison should be about those costs, not an impossibility claim.

**3. Resolve the generated-default hazard before claiming that stops have only explicit producers.**

The generated form of [Undefined.t](../../frontend/model/undefined.lem#L1424),
inspected at `lean_frontend/generated/Undefined.lean:1852` in the built provider,
has a primary `Inhabited (t0 α)` instance requiring `Inhabited α`, followed by
low-priority alternatives for `Undef` and `Error`. For an unconstrained type
parameter, the existing fallback is the latter. This kernel-checked probe
against the available compiled provider succeeds:

```lean
theorem existing_default_is_error {α : Type} :
    (default : t0 α) = Error default default := rfl
```

Appending the proposed constructor in a reduced module generated by the pinned
Lem tool adds another low-priority instance:

```lean
instance (priority := low) {α : Type} : Inhabited (t α) where
  default := Stopped default
```

The new reason type's default is `Exhausted`. The following consequently also
checks by `rfl`, without any axioms:

```lean
theorem default_becomes_exhaustion {α : Type} :
    (default : t α) = Stopped Exhausted := rfl
```

This is not a reproduced C-level bug. It is a reproduced generator/typeclass
interaction that invalidates a claim that only explicit zero-fuel arms can
produce the new value. Generic default-valued code, including logical fallback
paths, can now look like exhaustion. For inhabited concrete payload types, the
primary `Defined default` instance can still win; the unconstrained case is
the important counterexample.

The relevant backend mechanism is
`lem-lean/src/lean_backend.ml:7331–7358` at `f6542f8`: usable constructor
defaults are emitted at ordinary priority for the first and equal low priority
for the remaining alternatives.

**Required checkpoint:** specify the default policy for the extended outcome
types and check generic as well as concrete instantiations. Ordinary defaults
must not silently become admissible exhaustion. Prefer an explicit supported
instance policy or a principled backend correction over an undocumented
constructor-order trick or another special priority value. Determine which
existing declaration mechanisms can express the policy before assuming that
no Lem-tool change is needed. The existing `declare {lean} skip_instances type t`
is a concrete escape hatch to assess, but suppresses more than `Inhabited`;
replacement instances must also be available without introducing an import
cycle or losing comparison parity. If a small backend change is needed,
include it openly in the scope and pin sequence.

`noConfusion` proves different constructors unequal. It does not prove that a
particular constructor arose only at an intended execution site.

**4. Expand the propagation inventory, and distinguish active source from history.**

The note's approximately ten arms in four shared files is an underestimate.
At the reviewed base, the following is a useful minimum checklist:

| Active source | Required review or change |
|---|---|
| [nondeterminism.lem:255](../../frontend/model/nondeterminism.lem#L255) | The live `liftAction` must preserve the reason across ordinary-error type changes |
| [undefined.lem:1431](../../frontend/model/undefined.lem#L1431) and [1458](../../frontend/model/undefined.lem#L1458) | `bind` and `fmap` must preserve a stop |
| [exception_undefined.lem:12](../../frontend/model/exception_undefined.lem#L12) | Nested exception/undefined bind must preserve a stop |
| [state_exception_undefined.lem:15](../../frontend/model/state_exception_undefined.lem#L15) and [38](../../frontend/model/state_exception_undefined.lem#L38) | Bind and `runEU`, omitted from the note, must preserve both reason and state |
| [driver.lem:145](../../frontend/model/driver.lem#L145), [178](../../frontend/model/driver.lem#L178), [412](../../frontend/model/driver.lem#L412), [423](../../frontend/model/driver.lem#L423), [444](../../frontend/model/driver.lem#L444) | Evaluator conversion, `liftCore_run`, and three formatted-I/O result lifts |
| [formatted.lem:485](../../frontend/model/formatted.lem#L485) and [744](../../frontend/model/formatted.lem#L744) | `convert` and `printf_aux` inspect the pure outcome directly |
| [formatted.lem:836](../../frontend/model/formatted.lem#L836) | `vsnprintf` has a catch-all that currently converts every non-`Defined` result into a pure error |

This identifies fourteen candidate propagation arms in six files, before
traversal repairs and other wildcard obligations. It is a source-derived lower
bound, not a completed compiler-discovered inventory. The second ND
implementation around `nondeterminism.lem:512`, counted in the note, is inside
a block comment beginning near line 297 and ending near line 543.

Warning 8 is useful but does not establish propagation. The existing
`vsnprintf` wildcard remains exhaustive after the type extension and can swallow
`Stopped`. The preserved OCaml negative control compiles with warning 8 fatal
while deliberately converting a stop to an ordinary error.

[Driver.hack](../../frontend/model/driver.lem#L1453) is another catch-all to
review. Its result type is a bare value, so adding a propagation arm is not
mechanically possible. Either establish that the new outcome is unreachable
under the existing shape/measure hypotheses, or identify it as a separate
effect-lifting obligation. Do not silently route it through another panic and
call the propagation problem closed.

The handwritten OCaml inventory also needs refinement. The active
[driver_ocaml.ml](../../backend/common/driver_ocaml.ml#L37) has a separate
`batch_output` datatype and printer, JSON/Charon branches, result conversion,
debug rendering, and human rendering. Printing new records is more than one
new arm in `batch_drive`. Conversely,
[backend/common/dune](../../backend/common/dune#L6) excludes `interactive_driver`
and `cerbcore` from the normal library: compiling the normal driver cannot
certify those dormant files. Classify each target as built, maintained but
separately tested, or historical. Do not count a commented or excluded match as
compiler-enforced coverage.

**5. Traversal semantics is the main behavioral design question.**

Adding all missing constructor arms still does not make every composition
absorb a stop. Two existing helpers combine monadic layers in a way the note
does not discuss:

```text
Exception_undefined.mapM f xs =
  Exception.bind (Exception.mapM f xs)
    (fun us -> Exception.return (Undefined.mapM id us))

State_exception_undefined.mapM f xs =
  State_exception.bind (State_exception.mapM f xs)
    (fun us -> State_exception.return (Undefined.mapM id us))
```

See [exception_undefined.lem:32](../../frontend/model/exception_undefined.lem#L32)
and [state_exception_undefined.lem:29](../../frontend/model/state_exception_undefined.lem#L29).
The outer traversal initially sees a `Stopped` as a successful outer result
containing an inner value. It can continue evaluating subsequent entries. The
inner `Undefined.mapM` runs only after that collection finishes.

The [reduced traversal probe](2026-09-16_lean-only-outcomes-review-evidence/Traversal.lean)
kernel-checks two counterexamples:

- An early inner `Stopped Exhausted` is followed by another state update; the
  eventual stop contains the later state.
- An early inner stop is replaced entirely by a later outer exception.

These are counterexamples for the layering pattern, not claims of a newly
executed C regression. The production path is relevant:
`Core_reduction.E.mapM` aliases `SEU.mapM`, and `core_run.lem:1380` calls it;
the pure evaluator also uses `EU.mapM` at several sites.

This requires an explicit decision about administrative stops. I recommend:
once such a stop is observed by a traversal, do not execute its remaining
semantic actions; preserve the reason and state at that point. Ordinary
`Undef` and `Error` behavior must remain as upstream defines it unless changed
under a separate correctness decision.

Do **not** simply rewrite every traversal in terms of the inner bind. The
current implementation may continue after an ordinary inner UB/error, and
OCaml's eager construction of a mapped list also affects evaluation order and
which exception becomes observable. A blanket short-circuit rewrite can change
legacy behavior, invalidating the argument that every behavioral change lies
behind a previously unreachable stop constructor.

A feasible repair is a stop-aware traversal that preserves the previous
evaluation and accumulation policy on all legacy cases and terminates on the
new case. Its precise implementation needs a small prototype, with callback
order, outer exception precedence, and state evolution tested. If a traversal
cannot encounter stops on the production domain, prove that restriction
instead. The contract cannot be discharged merely by compiling a new datatype.

This is the principal reason to put a feasibility checkpoint before a promise
of one mechanical medium-sized slice.

**6. Use a small set of concrete proof obligations.**

The provider should supply these facts over its actual definitions, without
importing Iris:

- **Separation:** exhaustion differs from fail-stop, unsupported, UB, ordinary
  `Error`, and `Other`. The two outcome channels share the same reason without
  manufacturing a location or mapping it through an ordinary-error function.
- **Absorption:** at the documented positive budgets, bind does not call its
  continuation after a stop; error-type and state lifts preserve the reason.
- **State:** preserve the state at failure, including `liftCore_run`'s returned
  run state and a memory lift's updated memory. There is no implicit rollback.
- **Traversal:** no later semantic action runs after an observed administrative
  stop; the stated legacy ordering and exception policy is preserved otherwise.
- **Observation:** all three runners report the same reason in the appropriate
  output position and preserve existing ordering and multiplicity.
- **Conservativity:** altered adapters commute with embedding the old outcome
  constructors; never introduce stops for ordinary inputs and callbacks that
  stay in the old fragment.

The algebraic portion is small. The probe proves preservation of the old pure
bind under embedding, stop absorption, channel conversion, and discrimination
by `rfl` or constructor elimination, all without axioms. The point is to
establish a tractable proof route, not to add a second production interpreter.

Respect existing budget precedence. The observer at zero fuel exhausts before
inspecting even an already stopped computation. ND bind and lift have existing
positive-fuel requirements; preserving their shape avoids unnecessary consumer
changes. A theorem claiming fail-stop wins at *every* budget would be false.

Keep [NoFuel](../CerbNDFuelProofs.lean#L20) specific to exhaustion. A run with no
fuel stop may still contain `FailStop`, `Unsupported`, or UB. Conversely, a
partial-correctness safety theorem may admit exhaustion as incomplete
observation but must not silently admit *every* `Stopped` reason. A predicate
such as "success or any Stopped" would make implementation failures and
unsupported executions satisfy the safety conclusion.

The consumer's `DriverSafeCtl` currently names
`CerbND.fuelExhaustedKill`, rather than all kills. Preserve that distinction and
add negative checks that the other two stop kinds cannot satisfy its
exhaustion disjunct. Retaining the alias and its type is helpful; retaining its
old definitional equality to `Error0 fuelExhaustedLoc ...` is incompatible with
the new constructor and should not be promised as an API guarantee.

**7. The wire protocol needs an incomplete-run policy, not just new tokens.**

Using `Exhausted {}`, `ModelFailure {msg: ...}`, and
`Unsupported {feature: ..., msg: ...}` is reasonable. Choose one spelling now;
there is no benefit in introducing two equivalent encodings. Let the printer
case on constructors, and let the decoder parse records before the lane
applies its comparison policy.

No existing baseline FUEL rows is encouraging, but is not a migration-cost or
correctness proof. In particular:

- [Main.lean](../Main.lean#L1083) currently returns zero for multiple executions,
  including mixtures of successful and killed branches. A batch containing
  `Defined` and `Exhausted` must still be incomplete, regardless of exit zero.
  The same caution applies to fail-stop and unsupported branches.
- An OCaml uncaught exception can abort the entire exploration. A Lean
  branch-local fail-stop may leave other enumerated results in its list. The
  harness must not discard that stop and compare the surviving successes as a
  complete oracle observation.
- Preserve execution framing, list order, multiplicity, raw bytes, and status.
  Do not silently compare sets or a successful prefix.
- Remaining pure exhaustion panics still exist outside D2. Retain their
  crash/incomplete classification. Replacing the old typed-fuel record must not
  accidentally remove recognition of those unconverted failures.
- Diagnostic messages can contain quotes, newlines, Unicode, and apparent
  protocol syntax. Use the existing byte/text escaping distinction, reject
  malformed or unknown records, and test adversarial payloads.
- An ordinary `Error` whose message happens to be `lem: fuel exhausted` must
  remain an ordinary error after migration. Do not keep the old current-run
  string test as a compatibility alias for structural exhaustion. Historical
  captures, if supported, need an explicitly selected legacy decoder.

The migration surface includes `Verdict.token`, `reference`, observation
completion/evidence, comparison projections, refusal parsing, and exit checks
in [observations.py](../../scripts/observations.py#L107), not just its regexes.
Likewise, changes to `FuelFormsTool` must recognize `Stopped Exhausted`, not
merely any `Stopped` constructor. Plant a zero case containing `FailStop` or
`Unsupported` and require it to fail the exhaustion classification.

Do not turn an unsupported CLI flag into an ND kill by fabricating a driver
state. Admission rejection and execution stopping are different layers. The
feature vocabulary can be shared while the CLI retains its documented exit-2
contract. S1 should say explicitly whether that pre-execution interface is
unchanged.

Host OOM, timeout, signal death, and malformed output remain harness failures.
They are not automatically values of `FailStop` merely because all involve a
stopped process. The seven existing typed model-failure sites have a more
specific correspondence claim.

**8. Make the reference argument visible without overpromising a proof.**

"Dead in OCaml" is a useful intended reachability property, not a fact supplied
by warning 8. Exhaustiveness only says each value matches a branch. Existing
wildcards, generic constructors/defaults, exposed APIs, and derived operations
need separate consideration.

For this slice, a proportionate assurance package is:

1. Preserve existing constructors and their payloads; review generated
   defaults and derived comparisons explicitly.
2. Show local legacy-embedding laws for changed combinators and the new
   stop-preservation laws.
3. Inspect the source/generation diff for new producers and reachable
   non-stop behavior changes, including traversal evaluation order.
4. Regenerate both targets, build the maintained configurations, and run the
   independent pristine-oracle lane in addition to fork-versus-Lean tests.
5. Exercise the new constructors directly; legacy C differential tests cannot
   cover an outcome the OCaml execution path never produces.

A new shared leaf module also affects the Makefile source inventory, generated
imports, Lake roots, and drift manifests. A handwritten `CerbStop` affects the
handwritten-copy manifest. These are routine edits, but missing them can make a
successful build use an unintended artifact.

Rebuild dependent OCaml modules and verify the libc artifact that the lanes
actually load. The Core dump definition in
[pipeline.ml](../../backend/common/pipeline.ml#L635) stores program data, not
these execution outcomes, so this review does not claim that appending the
outcome constructor necessarily changes the `.co` data format. Neither source
text compatibility nor stale compiled artifacts should be assumed safe without
the existing regeneration and staging checks.

Carrying a small explicit shared-model delta if upstream declines is a
reasonable maintenance choice. An upstream proposal can describe bounded
interpreters and mechanized consumers without claiming that every reference
interpreter needs to produce these outcomes. Target-only datatype extension
machinery should be considered only if there is an independent recurring need,
not simply because upstream does not merge this patch.

Remove the two obsolete atom census entries when their producers and consumers
have migrated. Keep the broader failure-reach and native-boundary checks for
the other mechanisms they still cover. A reduced census count is a consequence
of a cleaner representation, not the acceptance criterion itself.

**9. Stage the work around risks, and validate the consumer before landing.**

| Stage | Deliverable | Exit condition |
|---|---|---|
| S0: settle the contracts | Revised correspondence scope, stop payload, default policy, traversal policy, active match inventory | No open decision about what a stop means, how it is implicitly constructed, or whether later actions may run |
| S1a: implement the representation and transport | Shared vocabulary; two outcome extensions; explicit handling in active adapters; required traversal repairs | Both targets regenerate/build; direct constructor and state probes pass; legacy behavior changes are either absent or separately justified |
| S1b: migrate existing producers and consumers | Existing typed exhaustion/fail-stop sites, runners, proof helpers, gates, printers, codecs | Old location-based recognition is gone; budget/stop distinctions and mixed-run handling are checked |
| S1c: validate the candidate | Differential gates, independent oracle, actual downstream build, drift review | Evidence refers to the same candidate; provider and consumer contracts agree |
| S2: extend typed refusals | Convert supported refusal boundaries according to the separately scoped effect design | Converted sites fail structurally; remaining pure sites are still explicitly tracked |

S1a–S1c can be internal commits in one coherent implementation branch and one
public landing. Do not publish an intermediate state that adds a new default
but has not migrated classification and proof assumptions.

Move consumer validation into S1, rather than waiting until after the refusal
slice. The apparent one-literal consumer edit in `Heap.lean:1525` is a good
sign, not a complete migration bound: proof scripts and inferred instances may
depend on representations without mentioning the old constant text. Build the
consumer against the candidate provider in an isolated dependency checkout,
including Heap, the partial adequacy path, and total adequacy. Keep Iris
ownership predicates and rules in the consumer.

These changes should not require the entire parked pure-failure lifting design
to be implemented first. They also do not discharge it. State clearly that S1
migrates existing typed outcomes; the remaining pure functions still lack a
general abrupt-failure contract.

The original "one medium slice" estimate is plausible only after S0 resolves
defaults and traversal behavior. If either requires a Lem backend change or a
nontrivial evaluation-order repair, split that work into a small prerequisite
with its own proof and parity tests. The datatype itself is the low-risk part.

**10. Proposed acceptance examples and decisions.**

Use a compact set of meaningful adversarial checks:

| Check | Required result |
|---|---|
| Each stop through pure bind, exception bind, state bind, and both channel conversions | Same reason; continuation not run; correct failure-time state |
| Each stop through ND error-type/state lifts and all three runners | No ordinary-error mapper called on a stop; existing order and multiplicity preserved |
| Early stop followed by a state update or outer exception in a traversal | The chosen stop policy holds; no accidental loss or post-stop action |
| Legacy UB/error followed by another action or exception | Exact previously intended legacy ordering and precedence, unless separately repaired |
| Generic and concrete `Inhabited` demands after generation | No accidental new default exhaustion |
| Zero observer budget over a fail-stop computation | Exhaustion retains its existing precedence |
| Small and sufficient fuel on a terminating example | Explicit exhaustion at small fuel; unchanged completed result at sufficient fuel |
| `Defined` plus a stop in a multi-execution batch | Whole observation is incomplete/unavailable; never semantic agreement |
| Ordinary errors and escaped program output containing marker text | No classification as a structural stop |
| Forged old locations, adversarial diagnostic text, malformed records | No location-based reclassification; correct escaping or explicit protocol rejection |
| Pure panic, OOM, timeout, and signal controls | Remain failures; never upgraded into successful observations |
| `DriverSafeCtl`-shaped consumer conclusion | Only exhaustion is the admissible incomplete arm; fail-stop and unsupported do not satisfy it |

My responses to the six decisions in the scoping note are:

1. **B: yes**, with the revised correspondence contract and a per-layer
   explicit-outcome doctrine rather than a universal rule about all host stops.
2. **One `Stopped of interp_stop` per channel: yes.** It preserves the existing
   error parameter and keeps transport uniform.
3. **Structural exhaustion record now: yes.** Keep old ordinary observations
   unchanged and separately retain classification of unconverted pure failures.
4. **The three initial unsupported features: sufficient**, once the message
   payload and admission-versus-execution boundary are specified.
5. **Consumer review before implementation: useful**, followed by an actual
   candidate-provider consumer build before landing. This review inspected the
   consumer contracts but is not a separate consumer team's approval.
6. **Carry the shared delta if upstream declines: reasonable.** Do not build a
   target-only constructor facility solely to avoid a small, reviewed extension.

The successful design will make administrative stops easy to distinguish,
faithfully propagated, and impossible to mistake for completed source-program
behavior. Constructor discrimination achieves the first of these; explicit
default, traversal, and observation contracts are what achieve the other two.

**Evidence and limits.** The
[preserved probe sources and instructions](2026-09-16_lean-only-outcomes-review-evidence/README.md)
include generation on both targets, native checks, and ten kernel-checked
lemmas with no axioms. The [raw transcript](2026-09-16_lean-only-outcomes-review-evidence/results.txt)
records the tool versions, source hashes, commands, and exit codes. The reduced
types use string payloads in place of full locations/UB lists and include the
recommended diagnostic payload on `Unsupported`. They test representation,
generic defaults, elementary transport, and the traversal pattern; they do not
implement or certify D2 in the production model. No full release ladder,
production migration, independent-oracle run, or downstream rebuild was
performed for this design review.
