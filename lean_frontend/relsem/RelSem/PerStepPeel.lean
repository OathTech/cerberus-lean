/-
  RelSem.PerStepPeel — V2 (2026-08-28): THE LOOP PEEL — the generated
  driver loops (driver2 / drive_nonmemory_steps) reified as per-round
  `KExpr` joints, with OBSERVATION anchors tying every peel to the
  production computation (via RelSem/PerStepObs.lean's bind
  congruence/associativity — fuel'd bind is not associative as values,
  so the anchors live at the runner-observation level).

  This is the arc-16 S1 record §5 design ("peeling the two loop
  recursions — the canonical big-step ↔ small-step simulation"),
  executed: `dnmsK` peels one scheduler round per `KExpr` joint;
  `bodyK` peels one driver2 iteration around it; `callK2` is the
  round-granular reified harness, and `runND_callND_eq_callK2`
  transports statement-level runner membership onto it — so the
  adequacy bridges can consume WP proofs at per-round granularity
  while the statements keep quantifying the untouched `callND`.

  Transcription discipline (the callFinishK/PerStepCall pattern):
  every peel ATOM is a verbatim projection of the generated loop body
  (debug towers omitted where Unit eta makes them definitionally
  invisible); the `*_unfold` anchors are `rfl`-grade and break
  build-fatally on any drift in the generated loops.

  House rules: no sorry, no axioms declared. Under the in-build audit.
-/

import RelSem.PerStepObs
import RelSem.PerStepIris
import RelSem.PerStepCall

set_option autoImplicit false

namespace RelSem
namespace Cerb

/-! ## The dnms round atoms (projections of the generated loop body) -/

/-- The step-DISCOVERY function (dnms's read body — generated
    Driver.lean `drive_nonmemory_steps_aux2_lemFuel`, succ arm,
    verbatim). -/
def dnmsDiscover (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) (dr_st : driver_state) : List core_step2 :=
  let th_info :=
    match Lem_List.lookupBy (fun x y => x == y) tid
        dr_st.core_state0.thread_states with
    | some z => z
    | none =>
      (failwithI (String.append
        "Driver.drive_nonmemory_steps_aux2 => invalid tid: "
        (Lem_String_extra.stringFromNat tid))
        : Option thread_id × thread_state)
  step_ctx tagDefs dr_st.layout_state dr_st.core_file
    dr_st.core_extern tid th_info

/-- The step-DISCOVERY read: dnms's head atom. -/
def dnmsReadM (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) :
    ndM (List core_step2) step_kind driver_error mem_iv_constraint
      driver_state :=
  nd_read (dnmsDiscover tagDefs tid)

/-- One-level unfolding of the generated dnms loop at a `tid :: xs'`
    worklist (rfl-grade transcription anchor; drift in the generated
    loop breaks this build-fatally). -/
theorem dnms_succ_unfold
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (f : Nat) (acc : Fmap thread_id (List core_step2))
    (tid : Nat) (xs' : List Nat) :
    drive_nonmemory_steps_aux2_lemFuel (f + 1) tagDefs acc (tid :: xs')
      = nd_bind (dnmsReadM tagDefs tid) (fun steps =>
          match find_can_advance steps with
          | none => drive_nonmemory_steps_aux2_lemFuel f tagDefs
              (fmapAddBy defaultCompare tid steps acc) xs'
          | some step1 =>
              nd_bind (advance_step tagDefs tid step1) (fun wakeups =>
                drive_nonmemory_steps_aux2_lemFuel f tagDefs acc
                  (match wakeups with
                   | NOWAKEUP => tid :: xs'
                   | WAKEUP false tids => tid :: list_inserts tids xs'
                   | WAKEUP true tids => list_inserts tids xs'))) := rfl

/-! ## Observation wrappers at the production bind (`nd_bind` =
    `nd_bind_lemFuel lemDefaultFuel`, rfl-defeq) -/

theorem denote_seq {α : Type}
    (m : ndM α step_kind driver_error mem_iv_constraint driver_state)
    (k : α → KDriveExpr) :
    (KExpr.seq m k : KDriveExpr).denote
      = nd_bind m (fun v => (k v).denote) := rfl

section ObsWrappers
variable {A B D I E C S : Type}

/-- Stepping the observation through an active head. -/
theorem runNDFuel_bind_step_active (F : Nat) {m : ndM A I E C S}
    {g : A → ndM B I E C S} {σ σ' : S} {v : A}
    (h : app m σ = (NDactive v, σ')) :
    CerbND.runNDFuel (F + 1) (nd_bind m g) σ
      = CerbND.runNDFuel (F + 1) (g v) σ' :=
  runNDFuel_succ_congr F (app_bind_active h)

/-- Associativity wrapper at the production bind. -/
theorem runNDFuel_ndbind_assoc (F : Nat) (hF : F ≤ lemDefaultFuel)
    (m : ndM A I E C S) (f : A → ndM B I E C S)
    (g : B → ndM D I E C S) (σ : S) :
    CerbND.runNDFuel F (nd_bind (nd_bind m f) g) σ
      = CerbND.runNDFuel F (nd_bind m (fun x => nd_bind (f x) g)) σ :=
  runNDFuel_bind_assoc F hF hF hF hF m f g σ

/-- Return elimination at the observation (the fused-round anchor's
    glue: `bind (return v) k` observes as `k v`). -/
theorem runNDFuel_bind_return (F : Nat) {v : A}
    {k : A → ndM B I E C S} {σ : S} :
    CerbND.runNDFuel F (nd_bind (nd_return v) k) σ
      = CerbND.runNDFuel F (k v) σ := by
  cases F with
  | zero => rfl
  | succ F => exact runNDFuel_succ_congr F (app_bind_active rfl)

/-- Congruence wrapper at the production bind. -/
theorem runNDFuel_ndbind_congr (F : Nat) (hF : F ≤ lemDefaultFuel)
    (m : ndM A I E C S) (f g : A → ndM B I E C S) (σ : S)
    (h : ∀ (F' : Nat), F' ≤ F → ∀ (v : A) (σ' : S),
      CerbND.runNDFuel F' (f v) σ' = CerbND.runNDFuel F' (g v) σ') :
    CerbND.runNDFuel F (nd_bind m f) σ
      = CerbND.runNDFuel F (nd_bind m g) σ :=
  runNDFuel_bind_congr F hF hF m f g σ h

end ObsWrappers

/-! ## The dnms peel: ONE FUSED SCHEDULER ROUND per `KExpr` joint
    (discovery + advance in one atom — the round classes of
    Kit/Round.lean apply verbatim to the atom's app equation). -/

/-- ONE scheduler round as an atom: discover, then either advance
    (value `inl wakeups`) or report the terminal offers (`inr`). -/
def dnmsRoundM (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) :
    ndM (advance_info ⊕ List core_step2) step_kind driver_error
      mem_iv_constraint driver_state :=
  nd_bind (dnmsReadM tagDefs tid) (fun steps =>
    match find_can_advance steps with
    | none => nd_return (Sum.inr steps)
    | some step1 =>
        nd_bind (advance_step tagDefs tid step1)
          (fun wakeups => nd_return (Sum.inl wakeups)))

/-- The peeled dnms loop: fuel-indexed, one fused round per joint.
    Advancing rounds recurse (NOWAKEUP — the single-threaded shape);
    every other path falls back to the COARSE atom (the residual
    loop), so the observation anchor closes on all inputs. -/
@[reducible] def dnmsK (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) :
    Nat → Fmap thread_id (List core_step2) → Nat → List Nat →
      (Fmap thread_id (List core_step2) → KDriveExpr) → KDriveExpr
  | 0, acc, tid, xs', k =>
      .seq (drive_nonmemory_steps_aux2_lemFuel 0 tagDefs acc
        (tid :: xs')) k
  | f + 1, acc, tid, xs', k =>
      .seq (dnmsRoundM tagDefs tid) (fun r =>
        match r with
        | Sum.inr steps => .seq (drive_nonmemory_steps_aux2_lemFuel f
            tagDefs (fmapAddBy defaultCompare tid steps acc) xs') k
        | Sum.inl NOWAKEUP => dnmsK tagDefs f acc tid xs' k
        | Sum.inl (WAKEUP false tids) =>
            .seq (drive_nonmemory_steps_aux2_lemFuel f tagDefs acc
              (tid :: list_inserts tids xs')) k
        | Sum.inl (WAKEUP true tids) =>
            .seq (drive_nonmemory_steps_aux2_lemFuel f tagDefs acc
              (list_inserts tids xs')) k)

/-- THE dnms PEEL ANCHOR (observation-level): the peeled expression
    enumerates exactly as the coarse `bind` of the generated loop, at
    every fuel within the production budget. -/
theorem dnmsK_obs (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) :
    ∀ (f : Nat) (acc : Fmap thread_id (List core_step2)) (tid : Nat)
      (xs' : List Nat) (k : Fmap thread_id (List core_step2) → KDriveExpr)
      (F : Nat), F ≤ lemDefaultFuel → ∀ (σ : driver_state),
    CerbND.runNDFuel F (dnmsK tagDefs f acc tid xs' k).denote σ
      = CerbND.runNDFuel F
          (nd_bind (drive_nonmemory_steps_aux2_lemFuel f tagDefs acc
              (tid :: xs'))
            (fun r => (k r).denote)) σ := by
  intro f
  induction f with
  | zero => intro acc tid xs' k F _ σ; rfl
  | succ f ih =>
    intro acc tid xs' k F hF σ
    cases F with
    | zero => rfl
    | succ F =>
      have hread : app (dnmsReadM tagDefs tid) σ
          = (NDactive (dnmsDiscover tagDefs tid σ), σ) :=
        app_nd_read (dnmsDiscover tagDefs tid) σ
      -- LHS: expose the fused atom's inner bind, reassociate, step
      -- through the (always-active) discovery
      rw [show (dnmsK tagDefs (f + 1) acc tid xs' k).denote
          = nd_bind (dnmsRoundM tagDefs tid) (fun r =>
              ((match r with
                | Sum.inr steps => KExpr.seq
                    (drive_nonmemory_steps_aux2_lemFuel f tagDefs
                      (fmapAddBy defaultCompare tid steps acc) xs') k
                | Sum.inl NOWAKEUP => dnmsK tagDefs f acc tid xs' k
                | Sum.inl (WAKEUP false tids) =>
                    KExpr.seq (drive_nonmemory_steps_aux2_lemFuel f
                      tagDefs acc (tid :: list_inserts tids xs')) k
                | Sum.inl (WAKEUP true tids) =>
                    KExpr.seq (drive_nonmemory_steps_aux2_lemFuel f
                      tagDefs acc (list_inserts tids xs')) k)
                : KDriveExpr).denote) from rfl,
        show (dnmsRoundM tagDefs tid)
          = nd_bind (dnmsReadM tagDefs tid) (fun steps =>
              match find_can_advance steps with
              | none => nd_return (Sum.inr steps)
              | some step1 =>
                  nd_bind (advance_step tagDefs tid step1)
                    (fun wakeups => nd_return (Sum.inl wakeups)))
          from rfl,
        runNDFuel_ndbind_assoc (F + 1) hF _ _ _ σ,
        runNDFuel_bind_step_active F hread]
      -- RHS: unfold one loop level, reassociate, step through
      rw [dnms_succ_unfold,
        runNDFuel_ndbind_assoc (F + 1) hF _ _ _ σ,
        runNDFuel_bind_step_active F hread]
      cases hfind : find_can_advance (dnmsDiscover tagDefs tid σ) with
      | none =>
        simp only [denote_seq]
        rw [runNDFuel_bind_return (F + 1)]
        rfl
      | some step1 =>
        simp only [denote_seq]
        rw [runNDFuel_ndbind_assoc (F + 1) hF _ _ _ σ,
          runNDFuel_ndbind_assoc (F + 1) hF _ _ _ σ]
        refine (runNDFuel_ndbind_congr (F + 1) hF
          (advance_step tagDefs tid step1) _ _ σ ?_)
        intro F' hF' w σ'
        rw [runNDFuel_bind_return F']
        cases w with
        | NOWAKEUP => exact ih acc tid xs' k F' (by omega) σ'
        | WAKEUP b tids => cases b <;> rfl

/-! ## Round-atom app equations (what the per-round wpk instances
    feed: discovery + dispatch composed) -/

/-- The ADVANCING round atom: discovery finds `step1`, the advance
    yields NOWAKEUP. -/
theorem dnmsRoundM_adv
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {σ σ' : driver_state} {step1 : core_step2}
    (hfind : find_can_advance (dnmsDiscover tagDefs tid σ) = some step1)
    (hadv : app (advance_step tagDefs tid step1) σ
      = (NDactive NOWAKEUP, σ')) :
    app (dnmsRoundM tagDefs tid) σ
      = (NDactive (Sum.inl NOWAKEUP), σ') := by
  show app (nd_bind (dnmsReadM tagDefs tid) _) σ = _
  refine (app_bind_active (app_nd_read (dnmsDiscover tagDefs tid) σ)).trans ?_
  simp only [hfind]
  refine (app_bind_active hadv).trans ?_
  exact app_nd_return _ _

/-- The TERMINAL round atom: no advancing step; the offers return. -/
theorem dnmsRoundM_inr
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {σ : driver_state}
    (hfind : find_can_advance (dnmsDiscover tagDefs tid σ) = none) :
    app (dnmsRoundM tagDefs tid) σ
      = (NDactive (Sum.inr (dnmsDiscover tagDefs tid σ)), σ) := by
  show app (nd_bind (dnmsReadM tagDefs tid) _) σ = _
  refine (app_bind_active (app_nd_read (dnmsDiscover tagDefs tid) σ)).trans ?_
  simp only [hfind]
  exact app_nd_return _ _

/-! ## The driver2 iteration peel -/

/-- The scheduler's per-thread offer pick (ndct's mapM stage — the
    generated block, debug towers Unit-eta-invisible and omitted). -/
def ndctPick (m : Fmap thread_id (List core_step2)) :
    ndM (List (Nat × Option core_step2)) step_kind driver_error
      mem_iv_constraint driver_state :=
  nd_mapM (fun (p : Nat × List core_step2) =>
    match p with
    | (tid1, steps) =>
        nd_bind (pick (SK_misc ["new_drive_core_threads"]) steps)
          (fun step1 => nd_return (tid1, some step1)))
    (fmapElements m)

/-- ndct = get; dnms; pick (rfl-grade transcription anchor). -/
theorem ndct_unfold
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) :
    new_drive_core_threads tagDefs ()
      = nd_bind nd_get (fun (dr_st : driver_state) =>
          nd_bind (drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel
              tagDefs fmapEmpty
              (List.map Prod.fst dr_st.core_state0.thread_states))
            ndctPick) := rfl

/-- The driver2 iteration REMAINDER after the scheduler offers (the
    generated succ body's tail, verbatim modulo Unit-eta-invisible
    debug; `recur` = the decremented-fuel loop). -/
def driver2Rest (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (wc : Bool)
    (recur : Bool → ndM Unit step_kind driver_error mem_iv_constraint
      driver_state)
    (tid_steps : List (Nat × Option core_step2)) :
    ndM Unit step_kind driver_error mem_iv_constraint driver_state :=
  nd_bind nd_get (fun (_post_core_dr_st : driver_state) =>
    if Lem_Maybe.maybeEqualBy (fun x y => x == y)
        (CerbGlobal.current_execution_mode ())
        (some CerbGlobal.ExecutionMode.random) then
      bindExhaustive (pick (SK_misc ["driver 2"]) tid_steps)
        (fun (p : Nat × Option core_step2) =>
          match p with
          | (_tid1, step_opt) =>
              match step_opt with
              | some step1 => process_core_step2 tagDefs wc recur step1
              | none => nd_return ())
    else
      let non_blocked := List.filter
        (fun (p : Nat × Option core_step2) =>
          match p with
          | (_tid1, step_opt) =>
              not (Lem_Maybe.maybeEqualBy (fun x y => x == y) step_opt
                (some Step_blocked2)))
        tid_steps
      nd_bind
        (if List.length non_blocked == 0 then nd_return () else
          nd_return ())
        (fun (_ : Unit) =>
          nd_bind (pick (SK_misc ["driver non_blocked"]) non_blocked)
            (fun (x : Nat × Option core_step2) =>
              match x with
              | (_, none) => nd_return ()
              | (_, some step1) =>
                  process_core_step2 tagDefs wc recur step1)))

/-- One-level unfolding of the generated driver2 loop (rfl-grade
    transcription anchor). -/
theorem driver2_succ_unfold
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (f : Nat) (wc : Bool) :
    driver2_lemFuel (f + 1) tagDefs wc
      = nd_bind (new_drive_core_threads tagDefs ())
          (driver2Rest tagDefs wc (driver2_lemFuel f tagDefs)) := rfl

/-- THE BODY PEEL: one driver2 iteration, the dnms rounds as per-round
    joints; every non-singleton thread shape falls back to coarse
    atoms (the anchor closes on all inputs). -/
@[reducible] def bodyK (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (f' : Nat) (k : Unit → KDriveExpr) : KDriveExpr :=
  .seq nd_get (fun (dr_st : driver_state) =>
    match List.map Prod.fst dr_st.core_state0.thread_states with
    | [tid] =>
        dnmsK tagDefs lemDefaultFuel fmapEmpty tid [] (fun m =>
          .seq (ndctPick m) (fun tid_steps =>
            .seq (driver2Rest tagDefs false (driver2_lemFuel f' tagDefs)
              tid_steps) k))
    | tids =>
        .seq (nd_bind (drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel
            tagDefs fmapEmpty tids) ndctPick) (fun tid_steps =>
          .seq (driver2Rest tagDefs false (driver2_lemFuel f' tagDefs)
            tid_steps) k))

/-- THE BODY PEEL ANCHOR: `bodyK` enumerates exactly as the coarse
    driver2 atom, at every fuel within the production budget. -/
theorem bodyK_obs
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (f' : Nat) (k : Unit → KDriveExpr)
    (F : Nat) (hF : F ≤ lemDefaultFuel) (σ : driver_state) :
    CerbND.runNDFuel F (bodyK tagDefs f' k).denote σ
      = CerbND.runNDFuel F
          ((KExpr.seq (driver2_lemFuel (f' + 1) tagDefs false) k)
            : KDriveExpr).denote σ := by
  cases F with
  | zero => rfl
  | succ F =>
    rw [denote_seq (driver2_lemFuel (f' + 1) tagDefs false) k,
      driver2_succ_unfold, ndct_unfold]
    rw [runNDFuel_ndbind_assoc (F + 1) hF _ _ _ σ,
      runNDFuel_ndbind_assoc (F + 1) hF _ _ _ σ,
      runNDFuel_bind_step_active F (app_nd_get σ)]
    rw [show (bodyK tagDefs f' k).denote
        = nd_bind nd_get (fun (dr_st : driver_state) =>
            (match List.map Prod.fst dr_st.core_state0.thread_states with
             | [tid] =>
                 dnmsK tagDefs lemDefaultFuel fmapEmpty tid [] (fun m =>
                   .seq (ndctPick m) (fun tid_steps =>
                     .seq (driver2Rest tagDefs false
                       (driver2_lemFuel f' tagDefs) tid_steps) k))
             | tids =>
                 .seq (nd_bind (drive_nonmemory_steps_aux2_lemFuel
                     lemDefaultFuel tagDefs fmapEmpty tids) ndctPick)
                   (fun tid_steps =>
                     .seq (driver2Rest tagDefs false
                       (driver2_lemFuel f' tagDefs) tid_steps) k)
              : KDriveExpr).denote) from rfl,
      runNDFuel_bind_step_active F (app_nd_get σ)]
    rcases htids : List.map Prod.fst σ.core_state0.thread_states with
      _ | ⟨tid, rest⟩
    · simp only [denote_seq]
    · cases rest with
      | nil =>
        rw [dnmsK_obs tagDefs lemDefaultFuel fmapEmpty tid [] _ (F + 1)
          hF σ, runNDFuel_ndbind_assoc (F + 1) hF _ _ _ σ]
        simp only [denote_seq]
      | cons t2 rest2 =>
        simp only [denote_seq]


/-! ## Terminal-path app equations (the done iteration's atoms) -/

/-- The dnms residual at an EMPTY worklist: the accumulator returns. -/
theorem dnms_nil
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {f : Nat} {acc : Fmap thread_id (List core_step2)}
    {σ : driver_state} :
    app (drive_nonmemory_steps_aux2_lemFuel (f + 1) tagDefs acc []) σ
      = (NDactive acc, σ) := rfl

/-- The scheduler pick at ONE offered step (state-preserving). -/
theorem ndctPick_one {s1 : core_step2} {σ : driver_state} :
    app (ndctPick (fmapAddBy defaultCompare 0 [s1] fmapEmpty)) σ
      = (NDactive [(0, some s1)], σ) := rfl

/-- The done-processing driver2 remainder: the pick takes the done
    offer, `prepare_exit` rebuilds the core state (both execution
    modes — the opaque mode read is CASED once, here; the
    `driver2_done` recipe at the peel's tail atom). -/
theorem driver2Rest_done
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {recur : Bool → ndM Unit step_kind driver_error mem_iv_constraint
      driver_state}
    {v : value} {σ σ' : driver_state}
    (hout : { σ with core_state0 := prepare_exit σ.core_state0 v }
      = σ') :
    app (driver2Rest tagDefs false recur [(0, some (Step_done2 v))]) σ
      = (NDactive (), σ') := by
  subst hout
  show app (nd_bind nd_get _) σ = _
  refine (app_bind_active (app_nd_get σ)).trans ?_
  cases hmode : Lem_Maybe.maybeEqualBy (fun x y => x == y)
      (CerbGlobal.current_execution_mode ())
      (some CerbGlobal.ExecutionMode.random) with
  | true =>
    simp only [hmode, reduceIte, bindExhaustive]
    apply (app_bind_active ?hpickT).trans
    case hpickT => rfl
    apply (app_bind_active ?hdbgT).trans
    case hdbgT => rfl
    rfl
  | false =>
    simp only [hmode, reduceIte]
    apply (app_bind_active ?hgrd).trans
    case hgrd => rfl
    apply (app_bind_active ?hpickF).trans
    case hpickF => rfl
    apply (app_bind_active ?hdbgF).trans
    case hdbgF => rfl
    rfl

/-! ## The round-granular reified harness -/

open Lem_Basic_classes (ordCompare) in
/-- `callFinishK` (PerStepCall) with the driver2 atom PEELED
    (transcription otherwise verbatim). -/
@[reducible] def callFinishK2
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (fsym : sym)
    (expr1 : generic_expr core_run_annotation Unit sym)
    (bound : List (sym × value)) : KDriveExpr :=
  .seq get_thread_states
    (fun (ths : List (Nat × (Option thread_id × thread_state))) =>
    match ths with
    | [(_, (_, th_st))] =>
        let env' : List (Fmap sym value) :=
          match th_st.env with
          | [] => [Lem_Map.fromList bound]
          | xs :: xs' =>
            (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
              fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2)
                pv.1 pv.2 m) xs bound) :: xs'
        .seq
          (liftMem (nd_bind
            (CerbMem.allocateObject tid0 (PrefOther "errno")
              (CerbMem.alignofIval signed_int) signed_int none none)
            (fun (ptr_val : CerbMem.PointerValue) =>
              let zero := CerbMem.integerValueMval (Signed Int_)
                (CerbMem.integerIval (0 : Int))
              nd_bind
                (CerbMem.storeM (CerbLocation.other "errno init")
                  signed_int false ptr_val zero)
                (fun (_ : CerbMem.Footprint) => nd_return ptr_val))))
          (fun (errno_ptr_val : CerbMem.PointerValue) =>
        .seq (driver_update_thread_state tid0
          ({ arena := expr1,
             stack0 := Stack_empty,
             errno := errno_ptr_val,
             current_loc := CerbLocation.other "RelSem.callND",
             exec_loc := ELoc_normal
               [(fsym, CerbLocation.other "RelSem.callND")],
             env := env',
             current_proc_opt := some fsym } : thread_state))
          (fun (_ : Unit) =>
        bodyK tagDefs 999999 (fun (_ : Unit) =>
        .seq nd_get (fun (dr_st' : driver_state) =>
        .done (.value (finalize tagDefs "callND" dr_st'))))))
    | _ => .done (.killed (Other (DErr_other
        "callND: not exactly one thread after globals"))))

/-- THE ROUND-GRANULAR REIFIED HARNESS: `callK` with the body peeled. -/
@[reducible] def callK2
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) : KDriveExpr :=
  .seq (driver_globals tagDefs false file1) (fun (tid0 : Nat) =>
  .seq nd_get (fun (post_globals_dr_st : driver_state) =>
  .seq (resolveFunSym post_globals_dr_st.core_file fname)
    (fun (fsym : sym) =>
  .seq (lookupFunBody post_globals_dr_st.core_file fsym)
    (fun (pb : List (sym × core_base_type) ×
          generic_expr core_run_annotation Unit sym) =>
  .seq (lookupParamTys post_globals_dr_st.core_file fsym)
    (fun (ptys : List ctype) =>
  .seq (injectArgs tagDefs tid0 pb.1 ptys args)
    (fun (bound : List (sym × value)) =>
  callFinishK2 tagDefs tid0 fsym pb.2 bound))))))

/-- The finish-stage observation anchor: `callFinishK2` enumerates as
    `callFinishK`. -/
theorem callFinishK2_obs
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (fsym : sym)
    (expr1 : generic_expr core_run_annotation Unit sym)
    (bound : List (sym × value))
    (F : Nat) (hF : F ≤ lemDefaultFuel) (σ : driver_state) :
    CerbND.runNDFuel F
        (callFinishK2 tagDefs tid0 fsym expr1 bound).denote σ
      = CerbND.runNDFuel F
          (callFinishK tagDefs tid0 fsym expr1 bound).denote σ := by
  show CerbND.runNDFuel F
      (nd_bind get_thread_states _) σ = CerbND.runNDFuel F
      (nd_bind get_thread_states _) σ
  refine runNDFuel_ndbind_congr F hF _ _ _ σ ?_
  intro F1 hF1 ths σ1
  rcases ths with _ | ⟨⟨t1, ot, th_st⟩, _ | ⟨hd, tl⟩⟩
  · rfl
  · show CerbND.runNDFuel F1 (nd_bind _ _) σ1
      = CerbND.runNDFuel F1 (nd_bind _ _) σ1
    refine runNDFuel_ndbind_congr F1 (by omega) _ _ _ σ1 ?_
    intro F2 hF2 eptr σ2
    show CerbND.runNDFuel F2 (nd_bind _ _) σ2
      = CerbND.runNDFuel F2 (nd_bind _ _) σ2
    refine runNDFuel_ndbind_congr F2 (by omega) _ _ _ σ2 ?_
    intro F3 hF3 u σ3
    exact bodyK_obs tagDefs 999999 _ F3 (by omega) σ3
  · rfl

/-- THE HARNESS OBSERVATION ANCHOR: `callK2` enumerates as `callK`
    (hence, through `callK_denote`, as the production `callND`). -/
theorem callK2_obs
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value)
    (F : Nat) (hF : F ≤ lemDefaultFuel) (σ : driver_state) :
    CerbND.runNDFuel F (callK2 tagDefs file1 fname args).denote σ
      = CerbND.runNDFuel F (callK tagDefs file1 fname args).denote σ := by
  show CerbND.runNDFuel F (nd_bind _ _) σ
    = CerbND.runNDFuel F (nd_bind _ _) σ
  refine runNDFuel_ndbind_congr F hF _ _ _ σ ?_
  intro F1 hF1 tid0 σ1
  show CerbND.runNDFuel F1 (nd_bind _ _) σ1
    = CerbND.runNDFuel F1 (nd_bind _ _) σ1
  refine runNDFuel_ndbind_congr F1 (by omega) _ _ _ σ1 ?_
  intro F2 hF2 pg σ2
  show CerbND.runNDFuel F2 (nd_bind _ _) σ2
    = CerbND.runNDFuel F2 (nd_bind _ _) σ2
  refine runNDFuel_ndbind_congr F2 (by omega) _ _ _ σ2 ?_
  intro F3 hF3 fsym σ3
  show CerbND.runNDFuel F3 (nd_bind _ _) σ3
    = CerbND.runNDFuel F3 (nd_bind _ _) σ3
  refine runNDFuel_ndbind_congr F3 (by omega) _ _ _ σ3 ?_
  intro F4 hF4 pb σ4
  show CerbND.runNDFuel F4 (nd_bind _ _) σ4
    = CerbND.runNDFuel F4 (nd_bind _ _) σ4
  refine runNDFuel_ndbind_congr F4 (by omega) _ _ _ σ4 ?_
  intro F5 hF5 ptys σ5
  show CerbND.runNDFuel F5 (nd_bind _ _) σ5
    = CerbND.runNDFuel F5 (nd_bind _ _) σ5
  refine runNDFuel_ndbind_congr F5 (by omega) _ _ _ σ5 ?_
  intro F6 hF6 bound σ6
  exact callFinishK2_obs tagDefs tid0 fsym pb.2 bound F6 (by omega) σ6

/-- THE STATEMENT TRANSPORT: the production runner's enumeration of
    `callND` IS the enumeration of the round-granular reification —
    so a WP/adequacy result about `callK2` discharges the untouched
    statement faces. -/
theorem runND_callND_eq_callK2
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (σ : driver_state) :
    CerbND.runND (callND tagDefs file1 fname args) σ
      = CerbND.runND (callK2 tagDefs file1 fname args).denote σ := by
  rw [← callK_denote]
  show CerbND.runNDFuel CerbND.ndDefaultFuel _ σ
    = CerbND.runNDFuel CerbND.ndDefaultFuel _ σ
  exact (callK2_obs tagDefs file1 fname args CerbND.ndDefaultFuel
    (Nat.le_refl _) σ).symm

end Cerb
end RelSem
