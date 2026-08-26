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
import RelSem.Kit.Mem
import RelSem.Tactics.AppEqAttr
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem.Kit

open RelSem RelSem.Cerb

/-! ## The dnms round glue -/

/-- The advancing dnms round, fully generic (P1-probed): one fuel
    tick; the step discovery, find, and advance enter as hypotheses;
    NOWAKEUP scheduling (the single-threaded shape — every slate run). -/
@[app_eq 1000,
  step_law (kind := roundGlue) (variant := generic) (side := fed)
  (frontier := "round/glue")
  (trace := "{law := dnms_round, joint := dnms-round, hyps := [hfuel : rfl, hlook : rfl, hsteps : rfl, hfind : rfl, hadv : fed]}")
  (lineage := "fuel-relative round glue: one tick of the generated dnms loop, hypotheses = the discovery/advance equations (arc-9 S2)")]
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

/-- `dnms_round` with σ-COMPUTABLE hypotheses (arc-17 S3, the
    relative-chain emitter's face): every premise is spelled purely
    from `σ` (plus the round's advance theorem), so the emitter can
    kernel-defer them as `Eq.refl` hints — no elaborator unification
    against the scheduler computation (the stepAt wedge) is ever
    attempted. `step1` is instantiated at the round theorem's own
    (stepAt-spelled) step. -/
@[step_law (kind := roundGlue) (variant := computed) (side := fed)
  (frontier := "round/glue-computed")
  (trace := "{law := dnms_round_computed, joint := dnms-round, hyps := [hfuel : rfl, hlook : rfl, hfind : rfl, hadv : fed]}")
  (lineage := "dnms_round with sigma-computable premises (kernel-deferrable Eq.refl hints; the chain emitter face, arc-17 S3 salvage)")]
theorem dnms_round_computed
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {fuelS fuel : Nat} {acc : Fmap thread_id (List core_step2)}
    {tid : Nat} {xs' : List Nat}
    {σ σ' : driver_state} {step1 : core_step2}
    (hfuel : fuelS = fuel + 1)
    (hlook : (Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states).isSome = true)
    (hfind : find_can_advance (step_ctx tagDefs σ.layout_state
        σ.core_file σ.core_extern tid
        ((Lem_List.lookupBy (fun x y => x == y) tid
          σ.core_state0.thread_states).getD default))
      = some step1)
    (hadv : app (advance_step tagDefs tid step1) σ
        = (NDactive NOWAKEUP, σ')) :
    app (drive_nonmemory_steps_aux2_lemFuel fuelS tagDefs acc
          (tid :: xs')) σ
      = app (drive_nonmemory_steps_aux2_lemFuel fuel tagDefs acc
          (tid :: xs')) σ' := by
  obtain ⟨ti, hti⟩ := Option.isSome_iff_exists.mp hlook
  refine dnms_round hfuel hti rfl ?_ hadv
  rw [hti, Option.getD_some] at hfind
  exact hfind

/-- The terminal dnms round: no advancing step; the offered steps are
    accumulated and (at the singleton tid list) the accumulator is
    returned one tick later. -/
@[app_eq,
  step_law (kind := roundGlue) (variant := terminal) (side := rfl)
  (frontier := "round/terminal")
  (trace := "{law := dnms_terminal, joint := dnms-terminal, hyps := [hfuel : rfl, hlook : rfl, hsteps : rfl, hfind : rfl]}")
  (lineage := "the no-can-advance dnms exit: accumulator returned one tick later (arc-9 S2)")]
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
@[app_eq,
  step_law (kind := advance) (side := rfl)
  (frontier := "advance/tau")
  (trace := "{law := advance_tau_misc, joint := round/tau, hyps := []}")
  (lineage := "per-class computed-RHS advance law over the generated advance_step arm (decompilation-into-logic)")]
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
@[app_eq,
  step_law (kind := advance) (side := hyp)
  (frontier := "advance/runstate-eval")
  (trace := "{law := advance_runstate_eval, joint := round/runstate, hyps := [hm : rfl|hyp_norm_side]}")
  (lineage := "per-class computed-RHS advance law; the Defined-verdict premise is where eval ladders enter")]
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
@[app_eq,
  step_law (kind := advance) (side := hyp)
  (frontier := "advance/runstate-tau")
  (trace := "{law := advance_runstate_tau_misc, joint := round/runstate, hyps := [hm : rfl|hyp_norm_side]}")
  (lineage := "per-class computed-RHS advance law, RSK_tau flavor of the eval shape")]
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
@[app_eq,
  step_law (kind := advance) (side := fed)
  (frontier := "advance/action-request")
  (trace := "{law := advance_action_request, joint := round/action, hyps := [hreq : rfl|hyp_norm_side, hperf : fed]}")
  (lineage := "the sequential action-request advance: draw then perform; the per-request Kit/Mem blocks enter via hperf")]
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


/-! ## The perform layer (composed request laws — computed RHS).
    With these registered, an action-request round is fully mechanical
    whenever its Kit/Mem block's side facts discharge mechanically. -/

/-- `liftMem`, unfolded (explicit-equation form — the same kernel
    deep-recursion consideration as `advance_action_unfold`). -/
theorem liftMem_unfold {a : Type}
    (m : ndM a String mem_error (mem_constraint CerbMem.IntegerValue)
        CerbMem.MemState) :
    (liftMem m : ndM a step_kind driver_error
        (mem_constraint CerbMem.IntegerValue) driver_state)
      = liftND (fun (dr_st : driver_state) => dr_st.layout_state)
          (fun (dr_st : driver_state) (mem_st : CerbMem.MemState) =>
            { dr_st with layout_state := mem_st })
          (fun (err_str : String) => SK_misc ["memory", err_str])
          (fun (mem_err : mem_error) => DErr_memory mem_err) m := rfl

/-- The memory-lens crossing at an active head (the `liftMem` form of
    `app_liftND_active`). -/
@[app_eq]
theorem app_liftMem_active {a : Type}
    {m : ndM a String mem_error (mem_constraint CerbMem.IntegerValue)
        CerbMem.MemState}
    {σ : driver_state} {v : a} {mem0 mem' : CerbMem.MemState}
    (hσ : σ.layout_state = mem0)
    (h : app m mem0 = (NDactive v, mem')) :
    app (liftMem m) σ = (NDactive v, { σ with layout_state := mem' }) := by
  rw [liftMem_unfold]
  exact app_liftND_active _ _ _ _ (hσ ▸ h)

/-- The action-id draw (perform_action_request2's first stage),
    computed generically. -/
theorem aid_draw {σ : driver_state} :
    app (liftCore_run (runS fresh_action_id')) σ
      = (NDactive σ.core_run_state0.aid_supply,
         { σ with core_run_state0 :=
             { σ.core_run_state0 with
               aid_supply := σ.core_run_state0.aid_supply + 1 } }) :=
  liftCore_run_defined rfl

/-- advance_step's sequential memop-request branch, unfolded (the
    explicit-equation form — the advance_action_unfold discipline). -/
theorem advance_memop_unfold
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid tid' : Nat} {loc : CerbLocation.Loc}
    {memop : generic_memop sym} {cvals : List value}
    {mk_th_st : value → thread_state} :
    advance_step tagDefs tid
        (Step_memop_request2 loc memop cvals tid' false mk_th_st)
      = nd_bind (perform_memop_request2 tagDefs loc memop cvals tid'
          mk_th_st)
          (fun (u : Unit) => match u with | () => nd_return NOWAKEUP) := rfl

/-- Memop-request advance (sequential, not unseq-with-ccall; arc-18
    C4 — the Ememop surface's driver layer, first demanded by the
    divmod drive walk): the memop is performed
    (`perform_memop_request2` — the per-memop laws enter through the
    `hperf` hypothesis), then NOWAKEUP. -/
@[app_eq,
  step_law (kind := advance) (side := fed)
  (frontier := "advance/memop-request")
  (trace := "{law := advance_memop_request, joint := round/memop, hyps := [hperf : fed]}")
  (lineage := "the sequential memop-request advance: perform then NOWAKEUP; the per-memop laws enter via hperf")]
theorem advance_memop_request
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {tid tid' : Nat} {loc : CerbLocation.Loc}
    {memop : generic_memop sym} {cvals : List value}
    {mk_th_st : value → thread_state}
    {σ σ₁ : driver_state}
    (hperf : app (perform_memop_request2 tagDefs loc memop cvals tid'
        mk_th_st) σ = (NDactive (), σ₁)) :
    app (advance_step tagDefs tid
          (Step_memop_request2 loc memop cvals tid' false mk_th_st)) σ
      = (NDactive NOWAKEUP, σ₁) := by
  rw [advance_memop_unfold]
  refine (app_bind_active hperf).trans ?_
  exact app_nd_return _ _

/-- perform_memop_request2's PtrValidForDeref arm, unfolded (generic;
    explicit-equation form). -/
theorem perform_memop_pvfd_unfold
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {ty : ctype} {ptr : CerbMem.PointerValue}
    {tid : Nat} {mk_th_st : value → thread_state} :
    perform_memop_request2 tagDefs loc PtrValidForDeref
        [Vctype ty, Vobject (OVpointer ptr)] tid mk_th_st
      = nd_bind (nd_bind
          (liftMem (CerbMem.validForDerefPtrval ty ptr))
          (fun (is_valid : Bool) =>
            nd_return (mk_th_st (if is_valid then Vtrue else Vfalse))))
          (fun (th_st' : thread_state) =>
            nd_update (fun (dr_st : driver_state) =>
              update_core_state
                (update_thread_state tid th_st' dr_st.core_state0)
                dr_st)) := rfl

/-- PtrValidForDeref round's perform (arc-18 C4 — the Ememop class's
    first law; the pointer-validity read is STATE-PRESERVING, so the
    memory fact discharges by kernel rfl at ground memory: liveness +
    alignment arithmetic). -/
@[app_eq,
  step_law (kind := perform) (side := fed)
  (frontier := "perform/memop-pvfd")
  (trace := "{law := perform_memop_pvfd, joint := perform/memop, hyps := [hmem : fed]}")
  (lineage := "composed memop law: state-preserving validity read through the memory lens + thread update (computed RHS)")]
theorem perform_memop_pvfd
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {ty : ctype} {ptr : CerbMem.PointerValue}
    {tid : Nat} {mk_th_st : value → thread_state}
    {σ : driver_state} {b : Bool}
    (hmem : app (CerbMem.validForDerefPtrval ty ptr) σ.layout_state
        = (NDactive b, σ.layout_state)) :
    app (perform_memop_request2 tagDefs loc PtrValidForDeref
          [Vctype ty, Vobject (OVpointer ptr)] tid mk_th_st) σ
      = (NDactive (),
         update_core_state
           (update_thread_state tid
             (mk_th_st (if b then Vtrue else Vfalse)) σ.core_state0)
           σ) := by
  rw [perform_memop_pvfd_unfold]
  have h1 : app (nd_bind
      (liftMem (CerbMem.validForDerefPtrval ty ptr))
      (fun (is_valid : Bool) =>
        nd_return (mk_th_st (if is_valid then Vtrue else Vfalse)))) σ
      = (NDactive (mk_th_st (if b then Vtrue else Vfalse)), σ) := by
    refine (app_bind_active (app_liftMem_active rfl hmem)).trans ?_
    exact app_nd_return _ _
  refine (app_bind_active h1).trans ?_
  exact app_nd_update _ _

/-- CREATE round's perform (aid draw + allocate through the memory
    lens + trace/thread update). -/
@[app_eq,
  step_law (kind := perform) (side := fed)
  (frontier := "perform/create")
  (trace := "{law := perform_create, joint := perform/create, hyps := [hmem : fed]}")
  (lineage := "composed request law: aid draw + allocate through the memory lens + trace/thread update (computed RHS)")]
theorem perform_create
    {loc : CerbLocation.Loc} {tid : Nat}
    {pref : prefix0} {align : CerbMem.IntegerValue} {ty : ctype}
    {addrOpt : Option Int}
    {mk : Nat → CerbMem.PointerValue → thread_state}
    {σ : driver_state} {ptr : CerbMem.PointerValue}
    {mem' : CerbMem.MemState}
    (hmem : app (CerbMem.allocateObject tid pref align ty addrOpt none)
        σ.layout_state = (NDactive ptr, mem')) :
    app (perform_action_request2 false loc tid
          (CreateRequest2 pref align ty addrOpt none mk)) σ
      = (NDactive (),
         (fun σm => { σm with
            trace := ME_allocate_object tid pref align ty none ptr
              :: σm.trace,
            core_state0 := update_thread_state tid
              (mk σ.core_run_state0.aid_supply ptr) σm.core_state0 })
         { σ with
           core_run_state0 :=
             { σ.core_run_state0 with
               aid_supply := σ.core_run_state0.aid_supply + 1 },
           layout_state := mem' }) := by
  rw [perform_unfold]
  refine (app_bind_active aid_draw).trans ?_
  rw [ars_create_unfold]
  refine (app_bind_active (app_liftMem_active ?_ hmem)).trans ?_
  case _ => rfl
  exact app_nd_update _ _

/-- LOAD round's perform. -/
@[app_eq,
  step_law (kind := perform) (side := fed)
  (frontier := "perform/load")
  (trace := "{law := perform_load, joint := perform/load, hyps := [hmem : fed, hpref : fed]}")
  (lineage := "composed request law: aid draw + load through the memory lens + trace/thread update (computed RHS)")]
theorem perform_load
    {loc : CerbLocation.Loc} {tid : Nat}
    {mo : memory_order} {ty : ctype} {ptr : CerbMem.PointerValue}
    {mk : Nat → CerbMem.Footprint → CerbMem.MemValue → thread_state}
    {σ : driver_state} {fp : CerbMem.Footprint} {mval : CerbMem.MemValue}
    {mem' : CerbMem.MemState} {prefv : Option String}
    (hmem : app (CerbMem.loadM loc ty ptr) σ.layout_state
        = (NDactive (fp, mval), mem'))
    (hpref : app (CerbMem.prefixOfPointer ptr) mem'
        = (NDactive prefv, mem')) :
    app (perform_action_request2 false loc tid
          (LoadRequest2 mo ty ptr mk)) σ
      = (NDactive (),
         (fun σm => { σm with
            trace := ME_load loc prefv ty ptr mval :: σm.trace,
            core_state0 := update_thread_state tid
              (mk σ.core_run_state0.aid_supply fp mval) σm.core_state0 })
         { σ with
           core_run_state0 :=
             { σ.core_run_state0 with
               aid_supply := σ.core_run_state0.aid_supply + 1 },
           layout_state := mem' }) := by
  rw [perform_unfold]
  refine (app_bind_active aid_draw).trans ?_
  rw [ars_load_unfold]
  refine (app_bind_active (app_liftMem_active ?_ hmem)).trans ?_
  case _ => rfl
  refine (app_bind_active (app_liftMem_active ?_ hpref)).trans ?_
  case _ => rfl
  exact app_nd_update _ _

/-- STORE round's perform. -/
@[app_eq,
  step_law (kind := perform) (side := fed)
  (frontier := "perform/store")
  (trace := "{law := perform_store, joint := perform/store, hyps := [hmem : fed, hpref : fed]}")
  (lineage := "composed request law: aid draw + store through the memory lens + trace/thread update (computed RHS)")]
theorem perform_store
    {loc : CerbLocation.Loc} {tid : Nat}
    {mo : memory_order} {ty : ctype} {isLocking : Bool}
    {ptr : CerbMem.PointerValue} {mval : CerbMem.MemValue}
    {mk : Nat → CerbMem.Footprint → thread_state}
    {σ : driver_state} {fp : CerbMem.Footprint}
    {mem' : CerbMem.MemState} {prefv : Option String}
    (hmem : app (CerbMem.storeM loc ty isLocking ptr mval) σ.layout_state
        = (NDactive fp, mem'))
    (hpref : app (CerbMem.prefixOfPointer ptr) mem'
        = (NDactive prefv, mem')) :
    app (perform_action_request2 false loc tid
          (StoreRequest2 mo ty isLocking ptr mval mk)) σ
      = (NDactive (),
         (fun σm => { σm with
            trace := ME_store loc prefv ty isLocking ptr mval :: σm.trace,
            core_state0 := update_thread_state tid
              (mk σ.core_run_state0.aid_supply fp) σm.core_state0 })
         { σ with
           core_run_state0 :=
             { σ.core_run_state0 with
               aid_supply := σ.core_run_state0.aid_supply + 1 },
           layout_state := mem' }) := by
  rw [perform_unfold]
  refine (app_bind_active aid_draw).trans ?_
  rw [ars_store_unfold]
  refine (app_bind_active (app_liftMem_active ?_ hmem)).trans ?_
  case _ => rfl
  refine (app_bind_active (app_liftMem_active ?_ hpref)).trans ?_
  case _ => rfl
  exact app_nd_update _ _

/-! ### The NEG-transform run-state draw laws (arc-9 S3, design
    §11.2 — the census R59 round class's two supply stages; the
    digest read stays STUCK per the T4 stuck-form discipline
    (T4AppEq.lean:745-830) and is rewritten at the fixture by
    `hdig : CerberusFresh.digest () = ""`). -/

/-- `fresh_excluded_id`: draws the exclusion counter. -/
theorem eid_draw_eval {a : Type} (rs : core_run_state) :
    (E.fresh_excluded_id (a := a)) rs
      = Result (Defined rs.excluded_supply,
          { rs with excluded_supply := rs.excluded_supply + 1 }) := rfl

/-- `fresh_symbol0`: draws the sym supply; the produced symbol is the
    STUCK-digest form `Symbol (digest ()) rs.sym_supply SD_None`. -/
theorem sym_draw_eval {a : Type} (rs : core_run_state) :
    (E.fresh_symbol0 (a := a)) rs
      = Result (Defined (Symbol (CerberusFresh.digest ())
            rs.sym_supply SD_None),
          { rs with sym_supply := rs.sym_supply + 1 }) := rfl

/-- action_request_sequential2's SeqRMWRequest2 arm (arc-17 S2 — the
    S1-registered census gap: `seq_rmw`, 122 occurrences / 34 files;
    generic unfold, explicit-equation form). -/
theorem ars_seqrmw_unfold (loc : CerbLocation.Loc) (tid aid : Nat)
    (ty : ctype) (ptr : CerbMem.PointerValue)
    (mkv : CerbMem.MemValue → core_runM CerbMem.MemValue)
    (mk : Nat → CerbMem.Footprint → CerbMem.MemValue →
      CerbMem.MemValue → thread_state) :
    action_request_sequential2 loc tid aid (SeqRMWRequest2 ty ptr mkv mk)
      = nd_bind (liftMem (CerbMem.loadM loc ty ptr))
          (fun (p : CerbMem.Footprint × CerbMem.MemValue) =>
            match p with
            | (_, mval) => nd_bind (liftCore_run (mkv mval))
                (fun (mval' : CerbMem.MemValue) =>
                  nd_bind (liftMem (CerbMem.storeM loc ty false ptr mval'))
                    (fun (fp : CerbMem.Footprint) =>
                      nd_bind (liftMem (CerbMem.prefixOfPointer ptr))
                        (fun (pref : Option String) =>
                          nd_update (fun (dr_st : driver_state) =>
                            { dr_st with
                              trace := ME_seq_rmw loc pref ty ptr mval mval'
                                :: dr_st.trace,
                              core_state0 := update_thread_state tid
                                (mk aid fp mval mval')
                                dr_st.core_state0 }))))) := rfl

/-- SEQ-RMW round's perform (arc-17 S2; CONSTRUCT LAW for the
    supply-reading `seq_rmw` shape — the S1-registered gap, blocked
    until the env algebra existed because the RMW COMPUTE stage
    (`hrmw`, a runstate step) is where the NEG/exclusion transform's
    fresh-symbol draws live; its output hypotheses are exactly what
    the Kit/Env lookup lemmas discharge at open seed. Load, RMW
    compute, store, trace/thread update; the `hmid`/`hout` recasts
    follow the S1 output-recast discipline (callers pass NAMED states
    + rfl). -/
@[app_eq,
  step_law (kind := perform) (side := fed)
  (frontier := "perform/seqrmw")
  (trace := "{law := perform_seqrmw, joint := perform/seqrmw, hyps := [hmem : fed, hrmw : fed, hmem2 : fed]}")
  (lineage := "composed request law: the read-modify-write request (the arc-17 S2 T4 lane)")]
theorem perform_seqrmw
    {loc : CerbLocation.Loc} {tid : Nat}
    {ty : ctype} {ptr : CerbMem.PointerValue}
    {mkv : CerbMem.MemValue → core_runM CerbMem.MemValue}
    {mk : Nat → CerbMem.Footprint → CerbMem.MemValue →
      CerbMem.MemValue → thread_state}
    {σ σ₁ σ₂ : driver_state} {fp0 fp : CerbMem.Footprint}
    {mval mval' : CerbMem.MemValue}
    {memL memS : CerbMem.MemState} {prefv : Option String}
    (hload : app (CerbMem.loadM loc ty ptr) σ.layout_state
      = (NDactive (fp0, mval), memL))
    (hmid : { σ with
        core_run_state0 := { σ.core_run_state0 with
          aid_supply := σ.core_run_state0.aid_supply + 1 },
        layout_state := memL } = σ₁)
    (hrmw : app (liftCore_run (mkv mval)) σ₁ = (NDactive mval', σ₂))
    (hstore : app (CerbMem.storeM loc ty false ptr mval')
        σ₂.layout_state = (NDactive fp, memS))
    (hpref : app (CerbMem.prefixOfPointer ptr) memS
      = (NDactive prefv, memS)) :
    app (perform_action_request2 false loc tid
          (SeqRMWRequest2 ty ptr mkv mk)) σ
      = (NDactive (),
         (fun σm => { σm with
            trace := ME_seq_rmw loc prefv ty ptr mval mval' :: σm.trace,
            core_state0 := update_thread_state tid
              (mk σ.core_run_state0.aid_supply fp mval mval')
              σm.core_state0 })
         { σ₂ with layout_state := memS }) := by
  subst hmid
  rw [perform_unfold]
  refine (app_bind_active aid_draw).trans ?_
  rw [ars_seqrmw_unfold]
  refine (app_bind_active (app_liftMem_active ?_ hload)).trans ?_
  case _ => rfl
  refine (app_bind_active hrmw).trans ?_
  refine (app_bind_active (app_liftMem_active ?_ hstore)).trans ?_
  case _ => rfl
  refine (app_bind_active (app_liftMem_active ?_ hpref)).trans ?_
  case _ => rfl
  exact app_nd_update _ _

/-- KILL round's perform. -/
@[app_eq,
  step_law (kind := perform) (side := fed)
  (frontier := "perform/kill")
  (trace := "{law := perform_kill, joint := perform/kill, hyps := [hmem : fed]}")
  (lineage := "composed request law: kill through the memory lens + trace/thread update (computed RHS)")]
theorem perform_kill
    {loc : CerbLocation.Loc} {tid : Nat}
    {isDyn : Bool} {ptr : CerbMem.PointerValue}
    {mk : Nat → thread_state}
    {σ : driver_state} {mem' : CerbMem.MemState}
    (hmem : app (CerbMem.killM loc isDyn ptr) σ.layout_state
        = (NDactive (), mem')) :
    app (perform_action_request2 false loc tid
          (KillRequest2 isDyn ptr mk)) σ
      = (NDactive (),
         (fun σm => { σm with
            trace := ME_kill loc isDyn ptr :: σm.trace,
            core_state0 := update_thread_state tid
              (mk σ.core_run_state0.aid_supply) σm.core_state0 })
         { σ with
           core_run_state0 :=
             { σ.core_run_state0 with
               aid_supply := σ.core_run_state0.aid_supply + 1 },
           layout_state := mem' }) := by
  rw [perform_unfold]
  refine (app_bind_active aid_draw).trans ?_
  rw [ars_kill_unfold]
  refine (app_bind_active (app_liftMem_active ?_ hmem)).trans ?_
  case _ => rfl
  exact app_nd_update _ _

end RelSem.Kit
