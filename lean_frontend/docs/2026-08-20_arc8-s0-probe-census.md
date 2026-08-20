# Arc-8 S0: cerberus-scale DAEMON-elimination probe — demand census [AGENT:S0]

Date: 2026-08-20. Worker: arc-8 S0 (worktrees `arc/daemon-elim`, CERB @
`8bd59277d`, LEM @ `bd7e2eb`). Executes the probe designed in
`docs/2026-08-20_april-inhabited-archaeology.md` §D under the charter
(`docs/2026-08-20_arc8-daemon-charter.md`, slice S0). All edits were made
to `lean_frontend/generated/` as SCRATCH (never committed): the tree was
snapshotted to a tar before any edit, restored between legs, and restored
+ checksum-verified before this commit (appendix). Every build ran through
`../scripts/capped` (64G default cap). NO lem code was touched.

Verbatim-transcript doctrine: every quoted block below is literal tool
output; all tallies are labeled measured (grep/awk output) or derived.

## Executive summary

ALL THREE PROBE LEGS ARE GREEN, plus a fourth exploratory sweep (full
ablation of every generated DAEMON fallback instance) that converged in
3 rounds to a tiny, fully enumerated demand set. The April failure mode
did not reproduce anywhere:

- Leg (a) — in-module real ndM/nd_action/kill_reason instances +
  failwithI on msum/pick/log/mplus: **green on the first capped build,
  zero binders demanded, zero downstream errors.**
- Leg (b) — `[Inhabited a]` binders on bare-tyvar stubs (nd_mem,
  is_affection, fromLeft/fromRight; extended with the live-caller pair
  current_scope_is/destroy_scope): **green both builds, zero upward
  propagation; every concrete call site discharged via existing real
  instances.**
- Leg (c) — the literal April-class-1 re-run: DAEMON fallbacks for the
  6 generic Core AST family types DELETED, bounded real instances
  (`[Inhabited bty]`) supplied in-module: **green over the full
  CerberusLean lib including `Core_rewrite`'s fully-polymorphic
  `partial def`s (`flatten_seqs`, `remove_dead_aux` — free `bty`, no
  binder, no leak).** The April killer — `[Inhabited]` constraints
  leaking into partial-def signatures — did NOT recur, and the probe
  identified the mechanical reason (below).
- Leg (c3) extension — ALL 49 remaining `default := DAEMON` fallback
  instances ablated tree-wide: the ENTIRE demand = 8 h-shaped monadic
  `partial def`s + 31 value-level sites, discharged by 12 in-module
  real instances for 11 types, converging GREEN in 5 rounds (full
  round-by-round enumeration below). The tree now builds with ZERO
  Inhabited-DAEMON fallback instances.

**Recommendation: GO** (§Recommendation, with conditions that are
design inputs to S1/S2, not blockers).

## The load-bearing mechanism discovery

Lean 4.32.2's partial-def inhabitation check is the reason the April
class-1 demand is structurally gone. Scratch probe (toolchain
`leanprover/lean4:v4.32.2`, file not committed): a `partial def f {b :
Type} (g : T b) : T b := f g` over a `T` with NO Inhabited/Nonempty
instance anywhere COMPILES; the no-witness variant fails with (verbatim):

```
arc8s0-scratch.lean.tmp.lean:12:0: error: failed to compile 'partial' definition `h`, could not prove that the type
  {b : Type} → Nat → T b
is nonempty.

This process uses multiple strategies:
- It looks for a parameter that matches the return type.
- It tries synthesizing 'Inhabited' and 'Nonempty' instances for the return type, while making every parameter into a local 'Inhabited' instance.
- It tries unfolding the return type.

If the return type is defined using the 'structure' or 'inductive' command, you can try adding a 'deriving Nonempty' clause to it.
```

Consequences, all confirmed at cerberus scale by the legs below:
1. A `partial def` taking an argument of (or convertible into) its
   return-type family needs NO instance at all — this covers almost all
   of the 318 residual partial defs (AST transformers take the AST as
   input). This check is a Nonempty side condition; it leaves NOTHING
   in the term, so no cone/axiom footprint either way.
