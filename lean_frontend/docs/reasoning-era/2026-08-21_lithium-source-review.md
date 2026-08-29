# Lithium source review — RefinedC's automation engine vs our walker/emitter

Date: 2026-08-21. Provenance: [AGENT: lithium-source-review worker],
read-only survey. Companion to the external literature survey (brief:
`notes/2026-08-21_iris-litreview-brief.md`); this document is the
CODE-level pass the paper survey won't reach.

Sources read (all under `deps/refinedc/`, vendored checkout):
`ARCHITECTURE.md`, `DEVELOPERS.md`, `GUIDE.md`, `FAQ.md`, all of
`theories/lithium/` (base, pure_definitions, definitions, syntax,
hooks, proof_state, normalize, simpl_classes, simpl_instances (skim),
solvers, instances, interpreter, lvar, benchmarks/), and a lighter
pass over `theories/caesium/` (lang, lifting, tactics, notation heads)
and `theories/typing/` (programs, automation, adequacy, GUIDE).
Comparison target: our arc-9 walker
(`worktrees/cerberus-lean-arc/wp-tactics/lean_frontend/relsem/RelSem/Tactics/AppWalk.lean`,
`AppEqAttr.lean`, `Kit/`), and the S2/S3 build records
(`docs/2026-08-20_arc9-s2-build.md`, `docs/2026-08-20_arc9-s3-build.md`).

**Labeling convention:** claims tagged **[S]** are read directly from
the cited source lines (paraphrase of code, not of papers); claims
tagged **[R]** are my reconstruction/inference (architecture-level
reading between files, or a judgment call). File:line cites are
against the vendored checkout as of 2026-08-21.

---

## 1. Lithium's execution model, precisely

### 1.1 The goal grammar

**[S]** Lithium goals are ordinary Iris propositions (`iProp Σ`) in a
restricted grammar, presented in continuation-passing style: nearly
every connective takes the *rest of the proof* as an explicit
continuation argument. The grammar is defined as thin definitions over
Iris connectives in `theories/lithium/syntax.v:6-68` (module `li`):

- `exhale P T := P ∗ T` (prove/consume P, continue with T) — syntax.v:11-12
- `inhale P T := P -∗ T` (assume/produce P) — syntax.v:14-15
- `all/exist` = `bi_forall`/`bi_exist` — syntax.v:17-20
- `done := True`, `false := False` — syntax.v:22-23
- `and`, `and_map` (big conjunction over a gmap) — syntax.v:25-29
- `find_in_context fic T := ∃ b, fic_Prop b ∗ T b` (context search
  binder) — definitions.v:158-165
- `case_if P T1 T2 := (⌜P⌝ -∗ T1) ∧ (⌜¬P⌝ -∗ T2)`;
  `case_destruct a T := ∃ b, T a b` — definitions.v:227-231
- `drop_spatial` (□), `tactic` (`li_tactic`, an escape hatch to
  arbitrary user goal transformers), `accu` (capture the current
  spatial context as a proposition: `accu f := ∃ P, P ∗ □ f P`,
  definitions.v:327-331), `trace` (no-op info marker), `modal`
  (a first-class modality record `limodal` with wand/intro/bind laws,
  definitions.v:9-141), `subsume P1 M P2 T := P1 -∗ ‖M‖ ∃ x, P2 x ∗ T x`
  (definitions.v:219-224), `iterate` (foldr over a list — the loop
  form), and `bind0..bind5` (continuation binders of arities 0-5) —
  syntax.v:31-67.

**[S]** A custom notation entry (`[{ ... }]`, `x ← y; z`, `exhale`/
`inhale`, `∃ x, …;` …) makes rules readable, and `P :- Q` /
`P where x… :- Q` denote `Q ⊢ P` (syntax.v:81-197). The notations are
*definitionally transparent*: `liFromSyntax` cbv-unfolds the `li.*`
wrappers back to raw Iris connectives (syntax.v:199-220), so the
grammar is purely a surface discipline — the interpreter dispatches on
the underlying Iris term shapes.

**[S]** User-facing judgments (RefinedC's `typed_val_expr`,
`typed_bin_op`, …) are *themselves* CPS: e.g.
`typed_val_expr e T := ∀ Φ, (∀ v ty, v ◁ᵥ ty -∗ T v ty -∗ Φ v) -∗ WP e {{Φ}}`
(typing/programs.v:96-98). WP never appears bare in an automation
goal; every judgment ends in a continuation `T`, and every typing rule
has the shape `premises-in-the-grammar ⊢ judgment T` — one rule
application *rewrites the goal in place* instead of splitting it.

### 1.2 The interpreter and the determinism discipline

