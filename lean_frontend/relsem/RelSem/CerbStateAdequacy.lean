/-
  RelSem.CerbStateAdequacy — V1 (2026-08-28): ADEQUACY over the
  DECOMPOSED interpretation (CerbStateRA/CerbStateWP), rebuilt from
  the arc-16 S2 / arc-18 C2 route:

  * the closed functor bundle (`CerbStS`, HeapLangS template);
  * the general adequacy face (`cerbSt_adequacy`): any initial state
    with `MemInv`, any CHOSEN coherent tracked-env footprint `e₀` —
    the client receives the initial byte/allocation big-ops, the env
    fragments of `e₀`, and the three exclusive halves (ctl/supply/
    memrest). Tracked env cells are BORN HERE (the chosen set) or at
    the env-write rule; mid-run tracking-birth of an unowned cell is
    the documented V2 design item (CerbStateRA header).
  * the production-runner face (`kAdequateSt_of_wp`) and the threaded
    harness bridges (`kCallHarnessAdequateThrSt_of_wp` + UB-freedom):
    the initial harness state has empty memory and no threads, so the
    client capital collapses to exactly the three halves; the
    CONCLUSIONS are byte-identical to the retired heap-route bridges.
  * the consistency-face bridges (`kCallHarnessAdequateCnsSt_of_wp` +
    UB-freedom): the V0 Cns statement faces discharged from a ∀-seed
    WP obligation (the consistency hypothesis is simply not needed —
    an unconditional WP proof is stronger; pure plumbing
    `callHarnessAdequateCns_of_thrAll` below).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.CerbStateWP
import RelSem.Threaded
import RelSem.PerStepCall
import RelSem.PerStepPeel

set_option autoImplicit false

namespace RelSem
namespace CerbSt

open Iris Iris.BI Iris.ProgramLogic
open RelSem.Cerb

/-! ## The closed functor bundle (HeapLangS template: 0-3 the
    invariant/credit machinery, 4-6 the GenHeap byte map, 7 the
    allocation ghost map, 8 the env ghost map, 9-11 the three
    exclusive ghost cells) -/

def CerbStS : BundledGFunctors
  | 0 => ⟨InvMapF, by infer_instance⟩
  | 1 => ⟨constOF CoPsetDisjL, by infer_instance⟩
  | 2 => ⟨constOF (DisjointLeibnizSet PosSet), by infer_instance⟩
  | 3 => ⟨Auth.AuthURF (constOF Credit), by infer_instance⟩
  | 4 => ⟨constOF (HeapView Int (Agree (DiscreteO CerbMem.AbsByte))
            CerbStF), by infer_instance⟩
  | 5 => ⟨constOF (HeapView Int (Agree (DiscreteO GName)) CerbStF),
          by infer_instance⟩
  | 6 => ⟨constOF MetaUR, by infer_instance⟩
  | 7 => ⟨constOF (HeapView Int (Agree (DiscreteO CerbMem.Allocation))
            CerbStF), by infer_instance⟩
  | 8 => ⟨constOF (HeapView Int (Agree (DiscreteO EnvCell))
            CerbStF), by infer_instance⟩
  | 9 => ⟨GhostVarF driver_state, by infer_instance⟩
  | 10 => ⟨GhostVarF Supplies, by infer_instance⟩
  | 11 => ⟨GhostVarF CerbMem.MemState, by infer_instance⟩
  | _ => ⟨constOF Unit, by infer_instance⟩

instance instCerbStGpreS_CerbStS : CerbStGpreS CerbStS where
  toWsatGpreS := by
    constructor
    · exists 0
    · exists 1
    · exists 2
  toLcGpreS := by
    constructor
    · exists 3
  bytes_pre := by
    constructor
    · constructor
      exists 4
    · constructor
      exists 5
    · exists 6
  alloc_pre := by
    constructor
    exists 7
  env_pre := by
    constructor
    exists 8
  ctl_pre := @GhostVarG.mk _ _ ⟨9, rfl⟩
  sup_pre := @GhostVarG.mk _ _ ⟨10, rfl⟩
  mrest_pre := @GhostVarG.mk _ _ ⟨11, rfl⟩

variable {GF : BundledGFunctors}

/-! ## Initial-state facts (twins of the retired heap-route ones) -/

