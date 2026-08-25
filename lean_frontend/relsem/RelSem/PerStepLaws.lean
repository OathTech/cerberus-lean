/-
  RelSem.PerStepLaws — arc-16 S3 (2026-08-24): THE PRIMITIVE WP LAW
  LIBRARY — one proved WP lemma per exec-relevant Core construct, over
  the peeled per-step language (PerStepPeel) at the OwnP
  interpretation (PerStepIris).

  THE CONSTRUCT INVENTORY (how compiled Core constructs meet the
  machine): a Core construct manifests as a dnms ROUND whose class is
  its step-discovery's offer —

  | Core construct (source shape)   | round class        | law           |
  |----------------------------------|--------------------|---------------|
  | wseq/sseq/case/let strip         | Step_tau2 TSK_Misc | wpk_round_tau |
  | proc return (Return kind)        | Step_tau2 TSK_Return | wpk_round_tau_ret |
  | pure eval (Epure/Eop/…), Erun/Esave jumps | RSK_eval   | wpk_round_eval |
  | tau-kind runstate steps          | RSK_tau TSK_Misc   | wpk_round_rsk_tau |
  | runstate proc return             | RSK_tau TSK_Return | wpk_round_rsk_ret |
  | create (object allocation)       | CreateRequest2     | wpk_round_create |
  | load                             | LoadRequest2       | wpk_round_load |
  | store                            | StoreRequest2      | wpk_round_store |
  | kill (end of lifetime)           | KillRequest2       | wpk_round_kill |
  | no-advance (accumulate offer)    | find = none        | wpk_round_accum |
  | ccall/proc dispatch              | Step_ccall2 (driver2 layer) | wpk_pcs_ccall |
  | program exit                     | Step_done2 (driver2 layer)  | wpk_pcs_done |
  | scheduler mode split             | (opaque config read)        | wpk_ite |

  Each law is proved ONCE against the generated semantics (its
  hypotheses are the Kit law table's, hypothesis for hypothesis —
  REUSE of the arc-9 `@[app_eq]` equation layer at the per-construct
  level) and fires for every program containing the construct; a
  program's proof pays only for its own structure. Side conditions
  are KERNEL-COMPUTABLE pure facts (`rfl`/`decide`-dischargeable at
  concrete instances — ban-compliant reflection).

  Lineage (canon-first): Floyd–Hoare/weakest-precondition rules per
  language construct — the HeapLang `PrimitiveLaws.lean` shape; the
  big-step-to-per-construct factoring is Myreen-style decompilation
  applied at Core's compiled shapes. The HEAP-ROUTE twins of the
  memory rounds are S2's `wpk_load/store/alloc/kill`, which fire
  UNMODIFIED at the `liftMem` atoms `arsK` exposes (their trigger
  shape, byte-identical); the OwnP-route composites below serve
  concrete-state proofs, and the heap-route neighbor rules
  (discovery/draw/update under `CerbMemInterp`) are part-2 work,
  priced in the S3 record.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.PerStepIris
import RelSem.PerStepCall
import RelSem.PerStepPeel

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI
open RelSem.Kit

variable {GF : BundledGFunctors} [CerbGS .hasLC GF]
variable {s : Stuckness} {E : CoPset}

/-! ## Generic step forms (the tactic layer's lemma backing) -/

/-- `wpk_seq_active` with the current state given up to a definitional
    cast (`hσ` discharges by `rfl`): lets a tactic step from whatever
    spelling of the state the goal carries (the S1 §6 projection-term
    technique, automated). -/
