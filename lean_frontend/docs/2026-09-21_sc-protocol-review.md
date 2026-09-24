# SC protocol integration review

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


2026-09-21, [AGENT]. Parent: `4bba2b458`. This records the current S1/S2
protocol slice under the [charter](2026-09-21_charter-sc-prototype.md).
It does not claim atomic/race/fence checking or a complete SC prototype.

## Shared source changes and oracle drift

`Ememop` now carries the same runtime-annotation parameter as Core actions
and calls. The C elaborator and text parser construct unit annotations;
`convert_expr` changes them to empty runtime annotations. Substitution,
rewriting, renumbering, typing, inlining and pretty-printing preserve the field
or deliberately ignore it when their result is independent of annotations.
The pretty-printed syntax is unchanged. The Lean parser and speclab Core
constructors carry the corresponding unit field. Mechanical arity updates also
cover the BMC, abstract-interpreter, web and old OCaml backend sources; these
backends are not independently certified by the normal driver build.

`Core_reduction.step_ctx_with` wraps the existing reducer with an optional SC
context. `step_ctx` remains its disabled wrapper. Completion receipts distinguish
the legacy action-id result from an enabled SC event set. Ordinary calls,
memops and filesystem completions use the existing continuations. The modern
stack records whether an entry came from a C call or a Core procedure, so C11
6.5.2.2p10's indeterminate sequencing does not become a rule for every Core call.
The new join constructor is appended after the old payload constructors to
preserve their OCaml comparison ranks. Closure comparisons still fail loudly.

`Sc_order` implements continuation-scoped predecessor propagation. Scheduling
an unsequenced sibling does not annotate its peers. Weak sequencing passes
positive effects; strong sequencing promotes completed negative effects.
Receiving requests separate same-thread `sb` from cross-thread additional-sw.
C call entry/return carries the appropriate indeterminate order. Joined child
history includes descendants even if the parent performs no intervening access.
These are operational metadata rules, not a proved correspondence to Cmm.

`Sc_runtime` retains every primitive observation by fresh occurrence identity.
Request boundaries and internal effects remain separate. Allocation/lifetime,
byte/provenance data and varargs observations remain available to the unfinished
checker. `sc_step` exposes every currently enabled Core/thread choice without
deduplication. Child errno is allocated separately and left indeterminate, as
required by C11 7.5p3. Startup effects are owned and precede the corresponding
main/child continuations without ordering unrelated expression siblings.

Driver memory operations use the checked lift only when SC state is enabled.
The old public `liftMem`, sequential wrappers and finalization grouping remain.
`drive_recorded true` is an internal unchecked execution entry used by component
tests after `sc_enable`; the public `drive true` still returns an explicit port
gap after recording. No unchecked recorded result is advertised as SC success.

The fork-drift refresh preserves every historical review note, `renumber=arc13`,
the pinned upstream merge-base and the Lem pin. It adds eleven source-surface
paths and updates eleven existing source pins. Two new generated modules have
content pins. `core.ml` and `core_aux.ml` move from cosmetic to semantic because
their annotation signatures/bodies now change. Other changed generated hashes
correspond to the shared changes above. Paired build agreement cannot validate
these modeling choices independently. The retained full run, diagnostic repair,
fresh Tier A and three-engine report provide the integration evidence below.

## Failure-register review

The first unit run intentionally encounters a stale register: ten old
`step_ctx` sites move to `step_ctx_with`, two `drive_fs_step` sites move to
`drive_fs_step_with`, and one `perform_memop_request2` site moves to
`perform_memop_with`. Each retains the same failure expression, position and
reviewed reach class. No unknown site is silently promoted to unreachable.

Four new sites receive source-invariant reviews for the `drive` execution path:

- The `Step_join2` equality arm contains a closure and must fail if compared
  structurally. Driver equality tests only the nullary blocked constructor;
  the SC selector pattern-matches and never compares payloads.
- Both `sc_receipt_from_state` failures reject a broken ownership invariant.
  Public SC entry enables the state; each action/memop/runtime request begins
  ownership before its completion. Checked lifting preserves ownership or
  kills before that callback. Sequential wrappers use their original receipt.
- The runtime completion callback expects an `Epure` arena. Its only callers
  pass states produced by `th_st_from_int`, `th_st_from_ptr` or
  `th_st_from_void` in `drive_fs_step_with`, each of which constructs that shape.

These are reviewed source claims, not universal API invariant theorems.
The resulting register has 238 sites: 171 invariant-unreachable, 48 reachable,
19 unknown; 236 have execution-closure owners and two have unresolved owners.
There are no discardable generated failures. The census and exact review delta
are retained in the worktree's `.tmp/sc-prototype/protocol-failure-*` evidence.

## Component evidence and proof limits

Both targets regenerate and both production builds pass. The Lean library
build includes every declared root. All 18 production SC protocol controls pass
at caller fuel 64. OCaml's actual exhaustive `Smt2.runND` passes the same 18
groups: thirteen execution/order groups with matching alternative counts and
five controls for original failure preservation, completed read/equal-write
prefixes, journal draining, and explicit failure with retained raw observations
when ownership is absent. Inputs are constructed Core and checked memory states;
this is not C-to-Core coverage. The existing observation, fail-stop and fuel
exemplar controls also pass.

Eight kernel laws describe the actual operations: disabled lifting at every
caller fuel; disabled post-memory observation; unsequenced, weak, strong and
C-caller continuation equations; descendant completion retention; and exact
membership of `sc_choices` in the current Core/thread choices. The existing
fuel-exemplar theorem still proves its original statement for its one program,
all caller fuels and all allowed address-space tops. It is not a universal
single-thread conservativity theorem. The unit run's fuel classifier reports
64 measured, 15 absorbing and no reachable ambient worker; all eight new laws
pass the existing axiom policy.

Two fresh production connection plants are detected: disconnecting checked
lifting breaks the failure-prefix control, and ordering every request after
all thread history breaks the unsequenced-store control. Both mutated overlays
compile and fail on the intended witness. Four C frontend-to-recorder controls
pass in both native engines (1/6/6/6 alternatives); their isolated entry wrappers
invoke unchecked recording. They do not establish a shipped C SC verdict path.

## Integration checkpoint, 2026-09-22

The original full run completes all 39 selected commands, with B10.1 alone
failing on seven renamed frames. The exact
[diagnostic review](2026-09-21_sc-protocol-diagnostic-review.md) and register
repair preserve failure statuses and the existing comparison projection.
Fresh Tier A passes all 16 commands. The mandatory 859-case three-engine report
passes the pristine gate, and its 40 differing/undecodable Lean IDs exactly
match the observer checkpoint. Fresh comparator plants and fork-drift pass.

All 1,808 executable/tool/runtime artifact records and both external input
inventories are identical across the original full and fresh fast runs. The
intervening registry, comments and documentation edits do not invalidate the
unaffected passing Tier B results. Those results are retained; the original
full report remains failed rather than being rewritten as a fresh 39/39 run.
[Integration evidence](2026-09-21_sc-prototype-evidence/protocol/integration/README.md)
contains the original statuses, repair identity argument and raw observations.
Final completion still requires a fresh full run. Atomic/race/fence/
representation/lifetime composition and C entry wiring remain unfinished.
