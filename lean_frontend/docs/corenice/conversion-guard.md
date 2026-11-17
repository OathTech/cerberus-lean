# Parked design: a checked integer-representability guard

Explored after integration `36e50de3f`, on `plan/corenice-conversion-guard`.
**Parked as the next milestone.** No implementation has begun. The mechanism
below is retained as an assessed proposal, not an active implementation plan,
measured improvement, or correspondence theorem.

The [extension-selection criterion](cerberus-nice-design.md#selecting-additions-to-corenice)
requires a fact structurally ensured by generation that ordinary Core loses.
Source/target range inclusion is known at generation, but the numerical guard
also needs the evaluated operand to satisfy its source-type range. We have not
identified a sufficiently local generation invariant supplying that fact. The
runtime design review established a credible checked-call mechanism; it did
not establish that this extension meets the project's selection criterion.

Do not proceed merely because successful checks give a useful range premise,
or accept ordinary generated failures as a restricted success domain. Revisit
only if a concrete generation rule and a generic preservation argument make
the checks redundant for its output. The existing Core/CoreNice conversion
and breakpoint pathways remain the baseline.

## Purpose and first scope

Add an explicit runtime check to selected existing loaded-integer conversion
calls. A specified integer must fit the actual target type without changing
its numerical value. Success leaves the ordinary conversion computation intact;
failure produces a typed `NiceFault`. Unspecified loaded values retain their
ordinary behavior. This is a checked semantic restriction, not a new cast
implementation or an assumption that all valid C casts preserve values.

The first producer covers statically known range-including conversions in the
existing concrete, sequential recipe. The exact supported source/target shape
is `Ctype annotations (Basic (Integer (Signed base | Unsigned base)))`, with
`base` one of `Ichar`, `Short`, `Int_`, `Long`, or `LongLong`. Original annotations
are retained. This includes explicit signed/unsigned character types but excludes
the special `IntN_t`, `Int_leastN_t`, `Int_fastN_t`, `Intmax_t` and `Intptr_t`
bases. `_Bool`, plain `char`, enum-dependent types, the other special integer
aliases, atomic wrappers, floating/pointer conversions and dynamically computed
targets are also outside the first placement policy. A typedef already resolved
to a supported ordinary type is handled as that type. Use the model's bounds,
not host integer sizes. Other conversion sites remain ordinary calls and are
reported as unguarded.

The intended useful contract is conditional: after a successful check, a
specified input is representable in the target. Under the actual standard
conversion definition, the in-range non-`_Bool` branch then preserves that
same provenance-carrying integer. Unspecified input does not become specified,
initialized, or numerically bounded as a consequence of passing the guard.

## Why the guard belongs at pure-call entry

The original [`PEcall` rule](../../../frontend/corenice/model/core_eval.lem)
advances each argument by one pure-evaluation round using `EU.mapM self`.
It repeats this process until all arguments are values. Only then does
`call_function` resolve the callee, check declaration kind and arity, and
substitute values into its body. The body is not evaluated in that call step.

Wrapping only the value operand in a checking expression could fault before
the target argument finishes evaluating. A fresh `let` chain could similarly
change argument progress and failure precedence. Neither is the proposed
implementation. In particular, a guard must not evaluate an operand twice or
introduce a new C temporary or fresh semantic symbol.

Use a dedicated pure-call form in the owned Lem AST, schematically:

```text
PEcall             callee arguments
PEchecked_int_call site callee arguments
```

Both forms keep the original callee and ordered argument expressions. The
checked form has a fixed contract on the two evaluated arguments: target
`ctype` followed by loaded integer. There is no duplicate target type, source
type, cached bound, assumed interval, or expected result in its metadata.
The actual evaluated target determines the check.

This is one restricted check form, not a general assertion language. It can be
represented by a separate constructor as above without changing ordinary call
construction. A common evaluation helper may share the ordinary call logic;
the implementation must not create a second independently maintained argument
evaluator.

## Execution rule

The checked arm performs the following operations in this order:

1. Advance the arguments using the same `EU.mapM self` operation and residual
   reconstruction as `PEcall`. Propagate ordinary evaluation failure unchanged.
   If arguments are not all values, retain the checked node with its site and
   residual arguments; do not check early.
2. On the evaluated vector, invoke the existing `call_function` unchanged.
   Missing callee, non-function declaration, wrong arity and substitution
   failures retain their existing precedence. Keep the returned body, without
   evaluating it.
3. Check the same evaluated argument vector as specified below.
4. On success, return that exact expanded body through the ordinary
   `pull_constrained` path. On range failure, return `NiceFault` before the
   conversion body executes.

Pseudocode (not a new evaluator specification):

```text
args' := original_argument_round(args)
if args' are not all values:
    return checked_call(site, callee, args')
body := original_call_function(file, callee, values(args'))
check_loaded_integer_fits(site, callee, values(args'))
return original_pull_constrained(body)
```

The check has no memory writes, fresh-name allocation, nondeterministic choice,
driver step, breakpoint, output, or semantic success log. It neither resets
fuel nor replaces the current reader/configuration inputs. Its successful
call step produces the same body as an ordinary call from the same arguments.
Additional computation may affect resource limits; exhaustion remains
incomplete evidence, not a semantic result or a passing comparison.

The guard's input-range contract does not depend on the callee being named
`conv_loaded_int`. Its erasure retains the actual callee. Claiming that the
eventual result preserves the input additionally requires that the callee
has the actual ordinary conversion definition. The producer selects the
resolved standard-library helper; a same-spelled arbitrary function is not
conversion evidence. No runtime fast path bypasses the retained body.

## Exact predicate and outcomes

The vector must have the form `[Vctype T, Vloaded v]`. On an invalid checked
form, report an explicit `Illformed_program` guard-use error after the ordinary
call checks above. A generated normal campaign must never accept this error.

* `v = LVunspecified U`: succeed without computing bounds, resolving an enum,
  or examining an integer payload. For the ordinary conversion body, the result
  is later `LVunspecified T`. This preserves the original unspecified path,
  which does not call `Ivmin`/`Ivmax`. It is not target-validity evidence. The
  producer's target restrictions still apply; manually built unspecified calls
  do not acquire a stronger runtime target check.
* `v = LVspecified (OVinteger n)`: require a supported ordinary signed/unsigned
  target; then obtain `lo` and `hi` from the same `Mem.min_ival` / `max_ival`
  services used by the original library semantics. Evaluate
  `Mem.le_ival lo n` and `Mem.le_ival n hi`. Succeed exactly when both return
  `Just true`. Retain `n` unchanged, including its provenance.
* Another specified object kind, a malformed target, or a target outside the
  supported guard domain is an explicit guard-use/unsupported error, not an
  out-of-range witness. It does not silently fall through to an unguarded call.
* An undecided comparison is explicitly unsupported in this first recipe. It
  must not become success, `IntegerNotRepresentable`, or a new choice. Fail
  noisily with a distinguishable guard-unsupported error. Such a result cannot
  count as validated correspondence. In the current concrete backend,
  [`leIval_isSome`](../../CerbMem.lean) rules this case out; extending the guard
  to other backends would need its own semantics and tests.

Both decidable comparisons must be obtained before reporting their range
result; unsupported evaluation must not be disguised as a proved negative.
Do not reconstruct the integer with `Mem.integer_ival` or convert through a
host-sized integer. Comparisons may inspect numerical content, but the original
argument vector and its provenance pass untouched to ordinary substitution.

`_Bool` is deliberately excluded for specified values: its ordinary conversion
normalizes nonzero values to one before the range branch. The concrete memory
model's current `_Bool` maximum also follows an upstream representation
convention of 255, so a generic min/max check is not a boolean-conversion
contract. Enum normalization and special aliases similarly deserve explicit
follow-up rather than accidental admission. Atomic wrappers are not stripped
silently for admission; the producer checks the actual retained target shape.

For example, with an eight-bit unsigned target, 255 passes and 256 faults. The
unguarded Core conversion of 256 remains valid and wraps. That is an intended
negative control for a manually inserted guard, not a normal producer result.

## Fault and site data

Extend the existing [`NiceFault`](../../../frontend/corenice/model/errors.lem)
sum with one semantic range-failure constructor:

```text
IntegerNotRepresentable {
    site,
    calledFunction,
    targetType,
    integerValue,
    lowerBound,
    upperBound,
    lowerTest,
    upperTest
}
```

All values come from the executing node and actual evaluated operands/bounds.
The two tests are the actual decidable comparison results; at least one is
false. Preserve the `Mem.integer_value` objects rather than only formatted
numbers. Ordinary unsupported/ill-formed errors remain distinct from this
fault. Rendering and JSON are derived from the typed payload.

Use a dedicated site record with diagnostic occurrence identity, source
location and optional owning definition. Locations may honestly be unknown or
generated. Allocate IDs separately from Cerberus's semantic symbol supply;
substitution, copying, linking and repeated loop/recursive execution preserve
the original site identity. It identifies a static check, not an activation.
No whole state or execution history belongs in the payload.

## Initial insertion policy

Place checks where the typed producer knows both source and target types and
is already emitting the standard loaded-integer conversion. Let their model
bounds be `[slo, shi]` and `[tlo, thi]`. The initial eligibility condition is:

```text
supported(source) and supported(target)
and tlo <= slo and shi <= thi
and the retained conversion uses that same static target
```

This permits same-type and suitable widening conversions; it does not rely on
sample execution values or a chosen choice tape. There is no automatic guard
for a narrowing conversion just because a test happened to supply a small
number. An unknown eligibility result leaves the site explicitly unguarded.

[`conv_loaded_arith`](../../../frontend/corenice/model/translation_aux.lem)
already receives both types and is used by assignment, initialization and
return lowering. The integer-cast arm of
[`translate_expr`](../../../frontend/corenice/model/translation.lem) also has
both types. These are the first producer sites. Preserve their existing
effectful operand wrappers and original call arguments exactly. Do not enable
checks indiscriminately in `mkcall_conv_loaded_int`, whose interface lacks the
source type. Argument conversion using `mkcall_conv_loaded_int_` carries a
dynamic target expression and remains unguarded in the first milestone.

Source ranges are a placement justification, not a runtime premise taken on
faith: the guard checks the actual target and value. Loaded integer values
do not themselves retain the source C type. Proving that automatic guards
never fail therefore still needs the appropriate source-value/translation
invariant. Range inclusion alone is not that theorem.

Keep raw runtime-library calls unchanged in this first producer. They remain
executable and compared. Existing wrapping conversions, `_Bool` conversions,
and other deliberately unguarded cases must continue to work. A manually
inserted stronger guard or a later proof-producer annotation uses the same
runtime semantics but has a separate no-fault obligation.

Report eligible guarded sites and unguarded sites by reason: unsupported type,
dynamic target, range not included, or missing source-type context. These are
coverage reports, not a new all-C gate. An implementation failure at an
eligible site must fail loudly; it cannot masquerade as an unsupported site.

## Erasure, preservation and proof boundary

Structural erasure is exact:

```text
erase(PEchecked_int_call site name args) = PEcall name (map erase args)
```

Keep every original annotation, callee, argument, literal and semantic symbol.
Erase only the added constructor distinction and diagnostic site. Do not
normalize conversions, erase a changed target, or replace library calls with
host arithmetic. Extend the independent whole-artifact comparator accordingly.

The first eventual local theorem is the successful checked-call equation over
the actual production evaluator: argument evaluation and ordinary call
expansion agree, the check passes, and the same expanded body proceeds. The
specified-input case additionally establishes both target-range comparisons;
the unspecified case establishes no numerical fact. Under the pinned ordinary
library definition, the in-range branch returns the original integer.

Program correspondence separately needs producer no-fault correctness and
transport of the guard through all AST operations. A faulting Nice run is not
an equivalent Core run merely because its earlier observations agree. No
conversion theorem, general no-fault theorem or symbolic midpoint relation is
part of the implementation milestone.

The guard does not remove the old conversion's evaluation cost. Its immediate
benefit is the explicit successful-execution contract. It may not improve
symbolic proof effort enough to justify itself; a later small parametric client
exercise should compare against the existing reusable conversion lemmas.

## Implementation ownership and audit

Implement in the owned Lem definitions and ordinary CoreNice generation path;
no Lem compiler modification or original Core change is expected. Regenerate
the owned modules and quotation instrument. Never edit generated model output.

Audit the new pure constructor through typing, substitution, symbol mapping,
constraint lifting, runtime conversion, equality/ordering/printing and all
walkers. The relevant owned modules include `core`, `core_aux`, `core_eval`,
`core_typing`, `core_typing_aux`, `core_rewrite`, `core_indet`, `core_run_aux`,
`translation_aux`, `translation`, `errors`, `pp` and `formatted`; the
[ownership manifest](../../../frontend/corenice/sources.json) governs the real
dependency closure, so this list is a starting point rather than an exclusion.

In particular, `core_rewrite.remove_conv_int_pexpr` can fold away selected
ordinary `PEcall` expressions. A checked call cannot be folded to an ordinary
call, value or body while dropping the check. Preserve it
through rewriting, or explicitly refuse that optional transformation until
there is a check-preserving rule. The current differential lowerer does not
invoke the optional simplifier; test this transport independently rather than
claiming coverage from that fact.

Original Core text continues to parse ordinary unguarded calls. Typed AST
construction and producer-generated guards suffice for the first prototype;
no guarded textual roundtrip is claimed. Pretty-printing must still visibly
distinguish a checked call. Update typed fault JSON and diagnostic consumers.

## Differential and direct validation

Use the existing bidirectional choice-tape runner and exact observation profile
for ordinary successful runs. A pure call-entry check should introduce no
driver observation or choice requiring a weaker comparator. Exercise it with
both automatic execution and saturated pause/resume policies. Fuel exhaustion,
unexpected `NiceFault`, matched model errors and unsupported runs are failures
of ordinary validation, never positive matches. Deliberate negative controls
are reported separately with their exact expected failure.

Required direct production-evaluator checks:

* Lower and upper boundaries, zero, negative values, and one value outside each
  bound; signed and unsigned ordinary targets with model-derived limits.
* Unspecified input bypasses bounds and retains ordinary target retagging;
  a provenance-bearing specified integer reaches the unchanged conversion
  body. Assert exact value/body equality, not only a numerical projection.
* A still-reducing target paired with an already out-of-range value; nested
  target/value calls; undefined/error operands; unknown callee, wrong arity
  and non-function callee. Ordinary argument/call failures must win when the
  original call would encounter them before body execution.
* A function body that fails: if arguments pass the check, its failure remains;
  if a valid guard fails first, its `NiceFault` precedes body execution.
* Malformed and unsupported guard use is distinguished from a proved range
  failure. No success is manufactured from an undecided comparison.
* Substitution, constraint lifting, linking/conversion and optional rewriting
  retain the guard. Nested calls and duplicated expressions retain their own
  sites. No fresh semantic symbol is consumed.

Required C-level evidence:

* Same-type and signed/unsigned range-including casts, assignments,
  initializations and returns; loops and calls that revisit guarded code.
* Narrowing/wrapping and `_Bool` controls remain unguarded and agree with Core.
  Dynamic argument targets and other excluded categories are reported honestly.
* Complete paired artifact equality under the narrow erasure, including fresh
  supplies. Mutating the retained target, callee or argument must remain visible
  to the independent artifact comparator.
* Genuine competing-call schedules and all/none/every-second pause policies on
  a small fixture containing guarded conversions. No check is moved across a
  memory action, argument evaluation, return or breakpoint.
* Post-finalization insertion of a guard at a known out-of-range ordinary
  conversion produces the typed range fault at the reached site. The unguarded
  original must complete with its normal wrapping/implementation-defined result.
  Retain and compare the preceding observable prefix; require the expected
  guard payload, not just any failure.

Static guard counts alone cannot demonstrate execution. For selected normal
guarded sites with static target `T`, add this post-finalization operand
mutation using existing pure AST nodes:

```text
case originalOperand of
  Specified(_)   => Specified(max(T) + 1)
  Unspecified(_) => Specified(max(T) + 1)
```

Use wildcard binders and no fresh semantic symbols. This evaluates the original
operand before supplying a deliberately out-of-range value to the unchanged
production guard. Keep its callee, target, site and surrounding program intact.
The unmutated witness must first pass; require the exact `NiceFault` at that
selected site and the baseline preceding choice/effect prefix. Assert that
exactly one guarded occurrence was mutated and that independent artifact
comparison detects the deliberate operand change. A missing/ignored guard
cannot satisfy the required fault payload. A timeout, ordinary UB or model
error cannot count as detecting the mutation.

This witnesses reached sites, not every dynamic activation. It is limited to
the static-target recipe and sufficiently provisioned finite tests; it is not
an exact fuel or arbitrary dynamic-target correspondence argument. No global
logger, effectful pure-evaluator counter, or production test flag is needed.
The existing [source-mutation machinery](source-mutations.md) remains available
for further calibration if a real coverage gap justifies it.

## Retained proposed milestones (inactive)

1. **AST and runtime guard.** Implement the owned constructor, typed fault and
   call-entry rule; regenerate and build the affected closure. Direct tests
   must establish failure precedence, identity of the successful expanded body,
   unspecified bypass and provenance preservation before producer rollout.
2. **Conservative producer and erasure.** Add the static range-inclusion policy
   at the source-aware conversion sites, separate diagnostic IDs, coverage
   report and precise artifact erasure. Keep excluded conversions ordinary.
3. **Differential evidence.** Run the focused positive/negative controls above,
   meaningful samples from the existing C campaign, and interactions with
   comesfrom and saturated breakpoints. Record named commands, input/tape
   counts, reached sites and untested categories; discard raw traces afterward.
4. **Independent review.** Review semantics and instruments without restricting
   scope, resolve findings individually, and present a local milestone candidate
   for the integration branch. Do not imply a proof or automatic landing.

No full proof build is needed for this design document. Implementation gets
focused regeneration/build/runtime validation; actual theorem claims later
receive the repository's axiom and kernel-replay checks. There is no new broad
gate or requirement to prove the compiler before obtaining a useful prototype.

## Decisions and review

* [USER, 2026-11-17] Explore a runtime representability check while retaining
  ordinary Core conversion, following the additive CoreNice approach.
* [AGENT, 2026-11-17] Propose a checked pure-call constructor that checks the
  already evaluated arguments after ordinary call expansion, and begin with
  source-type range inclusion as the automatic placement policy.
* [AGENT, 2026-11-17] Park this proposal as the next addition: a safe runtime
  mechanism alone does not establish the required structural justification;
  the input's source-range invariant remains unaccounted for.

Independent unrestricted source/design review found no semantic blocker for
the stated concrete recipe. Its two document findings are resolved:

| Finding | Disposition |
| --- | --- |
| The rewrite audit described general call-body inlining, but the inspected routine folds away selected calls. | Corrected the description and named `remove_conv_int_pexpr`; retaining or explicitly refusing the guard remains required. |
| The first supported integer set left character inclusion tentative and could admit special bases inside `Signed`/`Unsigned`. | Specified the exact five admitted base constructors and actual retained `Ctype` shape. |

The review also checked argument-round/error precedence, unspecified bypass,
provenance, producer eligibility, the input/result contract distinction and
executed-site mutation controls. Local link and whitespace checks pass. No
generation, builds, execution campaigns or kernel replay were run for this
documentation-only design (replay time: not applicable). It records no
implemented or measured result.
