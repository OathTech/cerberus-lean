# Arc 7 / S4 — Layer 3 minimal: iris-lean coupled, adequacy proved (worker record)

Date: 2026-08-20. Provenance: [AGENT:S4] unless marked. Substrate: the
S1-S3 RelSem stack (ExecModel/Machine/RunND/Cerberus/Call, docs
2026-08-19_relsem-spike.md + 2026-08-20_arc7-s3-layer2-slate.md).
iris-lean: upstream leanprover-community/iris-lean @
`79dab154a64051384179c4d4e00511752cf2a168` (= the deps/iris-lean local
build, Lean 4.32.2), added as a Lake dep this slice (§2).

## 0. THE RULE-LIBRARY INVENTORY (operator directive: written FIRST,
##    before any proof; the reuse-vs-build table is the scope fence)

Method: read Iris/ProgramLogic/{Language,WeakestPre,Lifting,Adequacy,
TotalAdequacy}.lean, Iris/BI/Lib/GenHeap.lean,
Iris/Instances/Lib/GhostVar.lean, Iris/HeapLang/PrimitiveLaws.lean at
the pinned rev; signatures below are from those files (file:line).

### 0.1 What iris-lean provides (verified at the pin)

* **Language interface** (Language.lean:34-115): classes `ToVal`
  (`toVal/ofVal` + 2 laws), `PrimStep`
  (`primStep : Expr × State → Obs → Expr × State × List Expr → Prop`),
  `Language extends PrimStep Expr State (List Obs), ToVal Expr Val`
  with the single law `val_stuck`. Thread-pool `Step` (:127),
  `ErasedStep`/`-·->ₜₚ*` (:166-175), `PurePrimStep` (:391 — demands
  state-INdependence: `σ₁ = σ₂` for every state), `PureExec` (:423),
  `Language.Context` (evaluation contexts, :271).
* **Generic WP** (WeakestPre.lean): `StateInterp` carrier class
  (`stateInterp : State → Nat → List Obs → Nat → IProp GF`, :35-42);
  `IrisGS_gen` (:45 — adds `numLatersPerStep`, `forkPost`,
  `stateInterp_mono`); `wp_unfold` (:128), `wp_value_fupd'` (:192),
  `wp_strong_mono` (:197), `fupd_wp`/`wp_fupd` (:238/:260), `wp_atomic`
  (:268), `wp_bind` (:434 — needs `Language.Context`), `wp_mono`
  (:446), `wp_value'` (:483), `wp_frame_l/r` (:498/:507), `wp_wand`
  (:584), full ElimModal/Frame proof-mode integration (:612-729).
* **Lifting** (Lifting.lean): `wp_lift_step_fupdN/‑_fupd/‑` (:24/:36/:77),
  `wp_lift_atomic_step_fupd`/`wp_lift_atomic_step` (:133/:156 — one
  step to a VALUE, exactly our shape), `wp_lift_pure_step_no_fork`
  (:93), `wp_pure_step_fupd/later` (:186/:214).
* **Adequacy** (Adequacy.lean): record `adequate s e₁ σ₁ (φ : Val →
  State → Prop)` with fields `adequate_result : ∀ t2 σ2 v2, ([e1], σ1)
  -·->ₜₚ* (ToVal.ofVal v2 :: t2, σ2) → φ v2 σ2` and
  `adequate_not_stuck` (:237-243); master `wp_strong_adequacy_gen`
  (:173-231); workhorse `wp_adequacy_gen` (:302-334):

  ```
  theorem wp_adequacy_gen [InvGpreS GF] (s : Stuckness) (e : Expr)
      (σ : State) (φ : Val → Prop)
      (Hwp : ∀ [InvGS_gen hlc GF] (κs : List Obs),
          ⊢ |={⊤}=> ∃ (stateI : State → List Obs → IProp GF)
              (forkPost : Val → IProp GF),
            letI : IrisGS_gen hlc Expr GF := …
            stateI σ κs ∗ WP e @ s ; ⊤ {{ v, ⌜φ v⌝ }}) :
      adequate s e σ (fun v _ => φ v)
  ```

  plus `wp_invariance_gen` (:341), `adequate_tp_safe` (:266);
  `twp_total` (TotalAdequacy.lean:197 — total WP ⇒ strong
  normalization; fuel makes this moot for us).
