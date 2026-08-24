/-
  RelSem.PerStepPeel — arc-16 S3 (2026-08-24): THE TWO LOOP PEELS.

  The S1 record §5 requirement, built: reified loop formers for the two
  generated fuel recursions —

  * `dnmsK`    peels `drive_nonmemory_steps_aux2_lemFuel` to PER-CORE-
    STEP granularity (one `seq` joint per round: the step-discovery
    read + the advance; the sequential action-request rounds reify
    further, down to the `liftMem` MEMORY-OP ATOMS — the exact trigger
    shape of the S2 heap rules `wpk_load/store/alloc/kill`);
  * `driver2K` peels `driver2_lemFuel` to per-iteration granularity
    (scheduler stages as joints, `process_core_step2`'s exec-relevant
    arms reified via `pcsK`, the rest as residual atoms).

  THE CONNECTION is the canonical big-step ↔ small-step simulation:
  the interpreter (one collapsed `app` of the generated loop) and the
  machine (the peeled expression's per-joint steps) enumerate the same
  behaviors. Because fuel'd bind re-association is propositionally
  FALSE as values (S1 §1), the simulation is stated at the RUNNER-
  OBSERVATION level (`*_runner_eq`: `CerbND.runNDFuel` cannot
  distinguish the peeled denotation from the generated loop at any
  fuel within the production envelope), and adequacy consumes it
  through the GENERIC completeness `ksteps_of_runND` — so WP proofs
  over the peeled harness `callK2` land the same statement-facing
  conclusions (`CallHarnessAdequate`/`CallHarnessUBFree`, byte-
  identical defs) as the S1 route.

  Lineage (canon-first): the functional-big-step ↔ small-step
  equivalence proof of standard operational-semantics practice
  ("the interpreter implements the machine"), walked once per loop
  body; the observational bind laws it consumes are
  RelSem/PerStepRunner.lean. Nothing here re-axiomatizes: every atom
  is the generated computation itself, every unfold is `rfl`-anchored
  against the generated definition (mirror-OCaml cite-and-anchor
  discipline: drift in Driver.lean's loop bodies breaks this module's
  `rfl` bridges build-fatally).

  Transcription note: the generated bodies' debug-print stages
  (`match CerbDebug.print_debug_pure … with | () => e`) and dead lets
  vanish DEFINITIONALLY (Unit structure eta + zeta) — the mirrors
  below omit them, and the `rfl` anchors check the equivalence.

  House rules: no sorry, no axioms declared. Under the in-build audit.
-/

import RelSem.Call
import RelSem.PerStep
import RelSem.PerStepRunner
import RelSem.Kit.Round

set_option autoImplicit false

namespace RelSem
namespace Cerb

open RelSem.Kit

/-! ## Denotation helpers -/

theorem denote_seq {A I E C S : Type} {α : Type} (m : ndM α I E C S)
    (k : α → KExpr A I E C S) :
    (KExpr.seq m k).denote = nd_bind m (fun v => (k v).denote) := rfl

/-! ## The dnms peel: reified loop former -/

/-- The step-discovery read of one dnms round (mirror of the
    generated `nd_read` body, Driver.lean `drive_nonmemory_steps_aux2`;
    the `rfl` anchor in `dnmsK_runner_eq` pins the transcription). -/
def stepDiscovery (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) : driver_state → List core_step2 :=
  fun dr_st =>
    let th_info :=
      match Lem_List.lookupBy (fun x y => x == y) tid
          dr_st.core_state0.thread_states with
      | some z => z
      | none =>
        (failwithI (String.append
            "Driver.drive_nonmemory_steps_aux2 => invalid tid: "
            (Lem_String_extra.stringFromNat tid))
          : (Option thread_id × thread_state))
    step_ctx tagDefs dr_st.layout_state dr_st.core_file dr_st.core_extern
      tid th_info

/-- The wakeup scheduling of the generated round (mirror of the
    `xs''` let-match). -/
def wakeupIns (w : advance_info) (tid : Nat) (xs' : List Nat) : List Nat :=
  match w with
  | NOWAKEUP => tid :: xs'
  | WAKEUP false tids => tid :: list_inserts tids xs'
  | WAKEUP true tids => list_inserts tids xs'

/-- Reified `action_request_sequential2` (the sequential perform's
    dispatch): the four memory-op requests expose their `liftMem`
    atoms — the S2 heap rules' exact trigger shapes — plus the trace/
    thread bookkeeping `nd_update` as its own joint; other requests
    stay residual atoms. `rest` is the continuation expression (the
    peeled remainder of the loop). Mirrors `ars_*_unfold`
    (RelSem/Kit/Round.lean). -/
@[reducible] def arsK (loc : CerbLocation.Loc) (tid' aid : Nat)
    (rest : KExpr driver_result step_kind driver_error mem_iv_constraint driver_state) :
    action_request2 thread_state → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state
  | .LoadRequest2 _mo ty ptr mk =>
      .seq (liftMem (CerbMem.loadM loc ty ptr))
        (fun (p : CerbMem.Footprint × CerbMem.MemValue) =>
          match p with
          | (fp, mval) =>
            .seq (liftMem (CerbMem.prefixOfPointer ptr))
              (fun (pref : Option String) =>
              .seq (nd_update (fun (dr_st : driver_state) =>
                { dr_st with
                  trace := ME_load loc pref ty ptr mval :: dr_st.trace,
                  core_state0 := update_thread_state tid' (mk aid fp mval)
                    dr_st.core_state0 }))
                (fun _ => rest)))
  | .StoreRequest2 _mo ty isLocking ptr mval mk =>
      .seq (liftMem (CerbMem.storeM loc ty isLocking ptr mval))
        (fun (fp : CerbMem.Footprint) =>
        .seq (liftMem (CerbMem.prefixOfPointer ptr))
          (fun (pref : Option String) =>
          .seq (nd_update (fun (dr_st : driver_state) =>
            { dr_st with
              trace := ME_store loc pref ty isLocking ptr mval
                :: dr_st.trace,
              core_state0 := update_thread_state tid' (mk aid fp)
                dr_st.core_state0 }))
            (fun _ => rest)))
  | .CreateRequest2 pref align ty addrOpt initOpt mk =>
      .seq (liftMem (CerbMem.allocateObject tid' pref align ty addrOpt
          initOpt))
        (fun (ptrval : CerbMem.PointerValue) =>
        .seq (nd_update (fun (dr_st : driver_state) =>
          { dr_st with
            trace := ME_allocate_object tid' pref align ty initOpt ptrval
              :: dr_st.trace,
            core_state0 := update_thread_state tid' (mk aid ptrval)
              dr_st.core_state0 }))
          (fun _ => rest))
  | .KillRequest2 isDyn ptr mk =>
      .seq (liftMem (CerbMem.killM loc isDyn ptr))
        (fun _ =>
        .seq (nd_update (fun (dr_st : driver_state) =>
          { dr_st with
            trace := ME_kill loc isDyn ptr :: dr_st.trace,
            core_state0 := update_thread_state tid' (mk aid)
              dr_st.core_state0 }))
          (fun _ => rest))
  | req => .seq (action_request_sequential2 loc tid' aid req)
      (fun _ => rest)

/-- One round's dispatch (after the discovery read): accumulate, or
    advance. The sequential action-request advance reifies down
    through the aid draw to `arsK`; every other advance class is one
    `advance_step` atom (still a per-Core-step joint — its `app`
    equations are the Kit advance laws). -/
@[reducible] def dnmsKBody
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) (xs' : List Nat)
    (contNone : List core_step2 → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state)
    (contRest : List Nat → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state) :
    List core_step2 → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state :=
  fun steps =>
    match find_can_advance steps with
    | none => contNone steps
    | some (Step_action_request2 _dbg loc tid' false m_request) =>
        .seq (liftCore_run m_request)
          (fun (request : action_request2 thread_state) =>
          .seq (liftCore_run (runS fresh_action_id'))
            (fun (aid : Nat) =>
              arsK loc tid' aid (contRest (tid :: xs')) request))
    | some step1 =>
        .seq (advance_step tagDefs tid step1)
          (fun w => contRest (wakeupIns w tid xs'))

/-- THE PER-CORE-STEP LOOP FORMER: `drive_nonmemory_steps_aux2` with
    the step boundaries bind-collapse erased re-erected as `seq`
    joints. Fuel-0 and the continuation mirror the generated recursion
    exactly (the empty-tids exit continues DIRECTLY at `k acc` — one
    fewer step than the generated `nd_return`, bridged in the walk). -/
@[reducible] def dnmsK (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) :
    Nat → Fmap thread_id (List core_step2) → List Nat →
    (Fmap thread_id (List core_step2) → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state) → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state
  | 0, acc, tids, k =>
      .seq (drive_nonmemory_steps_aux2_lemFuel 0 tagDefs acc tids) k
  | _ + 1, acc, [], k => k acc
  | n + 1, acc, tid :: xs', k =>
      .seq (nd_read (stepDiscovery tagDefs tid))
        (dnmsKBody tagDefs tid xs'
          (fun steps =>
            dnmsK tagDefs n (fmapAddBy defaultCompare tid steps acc) xs' k)
          (fun tids' => dnmsK tagDefs n acc tids' k))

/-! ## The dnms simulation (big-step ↔ small-step, runner-observed) -/

/-- THE DNMS PEEL: within the production fuel envelope, the runner
    cannot distinguish the peeled loop from the generated recursion
    bound to the same continuation. One walk of the generated body,
    by induction on the LOOP fuel; all node casing is delegated to
    `runNDFuel_bind_congr`. -/
theorem dnmsK_runner_eq
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (k : Fmap thread_id (List core_step2) → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state) :
    ∀ (n : Nat) (acc : Fmap thread_id (List core_step2))
      (tids : List Nat) (F : Nat), F ≤ lemDefaultFuel →
    ∀ σ : driver_state,
      CerbND.runNDFuel F (dnmsK tagDefs n acc tids k).denote σ
        = CerbND.runNDFuel F
            (nd_bind (drive_nonmemory_steps_aux2_lemFuel n tagDefs acc tids)
              (fun m => (k m).denote)) σ := by
  intro n
  induction n with
  | zero => intro acc tids F hF σ; rfl
  | succ n ih =>
    intro acc tids F hF σ
    cases tids with
    | nil =>
      -- generated exit: `nd_return acc`; peeled exit: `k acc` directly.
      exact (runNDFuel_bind_active
        (m := drive_nonmemory_steps_aux2_lemFuel (n + 1) tagDefs acc [])
        (f := fun m => (k m).denote) rfl F).symm
    | cons tid xs' =>
      -- expose the round: read; dispatch. Both sides share the read.
      show CerbND.runNDFuel F
          (KExpr.seq (nd_read (stepDiscovery tagDefs tid))
            (dnmsKBody tagDefs tid xs'
              (fun steps => dnmsK tagDefs n
                (fmapAddBy defaultCompare tid steps acc) xs' k)
              (fun tids' => dnmsK tagDefs n acc tids' k))).denote σ
        = CerbND.runNDFuel F
            (nd_bind (nd_bind (nd_read (stepDiscovery tagDefs tid))
              (fun steps =>
                match find_can_advance steps with
                | none => drive_nonmemory_steps_aux2_lemFuel n tagDefs
                    (fmapAddBy defaultCompare tid steps acc) xs'
                | some step1 => nd_bind (advance_step tagDefs tid step1)
                    (fun w => drive_nonmemory_steps_aux2_lemFuel n tagDefs
                      acc (wakeupIns w tid xs'))))
              (fun m => (k m).denote)) σ
      rw [denote_seq, runNDFuel_bind_assoc' hF,
        runNDFuel_bind_active (app_nd_read _ σ) F,
        runNDFuel_bind_active (app_nd_read _ σ) F]
      -- the discovered steps are opaque data from here on
      generalize stepDiscovery tagDefs tid σ = steps₀
      -- dispatch on the round class
      rcases hfind : find_can_advance steps₀ with _ | step1
      · -- accumulate round: recursion at n, no further atoms
        simp only [dnmsKBody, hfind]
        exact ih (fmapAddBy defaultCompare tid steps₀ acc) xs' F hF σ
      · -- an advancing round. The residual (one-atom) shape is shared
        -- by every advance class except the reified sequential
        -- action request; prove it once.
        have hres : ∀ (s1 : core_step2),
            CerbND.runNDFuel F
              (KExpr.seq (advance_step tagDefs tid s1)
                (fun w => dnmsK tagDefs n acc (wakeupIns w tid xs') k)).denote σ
            = CerbND.runNDFuel F
                (nd_bind (nd_bind (advance_step tagDefs tid s1)
                  (fun w => drive_nonmemory_steps_aux2_lemFuel n tagDefs acc
                    (wakeupIns w tid xs')))
                  (fun m => (k m).denote)) σ := by
          intro s1
          rw [denote_seq, runNDFuel_bind_assoc' hF]
          exact runNDFuel_bind_congr' hF
            (fun w σ₁ F' hF' =>
              ih acc (wakeupIns w tid xs') F' (Nat.le_trans hF' hF) σ₁) σ
        -- the deep (reified) sequential action-request arm, proved
        -- against the Kit unfolds; shared tail: the NOWAKEUP return
        -- feeding the round's recursion.
        have htail : ∀ (u : Unit) (σ' : driver_state) (F' : Nat), F' ≤ F →
            CerbND.runNDFuel F' (dnmsK tagDefs n acc (tid :: xs') k).denote σ'
            = CerbND.runNDFuel F'
                (nd_bind ((fun (u : Unit) =>
                    match u with
                    | () => (nd_return NOWAKEUP : driverM advance_info)) u)
                  (fun w => nd_bind (drive_nonmemory_steps_aux2_lemFuel n
                    tagDefs acc (wakeupIns w tid xs'))
                    (fun m => (k m).denote))) σ' := by
          intro u σ' F' hF'
          rw [runNDFuel_bind_active (app_nd_return NOWAKEUP σ') F']
          exact ih acc (tid :: xs') F' (Nat.le_trans hF' hF) σ'
        cases step1 with
        | Step_action_request2 dbg loc tid' unseq m_request =>
          cases unseq with
          | true =>
            simp only [dnmsKBody, hfind]
            exact hres _
          | false =>
            simp only [dnmsKBody, hfind]
            rw [denote_seq, runNDFuel_bind_assoc' hF,
              advance_action_unfold, runNDFuel_bind_assoc' hF,
              runNDFuel_bind_assoc' hF]
            refine runNDFuel_bind_congr' hF (fun request σ₁ F' hF' => ?_) σ
            -- request drawn; the aid draw next
            rw [denote_seq, perform_unfold, runNDFuel_bind_assoc'
              (Nat.le_trans hF' hF)]
            refine runNDFuel_bind_congr' (Nat.le_trans hF' hF)
              (fun aid σ₂ F'' hF'' => ?_) σ₁
            -- the sequential dispatch per request class
            have hF''F : F'' ≤ F := by omega
            have hFB : F'' ≤ lemDefaultFuel := by omega
            cases request with
            | LoadRequest2 mo ty ptr mk =>
              simp only [arsK]
              rw [denote_seq, ars_load_unfold, runNDFuel_bind_assoc' hFB]
              refine runNDFuel_bind_congr' hFB
                (fun p σ₃ F₃ hF₃ => ?_) σ₂
              obtain ⟨fp, mval⟩ := p
              dsimp only
              have hF₃B : F₃ ≤ lemDefaultFuel := by omega
              rw [denote_seq, runNDFuel_bind_assoc' hF₃B]
              refine runNDFuel_bind_congr' hF₃B
                (fun pref σ₄ F₄ hF₄ => ?_) σ₃
              rw [denote_seq,
                runNDFuel_bind_active (app_nd_update _ σ₄) F₄,
                runNDFuel_bind_active (app_nd_update _ σ₄) F₄]
              exact htail () _ F₄ (by omega)
            | StoreRequest2 mo ty isL ptr mval mk =>
              simp only [arsK]
              rw [denote_seq, ars_store_unfold, runNDFuel_bind_assoc' hFB]
              refine runNDFuel_bind_congr' hFB
                (fun fp σ₃ F₃ hF₃ => ?_) σ₂
              have hF₃B : F₃ ≤ lemDefaultFuel := by omega
              rw [denote_seq, runNDFuel_bind_assoc' hF₃B]
              refine runNDFuel_bind_congr' hF₃B
                (fun pref σ₄ F₄ hF₄ => ?_) σ₃
              rw [denote_seq,
                runNDFuel_bind_active (app_nd_update _ σ₄) F₄,
                runNDFuel_bind_active (app_nd_update _ σ₄) F₄]
              exact htail () _ F₄ (by omega)
            | CreateRequest2 pref align ty addrOpt initOpt mk =>
              simp only [arsK]
              rw [denote_seq, ars_create_unfold, runNDFuel_bind_assoc' hFB]
              refine runNDFuel_bind_congr' hFB
                (fun ptrval σ₃ F₃ hF₃ => ?_) σ₂
              rw [denote_seq,
                runNDFuel_bind_active (app_nd_update _ σ₃) F₃,
                runNDFuel_bind_active (app_nd_update _ σ₃) F₃]
              exact htail () _ F₃ (by omega)
            | KillRequest2 isDyn ptr mk =>
              simp only [arsK]
              rw [denote_seq, ars_kill_unfold, runNDFuel_bind_assoc' hFB]
              refine runNDFuel_bind_congr' hFB
                (fun u σ₃ F₃ hF₃ => ?_) σ₂
              rw [denote_seq,
                runNDFuel_bind_active (app_nd_update _ σ₃) F₃,
                runNDFuel_bind_active (app_nd_update _ σ₃) F₃]
              exact htail () _ F₃ (by omega)
            | AllocRequest2 pref align sz mk =>
              simp only [arsK]
              rw [denote_seq]
              exact runNDFuel_bind_congr' hFB
                (fun u σ₃ F₃ hF₃ => htail u σ₃ F₃ (by omega)) σ₂
            | SeqRMWRequest2 ty ptr fM mk =>
              simp only [arsK]
              rw [denote_seq]
              exact runNDFuel_bind_congr' hFB
                (fun u σ₃ F₃ hF₃ => htail u σ₃ F₃ (by omega)) σ₂
        | Step_ccall2 a b => simp only [dnmsKBody, hfind]; exact hres _
        | Step_with_runstate2 a b =>
          simp only [dnmsKBody, hfind]; exact hres _
        | Step_tau2 a b c => simp only [dnmsKBody, hfind]; exact hres _
        | Step_blocked2 => simp only [dnmsKBody, hfind]; exact hres _
        | Step_error2 a => simp only [dnmsKBody, hfind]; exact hres _
        | Step_thread_done2 a b =>
          simp only [dnmsKBody, hfind]; exact hres _
        | Step_done2 a => simp only [dnmsKBody, hfind]; exact hres _
        | Step_memop_request2 a b c d e f =>
          simp only [dnmsKBody, hfind]; exact hres _
        | Step_spawn_threads2 a b =>
          simp only [dnmsKBody, hfind]; exact hres _
        | Step_fs2 a b c => simp only [dnmsKBody, hfind]; exact hres _
        | Step_nd2 a => simp only [dnmsKBody, hfind]; exact hres _

/-- Scheduling guard whose branches are both `nd_return` (the
    exhaustive branch's no-step debug guard): active either way. -/
theorem app_ite_return {A I E C S : Type} (c : Bool) (v : A) (σ : S) :
    app (if c then (nd_return v : ndM A I E C S) else nd_return v) σ
      = (NDactive v, σ) := by
  cases c <;> rfl

/-! ## The driver2 peel: reified iteration former -/

/-- The per-thread step pick of `new_drive_core_threads` (mirror; the
    generated lambda's debug stages vanish by Unit eta — the anchor in
    `driver2K_runner_eq` pins it). -/
def ndctPick : (Nat × List core_step2) → driverM (Nat × Option core_step2) :=
  fun p =>
    match p with
    | (tid1, steps) =>
        nd_bind (pick (SK_misc ["new_drive_core_threads"]) steps)
          (fun step1 => nd_return (tid1, some step1))

/-- The non-blocked filter of the exhaustive scheduling branch
    (mirror of the generated `List.filter` argument). -/
def nonBlockedFilter : (Nat × Option core_step2) → Bool :=
  fun p =>
    match p with
    | (_tid1, step_opt) =>
        not (Lem_Maybe.maybeEqualBy (fun x y => x == y) step_opt
          (some Step_blocked2))

/-- The generated driver2 iteration body AFTER `new_drive_core_threads`
    (clean mirror: debug matches erased by Unit eta, dead let zeta'd,
    `non_blocked` inlined; `rfl`-anchored in the peel walk). -/
def driver2Body (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (wc : Bool) (n : Nat) :
    List (Nat × Option core_step2) → driverM Unit :=
  fun tid_steps =>
    nd_bind nd_get (fun _post_core_dr_st =>
      if Lem_Maybe.maybeEqualBy (fun x y => x == y)
          (CerbGlobal.current_execution_mode ())
          (some CerbGlobal.ExecutionMode.random) then
        nd_bind (pick (SK_misc ["driver 2"]) tid_steps)
          (fun p =>
            match p with
            | (_tid1, step_opt) =>
              match step_opt with
              | some step1 =>
                  process_core_step2 tagDefs wc (driver2_lemFuel n tagDefs)
                    step1
              | none => nd_return ())
      else
        nd_bind
          (if List.length (List.filter nonBlockedFilter tid_steps) == 0
           then nd_return () else nd_return ())
          (fun _ =>
            nd_bind (pick (SK_misc ["driver non_blocked"])
                (List.filter nonBlockedFilter tid_steps))
              (fun x =>
                match x with
                | (_, none) => nd_return ()
                | (_, some step1) =>
                    process_core_step2 tagDefs wc
                      (driver2_lemFuel n tagDefs) step1)))

/-- Reified `process_core_step2` (the exec-relevant arms as joints:
    ccall dispatch, memop, program exit; the action-request arm at
    perform granularity; fs and the wrong-step arms as residual atoms
    carrying the REAL recursion `resid`). `rest` is the peeled next
    iteration, `k` the post-loop continuation. -/
@[reducible] def pcsK (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (wc : Bool) (resid : Bool → driverM Unit)
    (rest : KExpr driver_result step_kind driver_error mem_iv_constraint driver_state)
    (k : Unit → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state) :
    core_step2 → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state
  | Step_action_request2 _dbg loc1 tid1 _u m_request =>
      .seq (liftCore_run m_request)
        (fun (request : action_request2 thread_state) =>
        .seq (perform_action_request2 wc loc1 tid1 request)
          (fun _ => rest))
  | Step_memop_request2 loc1 memop1 cvals tid1 _u mk_th_st =>
      .seq (perform_memop_request2 tagDefs loc1 memop1 cvals tid1 mk_th_st)
        (fun _ => rest)
  | Step_done2 cval =>
      .seq (nd_update (fun (dr_st : driver_state) =>
        { dr_st with core_state0 := prepare_exit dr_st.core_state0 cval }))
        (fun _ => k ())
  | Step_ccall2 tid1 step_m =>
      .seq (liftCore_run step_m)
        (fun (th_st' : thread_state) =>
        .seq (nd_update (fun (dr_st : driver_state) =>
          { { dr_st with dr_step_counter := dr_st.dr_step_counter + 1 }
              with core_state0 :=
                update_thread_state tid1 th_st' dr_st.core_state0 }))
          (fun _ => rest))
  | step1 => .seq (process_core_step2 tagDefs wc resid step1) k

/-- THE PER-ITERATION LOOP FORMER: `driver2_lemFuel` with iteration
    boundaries as `seq` joints, the dnms segment spliced as `dnmsK`
    (per-Core-step granularity INSIDE each iteration), scheduling
    stages as joints, and `process_core_step2` reified via `pcsK`. -/
@[reducible] def driver2K (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (wc : Bool) :
    Nat → (Unit → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state) →
    KExpr driver_result step_kind driver_error mem_iv_constraint driver_state
  | 0, k => .seq (driver2_lemFuel 0 tagDefs wc) k
  | n + 1, k =>
      .seq nd_get (fun (dr_st : driver_state) =>
        dnmsK tagDefs lemDefaultFuel fmapEmpty
          (List.map Prod.fst dr_st.core_state0.thread_states)
          (fun m =>
            .seq (nd_mapM ndctPick (fmapElements m))
              (fun (tid_steps : List (Nat × Option core_step2)) =>
              .seq nd_get (fun (_post : driver_state) =>
                if Lem_Maybe.maybeEqualBy (fun x y => x == y)
                    (CerbGlobal.current_execution_mode ())
                    (some CerbGlobal.ExecutionMode.random) then
                  .seq (pick (SK_misc ["driver 2"]) tid_steps)
                    (fun (p : Nat × Option core_step2) =>
                      match p with
                      | (_, some step1) =>
                          pcsK tagDefs wc (driver2_lemFuel n tagDefs)
                            (driver2K tagDefs wc n k) k step1
                      | (_, none) => k ())
                else
                  .seq (pick (SK_misc ["driver non_blocked"])
                      (List.filter nonBlockedFilter tid_steps))
                    (fun (p : Nat × Option core_step2) =>
                      match p with
                      | (_, none) => k ()
                      | (_, some step1) =>
                          pcsK tagDefs wc (driver2_lemFuel n tagDefs)
                            (driver2K tagDefs wc n k) k step1)))))

/-! ## The driver2 simulation -/

/-- THE DRIVER2 PEEL (the S1 §5 "driver2 walk"): runner-equality of
    the peeled iteration former against the generated recursion, one
    walk of the iteration body, per-iteration induction; consumes the
    dnms peel for the inner loop segment. -/
theorem driver2K_runner_eq
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) (wc : Bool)
    (k : Unit → KExpr driver_result step_kind driver_error mem_iv_constraint driver_state) :
    ∀ (n F : Nat), F ≤ lemDefaultFuel → ∀ σ : driver_state,
      CerbND.runNDFuel F (driver2K tagDefs wc n k).denote σ
        = CerbND.runNDFuel F
            (nd_bind (driver2_lemFuel n tagDefs wc)
              (fun v => (k v).denote)) σ := by
  intro n
  induction n with
  | zero => intro F hF σ; rfl
  | succ n ih =>
    intro F hF σ
    -- THE ANCHORS: the generated iteration against the clean mirrors
    -- (Unit-eta erases the debug stages; drift in Driver.lean's
    -- driver2/new_drive_core_threads bodies breaks these `rfl`s).
    have h1 : driver2_lemFuel (n + 1) tagDefs wc
        = nd_bind (new_drive_core_threads tagDefs ())
            (driver2Body tagDefs wc n) := rfl
    have h2 : new_drive_core_threads tagDefs ()
        = nd_bind nd_get (fun (dr_st : driver_state) =>
            nd_bind (drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel
              tagDefs fmapEmpty
              (List.map Prod.fst dr_st.core_state0.thread_states))
              (fun m => nd_mapM ndctPick (fmapElements m))) := rfl
    -- shared tail: the process arm bound to the outer continuation;
    -- proved per exec-arm against the pcsK reification.
    have hpcs : ∀ (step1 : core_step2) (F' : Nat), F' ≤ F →
        ∀ σ' : driver_state,
        CerbND.runNDFuel F'
          (pcsK tagDefs wc (driver2_lemFuel n tagDefs)
            (driver2K tagDefs wc n k) k step1).denote σ'
        = CerbND.runNDFuel F'
            (nd_bind (process_core_step2 tagDefs wc
              (driver2_lemFuel n tagDefs) step1)
              (fun v => (k v).denote)) σ' := by
      intro step1 F' hF' σ'
      have hF'B : F' ≤ lemDefaultFuel := by omega
      cases step1 with
      | Step_action_request2 dbg loc1 tid1 u m_request =>
        simp only [pcsK, process_core_step2]
        rw [denote_seq, runNDFuel_bind_assoc' hF'B]
        refine runNDFuel_bind_congr' hF'B (fun request σ₁ F₁ h₁ => ?_) σ'
        have h₁B : F₁ ≤ lemDefaultFuel := by omega
        rw [denote_seq, runNDFuel_bind_assoc' h₁B]
        refine runNDFuel_bind_congr' h₁B (fun u₁ σ₂ F₂ h₂ => ?_) σ₁
        exact ih F₂ (by omega) σ₂
      | Step_memop_request2 loc1 memop1 cvals tid1 u mk_th_st =>
        simp only [pcsK, process_core_step2]
        rw [denote_seq, runNDFuel_bind_assoc' hF'B]
        refine runNDFuel_bind_congr' hF'B (fun u₁ σ₁ F₁ h₁ => ?_) σ'
        exact ih F₁ (by omega) σ₁
      | Step_done2 cval =>
        simp only [pcsK, process_core_step2]
        rw [denote_seq, runNDFuel_bind_assoc' hF'B,
          runNDFuel_bind_active (app_print_debug 3 [DB_driver] _ σ') F',
          runNDFuel_bind_active (app_nd_update _ σ') F']
      | Step_ccall2 tid1 step_m =>
        simp only [pcsK, process_core_step2]
        rw [denote_seq, runNDFuel_bind_assoc' hF'B]
        refine runNDFuel_bind_congr' hF'B (fun th' σ₁ F₁ h₁ => ?_) σ'
        have h₁B : F₁ ≤ lemDefaultFuel := by omega
        rw [denote_seq, runNDFuel_bind_assoc' h₁B,
          runNDFuel_bind_active (app_nd_update _ σ₁) F₁,
          runNDFuel_bind_active (app_nd_update _ σ₁) F₁]
        exact ih F₁ (by omega) _
      | Step_with_runstate2 a b => simp only [pcsK]; rw [denote_seq]
      | Step_tau2 a b c => simp only [pcsK]; rw [denote_seq]
      | Step_blocked2 => simp only [pcsK]; rw [denote_seq]
      | Step_error2 a => simp only [pcsK]; rw [denote_seq]
      | Step_thread_done2 a b => simp only [pcsK]; rw [denote_seq]
      | Step_spawn_threads2 a b => simp only [pcsK]; rw [denote_seq]
      | Step_fs2 a b c => simp only [pcsK]; rw [denote_seq]
      | Step_nd2 a => simp only [pcsK]; rw [denote_seq]
    -- the walk
    show CerbND.runNDFuel F
        (KExpr.seq nd_get (fun (dr_st : driver_state) =>
          dnmsK tagDefs lemDefaultFuel fmapEmpty
            (List.map Prod.fst dr_st.core_state0.thread_states)
            (fun m =>
              KExpr.seq (nd_mapM ndctPick (fmapElements m))
                (fun (tid_steps : List (Nat × Option core_step2)) =>
                KExpr.seq nd_get (fun (_post : driver_state) =>
                  if Lem_Maybe.maybeEqualBy (fun x y => x == y)
                      (CerbGlobal.current_execution_mode ())
                      (some CerbGlobal.ExecutionMode.random) then
                    KExpr.seq (pick (SK_misc ["driver 2"]) tid_steps)
                      (fun (p : Nat × Option core_step2) =>
                        match p with
                        | (_, some step1) =>
                            pcsK tagDefs wc (driver2_lemFuel n tagDefs)
                              (driver2K tagDefs wc n k) k step1
                        | (_, none) => k ())
                  else
                    KExpr.seq (pick (SK_misc ["driver non_blocked"])
                        (List.filter nonBlockedFilter tid_steps))
                      (fun (p : Nat × Option core_step2) =>
                        match p with
                        | (_, none) => k ()
                        | (_, some step1) =>
                            pcsK tagDefs wc (driver2_lemFuel n tagDefs)
                              (driver2K tagDefs wc n k) k step1)))))).denote σ
      = CerbND.runNDFuel F
          (nd_bind (driver2_lemFuel (n + 1) tagDefs wc)
            (fun v => (k v).denote)) σ
    rw [h1, h2, runNDFuel_bind_assoc' hF, runNDFuel_bind_assoc' hF,
      denote_seq,
      runNDFuel_bind_active (app_nd_get σ) F,
      runNDFuel_bind_active (app_nd_get σ) F]
    try dsimp only
    rw [runNDFuel_bind_assoc' hF]
    rw [dnmsK_runner_eq tagDefs _ lemDefaultFuel fmapEmpty
      (List.map Prod.fst σ.core_state0.thread_states) F hF σ]
    refine runNDFuel_bind_congr' hF (fun m σ₁ F₁ h₁ => ?_) σ
    have h₁B : F₁ ≤ lemDefaultFuel := by omega
    try dsimp only
    rw [denote_seq]
    refine runNDFuel_bind_congr' h₁B (fun tid_steps σ₂ F₂ h₂ => ?_) σ₁
    have h₂B : F₂ ≤ lemDefaultFuel := by omega
    simp only [driver2Body]
    try dsimp only
    rw [denote_seq, runNDFuel_bind_assoc' h₂B,
      runNDFuel_bind_active (app_nd_get σ₂) F₂,
      runNDFuel_bind_active (app_nd_get σ₂) F₂]
    try dsimp only
    cases hmode : Lem_Maybe.maybeEqualBy (fun x y => x == y)
        (CerbGlobal.current_execution_mode ())
        (some CerbGlobal.ExecutionMode.random) with
    | true =>
      simp only [reduceIte]
      rw [denote_seq, runNDFuel_bind_assoc' h₂B]
      refine runNDFuel_bind_congr' h₂B (fun p σ₃ F₃ h₃ => ?_) σ₂
      obtain ⟨t, so⟩ := p
      cases so with
      | none =>
        try dsimp only
        rw [runNDFuel_bind_active (app_nd_return () σ₃) F₃]
      | some step1 =>
        try dsimp only
        exact hpcs step1 F₃ (by omega) σ₃
    | false =>
      rw [if_neg Bool.false_ne_true, if_neg Bool.false_ne_true]
      rw [runNDFuel_bind_assoc' h₂B,
        runNDFuel_bind_active
          (app_ite_return
            (List.length (List.filter nonBlockedFilter tid_steps) == 0)
            () σ₂) F₂]
      try dsimp only
      rw [denote_seq, runNDFuel_bind_assoc' h₂B]
      refine runNDFuel_bind_congr' h₂B (fun p σ₃ F₃ h₃ => ?_) σ₂
      obtain ⟨t, so⟩ := p
      cases so with
      | none =>
        try dsimp only
        rw [runNDFuel_bind_active (app_nd_return () σ₃) F₃]
      | some step1 =>
        try dsimp only
        exact hpcs step1 F₃ (by omega) σ₃

/-! ## The peeled harness: `callK` with the loop stage peeled -/

/-- `callFinishK` (RelSem/PerStepCall.lean) with the ONE `driver2`
    atom replaced by the peeled `driver2K` at the production loop
    budget — every other stage byte-identical. -/
@[reducible] def callFinishK2
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (fsym : sym)
    (expr1 : generic_expr core_run_annotation Unit sym)
    (bound : List (sym × value)) :
    KExpr driver_result step_kind driver_error mem_iv_constraint driver_state :=
  .seq get_thread_states
    (fun (ths : List (Nat × (Option thread_id × thread_state))) =>
    match ths with
    | [(_, (_, th_st))] =>
        let env' : List (Fmap sym value) :=
          match th_st.env with
          | [] => [Lem_Map.fromList bound]
          | xs :: xs' =>
            (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
              fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
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
        driver2K tagDefs false lemDefaultFuel (fun (_ : Unit) =>
        .seq nd_get (fun (dr_st' : driver_state) =>
        .done (.value (finalize tagDefs "callND" dr_st'))))))
    | _ => .done (.killed (Other (DErr_other
        "callND: not exactly one thread after globals"))))

/-- THE PEELED HARNESS: `callK`'s stage spine with the loop peeled. -/
@[reducible] def callK2 (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) :
    KExpr driver_result step_kind driver_error mem_iv_constraint driver_state :=
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

/-- The peeled harness is runner-indistinguishable from the PRODUCTION
    harness `callND` within the production budget (the statement-freeze
    bridge: `callND` untouched; drift in Call.lean's spine breaks the
    spine descent build-fatally, as `callK_denote` does for `callK`). -/
theorem callK2_runner_eq
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) :
    ∀ (F : Nat), F ≤ lemDefaultFuel → ∀ σ : driver_state,
      CerbND.runNDFuel F (callK2 tagDefs file1 fname args).denote σ
        = CerbND.runNDFuel F (callND tagDefs file1 fname args) σ := by
  intro F hF σ
  simp only [callK2, callND, callFinishK2, callFinish, denote_seq]
  refine runNDFuel_bind_congr' hF (fun tid0 σ₁ F₁ h₁ => ?_) σ
  have h₁B : F₁ ≤ lemDefaultFuel := by omega
  try dsimp only
  refine runNDFuel_bind_congr' h₁B (fun pgst σ₂ F₂ h₂ => ?_) σ₁
  have h₂B : F₂ ≤ lemDefaultFuel := by omega
  try dsimp only
  refine runNDFuel_bind_congr' h₂B (fun fsym σ₃ F₃ h₃ => ?_) σ₂
  have h₃B : F₃ ≤ lemDefaultFuel := by omega
  try dsimp only
  refine runNDFuel_bind_congr' h₃B (fun pb σ₄ F₄ h₄ => ?_) σ₃
  have h₄B : F₄ ≤ lemDefaultFuel := by omega
  try dsimp only
  refine runNDFuel_bind_congr' h₄B (fun ptys σ₅ F₅ h₅ => ?_) σ₄
  have h₅B : F₅ ≤ lemDefaultFuel := by omega
  try dsimp only
  refine runNDFuel_bind_congr' h₅B (fun bound σ₆ F₆ h₆ => ?_) σ₅
  have h₆B : F₆ ≤ lemDefaultFuel := by omega
  -- the finish stage: same spine, loop stage peeled
  try dsimp only
  refine runNDFuel_bind_congr' h₆B (fun ths σ₇ F₇ h₇ => ?_) σ₆
  have h₇B : F₇ ≤ lemDefaultFuel := by omega
  rcases ths with _ | ⟨⟨t1, ot, th_st⟩, _ | ⟨hd, tl⟩⟩
  · rfl
  · try dsimp only
    refine runNDFuel_bind_congr' h₇B (fun errno σ₈ F₈ h₈ => ?_) σ₇
    have h₈B : F₈ ≤ lemDefaultFuel := by omega
    try dsimp only
    refine runNDFuel_bind_congr' h₈B (fun u σ₉ F₉ h₉ => ?_) σ₈
    exact (driver2K_runner_eq tagDefs false _ lemDefaultFuel F₉
      (by omega) σ₉).trans rfl
  · rfl

end Cerb
end RelSem
