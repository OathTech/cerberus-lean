/-
  RelSem.ConstructLaws — arc-17 S1 (2026-08-24): THE PER-CONSTRUCT LAW
  REGISTRY (charter S1 — the equation-supply frontier).

  ONE REGISTRATION POINT for fixture-independent construct laws: laws
  derived from the STEREOTYPED SHAPES Cerberus elaboration emits per C
  construct, proved once against the generated semantics, firing for
  every program that contains the shape. *Lineage (canon-first)*:
  decompilation-into-logic (Myreen) — the compiler's output shapes are
  finite and stereotyped, so one derived rule per shape replaces
  per-program equation chains; the dnms-round glue and advance-class
  laws this registry composes with live in Kit/Round.lean (arc-9 S2).

  REGISTRY DISCIPLINE (the arc-18 goal-directed search is the eventual
  consumer — Lithium-fragment shape: normal-form goals, ONE rule per
  goal form, no backtracking):
  * one law per construct shape, hypotheses in the order the engine
    will discharge them (structural side conditions first, semantic
    payload hypotheses last);
  * every law's docstring carries (a) the SHAPE it decompiles (which
    generated arm, cited file:line), (b) why the next program gets it
    free, (c) its TRACE-ATOM SCHEMA per the S0 automation-trace format
    spec (docs/2026-08-24_arc17-s0-discharge-substrate.md §3.6):
    `{lawName, joint, hypothesis slots}` — fed equations enter BY NAME,
    side conditions carry their disposition (`assumption|ground|rfl`);
  * NO fixture symbols in this file, ever (the mega-lemma counter of
    check_proof_size.sh scans this file exactly as it scans Kit/).

  House rules: no sorry, no axioms declared here; import discipline:
  no Iris, no fixtures. Cone pins in RelSem/Audit.lean.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.Call
import RelSem.Kit.Eval
import RelSem.Kit.Round
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem.Laws

open RelSem RelSem.Cerb RelSem.Kit

/-! ## The state-read crossing -/

/-- CONSTRUCT LAW `seu_read_bind` — the run-state READ at the head of a
    with-runstate step.

    SHAPE: `stExceptUndef_bind (runSE (state_except_read f)) k` — the
    compiled form of every "consult the run state, then continue" step
    (generated/Core_reduction.lean:484, the Erun arm's label read is
    the canonical instance). The read is DEFINITIONALLY a Defined
    result at the unchanged state, so the bind crosses generically —
    at ANY run state, concrete or open. WHY THE NEXT PROGRAM GETS IT
    FREE: the law never mentions what is read or from which state; the
    read's VALUE is handled downstream (`erun_jump_m`'s `hres`).

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := seu_read_bind,
    joint := runstate-read, hyps := []}` — no hypothesis slots; the
    consumer recomputes `f st` (S0 §3.1 item 2). -/
@[step_law (kind := construct) (side := rfl)
  (frontier := "construct/runstate-read")
  (trace := "{law := seu_read_bind, joint := runstate-read, hyps := []}")
  (lineage := "decompilation-into-logic (Myreen): one derived rule per stereotyped elaboration shape")]
theorem seu_read_bind {A B S E : Type}
    (f : S → A) (k : A → S → exceptM (t0 B × S) E) (st : S) :
    stExceptUndef_bind (runSE (state_except_read f)) k st = k (f st) st :=
  stub_defined rfl

/-! ## The Erun/Esave label jump -/

/-- CONSTRUCT LAW `erun_jump_m` — the label-jump M-computation
    (Erun/Esave: C `goto`, loop back-edges, and the save/run return
    encoding all elaborate to `Erun`).

    SHAPE: the `Erun` arm of `step_ctx`
    (generated/Core_reduction.lean:484): resolve the label in the
    run state's `labeled` map (`runSE (state_except_read …)`), match
    on the result (a missing label is a loud failure), then run the
    jump continuation (argument evaluation + env update + arena
    replacement). The law splits exactly there: `hres` carries the
    RESOLUTION (kernel-computable from a `labeled`-projection
    hypothesis — `simp only [mkDr-style projections, hlab]; rfl` at
    every fixture), `hk` carries the JUMP BODY (the args foldM, whose
    element evaluations are the fixture's ∀-run-state eval lemmas).

    WHY THE NEXT PROGRAM GETS IT FREE: this was THE round class that
    pinned fixtures to a concrete run state (the arc-16 S3/S4
    `round6_thr`/`round13_thr`/`round21_thr` twins existed only for
    it). With resolution as a hypothesis the round lemma is ∀-run-
    state: every state ladder — ambient, threaded ∀-seed, future cmm —
    instantiates the SAME lemma and discharges `hlab` by `rfl`.

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := erun_jump_m,
    joint := rsk-eval/label-jump, hyps := [hres : ground (labeled-map
    lookup; consumer recomputes), hk : fed-equation BY NAME (the
    fixture's eval-chain lemma)]}`. -/