2. Strategy 2 ("making every parameter into a local 'Inhabited'
   instance") means `[Inhabited x]`-bounded derived instances fire for
   h-shaped defs whose parameters happen to include the needed tyvars —
   without any signature edit (e.g. `trysM` below).
3. April's world (every generated function a `partial def` whose return
   type had to be *instance*-inhabited) no longer exists on two
   independent axes: totalization removed most partial defs, and the
   checker no longer needs instances when witnesses are in scope.

## Baseline

Pristine `generated/` snapshot: `generated-pristine.tar` (worktree root,
untracked, 195 .lean files). Aggregate checksum of all .lean files
(md5 of sorted per-file md5 list): `cd52557c00c4b017e15eae41049a359d`.
Baseline capped build of the pristine tree (verbatim tail):

```
Build completed successfully (275 jobs).
```

(exit 0; `../scripts/capped lake build cerberus-lean` from
lean_frontend/.)

## Leg (a) — ND monad seam: in-module real instances + failwithI

Edits (all in `generated/Nondeterminism.lean`, pristine line numbers):
- :64–65 `instance (priority := low) {err} : Inhabited (kill_reason err)
  … default := DAEMON` → real `default := Undef0 default default`.
- :123–126 the nd_action/ndM DAEMON fallbacks → real
  `default := NDkilled default` and
  `default := ND (fun st1 => (NDkilled default, st1))`
  (CerbInhabitedInstances:59–63 bodies, simulating backend derivation
  IN-MODULE — the class the arc-7 eviction mechanism cannot reach).
- failwith → failwithI at the four ndM-typed sites: :215 (`log`), :223
  (`mplus`), :226 (`msum`, the `"ND2.msum []"` branch), :257 (`pick`,
  the empty-list branch). The two bare-tyvar sites in the module
  (nd_mem :268, warns_if_no_active_ex :278) were left for leg (b).

Build 1 (`lake build cerberus-lean`, exe closure = 275 jobs, includes
Cmm_op/Core_run/Driver/Translation): **green, first try** (verbatim
tail):

```
✔ [275/275] Built «cerberus-lean»:exe (510ms)
Build completed successfully (275 jobs).
```

**Demand set: EMPTY.** No `[Inhabited a]` binder was demanded on msum,
pick, log, mplus, or any transitive caller; the unconditional in-module
instances discharged failwithI at all four sites and the whole importing
world re-elaborated unchanged. `pick` is on every driver cone, so this
is the highest-traffic site in the tree.

## Leg (b) — bare-tyvar stubs: `[Inhabited a]` binders

Tree restored from tar (checksum re-verified = pristine) before this leg.

Edits:
- `generated/Nondeterminism.lean:267–268` `nd_mem {a b c} (x : b)
  (m : c) : a` → `[Inhabited a]` binder + failwithI.
- `generated/Utils.lean:106` `fromLeft {a b} : Sum a b → a` and `:109`
  `fromRight` → `[Inhabited a]` + failwithI.
- `generated/Defacto_memory.lean:377` `is_affection {a b c} … : a` →
  `[Inhabited a]` + failwithI.

Build 1: **green** (verbatim: `Build completed successfully (275
jobs).`, exit 0, zero `error:` lines in the log).

Caveat found and answered: reference census shows fromLeft, fromRight
and is_affection have ZERO call sites in the generated tree (dead in
the current corpus), so their green is weak evidence. nd_mem has one
live use — `generated/Cmm_op.lean:416`, inside the `monTrace` inductive
at type `Prop` — which resolved via Lean core's `Inhabited Prop`
(Cmm_op.olean rebuilt in this run).

