/-
  RelSem.Kit.Round — arc-9 S2 (2026-08-20): L1 kit, the driver-round
  layer (design docs/2026-08-20_arc9-s1-design.md §1.2, [NEW,
  computed-RHS]).

  S2 REFINEMENT (recorded in the S2 record §2, P1): instead of one
  wrapper lemma per round CLASS around the whole dnms body, the
  generated `drive_nonmemory_steps_aux2_lemFuel` factors as

    dnms_round      -- generic glue: one fuel tick under hlook (thread
                    -- lookup) / hsteps (the step_ctx step-DISCOVERY
                    -- equation, rfl at concrete arenas) / hfind /
                    -- hadv (the advance app equation)
    dnms_terminal   -- the no-can-advance exit (accumulator returned)
    advance_*       -- per-class computed-RHS advance laws (dnmsBump =
                    -- counter bump + update_thread_state)

  so the walker's per-round work reduces to the step-discovery
  computation (defeq at concrete arenas, payload-opaque) plus the
  registered advance law; the round classes of the design (§1.2
  round_pure_eval / round_tau_* / round_load / ...) are REALIZED as
  (step_ctx-discovery by rfl) × (advance class below), not as separate
  dnms wrappers.

  The `hfuel` hypothesis pattern: the conclusion's fuel position is a
  BARE variable (a DiscrTree wildcard) so the law fires at literal and
  symbolic fuels alike; `hfuel` discharges by rfl (Nat offset
  unification: `999999 =?= ?f+1`, `fuel+30 =?= ?f+1`).

  Import discipline (design §6): no Iris, no fixtures.

  House rules: no sorry, no axioms declared here. Pins in Kit/Audit.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.Call
import RelSem.Kit.Eval
import RelSem.Tactics.AppEqAttr

set_option autoImplicit false

namespace RelSem.Kit

open RelSem RelSem.Cerb

/-! ## The dnms round glue -/

/-- The advancing dnms round, fully generic (P1-probed): one fuel
    tick; the step discovery, find, and advance enter as hypotheses;
    NOWAKEUP scheduling (the single-threaded shape — every slate run). -/