theorem wpk_seq_active' {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {σ0 σ σ' : driver_state} {v : α}
    (hσ : σ0 = σ) (h : app m σ = (NDactive v, σ'))
    {Φ : DriveVal → IProp GF} :
    stateIs σ0 ∗ (stateIs σ' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} :=
  hσ ▸ wpk_seq_active h

/-! ## RE-HOMED (arc-18 C1): `wpk_seq_active_ecast` and
    `wpk_seq_active_proj` — the TWO LIVE seq laws the wp-tactic layer
    consumes (`wp_step`/`wp_pures` backing lemmas) — now live in
    RelSem/PerStepIris.lean beside `wpk_seq_active`/`wpk_done` and are
    registered in the one registry (`@[step_law (kind := wpSeq)]`).
    Everything REMAINING in this file is the dormant arc-16 half
    (Q1 [USER]: DELETE) — it retires at C2 with the peels
    (retirement register entry 2,
    docs/2026-08-25_reasoning-layer-contracts.md §7). -/

/-- Boolean split on a reified scheduling decision (the opaque
    execution-mode read): both arms provable ⇒ the `if` is. -/
theorem wpk_ite {c : Bool} {e₁ e₂ : KDriveExpr} {P : IProp GF}
    {Φ : DriveVal → IProp GF}
    (h₁ : P ⊢ WP e₁ @ s ; E {{ Φ }})
    (h₂ : P ⊢ WP e₂ @ s ; E {{ Φ }}) :
    P ⊢ WP (if c then e₁ else e₂) @ s ; E {{ Φ }} := by
  cases c with
  | false => rw [if_neg Bool.false_ne_true]; exact h₂
  | true => rw [if_pos rfl]; exact h₁

/-! ## The dnms round laws (per-construct, at the peeled loop).

    Shared hypothesis block (the Kit `dnms_round` vocabulary,
    hypothesis for hypothesis): `hfuel` in the bare-variable
    DiscrTree-wildcard form; `hlook` the thread lookup; `hsteps` the
    step DISCOVERY (rfl at concrete arenas — the construct enters
    here); `hfind` the offered advancing step. -/

section RoundLaws

variable {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
variable {nS n : Nat} {acc : Fmap thread_id (List core_step2)}
variable {tid : Nat} {xs' : List Nat} {σ : driver_state}
variable {th_info : Option thread_id × thread_state}
variable {steps : List core_step2}
variable {k : Fmap thread_id (List core_step2) → KDriveExpr}
variable {Φ : DriveVal → IProp GF}

/-- Round-entry computation: under `hlook`, the discovery read yields
    exactly the `step_ctx` offer. -/
theorem stepDiscovery_eq
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps) :
    stepDiscovery tagDefs tid σ = steps := by
  unfold stepDiscovery
  rw [hlook]
  exact hsteps

/-- NO-ADVANCE round (the offer is accumulated; e.g. the thread's
    only offer is the terminal `Step_done2`): one read step, the loop
    continues on the remaining threads. -/
theorem wpk_round_accum
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps = none) :
    stateIs (GF := GF) σ ∗ (stateIs σ -∗
        WP (dnmsK tagDefs n (fmapAddBy defaultCompare tid steps acc)
          xs' k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} := by
  subst hfuel
  have hd := stepDiscovery_eq (tagDefs := tagDefs) hlook hsteps
  show stateIs σ ∗ _ ⊢
    WP (KExpr.seq (nd_read (stepDiscovery tagDefs tid)) _) @ s ; E {{ Φ }}
  iintro ⟨Hst, Hcont⟩
  iapply wpk_seq_active (app_nd_read (stepDiscovery tagDefs tid) σ)
  iframe Hst
  iintro Hst
  rw [hd]
  simp only [dnmsKBody, hfind]
  iapply Hcont $$ Hst

/-- The generic ADVANCE round: any advancing offer OTHER than the
    reified sequential action request, its advance `app` equation as
    hypothesis (the Kit advance laws' conclusion shape). The
    per-construct tau/eval laws below instantiate `hadv`. -/
theorem wpk_round_advance {step1 : core_step2} {w : advance_info}
    {σ' : driver_state}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps = some step1)
    (hnoreq : ∀ (dbg : String) (loc : CerbLocation.Loc) (tid' : Nat)
        (m_request : core_runM (action_request2 thread_state)),
        step1 ≠ Step_action_request2 dbg loc tid' false m_request)
    (hadv : app (advance_step tagDefs tid step1) σ
        = (NDactive w, σ')) :
    stateIs (GF := GF) σ ∗ (stateIs σ' -∗
        WP (dnmsK tagDefs n acc (wakeupIns w tid xs') k)
          @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} := by
  subst hfuel
  have hd := stepDiscovery_eq (tagDefs := tagDefs) hlook hsteps
  show stateIs σ ∗ _ ⊢
    WP (KExpr.seq (nd_read (stepDiscovery tagDefs tid)) _) @ s ; E {{ Φ }}
  iintro ⟨Hst, Hcont⟩
  iapply wpk_seq_active (app_nd_read (stepDiscovery tagDefs tid) σ)
  iframe Hst
  iintro Hst
  rw [hd]
  -- dispatch to the residual arm (every non-reified constructor)
  cases step1 with
  | Step_action_request2 dbg loc tid' unseq m_request =>
    cases unseq with
    | false => exact absurd rfl (hnoreq dbg loc tid' m_request)
    | true =>
      simp only [dnmsKBody, hfind]
      iapply wpk_seq_active hadv
      iframe Hst
      iintro Hst
      iapply Hcont $$ Hst
  | Step_ccall2 a b =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_with_runstate2 a b =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_tau2 a b c =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_blocked2 =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_error2 a =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_thread_done2 a b =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_done2 a =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_memop_request2 a b c d e f =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_spawn_threads2 a b =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_fs2 a b c =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst
  | Step_nd2 a =>
    simp only [dnmsKBody, hfind]
    iapply wpk_seq_active hadv
    iframe Hst
    iintro Hst
    iapply Hcont $$ Hst

/-- SEQ/CASE/LET STRIP (`Step_tau2 TSK_Misc`: the sequencing tau of
    wseq/sseq/pattern strips): one read + one advance; the post-state
    is COMPUTED (`dnmsBump` — Kit `advance_tau_misc` reused). -/
theorem wpk_round_tau {dbg : String} {th' : thread_state}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_tau2 dbg TSK_Misc th')) :
    stateIs (GF := GF) σ ∗ (stateIs (dnmsBump tid th' σ) -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} :=
  wpk_round_advance hfuel hlook hsteps hfind
    (fun _ _ _ _ h => by cases h) advance_tau_misc

/-- PURE EVAL / RUN / SAVE (`RSK_eval` runstate steps: Epure/Eop
    chains, Erun jumps, Esave landings — the round the T1 conv chain
    and every eval ladder crosses): the core-run verdict enters as the
    pure hypothesis `hm` (Kit `advance_runstate_eval` reused). -/
theorem wpk_round_eval {dbg : String}
    {step_m : core_runM thread_state}
    {th' : thread_state} {rs' : core_run_state}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_with_runstate2 (RSK_eval dbg) step_m))
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    stateIs (GF := GF) σ ∗
      (stateIs (dnmsBump tid th' { σ with core_run_state0 := rs' }) -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} :=
  wpk_round_advance hfuel hlook hsteps hfind
    (fun _ _ _ _ h => by cases h) (advance_runstate_eval hm)

/-- Runstate tau (`RSK_tau TSK_Misc`) — same shape as eval (Kit
    `advance_runstate_tau_misc` reused). -/
theorem wpk_round_rsk_tau {dbg : String}
    {step_m : core_runM thread_state}
    {th' : thread_state} {rs' : core_run_state}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_with_runstate2 (RSK_tau dbg TSK_Misc) step_m))
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    stateIs (GF := GF) σ ∗
      (stateIs (dnmsBump tid th' { σ with core_run_state0 := rs' }) -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} :=
  wpk_round_advance hfuel hlook hsteps hfind
    (fun _ _ _ _ h => by cases h) (advance_runstate_tau_misc hm)

/-! ### PROC RETURN (`TSK_Return` kinds): the advance prepends the
    function-return trace event. The two advance `app` equations are
    NEW to the equation layer (the Kit table covers the Misc kinds);
    same computed-RHS discipline. -/

/-- Return-kind tau advance: trace event + computed bump. -/
theorem advance_tau_return
    {tid : Nat} {dbg : String} {sym1 : sym}
    {mvo : Option CerbMem.MemValue} {th' : thread_state}
    {σ : driver_state} :
    app (advance_step tagDefs tid
          (Step_tau2 dbg (TSK_Return sym1 mvo) th')) σ
      = (NDactive NOWAKEUP,
         dnmsBump tid th'
           { σ with trace := ME_function_return sym1 mvo :: σ.trace }) := by
  refine (app_bind_active (app_nd_update _ σ)).trans ?_
  refine (app_bind_active (app_nd_update _ _)).trans ?_
  exact app_nd_return _ _

/-- Return-kind runstate advance. -/
theorem advance_runstate_return
    {tid : Nat} {dbg : String} {sym1 : sym}
    {mvo : Option CerbMem.MemValue}
    {step_m : core_runM thread_state}
    {σ : driver_state} {th' : thread_state} {rs' : core_run_state}
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    app (advance_step tagDefs tid
          (Step_with_runstate2 (RSK_tau dbg (TSK_Return sym1 mvo))
            step_m)) σ
      = (NDactive NOWAKEUP,
         dnmsBump tid th'
           { σ with trace := ME_function_return sym1 mvo :: σ.trace,
                    core_run_state0 := rs' }) := by
  refine (app_bind_active (app_nd_update _ σ)).trans ?_
  refine (app_bind_active (liftCore_run_defined
    (dr := { σ with trace := ME_function_return sym1 mvo :: σ.trace })
    hm)).trans ?_
  refine (app_bind_active (app_nd_update _ _)).trans ?_
  exact app_nd_return _ _

/-- Proc-return round (tau kind). -/
theorem wpk_round_tau_ret {dbg : String} {sym1 : sym}
    {mvo : Option CerbMem.MemValue} {th' : thread_state}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_tau2 dbg (TSK_Return sym1 mvo) th')) :
    stateIs (GF := GF) σ ∗
      (stateIs (dnmsBump tid th'
          { σ with trace := ME_function_return sym1 mvo :: σ.trace }) -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} :=
  wpk_round_advance hfuel hlook hsteps hfind
    (fun _ _ _ _ h => by cases h) advance_tau_return

/-- Proc-return round (runstate kind). -/
theorem wpk_round_rsk_ret {dbg : String} {sym1 : sym}
    {mvo : Option CerbMem.MemValue}
    {step_m : core_runM thread_state}
    {th' : thread_state} {rs' : core_run_state}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_with_runstate2 (RSK_tau dbg (TSK_Return sym1 mvo))
            step_m))
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    stateIs (GF := GF) σ ∗
      (stateIs (dnmsBump tid th'
          { σ with trace := ME_function_return sym1 mvo :: σ.trace,
                   core_run_state0 := rs' }) -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} :=
  wpk_round_advance hfuel hlook hsteps hfind
    (fun _ _ _ _ h => by cases h) (advance_runstate_return hm)

end RoundLaws

/-! ## The memory rounds (create/load/store/kill through the DEEP
    reified arm): per-atom steps — request draw, aid draw, the
    `liftMem` MEMORY OP (the S2 heap rules' trigger atom), the
    bookkeeping update. Stated OwnP-route with the physical `app`
    equations as hypotheses (the Kit `mem_*_block` conclusions fit
    `hmem` directly); the HEAP-ROUTE versions of the op atom are S2's
    `wpk_load/store/alloc/kill`, unmodified. -/

section MemRounds

variable {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
variable {nS n : Nat} {acc : Fmap thread_id (List core_step2)}
variable {tid : Nat} {xs' : List Nat} {σ : driver_state}
variable {th_info : Option thread_id × thread_state}
variable {steps : List core_step2}
variable {k : Fmap thread_id (List core_step2) → KDriveExpr}
variable {Φ : DriveVal → IProp GF}
variable {dbg : String} {loc : CerbLocation.Loc} {tid' : Nat}
variable {m_request : core_runM (action_request2 thread_state)}
variable {rs₁ : core_run_state}

/-- The entry spine of a sequential action-request round: read +
    request draw + aid draw, landing on the `arsK` dispatch. Factored
    once; the four memory laws instantiate the request. -/
theorem wpk_round_request_entry
    {request : action_request2 thread_state}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_action_request2 dbg loc tid' false m_request))
    (hreq : m_request σ.core_run_state0 = Result (Defined request, rs₁)) :
    stateIs (GF := GF) σ ∗
      (stateIs { σ with core_run_state0 :=
            { rs₁ with aid_supply := rs₁.aid_supply + 1 } } -∗
        WP (arsK loc tid' rs₁.aid_supply
              (dnmsK tagDefs n acc (tid :: xs') k) request)
          @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} := by
  subst hfuel
  have hd := stepDiscovery_eq (tagDefs := tagDefs) hlook hsteps
  show stateIs σ ∗ _ ⊢
    WP (KExpr.seq (nd_read (stepDiscovery tagDefs tid)) _) @ s ; E {{ Φ }}
  iintro ⟨Hst, Hcont⟩
  iapply wpk_seq_active (app_nd_read (stepDiscovery tagDefs tid) σ)
  iframe Hst
  iintro Hst
  rw [hd]
  simp only [dnmsKBody, hfind]
  iapply wpk_seq_active (liftCore_run_defined hreq)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active aid_draw
  iframe Hst
  iintro Hst
  iapply Hcont $$ Hst

/-- LOAD round (compare Kit `perform_load`, hypothesis for
    hypothesis; the liftMem atom is where the heap-route `wpk_load`
    attaches instead). -/
theorem wpk_round_load
    {mo : memory_order} {ty : ctype} {ptr : CerbMem.PointerValue}
    {mk : Nat → CerbMem.Footprint → CerbMem.MemValue → thread_state}
    {fp : CerbMem.Footprint} {mval : CerbMem.MemValue}
    {mem' : CerbMem.MemState} {prefv : Option String}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_action_request2 dbg loc tid' false m_request))
    (hreq : m_request σ.core_run_state0
        = Result (Defined (LoadRequest2 mo ty ptr mk), rs₁))
    (hmem : app (CerbMem.loadM loc ty ptr) σ.layout_state
        = (NDactive (fp, mval), mem'))
    (hpref : app (CerbMem.prefixOfPointer ptr) mem'
        = (NDactive prefv, mem')) :
    stateIs (GF := GF) σ ∗
      (stateIs { σ with
          core_run_state0 :=
            { rs₁ with aid_supply := rs₁.aid_supply + 1 },
          layout_state := mem',
          trace := ME_load loc prefv ty ptr mval :: σ.trace,
          core_state0 := update_thread_state tid'
            (mk rs₁.aid_supply fp mval) σ.core_state0 } -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} := by
  iintro ⟨Hst, Hcont⟩
  iapply wpk_round_request_entry hfuel hlook hsteps hfind hreq
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (σ := { σ with core_run_state0 := { rs₁ with aid_supply := rs₁.aid_supply + 1 } }) (app_liftMem_active rfl hmem)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (σ := { { σ with core_run_state0 := { rs₁ with aid_supply := rs₁.aid_supply + 1 } } with layout_state := mem' }) (app_liftMem_active rfl hpref)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (app_nd_update _ _)
  iframe Hst
  iintro Hst
  iapply Hcont
  iexact Hst

/-- STORE round (compare Kit `perform_store`). -/
theorem wpk_round_store
    {mo : memory_order} {ty : ctype} {isL : Bool}
    {ptr : CerbMem.PointerValue} {mval : CerbMem.MemValue}
    {mk : Nat → CerbMem.Footprint → thread_state}
    {fp : CerbMem.Footprint} {mem' : CerbMem.MemState}
    {prefv : Option String}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_action_request2 dbg loc tid' false m_request))
    (hreq : m_request σ.core_run_state0
        = Result (Defined (StoreRequest2 mo ty isL ptr mval mk), rs₁))
    (hmem : app (CerbMem.storeM loc ty isL ptr mval) σ.layout_state
        = (NDactive fp, mem'))
    (hpref : app (CerbMem.prefixOfPointer ptr) mem'
        = (NDactive prefv, mem')) :
    stateIs (GF := GF) σ ∗
      (stateIs { σ with
          core_run_state0 :=
            { rs₁ with aid_supply := rs₁.aid_supply + 1 },
          layout_state := mem',
          trace := ME_store loc prefv ty isL ptr mval :: σ.trace,
          core_state0 := update_thread_state tid'
            (mk rs₁.aid_supply fp) σ.core_state0 } -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} := by
  iintro ⟨Hst, Hcont⟩
  iapply wpk_round_request_entry hfuel hlook hsteps hfind hreq
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (σ := { σ with core_run_state0 := { rs₁ with aid_supply := rs₁.aid_supply + 1 } }) (app_liftMem_active rfl hmem)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (σ := { { σ with core_run_state0 := { rs₁ with aid_supply := rs₁.aid_supply + 1 } } with layout_state := mem' }) (app_liftMem_active rfl hpref)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (app_nd_update _ _)
  iframe Hst
  iintro Hst
  iapply Hcont
  iexact Hst

/-- CREATE round (compare Kit `perform_create`). -/
theorem wpk_round_create
    {pref : prefix0} {align : CerbMem.IntegerValue} {ty : ctype}
    {addrOpt : Option Int} {initOpt : Option CerbMem.MemValue}
    {mk : Nat → CerbMem.PointerValue → thread_state}
    {ptrv : CerbMem.PointerValue} {mem' : CerbMem.MemState}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_action_request2 dbg loc tid' false m_request))
    (hreq : m_request σ.core_run_state0
        = Result (Defined
            (CreateRequest2 pref align ty addrOpt initOpt mk), rs₁))
    (hmem : app (CerbMem.allocateObject tid' pref align ty addrOpt
          initOpt) σ.layout_state
        = (NDactive ptrv, mem')) :
    stateIs (GF := GF) σ ∗
      (stateIs { σ with
          core_run_state0 :=
            { rs₁ with aid_supply := rs₁.aid_supply + 1 },
          layout_state := mem',
          trace := ME_allocate_object tid' pref align ty initOpt ptrv
            :: σ.trace,
          core_state0 := update_thread_state tid'
            (mk rs₁.aid_supply ptrv) σ.core_state0 } -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} := by
  iintro ⟨Hst, Hcont⟩
  iapply wpk_round_request_entry hfuel hlook hsteps hfind hreq
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (σ := { σ with core_run_state0 := { rs₁ with aid_supply := rs₁.aid_supply + 1 } }) (app_liftMem_active rfl hmem)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (app_nd_update _ _)
  iframe Hst
  iintro Hst
  iapply Hcont
  iexact Hst

/-- KILL round (compare Kit `perform_kill`). -/
theorem wpk_round_kill
    {isDyn : Bool} {ptr : CerbMem.PointerValue}
    {mk : Nat → thread_state} {mem' : CerbMem.MemState}
    (hfuel : nS = n + 1)
    (hlook : Lem_List.lookupBy (fun x y => x == y) tid
        σ.core_state0.thread_states = some th_info)
    (hsteps : step_ctx tagDefs σ.layout_state σ.core_file
        σ.core_extern tid th_info = steps)
    (hfind : find_can_advance steps
        = some (Step_action_request2 dbg loc tid' false m_request))
    (hreq : m_request σ.core_run_state0
        = Result (Defined (KillRequest2 isDyn ptr mk), rs₁))
    (hmem : app (CerbMem.killM loc isDyn ptr) σ.layout_state
        = (NDactive (), mem')) :
    stateIs (GF := GF) σ ∗
      (stateIs { σ with
          core_run_state0 :=
            { rs₁ with aid_supply := rs₁.aid_supply + 1 },
          layout_state := mem',
          trace := ME_kill loc isDyn ptr :: σ.trace,
          core_state0 := update_thread_state tid'
            (mk rs₁.aid_supply) σ.core_state0 } -∗
        WP (dnmsK tagDefs n acc (tid :: xs') k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs nS acc (tid :: xs') k) @ s ; E {{ Φ }} := by
  iintro ⟨Hst, Hcont⟩
  iapply wpk_round_request_entry hfuel hlook hsteps hfind hreq
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (σ := { σ with core_run_state0 := { rs₁ with aid_supply := rs₁.aid_supply + 1 } }) (app_liftMem_active rfl hmem)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (app_nd_update _ _)
  iframe Hst
  iintro Hst
  iapply Hcont
  iexact Hst

end MemRounds

/-! ## The driver2-layer laws (ccall/proc dispatch; program exit) -/

section PcsLaws

variable {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
variable {wc : Bool} {resid : Bool → driverM Unit}
variable {rest : KDriveExpr} {k : Unit → KDriveExpr}
variable {σ : driver_state} {Φ : DriveVal → IProp GF}

/-- PROGRAM EXIT (`Step_done2`): the exit bookkeeping step, then the
    post-loop continuation. -/
theorem wpk_pcs_done {cval : value} :
    stateIs (GF := GF) σ ∗
      (stateIs { σ with core_state0 := prepare_exit σ.core_state0 cval }
        -∗ WP (k ()) @ s ; E {{ Φ }}) ⊢
      WP (pcsK tagDefs wc resid rest k (Step_done2 cval))
        @ s ; E {{ Φ }} := by
  iintro ⟨Hst, Hcont⟩
  iapply wpk_seq_active (app_nd_update _ σ)
  iframe Hst
  iintro Hst
  iapply Hcont $$ Hst

/-- CCALL / PROC DISPATCH (`Step_ccall2`): the callee's frame setup
    evaluates in the core-run monad (pure hypothesis `hm`), the
    thread is rebuilt, the loop continues (per-iteration). -/
theorem wpk_pcs_ccall {tid1 : Nat}
    {step_m : core_runM thread_state}
    {th' : thread_state} {rs' : core_run_state}
    (hm : step_m σ.core_run_state0 = Result (Defined th', rs')) :
    stateIs (GF := GF) σ ∗
      (stateIs { σ with
          core_run_state0 := rs',
          dr_step_counter := σ.dr_step_counter + 1,
          core_state0 := update_thread_state tid1 th' σ.core_state0 } -∗
        WP rest @ s ; E {{ Φ }}) ⊢
      WP (pcsK tagDefs wc resid rest k (Step_ccall2 tid1 step_m))
        @ s ; E {{ Φ }} := by
  iintro ⟨Hst, Hcont⟩
  iapply wpk_seq_active (liftCore_run_defined hm)
  iframe Hst
  iintro Hst
  iapply wpk_seq_active (app_nd_update _ _)
  iframe Hst
  iintro Hst
  iapply Hcont
  iexact Hst

end PcsLaws

/-! ## Statement-facing adequacy through the PEELED harness (the
    conclusions are the byte-identical committed statement forms; the
    runner-level simulation `callK2_runner_eq` transports the
    production runner's enumeration onto the peeled denotation, and
    the GENERIC completeness does the rest). -/

/-- WP over the peeled harness ⇒ `CallHarnessAdequate` (committed
    def, unchanged). -/
theorem kCallHarnessAdequate_of_wpK2 {GF : BundledGFunctors}
    [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state file1 fs)) ⊢
        WP (callK2 tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequate tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  have hmem2 : (out, tr, st') ∈ CerbND.runND
      (callK2 tagDefs file1 fname args).denote
      (initial_driver_state file1 fs) := by
    show (out, tr, st') ∈ CerbND.runNDFuel CerbND.ndDefaultFuel
      (callK2 tagDefs file1 fname args).denote
      (initial_driver_state file1 fs)
    rw [callK2_runner_eq tagDefs file1 fname args CerbND.ndDefaultFuel
      (Nat.le_refl _) (initial_driver_state file1 fs)]
    exact hmem
  have hφ := kAdequate_of_wp (GF := GF)
    (callK2 tagDefs file1 fname args)
    (initial_driver_state file1 fs)
    (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r)
    Hwp out tr st' hmem2
  obtain ⟨r, hr, hs⟩ := hφ
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- WP over the peeled harness ⇒ `CallHarnessUBFree` (committed def,
    unchanged). -/
theorem kCallHarnessUBFree_of_wpK2 {GF : BundledGFunctors}
    [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state file1 fs)) ⊢
        WP (callK2 tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFree tagDefs file1 fname args fs :=
  callHarnessUBFree_of_callHarnessAdequate
    (kCallHarnessAdequate_of_wpK2 tagDefs file1 fname args fs spec Hwp)

end Cerb
end RelSem