Extension (recorded deviation from the archaeology's pick, same class):
because the "known polymorphic callers" example was dead code, the leg
was extended with a LIVE-caller bare-tyvar site:
- `generated/Scope_table.lean:85` `current_scope_is {a ident scope} :
  List ((scope × Fmap ident a)) → scope` → `[Inhabited scope]` +
  failwithI. Live callers: `generated/Cabs_to_ail_effect.lean:564,
  :577, :1149` (concrete `scope`).
- `generated/Scope_table.lean:73` `destroy_scope` → failwithI only (its
  site type `(Fmap ident a × List (scope × Fmap ident a))` is fully
  discharged by LemLib's unconditional `Inhabited (Fmap α β)`
  (lean-lib/LemLib.lean:412) + Prod/List — a binder-free composite
  site).

Build 2: **green** (verbatim: `Build completed successfully (275
jobs).` / `EXIT:0`, zero `error:` lines). The live callers' demands
were discharged by the backend's OWN existing tier-1 real instance
`generated/Cabs_to_ail_effect.lean:207–208`:

```
instance : Inhabited (scope) where
  default := Scope_function
```

**Demand set: EMPTY at depth 1.** No binder propagated to any caller;
instance-implicit binders resolved silently at every concrete call site.

## Leg (c) — the April-class-1 re-run (partial-def sea)

Tree restored from tar (checksum re-verified = pristine) before this leg.

Edits (`generated/Core.lean`, pristine line numbers): the DAEMON
fallback instances for the 6 generic AST family types DELETED and
replaced in-module by the CerbCoreInstances.lean:37–64 real bodies:
- :479–482 `generic_pattern_ sym` / `generic_pattern sym` →
  unconditional (`CaseBase (none, BTy_unit)` / `Pattern [] …`).
- :587–590 `generic_pexpr_ bty sym` (unconditional PEundef node) /
  `generic_pexpr bty sym` (**`[Inhabited bty]`-bounded**).
- :841–844 `generic_expr_ a bty sym` / `generic_expr a bty sym`
  (both **`[Inhabited bty]`-bounded**).

Direct test subjects (fully polymorphic partial defs over the family
with FREE `bty`, i.e. exactly the April class-1 shape):
`generated/Core_rewrite.lean:191` `partial def remove_dead_aux {a b c}
(g : generic_expr c b a) : Sum (generic_expr c b a) (generic_expr c b
a)` and `:198` `partial def flatten_seqs {a b c} (g : generic_expr c b
a) : generic_expr c b a`; plus the concrete-`bty` cohort (remove_skips,
remove_unseqs, pure_propagation2, simpl_case, sequentialise_creates_
kills) and every other user of the family in the closure.

Build 1 (`lake build cerberus-lean`, 275 jobs): green — but
Core_rewrite/Core_sequentialise are OUTSIDE the exe import closure, so:

Build 2 (`lake build CerberusLean` — the full 227-job lib target whose
roots include Core_rewrite, lakefile.toml:79): **green, zero errors**
(verbatim tail: `Build completed successfully (227 jobs).` / `EXIT:0`);
Core_rewrite line (verbatim):

```
⚠ [219/275] Built Core_rewrite (1.5s)
```

(warnings only — unused-variable lints). **`[Inhabited]` did NOT leak
into any partial-def signature.** The free-`bty` subjects elaborated via
the argument-witness strategy (`g` inhabits the return family); the
concrete-`bty` cohort resolved the bounded instances at `bty := Unit`
etc. April's class-1 killer is structurally absent on today's tree.

## Leg (c3) extension — full fallback-ablation sweep (exploratory)

To enumerate the ENTIRE fallback demand surface in one experiment (the
charter's risk-6 census), every remaining `default := DAEMON` Inhabited
instance in the generated tree was ablated (commented out) on top of the
leg-(c) state — 49 instances (measured; + the 6 already replaced in
Core.lean = 55 total in the pristine tree across 15 files: Cn 20,
Core 14, AilSyntax 5, Nondeterminism 4, Core_aux 2, and 1 each in
Cerb_attributes, Bimap, Exception, Core_run_aux, Core_reduction, Dlist,
ErrorMonad, Undefined, Monadic_parsing, Multiset). No replacement
instances were supplied initially — the build errors ARE the demand
census. Iteration (one capped `lake build CerberusLean cerberus-lean`
per round; every error verbatim in the logs, key ones below):

**Round 1** — total demand: 4 partial defs, 2 types.

```
error: generated/Exception.lean:109:1: failed to compile 'partial' definition `except_foldlM`, could not prove that the type
  {a b msg : Type} → (a → b → exceptM a msg) → a → List b → exceptM a msg
is nonempty.
```

plus (same shape, headers only): Exception.lean:161 `trysM`
(`{a b msg} → msg → (a → exceptM b msg) → List a → exceptM b msg`),
Monadic_parsing.lean:117 `string0` (`List Char → parserM (List Char)`),
Monadic_parsing.lean:124 `many` (`{a} → parserM a → parserM (List a)`).
Nothing else in the reached prefix demanded anything. Fix: in-module
real instances — for exceptM one bounded instance PER CONSTRUCTOR
(`[Inhabited a] ⟨Result default⟩` at default priority, `[Inhabited msg]
⟨Exception default⟩` at low — except_foldlM needs the first via its
`a`-typed parameter, trysM needs the second via its `msg` parameter,
both through the checker's strategy-2 local instances); for parserM the
unconditional `⟨ParserM (fun _ => [])⟩`.

**Round 2** — total demand: 4 partial defs, 2 types (next modules in
topological order; Exception/Monadic_parsing now green).
ErrorMonad.lean:120 `ailErr_mapM` / :130 `ailErr_foldM` (type `errorM`),
Exception_undefined.lean:84 `exception_undef_foldM` / :89
`exception_undef_foldrM` (type `t0` via `exceptM (t0 a) b`). Verbatim
head of the first:

```
error: generated/ErrorMonad.lean:120:1: failed to compile 'partial' definition `ailErr_mapM`, could not prove that the type
  {a b : Type} → (a → errorM b) → List a → errorM (List b)
is nonempty.
```

Fix: in-module `⟨ErrorM (fun _ => Sum.inl default)⟩` (unconditional)
and `⟨Undef default []⟩` for t0 (unconditional, ground constructor).

**Round 3** — the demand class changes from partial defs to VALUE-LEVEL
sites (existing ground failwithI/default sites now resolving against
the ablated instances): 30 `failed to synthesize` errors in 3 files —
Defacto_memory 23 (all at concrete `ndM …` instantiations, e.g.
verbatim:

```
error: generated/Defacto_memory.lean:388:287: failed to synthesize instance of type class
  Inhabited (ndM impl_mem_value String mem_error (mem_constraint impl_integer_value) impl_mem_state)
```

— 7 distinct ndM instantiations), Desugaring_init 5 (3 distinct sites
at `Inhabited (expression Unit)`, AilSyntax family), Core_reduction 2
(`Inhabited (action_request2 thread_state)` and `(action_request2 (expr
core_run_annotation))` — the step_ctx same-module demand, i.e. the
known `instInhabitedAction_request2` entry vector reproduced exactly as
predicted). Fix: in-module real instances — Nondeterminism
kill_reason/nd_action/ndM (the leg-(a) bodies), AilSyntax
`⟨AilEconst default⟩` for expression_ (over the real tier-1 `constant`
instance :293) and the `[Inhabited a]`-bounded AnnotatedExpression
instance for expression, Core_reduction `[Inhabited a]`-bounded
`⟨KillRequest2 default default (fun _ => default)⟩`.

**Round 4** — total demand: 1 site, 1 type (verbatim):

```
error: generated/Driver.lean:149:28: failed to synthesize instance of type class
  Inhabited (file core_run_annotation)
```

Fix: in-module unconditional record instance for `generic_file bty a`
(all 11 fields default-inhabitable — Option/Fmap/List/enum heads; no
tyvar consumed).

**Round 5 — CONVERGED GREEN** (verbatim tail):

```
Build completed successfully (370 jobs).
```

(exit 0; the full CerberusLean lib + exe closure, including
Core_rewrite and — incidentally — RelSem.RunND/Cerberus/Call, which
re-elaborated green under the new instances. RelSem's Audit/T1–T4
modules were NOT in this closure — see condition 5.)

**Sweep totals (derived):** with all 55 fallbacks gone, the ENTIRE
tree-wide demand was 8 h-shaped partial defs (rounds 1–2) + 31
value-level sites (rounds 3–4), discharged by 12 in-module real
instances covering 11 types (exceptM ×2 constructors, parserM, errorM,
t0, kill_reason, nd_action, ndM, expression_, expression,
action_request2, generic_file) on top of the 6 leg-(c) Core-family
instances. Convergence in 5 rounds, monotone, no oscillation, no
signature ever edited, no demand ever propagated past the defining
module of the demanded type. The demand surfaced ONLY in the
effect-monad modules and at same-module/driver ground sites — the very
classes whose real-instance designs already exist in
CerbInhabitedInstances/CerbCoreInstances; never in the AST partial-def
sea.

## Instance-method / function-field census (the one-level-protection gotcha)

- **failwith inside generated `instance` blocks: 0** (measured — awk
  sweep pairing every top-level `instance` header with its indented
  body across all 195 generated .lean files found zero `failwith`
  occurrences inside instance bodies). The reader-lift-style fail-closed
  instance-method guard therefore has NOTHING to guard against in
  today's corpus; it should still exist (durability req 1).
- **Function-field / point-free storage of would-be-threaded defs: none
  found.** Empirically: every leg build was green, so no unresolved
  instance metavariable arose anywhere; specifically the S2 worklist
  defs (below) are referenced only fully-applied at concrete types
  (reference census: illTypedAil 30+ uses in Translation.lean,
  ensure_not_c_variable in Cabs_to_ail/Cabs_to_ail_effect, insupported
  4 uses in Core_unstruct, foldl2 in Core_run/Core_eval, fromJust in
  Core_typing, current_scope_is in Cabs_to_ail_effect; nd_mem's single
  use is Cmm_op.lean:416 at Prop; fromLeft/fromRight/is_affection/
  is_concrete_ival/impl_isWellAligned_ptrval/impl_memcpy/
  warns_if_no_active_ex have no callers in the tree).

## The enumerated S2 worklist (bare-failwith census, pristine tree)

Measured: 73 `failwith[^I]` grep occurrences across 14 files
(Defacto_memory 19, Core_linking 13, Utils 6, Core_run_aux 6,
Nondeterminism 6, CerbMem 5, Scope_table 4, Core_aux 4, Core_typing 3,
Translation_effect 2, Cabs_to_ail_effect 2, Translation_aux 1,
Core_unstruct 1, Cn 1 — raw occurrences incl. appended lem-source
comment blocks), in 54 enclosing defs, of which 5 are in the
hand-written seam file CerbMem.lean (callIntrinsic, integerIval,
opIval, provFromIntegerBytes, reconstructValue_lemFuel — OUT of backend
scope; hand-edit to failwithI separately) → **49 generated enclosing
defs**. Classified by failure-site type (derived from the extracted
signatures):

**Class M — monad/composite-headed, NO binder needed** (site type
discharged by an unconditional or concretely-bounded real instance;
proven by legs (a)/(c3)): Nondeterminism log/mplus/msum/pick;
Defacto_memory project_to_lvalue_type/impl_ne_ptrval/
get_allocation_size/perform_access/impl_case_mem_value (higher-order
`a` via funspec parameters — checker strategy 2); Cabs_to_ail_effect
as_switch_body/cabs_to_ail_effect_guard; Core_run_aux all 6 (exceptM/
stack-headed, concrete err); Core_linking link/merge_globs/
safe_map_union/free_action/free_expr/free_pexpr (List/Fmap/exceptM
heads); Core_typing typecheck_expr (+2 comment occurrences);
Core_aux seq_rmw/subst_pattern_val/unsafe_subst_pattern (generic_expr a
Unit sym — bounded instance fires at bty := Unit)/update_env_aux (Fmap);
Scope_table register/return_scope/destroy_scope (List/Fmap); Utils
map2_/list_index_update (List); Cn ensure_not_c_variable's… — no:
ensure_not_c_variable is class T. Derived count: ~36 of 49.

**Class T — true bare-tyvar sites, binder `[Inhabited tv]` required**
(~13 defs, the entire S2 threading surface; caller depth measured ≤ 1,
i.e. zero call-site/caller edits anywhere):
nd_mem, warns_if_no_active_ex (Nondeterminism); is_affection,
is_concrete_ival, impl_isWellAligned_ptrval, impl_memcpy
(Defacto_memory); insupported (Core_unstruct); illTypedAil
(Translation_aux); ensure_not_c_variable (Cn); fromLeft, fromRight,
fromJust, foldl2 (Utils); current_scope_is (Scope_table);
runStateM_errors, track_temporary_objects (Translation_effect — tyvar
under a product). Derived count: 16. All callers are at concrete types
(census above); instance-implicit binders mean zero call-site edits
(proven for nd_mem/current_scope_is with live callers).

## GO / NO-GO recommendation

**GO.** The strongest single piece of evidence: **leg (c) build 2 —
`Core_rewrite` (the module of fully-polymorphic `partial def`s over the
multi-tyvar `generic_expr` family, the exact shape that killed April on
first cerberus contact) compiled green with the DAEMON fallbacks
DELETED and only `[Inhabited bty]`-bounded real instances present,
demanding not a single signature constraint.** The April demand
explosion is not merely reduced — the mechanism that generated it
(instance-only inhabitation of every partial def's return type) no
longer exists in Lean 4.32.2's checker, and the probe measured the
entire residual demand surface: ~16 leaf defs needing one binder each
(depth ≤ 1), plus a handful of same-module monadic instances the S1
derivation must emit.

Conditions (design inputs for S1/S2, none blocking):
1. **S1 must emit derived instances IN-MODULE** (same file as the
   type) — the round-1/2 errors and the leg-(a) msum/pick class show
   hand-file eviction structurally cannot reach same-module and
   early-monad-module demands (the instInhabitedAction_request2
   precedent generalizes).
2. **S1 should derive one bounded instance per usable constructor**
   (priority-ordered, LemLib Sum-pair precedent LemLib.lean:90–91) —
   `except_foldlM` vs `trysM` need DIFFERENT constructors of exceptM;
   single-choice derivation would have left a residue.
3. **S2's threading surface is the Class-T list above** (16 defs,
   depth ≤ 1 today); the pass still needs the general fixpoint for
   durability req 1, but no corpus evidence of any deeper closure.
4. Behavior-neutrality (S3 zero-movement bar) was NOT probed here —
   probe legs only establish compile-time demand; runtime differential
   surface untouched by design.
5. RelSem/proof-layer re-elaboration was only PARTIALLY probed:
   RelSem.RunND/Cerberus/Call rebuilt green under the full ablation
   (round 5), but Audit.lean and the T1–T4 modules were outside the
   probed closure. S3 must expect Audit.lean's DAEMON-census pins to
   need UPDATING in the same commit as the deletion (they will fail
   loudly otherwise — that is the tripwire working) and must re-check
   the T1–T4 proof modules against the changed instance set.
6. The nd_mem-at-`Prop` datum (Cmm_op.lean:416) shows threading must
   tolerate tyvars instantiated at `Prop` (Lean core provides
   `Inhabited Prop`; no action needed, recorded for completeness).

NO-GO tripwires checked: no unbounded demand growth anywhere (largest
single-round demand: 4 defs); no demand escaped into the partial-def
sea beyond the enumerated monad modules; no deriving-chain (BEq/Ord)
entanglement observed in any round (the sorried BEq/Ord fallbacks were
never touched and never interacted).

## Appendix — restoration + gate re-run before commit

`generated/` restored from the pristine tar; aggregate checksum
re-verified equal to the pre-probe value
`cd52557c00c4b017e15eae41049a359d`; grep for the probe markers
(`ABLATED leg-c3` / `ARC8-S0 PROBE`) over the restored tree: zero hits.

Clean capped rebuild of the restored tree (verbatim tail of
`../scripts/capped lake build cerberus-lean`):

```
Build completed successfully (275 jobs).
EXIT:0
```

`./scripts/test_unit.sh` from the worktree root (verbatim tail):

```
==========================================
Total: 5 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (2 declared-boundary axioms)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
'core_object_type_of_ctype' does not depend on any axioms
'get_membersDefs' depends on axioms: [propext, Classical.choice, Quot.sound]
'zeros_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'fresh_symbol'' depends on axioms: [propext, Classical.choice, Quot.sound]
'match_pattern' depends on axioms: [propext]
'convert_pexpr' does not depend on any axioms
'nd_bind' does not depend on any axioms
'subst_sym_pexpr' depends on axioms: [propext, Classical.choice, Quot.sound]
'driver2' depends on axioms: [DAEMON, propext, Classical.choice, Quot.sound]
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free (DAEMON allowed there, per arc-3 D9)
check_theorem_axioms: OK (post-S5 bar: DAEMON-clean cones)
check_exec_totality: CLEAN (16 generated modules + hand-written CerbND, 0 allowlisted)
EXIT:0
```

(exit 0). Probe artifacts (logs `arc8s0-*.log`, the scratch file, the
pristine tar, the per-file checksum list) lived in the worktree root,
untracked, and were removed after this verification; only this census
is committed. `git status` at commit time shows the docs file as the
sole change.