@[app_eq]
theorem dnms_round
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {fuelS fuel : Nat} {acc : Fmap thread_id (List core_step2)}
    {tid : Nat} {xs' : List Nat}
    {σ σ' : driver_state} {th_info : Option thread_id × thread_state}
    {steps : List core_step2} {step1 : core_step2}
    (hfuel : fuelS = fuel + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps = some step1)
    (hadv : app (advance_step tagDefs tid step1) σ
        = (NDactive NOWAKEUP, σ')) :
    app (drive_nonmemory_steps_aux2_lemFuel fuelS tagDefs acc
          (tid :: xs')) σ
      = app (drive_nonmemory_steps_aux2_lemFuel fuel tagDefs acc
          (tid :: xs')) σ' := by
  subst hfuel
  rw [drive_nonmemory_steps_aux2_lemFuel]
  refine (app_bind_active (app_nd_read _ σ)).trans ?_
  simp only [hlook, hsteps, hfind]
  refine (app_bind_active hadv).trans ?_
  rfl

/-- The terminal dnms round: no advancing step; the offered steps are
    accumulated and (at the singleton tid list) the accumulator is
    returned one tick later. -/
@[app_eq]
theorem dnms_terminal
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {fuelS fuel : Nat} {acc : Fmap thread_id (List core_step2)}
    {tid : Nat}
    {σ : driver_state} {th_info : Option thread_id × thread_state}
    {steps : List core_step2}
    (hfuel : fuelS = fuel + 2)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps = none) :
    app (drive_nonmemory_steps_aux2_lemFuel fuelS tagDefs acc [tid]) σ
      = (NDactive (fmapAddBy defaultCompare tid steps acc), σ) := by
  subst hfuel
  rw [drive_nonmemory_steps_aux2_lemFuel]
  refine (app_bind_active (app_nd_read _ σ)).trans ?_
  simp only [hlook, hsteps, hfind]
  rw [drive_nonmemory_steps_aux2_lemFuel]
  exact app_nd_return _ σ

/-! ## The advance classes (computed RHS) -/

/-- The post-state of a thread-replacing advance: counter bumped, the
    thread rebuilt — THE computing function of the tau/runstate round
    classes (spelled exactly as the generated record update). -/
def dnmsBump (tid : Nat) (th' : thread_state) (σ : driver_state) :
    driver_state :=
  { { σ with dr_step_counter := σ.dr_step_counter + 1 }
      with core_state0 := update_thread_state tid th' σ.core_state0 }

/-- Tau advance (TSK_Misc): the new thread state rides INSIDE the
    step; the post-state is computed. Covers the design's
    round_tau_wseq / round_tau_sseq / round_tau_strip classes (their
    distinction lives in the step-DISCOVERY equation, not here). -/
@[app_eq]
theorem advance_tau_misc
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {dbg : String} {th' : thread_state}
    {σ : driver_state} :
    app (advance_step tagDefs tid (Step_tau2 dbg TSK_Misc th')) σ
      = (NDactive NOWAKEUP, dnmsBump tid th' σ) := by
  refine (app_bind_active (app_nd_return () σ)).trans ?_
  refine (app_bind_active (app_nd_update _ σ)).trans ?_
  exact app_nd_return _ _

/-- Runstate advance (RSK_eval): the monadic step evaluates in the
    core-run state monad (Defined verdict as hypothesis — where the
    Kit/Eval crossings and the fixture eval ladders enter), then the
    computed thread replacement. Covers the design's round_pure_eval /
    round_run_jump classes. -/
@[app_eq]
theorem advance_runstate_eval
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {dbg : String}
    {step_m : core_runM thread_state}
    {σ : driver_state} {th' : thread_state} {rs' : core_run_state}
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    app (advance_step tagDefs tid
          (Step_with_runstate2 (RSK_eval dbg) step_m)) σ
      = (NDactive NOWAKEUP,
         dnmsBump tid th' { σ with core_run_state0 := rs' }) := by
  refine (app_bind_active (app_nd_return () σ)).trans ?_
  refine (app_bind_active (liftCore_run_defined hm)).trans ?_
  refine (app_bind_active (app_nd_update _ _)).trans ?_
  exact app_nd_return _ _

/-- Runstate advance, tau flavor (RSK_tau with a non-Return kind):
    same shape as the eval flavor (the Erun/Esave negative-action
    variants land here). -/
@[app_eq]
theorem advance_runstate_tau_misc
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid : Nat} {dbg : String}
    {step_m : core_runM thread_state}
    {σ : driver_state} {th' : thread_state} {rs' : core_run_state}
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    app (advance_step tagDefs tid
          (Step_with_runstate2 (RSK_tau dbg TSK_Misc) step_m)) σ
      = (NDactive NOWAKEUP,
         dnmsBump tid th' { σ with core_run_state0 := rs' }) := by
  refine (app_bind_active (app_nd_return () σ)).trans ?_
  refine (app_bind_active (liftCore_run_defined hm)).trans ?_
  refine (app_bind_active (app_nd_update _ _)).trans ?_
  exact app_nd_return _ _

/-- advance_step's sequential action-request branch, unfolded (the
    explicit-equation form: carrying this defeq through implicit
    unification instead sends the KERNEL into deep recursion —
    S2 finding, recorded; `rw` with the pinned equation keeps the
    check linear). -/
theorem advance_action_unfold
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid tid' : Nat} {dbg : String} {loc : CerbLocation.Loc}
    {m_request : core_runM (action_request2 thread_state)} :
    advance_step tagDefs tid
        (Step_action_request2 dbg loc tid' false m_request)
      = nd_bind (nd_bind (liftCore_run m_request)
          (fun request => perform_action_request2 false loc tid' request))
          (fun (u : Unit) => match u with | () => nd_return NOWAKEUP) := rfl

/-- Action-request advance (sequential, not unseq-with-ccall): the
    request is drawn out of the runstate monad, then performed
    (`perform_action_request2` — the per-request Kit/Mem blocks enter
    through the `hperf` hypothesis). Covers the design's round_load /
    round_store / round_create / round_kill classes. -/
@[app_eq]
theorem advance_action_request
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid tid' : Nat} {dbg : String} {loc : CerbLocation.Loc}
    {m_request : core_runM (action_request2 thread_state)}
    {σ σ₁ σ₂ : driver_state} {request : action_request2 thread_state}
    (hreq : app (liftCore_run m_request) σ = (NDactive request, σ₁))
    (hperf : app (perform_action_request2 false loc tid' request) σ₁
        = (NDactive (), σ₂)) :
    app (advance_step tagDefs tid
          (Step_action_request2 dbg loc tid' false m_request)) σ
      = (NDactive NOWAKEUP, σ₂) := by
  rw [advance_action_unfold]
  refine (app_bind_active ((app_bind_active hreq).trans hperf)).trans ?_
  exact app_nd_return _ _

/-! ## perform/action unfolds (MOVED from T1AppEq — generic) -/

/-- perform_action_request2's sequential unfolding (generic; the
    opaque execution-mode read zeta-drops). -/
theorem perform_unfold (loc : CerbLocation.Loc) (tid : Nat)
    (req : action_request2 thread_state) :
    perform_action_request2 false loc tid req
      = nd_bind (liftCore_run (runS fresh_action_id'))
          (fun aid1 => action_request_sequential2 loc tid aid1 req) := rfl

/-- action_request_sequential2's LoadRequest2 arm (generic; the debug
    print is a Unit match, dropped by eta). -/
theorem ars_load_unfold (loc : CerbLocation.Loc) (tid aid : Nat)
    (mo : memory_order) (ty : ctype) (ptr : CerbMem.PointerValue)
    (mk : Nat → CerbMem.Footprint → CerbMem.MemValue → thread_state) :
    action_request_sequential2 loc tid aid (LoadRequest2 mo ty ptr mk)
      = nd_bind (liftMem (CerbMem.loadM loc ty ptr))
          (fun (p : CerbMem.Footprint × CerbMem.MemValue) =>
            match p with
            | (fp, mval) => nd_bind (liftMem (CerbMem.prefixOfPointer ptr))
                (fun (pref : Option String) =>
                  nd_update (fun (dr_st : driver_state) =>
                    { dr_st with
                      trace := ME_load loc pref ty ptr mval :: dr_st.trace,
                      core_state0 := update_thread_state tid (mk aid fp mval)
                        dr_st.core_state0 }))) := rfl

/-! ### Further action unfolds (MOVED from T3AppEq — generic; the
    T5 create/store/kill rounds consume these) -/

theorem ars_create_unfold (loc : CerbLocation.Loc) (tid aid : Nat)
    (pref : prefix0) (align : CerbMem.IntegerValue) (ty : ctype)
    (addrOpt : Option Int) (initOpt : Option CerbMem.MemValue)
    (mk : Nat → CerbMem.PointerValue → thread_state) :
    action_request_sequential2 loc tid aid
      (CreateRequest2 pref align ty addrOpt initOpt mk)
      = nd_bind (liftMem (CerbMem.allocateObject tid pref align ty
          addrOpt initOpt))
        (fun (ptrval : CerbMem.PointerValue) =>
          nd_update (fun (dr_st : driver_state) =>
            { dr_st with
              trace := ME_allocate_object tid pref align ty initOpt ptrval
                :: dr_st.trace,
              core_state0 := update_thread_state tid (mk aid ptrval)
                dr_st.core_state0 })) := rfl

theorem ars_store_unfold (loc : CerbLocation.Loc) (tid aid : Nat)
    (mo : memory_order) (ty : ctype) (isLocking : Bool)
    (ptr : CerbMem.PointerValue) (mval : CerbMem.MemValue)
    (mk : Nat → CerbMem.Footprint → thread_state) :
    action_request_sequential2 loc tid aid
      (StoreRequest2 mo ty isLocking ptr mval mk)
      = nd_bind (liftMem (CerbMem.storeM loc ty isLocking ptr mval))
        (fun (fp : CerbMem.Footprint) => nd_bind
          (liftMem (CerbMem.prefixOfPointer ptr))
          (fun (pref : Option String) =>
            nd_update (fun (dr_st : driver_state) =>
              { dr_st with
                trace := ME_store loc pref ty isLocking ptr mval
                  :: dr_st.trace,
                core_state0 := update_thread_state tid (mk aid fp)
                  dr_st.core_state0 }))) := rfl

theorem ars_kill_unfold (loc : CerbLocation.Loc) (tid aid : Nat)
    (isDyn : Bool) (ptr : CerbMem.PointerValue)
    (mk : Nat → thread_state) :
    action_request_sequential2 loc tid aid (KillRequest2 isDyn ptr mk)
      = nd_bind (liftMem (CerbMem.killM loc isDyn ptr))
        (fun (_ : Unit) =>
          nd_update (fun (dr_st : driver_state) =>
            { dr_st with
              trace := ME_kill loc isDyn ptr :: dr_st.trace,
              core_state0 := update_thread_state tid (mk aid)
                dr_st.core_state0 })) := rfl

end RelSem.Kit