/-- The memory invariant holds at the initial (empty) memory. -/
theorem MemInv_initial : MemInv CerbMem.initialMemState := by
  constructor
  · intro aid al hget
    rw [show CerbMem.initialMemState.allocations.get? aid
      = (none : Option CerbMem.Allocation) from rfl] at hget
    cases hget
  · intro aid hmem
    cases hmem
  · intro aid hmem
    cases hmem
  · intro a b hget
    rw [show CerbMem.initialMemState.bytemap.get? a
      = (none : Option CerbMem.AbsByte) from rfl] at hget
    cases hget

/-- States with no threads are env-well-formed (the initial harness
    state's face). -/
theorem EnvWf_of_no_threads {σ : driver_state}
    (h : thread0Env σ = []) : EnvWf σ := by
  intro f hf
  rw [h] at hf
  cases hf

/-- The empty tracked-env footprint is coherent at any state. -/
theorem EnvCoh_empty (σ : driver_state) :
    EnvCoh σ (∅ : CerbStF EnvCell) := by
  intro n c hc
  rw [show Std.PartialMap.get? (M := CerbStF)
    (∅ : CerbStF EnvCell) n = none from
      Std.LawfulPartialMap.get?_empty n] at hc
  cases hc

/-! ## The general adequacy face -/

/-- Adequacy at ANY initial state with `MemInv`, at a CHOSEN coherent
    tracked-env footprint `e₀`: allocate the six ghost components from
    the initial physical state (the `heap_adequacy` template), hand
    the client the initial footprint, conclude `adequate`. -/
theorem cerbSt_adequacy [CerbStGpreS GF] (e : KDriveExpr)
    (σ : driver_state) (φ : DriveVal → Prop)
    (hinv : MemInv σ.layout_state) (hwf : EnvWf σ)
    (e₀ : CerbStF EnvCell) (hcoh : EnvCoh σ e₀)
    (Hwp : ∀ [CerbStGS GF],
      (iprop(([∗map] a ↦ b ∈ bytesOf σ.layout_state, (a ↦ b)) ∗
        ([∗map] aid ↦ al ∈ allocsOf σ.layout_state,
          allocIs aid (.own 1) al) ∗
        ([∗map] n ↦ c ∈ e₀, ((CerbStGS.envName GF) ↪◯MAP[n] c)) ∗
        ctlIs stHalf (ctlOf σ) ∗
        supIs stHalf (suppliesOf σ) ∗
        mrestIs stHalf (memRestOf σ)) : IProp GF) ⊢
        WP e @ Stuckness.NotStuck ; ⊤ {{ v, ⌜φ v⌝ }}) :
    adequate Stuckness.NotStuck e σ (fun v _ => φ v) := by
  refine wp_adequacy (GF := GF) Stuckness.NotStuck e σ φ @fun iinv κs => ?_
  imod (genHeap_init (H := CerbStF) (bytesOf σ.layout_state))
    with ⟨%Gb, Hbi, Hbp, -⟩
  imod (ghost_map_alloc (H := CerbStF) (allocsOf σ.layout_state))
    with ⟨%γa, Hai, Hap⟩
  imod (ghost_map_alloc (H := CerbStF) e₀)
    with ⟨%γe, Hei, Hep⟩
  imod (ghost_var_alloc (GF := GF) (ctlOf σ)) with ⟨%γc, Hc⟩
  have hsplitC := ghost_var_split (GF := GF) γc (ctlOf σ)
    (1 : Qp).half (1 : Qp).half
  rw [Qp.half_add_half] at hsplitC
  icases hsplitC $$ Hc with ⟨Hc1, Hc2⟩
  imod (ghost_var_alloc (GF := GF) (suppliesOf σ)) with ⟨%γs, Hs⟩
  have hsplitS := ghost_var_split (GF := GF) γs (suppliesOf σ)
    (1 : Qp).half (1 : Qp).half
  rw [Qp.half_add_half] at hsplitS
  icases hsplitS $$ Hs with ⟨Hs1, Hs2⟩
  imod (ghost_var_alloc (GF := GF) (memRestOf σ)) with ⟨%γm, Hm⟩
  have hsplitM := ghost_var_split (GF := GF) γm (memRestOf σ)
    (1 : Qp).half (1 : Qp).half
  rw [Qp.half_add_half] at hsplitM
  icases hsplitM $$ Hm with ⟨Hm1, Hm2⟩
  imodintro
  iexists (fun σ' _ => iprop(
    genHeapInterp (G := Gb) (bytesOf σ'.layout_state) ∗
    (γa ↪●MAP allocsOf σ'.layout_state) ∗
    (∃ e' : CerbStF EnvCell, (γe ↪●MAP e') ∗ ⌜EnvCoh σ' e'⌝) ∗
    (γc ↪VAR{stHalf} ctlOf σ') ∗
    (γs ↪VAR{stHalf} suppliesOf σ') ∗
    (γm ↪VAR{stHalf} memRestOf σ') ∗
    ⌜MemInv σ'.layout_state⌝ ∗ ⌜EnvWf σ'⌝)), (fun _ => iprop(True))
  have hconvB : (iprop([∗map] a ↦ b ∈ bytesOf σ.layout_state,
        (pointsTo (G := Gb) a (.own 1) b)) : IProp GF)
      = iprop([∗map] a ↦ b ∈ bytesOf σ.layout_state,
          (pointsTo (G := CerbStGS.bytes
            (self := ⟨Gb, γa, γe, γc, γs, γm⟩)) a (.own 1) b)) := rfl
  have hconvA : (iprop([∗map] k ↦ v ∈ allocsOf σ.layout_state,
        (γa ↪◯MAP[k] v)) : IProp GF)
      = iprop([∗map] aid ↦ al ∈ allocsOf σ.layout_state,
          @allocIs GF ⟨Gb, γa, γe, γc, γs, γm⟩ aid (.own 1) al) := rfl
  have hconvE : (iprop([∗map] k ↦ v ∈ e₀,
        (γe ↪◯MAP[k] v)) : IProp GF)
      = iprop([∗map] n ↦ c ∈ e₀,
          ((CerbStGS.envName (self := ⟨Gb, γa, γe, γc, γs, γm⟩) GF)
            ↪◯MAP[n] c)) := rfl
  have hconvC : ((γc ↪VAR{stHalf} ctlOf σ) : IProp GF)
      = @ctlIs GF ⟨Gb, γa, γe, γc, γs, γm⟩ stHalf (ctlOf σ) := rfl
  have hconvS : ((γs ↪VAR{stHalf} suppliesOf σ) : IProp GF)
      = @supIs GF ⟨Gb, γa, γe, γc, γs, γm⟩ stHalf (suppliesOf σ) := rfl
  have hconvM : ((γm ↪VAR{stHalf} memRestOf σ) : IProp GF)
      = @mrestIs GF ⟨Gb, γa, γe, γc, γs, γm⟩ stHalf (memRestOf σ) := rfl
  icases hconvB $$ Hbp with Hbp
  icases hconvA $$ Hap with Hap
  icases hconvE $$ Hep with Hep
  icases hconvC $$ Hc2 with Hc2
  icases hconvS $$ Hs2 with Hs2
  icases hconvM $$ Hm2 with Hm2
  ihave Hwpres := @Hwp ⟨Gb, γa, γe, γc, γs, γm⟩
    $$ [$Hbp $Hap $Hep $Hc2 $Hs2 $Hm2]
  simp only []
  isplitr [Hwpres]
  · iframe Hbi Hai Hc1 Hs1 Hm1
    isplitl [Hei]
    · iexists e₀
      iframe Hei
      ipureintro
      exact hcoh
    · ipureintro
      exact ⟨hinv, hwf⟩
  · iapply Hwpres

/-- The production-runner face: WP under the initial footprint ⇒
    every enumerated outcome satisfies the postcondition. -/
theorem kAdequateSt_of_wp [CerbStGpreS GF] (e : KDriveExpr)
    (σ : driver_state) (φ : DriveVal → Prop)
    (hinv : MemInv σ.layout_state) (hwf : EnvWf σ)
    (e₀ : CerbStF EnvCell) (hcoh : EnvCoh σ e₀)
    (Hwp : ∀ [CerbStGS GF],
      (iprop(([∗map] a ↦ b ∈ bytesOf σ.layout_state, (a ↦ b)) ∗
        ([∗map] aid ↦ al ∈ allocsOf σ.layout_state,
          allocIs aid (.own 1) al) ∗
        ([∗map] n ↦ c ∈ e₀, ((CerbStGS.envName GF) ↪◯MAP[n] c)) ∗
        ctlIs stHalf (ctlOf σ) ∗
        supIs stHalf (suppliesOf σ) ∗
        mrestIs stHalf (memRestOf σ)) : IProp GF) ⊢
        WP e @ Stuckness.NotStuck ; ⊤ {{ v, ⌜φ v⌝ }}) :
    ∀ (out : nd_status driver_result driver_error driver_state)
      (tr : List String) (σ' : driver_state),
      (out, tr, σ') ∈ CerbND.runND e.denote σ →
      φ (Outcome.ofStatus out) := by
  have Had := cerbSt_adequacy e σ φ hinv hwf e₀ hcoh Hwp
  intro out tr σ' hmem
  exact Had.adequate_result [] σ' (Outcome.ofStatus out)
    (ksteps_erased (ksteps_of_runND hmem))

/-! ## The threaded harness bridges (the C2 shapes, conclusions
    byte-identical) -/

/-- THE THREADED ADEQUACY BRIDGE on the decomposed route: the initial
    harness state has empty memory and no threads, so the client's
    entire capital is the three exclusive halves. -/
theorem kCallHarnessAdequateThrSt_of_wp {GF : BundledGFunctors}
    [CerbStGpreS GF] (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbStGS GF],
      (ctlIs (GF := GF) stHalf
          (ctlOf (initial_driver_state_threaded seed file1 fs)) ∗
        supIs stHalf
          (suppliesOf (initial_driver_state_threaded seed file1 fs)) ∗
        mrestIs stHalf
          (memRestOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequateThr seed tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  rw [← callK_denote] at hmem
  have hφ := kAdequateSt_of_wp (GF := GF)
    (callK tagDefs file1 fname args)
    (initial_driver_state_threaded seed file1 fs)
    (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r)
    MemInv_initial (EnvWf_of_no_threads rfl)
    (∅ : CerbStF EnvCell) (EnvCoh_empty _)
    (by
      intro inst
      iintro ⟨Hb, Ha, He, Hc, Hs, Hm⟩
      iclear Hb
      iclear Ha
      iclear He
      iapply Hwp $$ [$Hc $Hs $Hm])
    out tr st' hmem
  obtain ⟨r, hr, hs⟩ := hφ
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- The UB-freedom face. -/
theorem kCallHarnessUBFreeThrSt_of_wp {GF : BundledGFunctors}
    [CerbStGpreS GF] (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbStGS GF],
      (ctlIs (GF := GF) stHalf
          (ctlOf (initial_driver_state_threaded seed file1 fs)) ∗
        supIs stHalf
          (suppliesOf (initial_driver_state_threaded seed file1 fs)) ∗
        mrestIs stHalf
          (memRestOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFreeThr seed tagDefs file1 fname args fs :=
  callHarnessUBFreeThr_of_adequateThr
    (kCallHarnessAdequateThrSt_of_wp seed tagDefs file1 fname args fs
      spec Hwp)

/-! ## The consistency-face bridges (the V0 layer-1 statement faces) -/

/-- Pure statement-layer plumbing: an unconditional ∀-seed threaded
    headline implies the consistency headline (the consistency
    hypothesis is discarded — the unconditional claim is stronger). -/
theorem callHarnessAdequateCns_of_thrAll {prior : List Nat}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    (h : ∀ seed : Nat,
      CallHarnessAdequateThr seed tagDefs file1 fname args fs spec) :
    CallHarnessAdequateCns prior tagDefs file1 fname args fs spec := by
  intro seed out tr st' hmem _hcons
  exact h seed out tr st' hmem

/-- THE CNS ADEQUACY BRIDGE: a ∀-seed WP obligation on the decomposed
    route discharges the V0 consistency statement face. -/
theorem kCallHarnessAdequateCnsSt_of_wp {GF : BundledGFunctors}
    [CerbStGpreS GF] (prior : List Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ (seed : Nat) [CerbStGS GF],
      (ctlIs (GF := GF) stHalf
          (ctlOf (initial_driver_state_threaded seed file1 fs)) ∗
        supIs stHalf
          (suppliesOf (initial_driver_state_threaded seed file1 fs)) ∗
        mrestIs stHalf
          (memRestOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequateCns prior tagDefs file1 fname args fs spec :=
  callHarnessAdequateCns_of_thrAll (fun seed =>
    kCallHarnessAdequateThrSt_of_wp (GF := GF) seed tagDefs file1 fname
      args fs spec (Hwp seed))

/-- The consistency UB-freedom face. -/
theorem kCallHarnessUBFreeCnsSt_of_wp {GF : BundledGFunctors}
    [CerbStGpreS GF] (prior : List Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ (seed : Nat) [CerbStGS GF],
      (ctlIs (GF := GF) stHalf
          (ctlOf (initial_driver_state_threaded seed file1 fs)) ∗
        supIs stHalf
          (suppliesOf (initial_driver_state_threaded seed file1 fs)) ∗
        mrestIs stHalf
          (memRestOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFreeCns prior tagDefs file1 fname args fs :=
  callHarnessUBFreeCns_of_adequateCns
    (kCallHarnessAdequateCnsSt_of_wp prior tagDefs file1 fname args fs
      spec Hwp)


/-! ## The ROUND-GRANULAR bridges (V2): the same conclusions, with the
    WP obligation at the PEELED reification `callK2`
    (RelSem/PerStepPeel.lean) — per-round steps for the driver body;
    the statement faces keep quantifying the untouched `callND`
    (`runND_callND_eq_callK2` is the observation transport). -/

/-- The threaded adequacy bridge at the peeled harness. -/
theorem kCallHarnessAdequateThrSt_of_wp2 {GF : BundledGFunctors}
    [CerbStGpreS GF] (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbStGS GF],
      (ctlIs (GF := GF) stHalf
          (ctlOf (initial_driver_state_threaded seed file1 fs)) ∗
        supIs stHalf
          (suppliesOf (initial_driver_state_threaded seed file1 fs)) ∗
        mrestIs stHalf
          (memRestOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK2 tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequateThr seed tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  rw [runND_callND_eq_callK2] at hmem
  have hφ := kAdequateSt_of_wp (GF := GF)
    (callK2 tagDefs file1 fname args)
    (initial_driver_state_threaded seed file1 fs)
    (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r)
    MemInv_initial (EnvWf_of_no_threads rfl)
    (∅ : CerbStF EnvCell) (EnvCoh_empty _)
    (by
      intro inst
      iintro ⟨Hb, Ha, He, Hc, Hs, Hm⟩
      iclear Hb
      iclear Ha
      iclear He
      iapply Hwp $$ [$Hc $Hs $Hm])
    out tr st' hmem
  obtain ⟨r, hr, hs⟩ := hφ
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- THE CNS ADEQUACY BRIDGE at the peeled harness: a ∀-seed WP
    obligation at per-round granularity discharges the V0 consistency
    statement face. -/
theorem kCallHarnessAdequateCnsSt_of_wp2 {GF : BundledGFunctors}
    [CerbStGpreS GF] (prior : List Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ (seed : Nat) [CerbStGS GF],
      (ctlIs (GF := GF) stHalf
          (ctlOf (initial_driver_state_threaded seed file1 fs)) ∗
        supIs stHalf
          (suppliesOf (initial_driver_state_threaded seed file1 fs)) ∗
        mrestIs stHalf
          (memRestOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK2 tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequateCns prior tagDefs file1 fname args fs spec :=
  callHarnessAdequateCns_of_thrAll (fun seed =>
    kCallHarnessAdequateThrSt_of_wp2 (GF := GF) seed tagDefs file1 fname
      args fs spec (Hwp seed))

/-- The consistency UB-freedom face at the peeled harness. -/
theorem kCallHarnessUBFreeCnsSt_of_wp2 {GF : BundledGFunctors}
    [CerbStGpreS GF] (prior : List Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ (seed : Nat) [CerbStGS GF],
      (ctlIs (GF := GF) stHalf
          (ctlOf (initial_driver_state_threaded seed file1 fs)) ∗
        supIs stHalf
          (suppliesOf (initial_driver_state_threaded seed file1 fs)) ∗
        mrestIs stHalf
          (memRestOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK2 tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFreeCns prior tagDefs file1 fname args fs :=
  callHarnessUBFreeCns_of_adequateCns
    (kCallHarnessAdequateCnsSt_of_wp2 prior tagDefs file1 fname args fs
      spec Hwp)

end CerbSt
end RelSem