**[S]** The whole engine is one Ltac step function `liStep`
(interpreter.v:1178-1202): a `first [...]` over ~17 sub-tactics
(`liTactic | liExtensible | liSep | liAnd | liWand | liExist | liImpl
| liForall | liSideCond | liFindInContext | liCase | liTrace |
liPersistent | liTrue | liFalse | liModal | liAccu | liDoneEvar |
liUnfoldLetGoal`), each of which is guarded by a `lazymatch goal` on
the head connective of the goal (e.g. `liAnd` fires only on
`envs_entails _ (‖_‖ bi_and ...)`, interpreter.v:1027-1035). The
driver is literally `repeat liRStep` (typing/automation.v:257-267 adds
RefinedC's statement/expression dispatch in front of `liStep`).

**[R]** Determinism is therefore *structural*, not enforced by a
search-control mechanism: at most one guard matches any goal (the
grammar's connectives are syntactically disjoint), so `first` never
has a real choice; each sub-tactic applies exactly one lemma
(`notypeclasses refine (tac_... )`) and continues. There is no goal
stack management beyond Rocq's; there is no backtracking across steps.

**[S]** The three places where *choice* exists, and how each is
disciplined:

1. **Rule choice within a judgment** (`liExtensible`,
   interpreter.v:195-211): the goal `‖M‖ P` is converted to a
   typeclass query (e.g. `_ : Subsume P1 M P2` or, via RefinedC's
   hook, `_ : TypedBinOp v1 …`), resolved by
   `solve [typeclasses eauto]`, and applied through
   `tac_apply_i2p : envs_entails Δ (‖M‖ (P').(i2p_P)) → envs_entails Δ (‖M‖ P)`
   (interpreter.v:187-192). TC search may internally backtrack, but
   the result is committed — a wrong rule choice is unrecoverable by
   design. The GUIDE's rule-writing discipline exists to make wrong
   choices impossible (matching `SimplifyHyp`/`SimplifyGoal` pairs
   must preserve provability; GUIDE.md:6-17), and the simplification
   classes carry an explicit `safe` bit — `SimplAndImpl impl safe
   changed P Ps` is an iff when `safe = true` and only an implication
   when not (simpl_classes.v:18-31), so "unsafe" (provability-losing)
   rules are a marked, deliberate category.
2. **Context search** (`liFindInContext`, interpreter.v:577-592):
   `FindInContext` instances are tried in priority order, exploiting
   that `typeclasses eauto` is multi-success — but the whole thing is
   wrapped in `once (...)`, so the first instance whose continuation
   tactic (`liFindHypOrTrue`) succeeds is committed
   (interpreter.v:585-591, with a Zulip cite in-comment). `liFindHyp`
   itself does a linear scan over the environment
   (`Esnoc`-recursion, interpreter.v:537-569) trying
   `unify Q P with typeclass_instances` per hypothesis — bounded local
   search inside one step, not global backtracking.
3. **Case splits** (`liCase`, interpreter.v:1101-1120): `case_if` /
   `case_destruct` produce both branches, then *immediately* prune:
   `repeat (liForall || liImpl); try by [exfalso; can_solve]`
   — with an in-code note that pruning here avoids duplicated
   normalization work and "has a big impact on performance"
   (interpreter.v:1117-1120).

**[S]** For completeness: `base.v:1066-1205` defines `rep`, an Ltac2
depth-first stepper with *optional bounded* backtracking
(`rep <- n tac` backtracks n steps on failure) — an exceptional tool,
not the normal mode; the normal driver is `repeat`.

**[S]** What happens when no rule applies: the goal simply survives
(`repeat` stops), and `liShow` re-sugars it into the readable grammar
for the user (interpreter.v:11); the FAQ's debugging recipe is
`repeat liRStep; liShow` then `Set Typeclasses Debug` (FAQ.md:33-46).
Stuck = user-visible goal, exactly our walker's stop-with-goal-intact
contract.

### 1.3 Rule registration and indexing (their law table)

**[S]** Rules are lemmas of shape `∀ args, (grammar-term ⊢ J a₁…aₙ T)`,
registered as instances of per-judgment typeclasses whose single
method is an `iProp_to_Prop` record — `i2p { i2p_P : iProp; i2p_proof
: i2p_P ⊢ P }` (definitions.v:144-152). The `[instance lemma]`
notation (proof_state.v:26-138) *generates* the instance from the
lemma statement by an Ltac reflection over its ∀-telescope: it finds
the conclusion head, picks the target class (`Subsume`,
`FindInContext`, `SimplifyHyp n`, `SimplifyGoal n`, or a hook-supplied
class), reorders side-condition hypotheses, auto-solves `eq_refl`-able
premises, and produces `i2p G Q c`. Priorities are ordinary TC
instance priorities (`Global Existing Instance foo_inst | 40`,
e.g. instances.v:14,22,58,99,146,172).

**[R]** So their "law table" is *the Rocq typeclass instance database*,
indexed by the head-symbol/hint-pattern discipline: `Hint Mode`
declarations on every class (definitions.v:169,182,188,196,216-217,224)
prevent search from firing on under-determined goals, and pervasive
`Typeclasses Opaque` + `Global Opaque` + `Keyed Unification`
(base.v:16,23-40) keep instance matching syntactic rather than
unfolding. There is no discrimination-tree data structure of their
own; they inherit Rocq's hint indexing. Our `@[app_eq]` DiscrTree with
metavariable-telescope keys + most-specific-first ordering
(AppEqAttr.lean:53-95) is the Lean-native equivalent, and is the
*better* substrate: candidate retrieval is exact-key rather than
head-symbol + unification-driven, and our priorities are computed from
key depth by default.

### 1.4 The mechanical/semantic split (their laws-only/side-condition split)

**[S]** Pure side conditions are **never solved inline** during the
walk (except a cheap `done` fast path, interpreter.v:461-465). They
are *shelved* behind an opaque marker: `shelve_sidecond` changes the
goal to `SHELVED_SIDECOND G` and shelves it (proof_state.v:8-24).
After the walk, `unshelve_sidecond` restores them and the batch is
handed to `solve_goal` (solvers.v:235-242): `simpl; try fast_done;`
hooks; `normalize_and_simpl_goal` (rewrite-normalization +
`SimplAndImpl` typeclass simplification + trivial-hypothesis
filtering, solvers.v:65-137); `reduce_closed_Z` (vm-compute closed
arithmetic); `enrich_context` (SMT-trigger-style saturation: quotient/
mod bounds, filter lengths, `set_Forall` instantiation —
solvers.v:153-219); then `repeat case_bool_decide; refined_solver lia`
(a fail-faster `naive_solver`, solvers.v:8-62). All of it sits behind
hooks (`can_solve_hook`, `normalize_hook`, etc., hooks.v:5-30) that
the client (RefinedC) instantiates (typing/automation.v:18,45).

**[S]** Simplification is a two-class system: `SimplifyHyp P M n` /
`SimplifyGoal M P n` with an `option N` priority where `Some 0` means
"always safe, do eagerly" and higher n means "later" (definitions.v:
201-217); the identity instances at priority 100 make the classes
total (instances.v:17-29). `Subsume` composes with simplification
generically (`subsume_simplify`, instances.v:38-58: whichever of
hyp-side or goal-side simplification has the lower n fires first).

**[R]** Comparison: our division is *harder* than theirs — our walker's
mechanical discharge is assumption / registered law / rfl and
*anything else stops the walk* (AppWalk.lean:714-719,1013-1021),
whereas Lithium's shelved side conditions are eventually attacked by a
heavyweight heuristic solver (`refined_solver lia` can backtrack over
∃/∨, solvers.v:47-61). Their split is walk-time vs batch-time; ours is
mechanical vs human-named. Both keep the walk itself deterministic.

### 1.5 Evar/existential discipline

**[S]** This is Lithium's most distinctive machinery. Existentials in
the goal are not turned into naked evars on sight; `liExist protect`
(interpreter.v:367-401) *packs* them into a linear "protected product"
telescope `A *ₗ B` (`li_prod`, `∃ₗ`, pure_definitions.v:8-51) — the
goal becomes `‖M‖ ∃ₗ x, …` with all pending existentials carried as
one tuple variable. Actual instantiation happens only at pure
equations: `liSideCond` on `∃ₗ x, ⌜P x⌝ ∗ …` calls `liExInst`
(interpreter.v:106-158), which builds an instantiation function
`λ EX, (…,…)ₗ`, solves `a = b with solve_protected_eq_db` (a
controlled unification with its own opacity database + a client hook
to unfold specific constants, interpreter.v:117-118,
typing/automation.v:25-40), and *re-quantifies whatever didn't get
determined* as fresh protected existentials. `SimplExist` instances
let types provide custom instantiation shapes (simpl_classes.v:8-10),
including the named-lvar mechanism (lvar.v: `LVAR_HINT name x` in the
pure context drives `SimplExist (lvar name A)`). Evar sharing between
the two subgoals of `□ P ∗ G` goes through `li_done_evar`
(interpreter.v:595-627,667-678). And crucially, hypothesis
cancellation is *refused* when the goal side contains an evar — "We
can't (and don't want to) cancel if there is an evar in the goal"
(interpreter.v:754-756).

**[R]** Net effect: unification is only ever asked small, controlled
questions; evars cannot leak into big terms or get instantiated by
accident during matching. Our walker reaches the same invariant by a
different route (computed-RHS laws: the RHS mvars are assigned only
from *normalized* values, S3 finding F-S3-8; op pre-match before full
unification, AppWalk.lean:905-928) — but we have no analog of the
*deferred* instantiation telescope, because our current statements
are equations without goal-side existentials. This changes at T8/T9
(call composition: postconditions with ∃).

### 1.6 How user extensions plug in

**[S]** Three tiers:
1. **New rules for existing judgments**: prove a lemma in the grammar,
   wrap with `[instance ...]`, `Existing Instance` with a priority
   (instances.v throughout; RefinedC's `int.v`/`own.v`/… are hundreds
   of these).
2. **New judgments**: define the CPS-shaped `iProp`, a typeclass, and
   extend `liExtensible_to_i2p_hook` with the syntactic dispatch line
   (hooks.v:53-56; RefinedC's instantiation typing/automation.v:49-86
   is a 15-case lazymatch).
3. **Arbitrary goal transformers**: `li_tactic t T` goals are
   dispatched through the `LiEntails` hint database — a
   `Hint Extern` per tactic, e.g. `li_vm_compute f x T` is solved by
   actually running `vm_compute` and continuing with `T y`
   (definitions.v:304-325). Plus ~14 named Ltac hooks (hooks.v) the
   client overrides with `::=`.

**[R]** Our equivalents: `@[app_eq]` (tier 1, better indexed),
`app_walk_step`/explicit lemmas (tier 3, but human-invoked rather than
goal-triggered), and nothing for tier 2 because we have exactly one
judgment shape (the app equation) — a deliberate simplification that
holds until the slate diversifies.

---

## 2. Performance engineering

### 2.1 Goal-size discipline: name every big term

**[S]** Two let-binding mechanisms run under everything:
- `let_bind_envs` (proof_state.v:158-187): the Iris proof-mode
  environment `Δ` (the whole hypothesis context) is bound to a local
  `H := Envs …` and the goal becomes `envs_entails H P` — the context
  appears *once*, as a variable, in every goal and every proof-term
  node. All environment lookups go through `li_pm_reduce` (cbv the
  variable + proof-mode eval, proof_state.v:143-156).
- `li_let_bind` / `LET_ID` (proof_state.v:204-231): judgment
  *continuations* are bound to `LET_GOAL := LET_ID T` before rule
  application (`liRIntroduceLetInGoal`, typing/automation.v:130-143;
  `liExtensible` does it for the subsume/judgment argument,
  interpreter.v:202-211), and unfolded only when the walk actually
  reaches them (`liUnfoldLetGoal`, interpreter.v:18-38). RefinedC also
  wraps the whole basic-block map and return continuation in markers
  (`CODE_MARKER`, `RETURN_MARKER`, typing/automation.v:191-204) with
  an explicit warning that `simpl` over the code map is exponential in
  block count (typing/automation.v:312-314). Both binders print as
  `HIDDEN` (proof_state.v:141,207).

**[R]** This is the single most load-bearing performance idea in
Lithium: *the goal never contains a large term in more than one
place, and usually in zero places*. It is exactly the direction our
S3 park record identified independently ("state-defs anchored FIRST so
every downstream term is depth-constant", s3-build §6.1) — Lithium is
evidence that it should be the *default and universal* discipline, not
an opt-in lane.

### 2.2 Proof-term size and the kernel question

**[S]** A Lithium proof term is a linear chain of
`tac_fast_apply (rule_i) …` nodes (interpreter.v:74-81), one per step,
each of whose `P1 ⊢ P2` argument is a registered instance (a named
constant, not an inline term). Where they worried about term size it
was *casts*: `simpl` inserts a cast even when it does nothing
(interpreter.v:13-16, with an upstream Rocq issue link), and
`liUnfoldLetGoal`'s unfold "inserts a cast but that is not too bad …
since the goal is small at this point" (interpreter.v:24-26).

**[S]** Closed computation is discharged by `vm_compute`:
`reduce_closed` (base.v:133-137), `li_vm_compute` with
`evar_safe_vm_compute` (evars hidden from the VM behind a ∀-cut,
base.v:150-161, definitions.v:310-325), `reduce_closed_Z` in the
solver. Deferred checking is used liberally: `change_no_check` in
`liEnforceMod` (interpreter.v:63), `shelve_sidecond`
(proof_state.v:16), `liTrace` (interpreter.v:1173),
`compute_map_lookup` (solvers.v:148-150) — cheap at tactic time, all
rechecked by the kernel at Qed.

**[R] Do they hit kernel-scale walls? No — and it is important to be
precise about why not.** Three structural reasons:
1. **No concrete program state ever appears in a goal.** Caesium's
   heap lives in Iris ghost state; goals mention symbolic locations
   and `l ↦ v` fragments; the "state" the automation manipulates is
   the proof-mode *environment*, whose size is the number of
   hypotheses, not the size of a memory. Their analog of our
   40G-whnf/deep-recursion findings simply cannot arise. Our workbench
   proves theorems about an *executable* semantics whose states are
   real 8-cell-bytemap-sized terms; this is a genuinely different
   regime, not an engineering gap on our side.
2. Where closed computation does occur (layout arithmetic, map
   lookups), it is pushed through the Rocq kernel's *VM* — a
   compiled evaluator *inside their TCB*. That move is exactly the
   class our doctrine bans (native_decide-equivalent). Our sanctioned
   substitute is `Kernel.whnf` (kWhnf, AppWalk.lean:185-234), which we
   already deploy (F-S3-5) — same intent, checker-grade engine.
3. Qed-time checking of a linear `tac_fast_apply` chain over
   let-bound environments is proportional to the number of steps ×
   small per-step terms; Rocq's lazy conversion machine plus the
   VM handle the rest. **Lithium contains no per-stage certificate
   emitter, no aux-theorem decomposition, no recursion-guard
   workarounds — there was nothing forcing them to invent one.**

### 2.3 Search/unification cost management

**[S]** Documented costs and their mitigations, all in-source:
- Failed `exact: eq_refl` unification "sometimes takes 30 seconds"
  (GetMemberLoc anecdote) → hypothesis matching goes through
  `unify Q P with typeclass_instances` (opacity-respecting), plus the
  `FindHypEqual` class: a per-key tactic pre-transforms the pattern to
  something that will unify *syntactically* (interpreter.v:541-556,
  definitions.v:176-182). [Our analog, independently derived: the op
  pre-match + head filter, F-S3-7/AppWalk.lean:893-928.]
- Replacing `tac_fast_apply` with specialized variants gave a
  measured 1-2% — with a link to their *continuous benchmarking
  dashboard* (coq-speed.mpi-sws.org) in the comment
  (interpreter.v:182-186). They keep a microbenchmark directory
  (lithium/benchmarks/liWand.v: 100-hypothesis wand/sep timing with
  `time` and Ltac-profiling scaffolding).
- Branch pruning in `liCase` before hypothesis normalization
  (interpreter.v:1117-1120); solver-side trimming of
  `Z.euclidean_division_equations_cleanup` cases for "around 200%
  slowdown" in one Linux-code function (base.v:50-97); `Hint Mode` +
  opacity everywhere; `Set Keyed Unification` (base.v:16);
  `#[projections(primitive)]` on the hot records
  (definitions.v:145, pure_definitions.v:10).
- `NormalizeWalk`/`Normalize` — a typeclass-directed rewriting pass
  designed to produce *one* `eq` proof per normalization rather than
  autorewrite's many (normalize.v:60-133), kept alongside the
  autorewrite version.

**[R]** Nothing here is memoization/caching in the checker sense —
Lithium has no result cache; its "caching" is Rocq's whnf/TC caches
plus the discipline of never asking expensive questions. Our F-S3-1
(hoist the canUnfold predicate to keep the whnf cache warm) is the
same genre.

---

## 3. The comparison table

Verdicts: **HAVE** = we already have the mechanism (named);
**IMPORT-S/M/L** = import the design at the given price;
**N/A** = not applicable in Lean 4 / our regime, with why.

| # | Lithium mechanism (cite) | Our mechanism (cite) | Verdict |
|---|---|---|---|
| 1 | One-step interpreter, goal-guarded `first` dispatch, stuck ⇒ readable goal (interpreter.v:1178-1202, liShow) | `walkLoop`/`walkOnce`, goal-guarded DiscrTree dispatch, stop-with-goal-intact (AppWalk.lean:1045-1204) | **HAVE** — and ours adds budget ledgering Lithium has no analog of |
| 2 | Rule table = TC instances + `Hint Mode` + priorities + `[instance]` generator (proof_state.v:26-138, instances.v) | `@[app_eq]` DiscrTree, metavariable-telescope keys, depth-priority (AppEqAttr.lean:53-95) | **HAVE** (ours is the right Lean-4 substrate; porting TC-based dispatch would be a regression). The `[instance]` *generator* (auto-deriving registration from a lemma's statement) is a small ergonomic delta — **IMPORT-S** if kit volume grows in T6-T9 |
| 3 | CPS goal grammar: every rule ends in continuation `T`; rule application rewrites the goal in place, no `.trans` chains (syntax.v, programs.v:96-98) | Equation-shaped laws chained by `Eq.trans` (walkOnce, AppWalk.lean:1114-1140) | **IMPORT-M (internal only)** — see §6 item 2. The final statement stays an equation (TCB); the *proof-term shape* can adopt the lesson: never build one monolithic trans-chain, emit per-stage named obligations. This is the already-identified walker-v3 emitter, now with corroborating evidence |
| 4 | Continuation/environment let-binding: `LET_ID`, `let_bind_envs`, markers, lazy unfold (proof_state.v:141-231, interpreter.v:18-38, automation.v:130-143,191-204,312-314) | `sealStates`/`mkAuxDefinition`/`sealCtorLeaves` — opt-in v3 lanes (AppWalk.lean:514-537,582-607) | **IMPORT-M** — make naming-the-big-term the default invariant, not a lane. Top import; see §6 item 1 |
| 5 | Shelved side conditions + batch solver + hooks (proof_state.v:8-24, solvers.v:235-242, hooks.v) | laws-only walk + explicit `app_walk_step` for semantic obligations (AppWalk.lean:714-719,1558-1571) | **HAVE** (the split), **IMPORT-S** (the batch-solver *pipeline*: normalize → enrich → case-split → arith; see item 6) |
| 6 | Pure-side normalization corpus: `lithium_rewrite` db (lengths of insert/app/fmap/take/drop/replicate, Z2Nat, bool_decide folds — normalize.v:33-58), `SimplAndImpl` safe/unsafe classes (simpl_classes.v:15-49), `enrich_context` saturation (solvers.v:153-186), `trigger_foralls` (solvers.v:188-219) | `app_norm` simp set (registered, thin); omega/decide at leaves; Kit/Map lawful-map laws (s3-build §1) | **IMPORT-S** — the arrays/nested-loops arc (T6-T7) will need exactly this lemma inventory as simp sets + an ordered side-condition tactic. The safe/unsafe marking is a doctrine-compatible idea (unsafe steps must be declared) |
| 7 | Protected existentials: `li_prod` telescopes, `liExInst` deferred instantiation at pure equations, `solve_protected_eq_db`, `SimplExist`, lvars (pure_definitions.v:8-66, interpreter.v:106-158,303-422, lvar.v) | No goal-side existentials yet (computed-RHS mvars, normalized-assignment discipline F-S3-8) | **IMPORT-M, deferred to T8/T9** — the moment statements/call-composition rules carry ∃, adopt the *pattern*: pack, defer, instantiate only against pure equations under a controlled unfolding set. Lean substrate: explicit telescope structure + `isDefEq` under `withCanUnfoldPred` (we have the pieces) |
| 8 | `FindHypEqual` + `unify … with typeclass_instances` (definitions.v:176-182, interpreter.v:541-556) | head-filtered assumption + op pre-match with budget caps (F-S3-7, AppWalk.lean:893-928) | **HAVE** (independently converged; ours adds budget caps) |
| 9 | Branch pruning at case splits before hyp normalization (interpreter.v:1117-1120) | n/a yet (T5 is loop-only; branches arrive with T7 early-exit) | **IMPORT-S** at T7: split, then kill dead branches with the cheap solver *before* any per-branch walking |
| 10 | `li.iterate` + `iterate_elim0..3` (INV-indexed fold elimination, syntax.v:316-377) | `iter_compose`/`iter_compose_from` (Kit/Loop.lean:28-65) | **HAVE** — same role (loop = invariant-indexed composition); ours is pure/equation-level and axiom-free, theirs is in-logic with modality support. The `_var` accumulator variants (their `with a1,a2` forms) confirm our planned `_exit`/`_var` extensions are the standard shape |
| 11 | `limodal` first-class modality parameter on every judgment (definitions.v:9-141) | n/a (no modalities in the equation layer; Iris side handled at adequacy) | **N/A now** — becomes relevant only if the relational layer grows fupd-like structure (concurrency arc); note it as a forward-design datum: parameterizing the walk over a modality was retrofitted into Lithium and touches *every* rule — if our concurrency arc will need one, thread it early |
| 12 | vm_compute / change_no_check discharge of closed computation (base.v:133-161, definitions.v:310-325) | `Kernel.whnf` (kWhnf), aux-rfl theorems, app_defeq (AppWalk.lean:185-234,1274-1321) | **N/A** — Rocq's VM is inside their kernel; the equivalent Lean moves (native_decide/ofReduce*) are banned by D14. Our kernel-engine substitution is the doctrine-compatible analog and already outperformed the elaborator (F-S3-5) |
| 13 | `accu` — capture the spatial context as a prop (definitions.v:327-331), used for `typed_block` loop invariants via Löb (automation.v:118-127) | invariant is human-named (`St` family), iter_compose deliberately unregistered (Kit/Loop.lean:7-9) | **N/A / anti-import** — `accu` is invariant *inference* (take whatever ownership is left as the invariant). Convenient, but it moves invariant content out of named statements; our doctrine (human names the invariant) is a deliberate divergence. Record as considered-and-rejected |
| 14 | Continuous perf dashboard + in-tree microbenchmarks (interpreter.v:183-186, lithium/benchmarks/) | measured findings in build records; T1 calibration as regression canary | **IMPORT-S** — a `bench/` lane (walker round timings, entry-block elaboration) run at slice boundaries would have caught F-T5-3 earlier and prices walker-v3 work honestly |
| 15 | `rep` Ltac2 bounded-backtracking stepper (base.v:1066-1205) | `app_walk n` budgets + `app_walk?` debug | **HAVE** (budgeted stepping); the backtrack-n-steps-on-failure debugging affordance is neat but nonessential |
| 16 | W-reflection of program syntax for dispatch (caesium/tactics.v:5 Module W; automation.v:157-247 `W.of_expr`-driven `liRExpr`/`liRStmt`) | `parseDnmsApp` fixed-shape meta parser (AppWalk.lean:1338-1360) | **HAVE** (ours is meta-level parsing, no reflection needed — Lean's Expr API does what they need Ltac reflection for) |

**What would have shortened T5's climb [R]:** items 4 and 3 — and
*only* those. The T5 park is a kernel-certificate-scale wall
(s3-build §5); Lithium's whole design keeps goals and proof terms
small by naming every large object and never building monolithic
chains, which is precisely the walker-v3 per-stage emitter that the S3
record already identified as the completion. Reading Lithium first
would have made "seal by default, field-wise boundaries, per-stage
obligations" the design premise of the S2 walker rather than the S3
retrofit. Nothing else in Lithium touches the T5 blocker: their evar
machinery, context search, and side-condition solver address problems
T5 doesn't have.

**What the T6-T9 slate should adopt before it starts [R]:** item 6
(side-condition normalization corpus — arrays are list/length/
take/drop arithmetic, which is literally their rewrite db), item 9
(prune-then-walk at branches, for early-exit), item 7's pattern
(deferred existential telescopes, for call composition), item 2's
`[instance]`-style registration ergonomics if the kit grows past ~100
laws, and item 14 (benchmarks).

---

## 4. Caesium + typing: statement-shape lessons (one page)

**[S]** Caesium is a *relational* small-step semantics: `Inductive
expr_step : expr → state → … → Prop` (caesium/lang.v:397), evaluation
contexts (lang.v:586), no fuel, no executable interpreter. Automation
never computes with it; it consumes *equation-shaped premises*
exposed by a three-tier lemma ladder in caesium/lifting.v: the raw
nondeterministic WP rule (`wp_binop`, lifting.v:146), a deterministic
corollary (`wp_binop_det`: "there is exactly one result v'",
lifting.v:162), and a pure-equation corollary (`wp_binop_det_pure`
with premise `eval_bin_op … = Some v'`, lifting.v:174). Typing rules
sit on the pure tier; the `Some`-equation premises become Lithium
side conditions. **[R]** Contrast with our fuel opsem: they *prove*
determinism where needed and hand automation an equation to solve; we
*compute* the step and hand the kernel an equation to check. Their
factoring is what makes a relational semantics automatable; ours is
what makes an executable semantics trustworthy. These are dual — no
import, but a useful frame: our `step_ctx`-discovery-equation +
advance-law structure (s2-build §2 P1) is the executable-world image
of their det/pure lemma tier.

**[S]** Judgment cleanliness: the typing layer's definitions unfold to
plain WP statements (`typed_stmt s fn ls R Q := ⌜length ls = …⌝ -∗
WPs s {{Q, post}}`, programs.v:66-70; `typed_val_expr` CPS over WP,
programs.v:96-98), so "well-typed" is *definitionally* a Hoare
statement — the typing layer adds zero trusted content. The final
statement (typing/adequacy.v:40-49, `refinedc_adequacy`) is phrased
against `nsteps (Λ := c_lang)` and `not_stuck` — pure operational
vocabulary; Iris (`typePreG`, ghost state, WP) appears only in the
proof and in the *hypothesis* the user proves per program. One
adequacy lemma discharges the whole tower. **[R]** This is exactly our
statement-TCB gate architecture (fuel-opsem-only statements, in-repo
adequacy, Audit.lean pins) — independently converged; no import, but
a strong external validation of the pattern. One honest delta: their
per-program obligation (`∀ HtypeG, … -∗ … ={⊤}=∗ [∗ list] main ◁ᵥ …`,
adequacy.v:43-47) still mentions Iris typing vocabulary; our slate
statements are cleaner on that axis (interpreter-only, Iris fully
discharged), at the cost that every new theorem re-crosses the
adequacy bridge.

**[S]** One more shape lesson: annotation-driven invariants. Loop/
block invariants arrive as *statement-side annotations* (typed_block,
`IPROP_HINT (BLOCK_PRECOND bid)` hypotheses, automation.v:118-127,
170-177) — the human names the invariant, the automation only
*consumes* it. Same division of labor as our unregistered
`iter_compose` (Kit/Loop.lean:7-9). Their `accu`-based fallback
(capture-remaining-ownership-as-invariant) is the one place they let
the machine guess an invariant; see table item 13 for why we decline.

---

## 5. Portability honesty — per idea

- **TC-instance rule registration + Hint Mode/priorities**: Rocq TC
  engine specifics (multi-success eauto, hint opacity, `once`).
  Lean-4 equivalent: environment-extension attribute + DiscrTree +
  explicit priority sort — **already built** (AppEqAttr.lean). Don't
  port the mechanism; optionally port the `[instance]` *generator* as
  a metaprogram that derives registration + key sanity checks from a
  lemma statement (straightforward `MetaM`).
- **`[{ ... }]` custom-entry goal grammar / liToSyntax**: Rocq
  custom-entry notations + cbv-transparent wrappers. Lean-4: doable
  with syntax categories + delaborators; value is cosmetic for us
  (our goals are equations, already readable). Skip.
- **`let_bind_envs`/`LET_ID`**: uses Ltac `pose`/`change_no_check` +
  `Strategy expand`. Lean-4 equivalent is *better*: `mkAuxDefinition`
  produces a real environment constant the kernel unfolds on demand
  (we do this); the missing piece is making it the walker's standing
  invariant, purely our-side engineering, no Rocq dependence.
- **Shelving + SHELVED_SIDECOND**: Rocq shelf. Lean-4: collect side
  goals into a list of mvars and run the batch solver at walk end
  (TacticM bookkeeping) — trivial to port.
- **`SimplAndImpl`/`Normalize` TC-driven simplification**: relies on
  Hint Extern discipline to avoid TC loops (normalize.v:104-106 notes
  a loop hazard). Lean-4: simp sets + `simproc`s are the native
  substrate and strictly stronger (indexed, cached); port the *lemma
  inventory and the safe/unsafe classification*, not the mechanism.
- **Protected evars (`li_prod`, `liExInst`)**: uses Rocq evar/shelve
  behavior + `unify … with db`. Lean-4: mvar postponement +
  `withCanUnfoldPred`-scoped `isDefEq` + an explicit telescope
  structure; all primitives exist, the design is the import. M work.
- **vm_compute / evar_safe_vm_compute / change_no_check**: Rocq
  kernel VM + Qed-deferred checking. **Not portable under our
  doctrine** (D14 ban class); `Kernel.whnf`/aux-rfl is the sanctioned
  analog and measured competitive (F-S3-5).
- **`rep` (Ltac2)**: Ltac2 backtracking exceptions. Lean-4: plain
  TacticM recursion — our walkLoop already is one; nothing to port.
- **`enrich_context`/`trigger_foralls` saturation**: pure Ltac over
  hypotheses; Lean-4 port is a small `MetaM` saturation pass feeding
  `omega`. S work, T6-relevant.
- **Canonical structures**: notably, Lithium does *not* lean on
  canonical structures (its one `Structure` is `limodal`,
  definitions.v:10); the portability risk usually attributed to
  Rocq automation (CS-based indexing) is absent here. **[S]**

---

## 6. Ranked import slate for workbench v2

Each item: what / where it plugs in / price / payoff claim.

1. **Name-every-big-term as the standing invariant** (Lithium
   `LET_ID`/`let_bind_envs` → our seal-by-default). Make the walker
   anchor state constants *first* (aux definitions), keep every fact
   value a spine-subterm of a named state, and make field-wise
   boundary certificates (`app_defeq_fields`) the default segment
   closure — i.e. the already-priced walker-v3 coherence item, with
   Lithium as the design confirmation that this is *the* discipline,
   not one option. Plugs into: AppWalk discharge lanes +
   walkOnce chaining. Price: **M** (engine pieces exist behind
   `WalkCfg.sealFacts/sealRounds/sealStates`; the work is the one-
   normal-form pipeline, s3-build §6.1). Payoff: this *is* the T5
   kernel-wall completion; also every T6-T9 theorem inherits
   depth-constant goals.
2. **Per-stage obligations instead of monolithic trans-chains**
   (Lithium's rewrite-goal-in-place CPS shape, read as a proof-term
   lesson). Internal to the emitter: each bind-stage crossing becomes
   its own named theorem (T4 granularity), the top proof references
   constants. Plugs into: the per-stage certificate emitter (the
   walker-v3 missing piece named in s3-build §5). Price: **M**
   (emitter only; laws unchanged). Payoff: bounds kernel recursion per
   stage — the measured wall row ("T4's hand rounds pass at identical
   content because each stage is a separate small obligation").
3. **Side-condition batch pipeline + normalization corpus** (shelve →
   normalize → simplify-with-declared-unsafe-steps → enrich → arith).
   Port the lithium_rewrite inventory (normalize.v:33-58) as
   `app_norm`-adjacent simp sets; add an ordered `sidecond` tactic
   (fast_done → simp with sets → saturation → omega/decide); adopt the
   safe/unsafe marking for any provability-losing simplification.
   Plugs into: dischargeHyp's non-mechanical boundary (as a *separate,
   post-walk* batch — keeping the walk-time mechanical bar intact).
   Price: **S**. Payoff: T6 arrays (length/take/drop/insert
   arithmetic is their exact db content), T7 guard arithmetic.
4. **Prune-then-walk at case splits** (liCase discipline,
   interpreter.v:1117-1120): on introducing a branch, immediately try
   to kill it with the cheap solver before any normalization/walking.
   Plugs into: the T7 early-exit round classes. Price: **S**.
   Payoff: avoids duplicating walk work across dead branches — their
   stated "big impact on performance".
5. **Deferred-existential telescopes** (li_prod pattern) for
   goal-side ∃ when call-composition/∃-postcondition statements arrive
   (T8/T9): pack existentials, instantiate only against pure equations
   under a declared unfolding set, refuse unification against
   evar-carrying goals elsewhere. Plugs into: a new Kit/Call layer +
   walker guard. Price: **M** (design + a telescope structure +
   controlled-instantiation tactic). Payoff: keeps T8/T9 walks
   deterministic in the presence of ∃ — the failure mode it prevents
   (accidental instantiation during matching) is the classic one.
6. **`[instance]`-style registration generator + key linting**: a
   metaprogram that, given a kit lemma, checks the conclusion shape,
   computes DiscrTree keys, warns on dead-position literals (the
   `addrOpt` DiscrTree-miss bug, s3-build §1, is exactly what a
   registration-time linter catches — Lithium's generator fails
   loudly on shape mismatch, proof_state.v:52-65 / our
   AppEqAttr.lean:60-62 already fails on non-equations; extend to
   key-quality warnings). Price: **S**. Payoff: prevents a measured
   bug class as the law count grows through T6-T9.
7. **Standing microbenchmark lane** (their benchmarks/ + coq-speed
   habit): commit a `bench/` exe timing the T1 calibration + one
   entry-block walk + one action round; run at slice boundaries.
   Price: **S**. Payoff: catches F-T5-3-class regressions before they
   cost a probe cycle; prices engine changes honestly.

Rejected imports (recorded): `accu`-style invariant inference (against
the human-names-the-invariant doctrine, table item 13); TC-based rule
dispatch (DiscrTree is the right Lean substrate); vm_compute-class
closed-computation discharge (D14 ban); goal-grammar notation layer
(cosmetic).

---

## 7. Report-back summary

- **Top-3 imports with prices:** (1) name-every-big-term as the
  standing walker invariant + field-wise boundaries — **M**, and it is
  the T5-wall completion already identified, now design-confirmed;
  (2) per-stage named obligations replacing monolithic trans-chains
  in the emitter — **M**; (3) the side-condition batch pipeline +
  normalization lemma corpus (their lithium_rewrite db, ported as simp
  sets + ordered solver, with safe/unsafe marking) — **S**, aimed at
  T6-T7.
- **Biggest we-already-have:** the deterministic goal-guarded
  one-step interpreter over an indexed law table with a hard
  mechanical/semantic split — our DiscrTree + budget-ledger version is
  on the better substrate (Lithium's dispatch is TC-resolution with
  hint-mode discipline; no discrimination trees, no budget
  accounting). Also independently converged: statement-TCB/adequacy
  separation, head-filtered hypothesis matching, stuck-goal
  readability.
- **Biggest not-applicable:** their closed-computation discharge
  (vm_compute + change_no_check) — it lives inside Rocq's
  kernel-trusted VM and Qed-deferred checking, i.e. the
  compiler-trusted-evaluation class our doctrine bans; our
  `Kernel.whnf`/aux-rfl route is the sanctioned analog. Likewise
  TC-engine rule indexing (wrong substrate for Lean 4).
- **Does Lithium answer our kernel-certificate-scale wall?** **No —
  it never faces it.** Concrete program states never appear in
  Lithium goals (the heap is Iris ghost state; goals carry `l ↦ v`
  fragments and let-bound environments), proof terms are linear
  chains of small named-instance applications, and residual closed
  computation goes to the trusted VM. The transferable content is
  structural and *corroborates the S3 park diagnosis from the
  outside*: keep every kernel obligation at one-rule-application
  granularity and every large value behind a name. The one
  genuinely new push it suggests: move further toward
  *footprint-shaped* premises (laws conditioned on lookups/accessor
  equations rather than whole-state values — our Kit/Map + env-family
  direction generalized), so whole-state defeq questions disappear
  from segment boundaries entirely rather than being decomposed after
  the fact.