* **gen_heap** (GenHeap.lean): `genHeapPreS/genHeapGS` (:45/:57),
  `genHeapInterp` (:79), `pointsTo l dq v` (:83), `pointsTo_agree`
  (:156), `genHeap_alloc` (:398), `genHeap_valid` (:451 — auth ∗ frag ⊢
  ⌜get? σ l = some v⌝), `genHeap_update` (:458), `genHeap_init` (:517);
  over `Std.LawfulFiniteMap` (ExtTreeMap instances provided).
* **ghost_var** (Instances/Lib/GhostVar.lean): `ghost_var γ dq a`
  over any `A : Type` (`GhostVarF A = constOF (DFracAgreeR
  (DiscreteO A))`), `ghost_var_alloc` (:71), `ghost_var_agree` (:85),
  `ghost_var_update_halves` (:133), fractional/timeless instances.
* **Proof mode**: the full IPM tactic set is live and exercised by
  the library itself (`iintro`/`icases`/`iapply`/`imod`/`iframe`/
  `ispecialize`/`iexists`/`ipureintro`/`imodintro`/`inext`/`icombine`/
  `iloeb`/`iinduction`, destructuring patterns, `$$` application) —
  see proofmode.md/tactics.md and every proof in ProgramLogic/*.
* **Packaging template**: HeapLang's `HeapLangGpreS`/`HeapLangGS`
  classes + the closed `HeapLangS : BundledGFunctors` witness +
  `heap_adequacy` (PrimitiveLaws.lean:28-160) — the pattern our
  concrete instantiation mirrors.

### 0.2 The load-bearing substrate fact the table turns on

S3's trace evidence (RelSem/Machine.lean § Coverage-by-need): every
T1-T5 harness run — value and UB verdicts alike — is ONE bind-collapsed
ND node, i.e. ONE `Step` (`active`/`killed`) from `callConfig` to a
`done` configuration. There are NO intermediate machine configurations
on the slate corpus: alloc/store/load/loop all happen INSIDE the single
`app` unfolding, and their reasoning lives in the Layer-2 app-equation
layer (S3), not between WP steps. Rules whose Iris shape presupposes
intermediate configurations (points-to framing across steps, per-
iteration loop rules) therefore have no WP-level work to do THIS ARC;
their content is Layer-2 lemmas consumed as side conditions of the one
lifting step. This is granularity-driven, not a shortcut: the Q4
refinement (finer Step, spike doc §2) is exactly what would move them
up to WP level, and is priced below.

### 0.3 The reuse-vs-build table (one row per slate-needed rule)

| # | slate need | iris-lean provides | call [AGENT:S4] |
|---|---|---|---|
| R1 | generic WP plumbing: mono / frame / wand / value / fupd | `wp_mono`, `wp_frame_l/r`, `wp_wand`, `wp_value'`, `fupd_wp`/`wp_fupd`, proof-mode instances | **REUSE** verbatim |
| R2 | bind | `wp_bind` requires `Language.Context`; our Expr is a monolithic suspended `ndM` — the language has no evaluation contexts, and sequencing is collapsed inside one `app` node (`nd_bind` active-head collapse, S3 evidence) | **N/A at WP level** — Layer-2 `app_bind_active/_killed` already carry this; nothing to build |
| R3 | THE driver-step lifting (one rule: a Step-visible `app` equation ⇒ a WP step) | `wp_lift_atomic_step` (Lifting.lean:156) is the generic shell (one step to a value) | **BUILD (thin)**: `wp_app_active` / `wp_app_killed` over our StateInterp — reuses the shell + our step-inversion lemma (`step_running_inv`, built this slice) |
| R4 | T1 return | `done o` configurations ARE values (`toVal (done o) = some o`); `wp_value'` | **REUSE** — return is value-ness of `done`; no rule to build |
| R5 | T2 pure arith + no-overflow precondition | `PureExec`/`wp_pure_*` inapplicable: our steps are state-DEPENDENT (`app m σ`), and `PurePrimStep` demands state-independence | **BUILD at Layer 2** (S5): the ∀-quantified app equation carries the precondition as a Lean hypothesis; at WP level the SAME lifting rule R3 fires — the precondition surfaces as the hypothesis of the WP lemma (charter shape `P args → WP … {{spec}}`). No new Iris rule |
| R6 | T3 alloc/store/load points-to + frame | full gen_heap stack exists (pointsTo/alloc/valid/update) | **DEFER gen_heap; BUILD at Layer 2** (S5): at driver-node granularity there are no intermediate configurations to frame across (§0.2); T3's content = MemState store/load lemmas (bytemap roundtrip; `PointsToByte` from the spike is the model-level shadow). gen_heap-over-heapOf is the Q4-refinement instantiation, priced not built |
| R7 | T4 struct-member points-to | gen_heap + nothing struct-specific | **BUILD at Layer 2** (S5): member offsets via the layout oracles (offsetsof/sizeofCtype) as pure equations inside the app computation; same deferral as R6 |
| R8 | T5 loop invariant (D5: WP-level item) | `iloeb` (Löb) available; total WP exists | **PARK with pricing** (T5 is proved-or-parked): a slate loop is INSIDE the single app node, so the "loop rule" is an app/fuel-level induction on `driver2_lemFuel` (invariant over the fuel recursion), not a WP rule — the D5 expectation is REVISED on the §0.2 evidence: at this granularity a WP-level loop rule has no traffic; build the fuel-induction rule when T5 is attempted |
| R9 | adequacy entry | `wp_adequacy_gen` + `adequate` (exact signatures §0.1) | **REUSE + BUILD the exit**: `steps_erased` (DSteps ⇒ thread-pool erased trace) + `adequate_result` ∘ `callOutcomes_sound` chain ⇒ `CallAdequate` (THE adequacy theorem, §4) |
| R10 | StateInterp / resources | `StateInterp` slot class; `ghost_var`; gen_heap | **BUILD (SC instantiation)**: full-driver-state `ghost_var` at ½/½ (§3); the slot stays parameterized |

Escalation-rule status for the table: no row may grow a tactic
campaign; every BUILD row is lemma-sized or explicitly parked.

## 1. Lake dep (Task 1a)

`lean_frontend/lakefile.toml`: `iris` required by git URL at rev
`79dab154a64051384179c4d4e00511752cf2a168`, `subDir = "Iris"`; `Qq`
(iris's dep) pinned at iris's vendored rev
`38d591e778f100aec9762bb582f9c7f55f50e9dc` as a direct git require so
the scoped form never queries Reservoir (offline discipline; batteries
was already pinned at the iris-vendored v4.32.0 in S0, by design).
`deps/gitconfig` gains the `iris-lean → deps/iris-lean` redirect
(project-scoped file, per its own convention). **Mirror note (next
network window): create `deps/mirrors/iris-lean.git` and re-point the
redirect** — recorded in deps/gitconfig too. `lake update iris Qq`
resolved offline through the redirects; `lake build Iris` green under
this package (296 jobs).

## 2. The language instance (Task 1b — RelSem/IrisLang.lean)

Realized from the spike's typechecked sketch
(RelSem/IrisCoupling.lean header, verified against Language.lean at
the pin): `Expr := DriveExpr`, `Val := Outcome driver_result
driver_error`, `State := driver_state`, `Obs := Empty` (no
observations v0), `primStep` an inductive wrapping ONE `DStep` with
`efs = []` (no forks, ever — the driver's threads live INSIDE the ndM
tree). `val_stuck` from the spike's `RelSem.val_stuck`;
`done_irreducible` gives value-irreducibility. Parametricity note:
this is the coupling of THE sequential ExecModel instance —
`seqModel.Config` decomposes as `⟨expr, st⟩` and `seqModel.Step =
DStep` by definition, so Layer 3 exits stay ExecModel-shaped (§4); the
Language typeclass itself is necessarily per-model (a cmm instance
gets its own), which is the forward-design contract: the ADEQUACY
SHAPE is model-generic, the coupling per-model.

New Layer-2 inversion lemmas the coupling needed (Machine.lean,
lemma-sized, no escalation): `step_running_active_inv` /
`step_running_killed_inv` (a terminal-headed node steps ONLY to its
`done`), used for the lifting rule's postcondition and determinism.

## 3. StateInterp: the SC instantiation of the slot (Task 2 —
##    RelSem/IrisState.lean)

**Decision [AGENT:S4]: full-driver-state `ghost_var` (½ interp / ½
proof), NOT gen_heap-over-heapOf, NOT a custom RA.** The probe that
decided it (with §0.2): the one WP step's postcondition must be
derived from `stateInterp σ₁` alone, and the app equation is a
function of the FULL `driver_state` — core_file, thread arena/env,
allocation counters, fs — not just heap bytes. gen_heap over
`heapOf st.layout_state` under-determines σ₁ (a WP against it must
hold for EVERY state agreeing on bytes, which is false for `callND`),
so it would need a second full-state resource anyway; and no slate
proof ever consults a points-to between steps (§0.2: no intermediate
steps exist). The Mansky-Du lesson (don't force a real C semantics
into the standard heap instance) plus build-only-what-T1-T4-need makes
the ghost cell the honest SC instantiation. gen_heap remains the
designated instantiation for the Q4 granularity refinement
(`genHeap_init` + the HeapBridge pattern are catalogued in §0.1 and
stay reusable as-is).

**The slot, documented (concurrency forward-design constraint):**
`CerbGS` carries `stateInterp σ _ _ _ := ghost_var γstate (½) σ` as
THE interpretation for THIS instantiation; swapping the memory/
concurrency model (cmm, RC11-style, or the gen_heap refinement)
replaces `CerbGS`'s interpretation — and per the survey's two-level
lesson may abstract the surface proposition type — WITHOUT reshaping
the Language instance (§2) or any adequacy statement (§4, behavior-
quantified through ExecModel). `stateIs σ` (the proof-side ½) is the
assertion the rules consume.

Points-to for T3/T4: per rows R6/R7, DERIVED at the MemState level
(Layer 2) inside app-equation lemmas; the Iris-level pointsTo is
deliberately NOT introduced this arc (dead weight at this granularity
— documented, priced for the refinement).

## 4. WP rules built (Task 3 — RelSem/IrisRules.lean)

Per the table: R3 only (+R1 reused, R4 free).

* `wp_app_active` — `app m σ = (NDactive v, σ') → stateIs σ ∗
  (stateIs σ' -∗ Φ (.value v)) ⊢ WP (.running m) {{ Φ }}`;
* `wp_app_killed` — the `killed` twin (Φ (.killed r); UB/kill verdicts
  are VALUES, excludable by specs — spike stuckness-honesty note);
* both via `wp_lift_atomic_step` + `ghost_var_agree` (pin σ₁ = σ) +
  `ghost_var_update_halves` (move the cell to σ') +
  `step_running_*_inv` (determinism of the step).
* `wp_callND` / `wp_callND_killed` — R3 instantiated at the harness
  computation (the "call rule for the callConfig protocol": the
  by-pointer argument injection is INSIDE `callND`'s app equation, so
  the call rule's hypothesis IS the ∀-quantified app equation, with
  the T2-style precondition carried as its Lean hypothesis — R5).

## 5. THE ADEQUACY THEOREM (Task 4 — RelSem/IrisAdequacy.lean)

(statement verbatim in §5.1 below; recorded after the build went
green.)

Chain: WP premise ⇒ `wp_adequacy_gen` ⇒ `adequate .NotStuck` over the
coupled language ⇒ (`callOutcomes_sound` : behavior ⇒ DSteps) +
(`steps_erased` : DSteps ⇒ `-·->ₜₚ*` at the singleton pool) +
`adequate_result` ⇒ every behavior satisfies φ ⇒
`CallAdequate … (fun b => φ b.1)`. Statement-TCB: the CONCLUSION
mentions only ExecModel-level objects (`CallAdequate`, i.e.
`seqModel.Adequate` at `callConfig`); Iris appears only in the
hypothesis (discharged by the T1 WP proof). FALLBACK STATUS: **not
taken** — no Config-class restriction was needed; the theorem covers
every `callConfig` (and a whole-program `initConfig` variant comes
free through the same lemmas).

## 6. T1 (Task 5) — status, statement, and the materialization record

(§6 filled in as the slice landed; see the end of this doc.)

### 6.1 The program-term materialization problem and the decision

The slate statements need the compiled Core file as a LEAN TERM. Three
routes were priced [AGENT:S4]:

1. **Run the Lean frontend in-logic** (embed cabs-json, desugar→
   elaborate): DEAD — the frontend draws fresh symbols through the
   `CerberusFresh.forceIO` boundary AXIOM (deliberately opaque), so
   the resulting term has no kernel equations.
2. **Parse the pinned oracle Core dump in-logic** (the test_core
   ingestion class): DEAD for proofs — CoreParser is built from 97
   `partial def`s (kernel-opaque); fine in statements, useless for
   computing the app equation. Totalizing the parser is a real
   project (parked; register item).
3. **Term-emission instrument**: parse the pinned dump AT COMPILE TIME
   (`#eval`-tier, compiled code — partiality irrelevant) and EMIT the
   parsed AST as Lean source; commit the generated module; drift-gate
   it at runtime against a fresh parse of the pinned dump. The emitted
   term is kernel-transparent by construction. **ADOPTED**, scoped to
   what T1 needs.

T1's file term (`t1File`): `id`'s proc body verbatim from the pinned
oracle dump (tests/verify/t1_id.core) + the `conv_loaded_int` stdlib
closure from runtime/libcore/std.core + hand-pinned funinfo for `id`
(`signed int (signed int)`, the caller protocol's injection type) —
assembled by a pure RelSem-local function. HONESTY NOTE (statement
data): this file's `stdlib` is the REACHED CLOSURE, not all of
std.core, and `funs` carries `id` only — the theorem is about exactly
this pinned Core program; the runtime drift gate re-parses the pinned
dump + std.core and structurally compares the emitted terms, and the
concrete differential runs `callND` on the SAME assembled file against
the recorded spec points. Upgrading the term to the full pipeline file
(emit the whole linked file) is the priced S5/arc-8 item.

## 7. Validation & audit

(recorded at slice end: Tier A zero-movement, lake build with the iris
dep, Audit sweep extended over the coupling modules, test_verify.)

## 8. Register items out of this slice

* CoreParser totalization (route-2 unblock) — parked, priced as a
  fuel-totalization sweep over 97 partial defs (arc-3 pattern).
* Term-emission instrument growth path: whole-linked-file emission
  (T2-T5 + libxml2-scale statements).
* gen_heap-over-heapOf instantiation — the Q4 granularity refinement's
  first work item (catalogued entry points in §0.1 make it a
  parameter fill of the slot, §3).
* mirrors: deps/mirrors/iris-lean.git at the next network window.