@[step_law (kind := construct) (side := fed)
  (frontier := "construct/label-jump")
  (trace := "{law := erun_jump_m, joint := rsk-eval/label-jump, hyps := [hres : ground, hk : fed]}")
  (lineage := "decompilation-into-logic: the Erun arm split at resolution/jump (arc-17 S1)")]
theorem erun_jump_m {B : Type}
    {resolve : core_run_state →
      Option (List (sym × core_base_type) ×
        generic_expr core_run_annotation Unit sym)}
    {onFail : core_run_state →
      exceptM (t0 B × core_run_state) core_run_cause}
    {kJump : List (sym × core_base_type) →
      generic_expr core_run_annotation Unit sym →
      core_run_state → exceptM (t0 B × core_run_state) core_run_cause}
    {rs : core_run_state}
    {sbs : List (sym × core_base_type)}
    {ce : generic_expr core_run_annotation Unit sym}
    {r : exceptM (t0 B × core_run_state) core_run_cause}
    (hres : resolve rs = some (sbs, ce))
    (hk : kJump sbs ce rs = r) :
    stExceptUndef_bind (runSE (state_except_read resolve))
      (fun x => match x with
        | none => onFail
        | some (sbs', ce') => kJump sbs' ce') rs = r := by
  rw [seu_read_bind, hres]
  exact hk

/-! ## The call structure: scheduler read + driver iteration -/

/-- CONSTRUCT LAW `ndct_offer1` — the single-thread scheduler read.

    SHAPE: `new_drive_core_threads` (generated/Driver.lean): read the
    state, run the non-memory loop over the thread ids, then pick one
    offered step per thread. At the single-threaded shape every slate
    run has (thread table `[(0, thi)]`, one offered step), the read
    and the pick are DETERMINISTIC — the whole scheduler stage reduces
    once the dnms result enters as a hypothesis. WHY THE NEXT PROGRAM
    GETS IT FREE: `ndct_eq` was per-fixture text in every fixture
    (T1/T2/T3 ambient + threaded); this law replaces each with one
    application fed by the fixture's dnms-chain equation.

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := ndct_offer1,
    joint := scheduler-read, hyps := [hths : ground (thread-table
    shape), hdnms : fed-equation BY NAME (the dnms chain)]}`. -/
@[step_law (kind := construct) (side := fed)
  (frontier := "construct/scheduler-read")
  (trace := "{law := ndct_offer1, joint := scheduler-read, hyps := [hths : ground, hdnms : fed]}")
  (lineage := "decompilation-into-logic: the single-thread scheduler read, one law per call structure")]
theorem ndct_offer1
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {σ σ' : driver_state} {step1 : core_step2}
    {thi : Option thread_id × thread_state}
    (hths : σ.core_state0.thread_states = [(0, thi)])
    (hdnms : app (drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel tagDefs
        fmapEmpty [0]) σ
      = (NDactive (fmapAddBy defaultCompare 0 [step1] fmapEmpty), σ')) :
    app (new_drive_core_threads tagDefs ()) σ
      = (NDactive [(0, some step1)], σ') := by
  refine (app_bind_active (app_nd_get σ)).trans ?_
  simp only [hths]
  refine (app_bind_active hdnms).trans ?_
  rfl

/-- CONSTRUCT LAW `driver2_done` — one driver iteration at a done
    offer (the program-exit iteration).

    SHAPE: `driver2_lemFuel` (generated/Driver.lean) at an offer list
    `[(0, some (Step_done2 v))]`: the opaque execution-mode read
    splits the scheduler dispatch (random vs exhaustive — both
    deterministic at a singleton offer; the split is CASED once, here),
    the pick yields the done step, and `process_core_step2`'s
    `Step_done2` arm rebuilds the core state via `prepare_exit` and
    RETURNS — no recursion, so ONE iteration is the whole run. WHY THE
    NEXT PROGRAM GETS IT FREE: `driver2_iter` (with its per-fixture
    execution-mode `cases` dance) was per-fixture text in every
    fixture; this law replaces each with one application fed by the
    fixture's scheduler equation (`ndct_offer1`'s output).

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := driver2_done,
    joint := driver-iteration/done, hyps := [hndct : fed-equation BY
    NAME (the scheduler read)]}`. -/
@[step_law (kind := construct) (side := fed)
  (frontier := "construct/driver-done")
  (trace := "{law := driver2_done, joint := driver-iteration/done, hyps := [hndct : fed, hout : ground]}")
  (lineage := "decompilation-into-logic: the program-exit driver iteration, cased once over the mode read")]
theorem driver2_done
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {fuel : Nat} {σ σ' : driver_state} {v : value}
    (hndct : app (new_drive_core_threads tagDefs ()) σ
      = (NDactive [(0, some (Step_done2 v))], σ'))
    {σ'' : driver_state}
    (hout : { σ' with core_state0 := prepare_exit σ'.core_state0 v }
      = σ'') :
    app (driver2_lemFuel (fuel+1) tagDefs false) σ
      = (NDactive (), σ'') := by
  subst hout
  change app (nd_bind _ _) _ = _
  refine (app_bind_active hndct).trans ?_
  refine (app_bind_active (app_nd_get σ')).trans ?_
  cases hmode : Lem_Maybe.maybeEqualBy (fun x y => x == y)
      (CerbGlobal.current_execution_mode ())
      (some CerbGlobal.ExecutionMode.random) with
  | true =>
    simp only [reduceIte, bindExhaustive]
    apply (app_bind_active ?hpickT).trans
    case hpickT => rfl
    apply (app_bind_active ?hdbgT).trans
    case hdbgT => rfl
    rfl
  | false =>
    apply (app_bind_active ?hgrd).trans
    case hgrd => rfl
    apply (app_bind_active ?hpickF).trans
    case hpickF => rfl
    apply (app_bind_active ?hdbgF).trans
    case hdbgF => rfl
    rfl

/-- REGISTRY HELPER `stepAt` — thread `tid`'s advancing step at `σ`,
    as a TERM (the step DISCOVERY composite: thread lookup → step_ctx
    → find_can_advance). Exists so the S0 emitter can mint per-round
    successor states MECHANICALLY (`derive_state_step … from
    (advance_step tagDefs tid (stepAt tagDefs tid σ)) at σ`) with no
    hand transcription of intermediate arenas; `Kit.dnms_round`'s
    `hfind`/`hadv` unify with it definitionally. The defaults are
    totalizing only (a lookup/discovery miss yields `Step_blocked2`,
    which no advance consumes — a mis-anchored mint fails loudly). -/
def stepAt (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) (σ : driver_state) : core_step2 :=
  (find_can_advance (step_ctx tagDefs σ.layout_state σ.core_file
    σ.core_extern tid
    ((Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states).getD default))).getD Step_blocked2

/-! ## The harness caller protocol (callND stages)

    The arc-16 S4 record classifies the "prefix skeleton" — the
    memory-bearing callND stages, which at an OPEN (∀-seed) state
    must route through the kit (the recorded spike hazard) — as the
    remaining per-fixture threaded text. These laws close that class
    for the scalar protocol: the stage shapes are CALL-STRUCTURE
    (identical for every fixture; relsemcore/RelSem/Call.lean), so
    the routing is proved ONCE and each fixture feeds memory-level
    facts (`rfl` at its closed memory states). -/

/-- CONSTRUCT LAW `inject_ptr_arg1` — the one-scalar-argument caller
    protocol (fresh object + store + pointer bind).

    SHAPE: `injectArgs` at a single pointer-typed parameter
    (relsemcore/RelSem/Call.lean:115/93 — `injectArg`'s
    `BTy_object OTy_pointer` arm): convert the value, allocate the
    parameter object, store, return the pointer binding. WHY THE NEXT
    PROGRAM GETS IT FREE: every scalar one-parameter fixture's
    injection stage is THIS shape — the fixture supplies only the
    memory-level alloc/store facts (kernel-computable, `wp_side`
    class).

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := inject_ptr_arg1,
    joint := harness-inject, hyps := [hmv : ground, halloc :
    ground/fed, hstore : ground/fed]}`. -/
@[step_law (kind := construct) (side := fed)
  (frontier := "construct/harness-inject")
  (trace := "{law := inject_ptr_arg1, joint := harness-inject, hyps := [hmv : ground, halloc : fed, hstore : fed, hout : ground]}")
  (lineage := "caller-protocol decompilation: the one-scalar-argument inject stage, proved once (arc-17 S1)")]
theorem inject_ptr_arg1
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid0 : Nat} {psym : sym} {ty : ctype} {v : value}
    {mval : CerbMem.MemValue}
    {σ : driver_state} {ptr : CerbMem.PointerValue}
    {mem1 mem2 : CerbMem.MemState} {fp : CerbMem.Footprint}
    (hmv : memValueFromValue tagDefs ty v = some mval)
    (halloc : app (CerbMem.allocateObject tid0 (PrefOther "callND arg")
        (CerbMem.alignofIval ty) ty none none) σ.layout_state
      = (NDactive ptr, mem1))
    (hstore : app (CerbMem.storeM (CerbLocation.other "callND arg init")
        ty false ptr mval) mem1 = (NDactive fp, mem2))
    {σ' : driver_state}
    (hout : { σ with layout_state := mem2 } = σ') :
    app (injectArgs tagDefs tid0 [(psym, BTy_object OTy_pointer)]
        [ty] [v]) σ
      = (NDactive [(psym, Vobject (OVpointer ptr))], σ') := by
  subst hout
  simp only [injectArgs, injectArg, hmv]
  apply (app_bind_active (app_liftMem_active rfl ?hm)).trans
  case hm =>
    refine (app_bind_active halloc).trans ?_
    refine (app_bind_active hstore).trans ?_
    exact app_nd_return _ _
  apply (app_bind_active (app_nd_return _ _)).trans
  exact app_nd_return _ _

/-- CONSTRUCT LAW `callND_errno` — the harness errno block.

    SHAPE: `callFinish`'s errno stage (relsemcore/RelSem/Call.lean:171
    — allocate errno, zero it, return the pointer), transcribed
    verbatim; fixture-INDEPENDENT (no file mention at all). WHY THE
    NEXT PROGRAM GETS IT FREE: every harness run has exactly this
    stage; the fixture supplies only the memory-level facts.

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := callND_errno,
    joint := harness-errno, hyps := [halloc : ground/fed, hstore :
    ground/fed]}`. -/
@[step_law (kind := construct) (side := fed)
  (frontier := "construct/harness-errno")
  (trace := "{law := callND_errno, joint := harness-errno, hyps := [halloc : fed, hstore : fed, hout : ground]}")
  (lineage := "caller-protocol decompilation: the fixture-independent errno stage")]
theorem callND_errno
    {tid0 : Nat} {σ : driver_state} {ptr : CerbMem.PointerValue}
    {mem1 mem2 : CerbMem.MemState} {fp : CerbMem.Footprint}
    (halloc : app (CerbMem.allocateObject tid0 (PrefOther "errno")
        (CerbMem.alignofIval signed_int) signed_int none none)
        σ.layout_state
      = (NDactive ptr, mem1))
    (hstore : app (CerbMem.storeM (CerbLocation.other "errno init")
        signed_int false ptr (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval (0 : Int)))) mem1
      = (NDactive fp, mem2))
    {σ' : driver_state}
    (hout : { σ with layout_state := mem2 } = σ') :
    app (liftMem (nd_bind
        (CerbMem.allocateObject tid0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun (ptr_val : CerbMem.PointerValue) =>
          let zero := CerbMem.integerValueMval (Signed Int_)
            (CerbMem.integerIval (0 : Int))
          nd_bind
            (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val zero)
            (fun (_ : CerbMem.Footprint) => nd_return ptr_val)))) σ
      = (NDactive ptr, σ') := by
  subst hout
  refine app_liftMem_active rfl ?_
  refine (app_bind_active halloc).trans ?_
  refine (app_bind_active hstore).trans ?_
  exact app_nd_return _ _

/-- CONSTRUCT LAW `get_ths_eq` — the harness thread-table read
    (`get_thread_states` is a get+return composite;
    generated/Driver.lean). Generic, state-preserving.

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := get_ths_eq,
    joint := harness-thread-read, hyps := []}`. -/
@[step_law (kind := construct) (side := rfl)
  (frontier := "construct/thread-read")
  (trace := "{law := get_ths_eq, joint := harness-thread-read, hyps := []}")
  (lineage := "decompilation-into-logic: get+return composite, generic state-preserving read")]
theorem get_ths_eq (σ : driver_state) :
    app get_thread_states σ
      = (NDactive σ.core_state0.thread_states, σ) :=
  (app_bind_active (app_nd_get σ)).trans (app_nd_return _ _)

/-- CONSTRUCT LAW `driver_update_ts` — the harness thread-setup stage
    (`driver_update_thread_state` is `nd_update` at the thread table;
    generated/Driver.lean). Generic `rfl`; registered so the stage has
    a NAMED feeding handle (the walk never self-computes it — the
    arc-16 S3 k9-bracket measurement is the reason).

    TRACE-ATOM SCHEMA (S0 §3.3 level 2): `{law := driver_update_ts,
    joint := harness-thread-setup, hyps := []}`. -/
@[step_law (kind := construct) (side := rfl)
  (frontier := "construct/thread-setup")
  (trace := "{law := driver_update_ts, joint := harness-thread-setup, hyps := [hout : ground]}")
  (lineage := "decompilation-into-logic: nd_update at the thread table, named feeding handle")]
theorem driver_update_ts (tid : Nat) (th : thread_state)
    (σ : driver_state) {σ' : driver_state}
    (hout : { σ with core_state0 :=
        update_thread_state tid th σ.core_state0 } = σ') :
    app (driver_update_thread_state tid th : driverM Unit) σ
      = (NDactive (), σ') := by
  subst hout; rfl

end RelSem.Laws
