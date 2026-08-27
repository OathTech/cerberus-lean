/-
  RelSem.CerbStateWP — V1 (2026-08-28): THE RESOURCE-LEVEL WP RULES
  over the per-step language under the DECOMPOSED interpretation
  (RelSem.CerbStateRA). Twin of the arc-16 S2 CerbHeapWP, rebuilt at
  component granularity:

  * ONE lifting skeleton (`wpk_seq_res_det`, from the generic
    `wp_lift_step` — HeapLang wp_lift_atomic_step lineage, unchanged);
  * the four memory-op rules now consume the MEMORY-MODEL RESIDUAL
    (`mrestIs`) instead of the whole machine rest — a load/store/alloc/
    kill no longer pins control, env, or supplies (they ride the
    frame);
  * NEW: the control-step rules (`wpk_seq_ctl`, `wpk_seq_ctl_env1`)
    and the env-write rule (`wpk_seq_env_write`) — the assertion
    layer's new capability: steps characterized by the control token
    plus owned env cells only, every other env cell surviving by
    FRAME (see CerbStateDemo for the exhibit);
  * the terminal readout (`wpk_get_done_ctl`): the postcondition holds
    for every state the control token admits.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.Lifting
import Iris.ProgramLogic.Adequacy
import RelSem.CerbStateRA
import RelSem.Kit.Mem
import RelSem.LawRegistry

set_option autoImplicit false

namespace RelSem
namespace CerbSt

open Iris Iris.BI Iris.ProgramLogic
open RelSem.Cerb

variable {GF : BundledGFunctors}

/-! ## Plumbing -/

/-- The interpretation, index-erased. -/
theorem cerbStInterp_eq [CerbStGS GF] {σ : driver_state}
    {ns : Nat} {obs : List Empty} {nt : Nat} :
    (stateInterp σ ns obs nt : IProp GF) ⊣⊢ CerbStInterp σ := .rfl

/-- Residual-projection transports (all `rfl` after subst: `memRestOf`
    keeps every non-map field). -/
theorem memRestOf_funptrmap {σ : driver_state} {mr : CerbMem.MemState}
    (h : memRestOf σ = mr) :
    σ.layout_state.funptrmap = mr.funptrmap := by
  subst h; rfl

theorem memRestOf_lastUsedUnionMembers {σ : driver_state}
    {mr : CerbMem.MemState} (h : memRestOf σ = mr) :
    σ.layout_state.lastUsedUnionMembers = mr.lastUsedUnionMembers := by
  subst h; rfl

theorem memRestOf_lastAddress {σ : driver_state}
    {mr : CerbMem.MemState} (h : memRestOf σ = mr) :
    σ.layout_state.lastAddress = mr.lastAddress := by
  subst h; rfl

theorem memRestOf_nextAllocId {σ : driver_state}
    {mr : CerbMem.MemState} (h : memRestOf σ = mr) :
    σ.layout_state.nextAllocId = mr.nextAllocId := by
  subst h; rfl

/-! ## The lifting skeleton -/

/-- Resource-conditioned deterministic step (S2 skeleton, verbatim at
    the new interpretation): if the resources `R` pin enough of the
    physical state (`Pre`) to determine the leading atom's one `app`
    step, WP of the `seq` follows from WP of the continuation under
    the updated resources `R'`. -/
theorem wpk_seq_res_det [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {R R' : IProp GF} {Pre : driver_state → Prop}
    {Φ : DriveVal → IProp GF} {s : Stuckness} {E : CoPset}
    (Hext : ∀ σ, (CerbStInterp (GF := GF) σ ∗ R : IProp GF) ⊢
      ⌜Pre σ⌝ ∗ (CerbStInterp σ ∗ R))
    (Happ : ∀ σ, Pre σ → app m σ = (NDactive v, upd σ))
    (Hupd : ∀ σ, Pre σ → (CerbStInterp (GF := GF) σ ∗ R : IProp GF) ⊢
      |==> (CerbStInterp (upd σ) ∗ R')) :
    R ∗ (R' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  iintro ⟨HR, Hcont⟩
  iapply wp_lift_step rfl
  iintro %σ %ns %obs %obs' %nt Hσ
  icases cerbStInterp_eq.1 $$ Hσ with Hσ
  icases (Hext σ) $$ [$Hσ $HR] with ⟨%Hpre, Hσ, HR⟩
  iapply fupd_mask_intro Std.LawfulSet.empty_subset
  iintro Hclose
  isplitl []
  · ipureintro
    cases s
    · exact kreducible_of_app_active (Happ σ Hpre)
    · trivial
  iintro !> %e₂ %σ₂ %eₜ %Hprim Hcred
  iclear Hcred
  obtain ⟨hd, -, hefs⟩ := kPrimStep_inv Hprim
  have hconf := kstep_seq_active_inv (Happ σ Hpre) hd
  injection hconf with he hσ
  subst he; subst hσ; subst hefs
  imod Hclose
  imod (Hupd σ Hpre) $$ [$Hσ $HR] with ⟨Hσ', HR'⟩
  imodintro
  icases cerbStInterp_eq.2 $$ Hσ' with Hσ'
  iframe Hσ'
  simp only [Algebra.BigOpL.bigOpL_nil]
  iframe
  iapply Hcont $$ HR'

/-! ## CONTROL STEP — the atom is characterized by the control token
    alone; layout untouched, supplies untouched, env lookup-monotone.
    EVERY env cell, byte range, allocation fragment, the supply and
    residual components ride the frame. -/

@[step_law (kind := stateWP) (variant := ctl) (side := fed)
  (frontier := "state/ctl")
  (trace := "{law := wpk_seq_ctl, joint := state/ctl, hyps := [Happ : fed, transports : fed]}")
  (lineage := "control-token step (ghost_var exclusive token; HeapLang pure-step analogue at the decomposed machine state — every env cell, heap fragment, supply frames)")]
theorem wpk_seq_ctl [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ →
      app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ →
      (upd σ).layout_state = σ.layout_state)
    (hsup : ∀ σ, ctlOf σ = c → EnvWf σ →
      suppliesOf (upd σ) = suppliesOf σ)
    (henv : ∀ σ, ctlOf σ = c → EnvWf σ →
      ∀ x v', envLookup σ x = some v' →
        envLookup (upd σ) x = some v')
    (hwfp : ∀ σ, ctlOf σ = c → EnvWf σ → EnvWf (upd σ)) :
    ctlIs (GF := GF) stHalf c ∗
      (ctlIs stHalf c' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det (Pre := fun σ => ctlOf σ = c ∧ EnvWf σ)
    (upd := upd) ?_ (fun σ hp => Happ σ hp.1 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h2, Hi⟩
    iframe Hi Hc
    ipureintro
    exact ⟨h1, h2⟩
  · intro σ hp
    iintro ⟨Hi, Hc⟩
    rw [show c = ctlOf σ from hp.1.symm]
    imod interp_ctl_move (hlay σ hp.1 hp.2) (hsup σ hp.1 hp.2)
      (henv σ hp.1 hp.2) (fun _ => hwfp σ hp.1 hp.2)
      $$ [$Hi $Hc] with ⟨Hi, Hc⟩
    imodintro
    rw [hctl' σ hp.1 hp.2]
    iframe Hi Hc

/-! ## CONTROL STEP WITH ONE ENV READ — as `wpk_seq_ctl`, with the
    step additionally characterized by ONE owned env cell (any
    fraction); the fragment returns unchanged. The rule whose
    instances read a local at a SYMBOLIC value. -/

@[step_law (kind := stateWP) (variant := ctlEnv1) (side := fed)
  (frontier := "state/ctl-env1")
  (trace := "{law := wpk_seq_ctl_env1, joint := state/ctl-env1, hyps := [Happ : fed(one-cell lookup), transports : fed]}")
  (lineage := "control step characterized by ONE owned env cell at a symbolic value (gmap-auth locals view; the read rule)")]
theorem wpk_seq_ctl_env1 [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state} {x : sym} {vx : value} {dq : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ x = some vx →
      app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ x = some vx →
      ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ x = some vx →
      (upd σ).layout_state = σ.layout_state)
    (hsup : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ x = some vx →
      suppliesOf (upd σ) = suppliesOf σ)
    (henv : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ x = some vx →
      ∀ y v', envLookup σ y = some v' →
        envLookup (upd σ) y = some v')
    (hwfp : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ x = some vx →
      EnvWf (upd σ)) :
    (ctlIs (GF := GF) stHalf c ∗ envIs x dq vx) ∗
      ((ctlIs stHalf c' ∗ envIs x dq vx)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det
    (Pre := fun σ => (ctlOf σ = c ∧ EnvWf σ) ∧
      envLookup σ x = some vx)
    (upd := upd) ?_ (fun σ hp => Happ σ hp.1.1 hp.1.2 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc, He⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h1b, Hi⟩
    icases interp_env_lookup $$ [$Hi $He] with ⟨%h2, Hi, He⟩
    iframe Hi Hc He
    ipureintro
    exact ⟨⟨h1, h1b⟩, h2⟩
  · intro σ hp
    iintro ⟨Hi, Hc, He⟩
    rw [show c = ctlOf σ from hp.1.1.symm]
    imod interp_ctl_move (hlay σ hp.1.1 hp.1.2 hp.2)
      (hsup σ hp.1.1 hp.1.2 hp.2) (henv σ hp.1.1 hp.1.2 hp.2)
      (fun _ => hwfp σ hp.1.1 hp.1.2 hp.2) $$ [$Hi $Hc] with ⟨Hi, Hc⟩
    imodintro
    rw [hctl' σ hp.1.1 hp.1.2 hp.2]
    iframe Hi Hc He

/-! ## ENV WRITE — the atom rebinds the OWNED cell `x` (full
    fraction); every other cell is preserved by number-apartness and
    rides the frame. The rule whose instances update a local while a
    DIFFERENT local's symbolic assertion survives untouched. -/

@[step_law (kind := stateWP) (variant := envWrite) (side := fed)
  (frontier := "state/env-write")
  (trace := "{law := wpk_seq_env_write, joint := state/env-write, hyps := [Happ : fed, hnew/hpres : fed(number-apartness)]}")
  (lineage := "env-cell update at full fraction; all other cells preserved by number-apartness and framed (gen_heap update shape at the locals view)")]
theorem wpk_seq_env_write [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state} {x : sym} {vOld vNew : value}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ →
      app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ →
      (upd σ).layout_state = σ.layout_state)
    (hsup : ∀ σ, ctlOf σ = c → EnvWf σ →
      suppliesOf (upd σ) = suppliesOf σ)
    (hnew : ∀ σ, ctlOf σ = c → EnvWf σ →
      envLookup (upd σ) x = some vNew)
    (hpres : ∀ σ, ctlOf σ = c → EnvWf σ →
      ∀ y v', symNum y ≠ symNum x →
        envLookup σ y = some v' → envLookup (upd σ) y = some v')
    (hwfp : ∀ σ, ctlOf σ = c → EnvWf σ → EnvWf (upd σ)) :
    (ctlIs (GF := GF) stHalf c ∗ envIs x (.own 1) vOld) ∗
      ((ctlIs stHalf c' ∗ envIs x (.own 1) vNew)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det (Pre := fun σ => ctlOf σ = c ∧ EnvWf σ)
    (upd := upd) ?_ (fun σ hp => Happ σ hp.1 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc, He⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h2, Hi⟩
    iframe Hi Hc He
    ipureintro
    exact ⟨h1, h2⟩
  · intro σ hp
    iintro ⟨Hi, Hc, He⟩
    rw [show c = ctlOf σ from hp.1.symm]
    imod interp_env_write x (hlay σ hp.1 hp.2) (hsup σ hp.1 hp.2)
      (hnew σ hp.1 hp.2) (hpres σ hp.1 hp.2)
      (fun _ => hwfp σ hp.1 hp.2) $$ [$Hi $Hc $He] with ⟨Hi, Hc, He⟩
    imodintro
    rw [hctl' σ hp.1 hp.2]
    iframe Hi Hc He

/-! ## THE TERMINAL READOUT: `nd_get` feeding a pure readout — the
    postcondition holds for EVERY state the control token admits. -/

@[step_law (kind := stateWP) (variant := getDone) (side := fed)
  (frontier := "state/get-done")
  (trace := "{law := wpk_get_done_ctl, joint := state/get-done, hyps := [hpost : fed(ctl-determined readout)]}")
  (lineage := "terminal readout at the control token (the nd_get joint; post holds for every state the token admits)")]
theorem wpk_get_done_ctl [CerbStGS GF]
    {g : driver_state → DriveVal} {c : driver_state}
    {φ : DriveVal → Prop} {s : Stuckness} {E : CoPset}
    (hpost : ∀ σ, ctlOf σ = c → φ (g σ)) :
    ctlIs (GF := GF) stHalf c ⊢
      WP (KExpr.seq nd_get (fun σ => KExpr.done (g σ)) : KDriveExpr)
        @ s ; E {{ o, ⌜φ o⌝ }} := by
  have hrest : ∀ σ : driver_state,
      app (nd_get : ndM driver_state step_kind driver_error
        mem_iv_constraint driver_state) σ = (NDactive σ, σ) :=
    fun σ => rfl
  iintro Hc
  iapply wp_lift_step rfl
  iintro %σ %ns %obs %obs' %nt Hσ
  icases cerbStInterp_eq.1 $$ Hσ with Hσ
  icases interp_ctl_agree $$ [$Hσ $Hc] with ⟨%h1, Hσ, Hc⟩
  iapply fupd_mask_intro Std.LawfulSet.empty_subset
  iintro Hclose
  isplitl []
  · ipureintro
    cases s
    · exact kreducible_of_app_active (hrest σ)
    · trivial
  iintro !> %e₂ %σ₂ %eₜ %Hprim Hcred
  iclear Hcred
  obtain ⟨hd, -, hefs⟩ := kPrimStep_inv Hprim
  have hconf := kstep_seq_active_inv (hrest σ) hd
  injection hconf with he hσ
  subst he; subst hσ; subst hefs
  imod Hclose
  imodintro
  icases cerbStInterp_eq.2 $$ Hσ with Hσ
  iframe Hσ
  simp only [Algebra.BigOpL.bigOpL_nil]
  iframe
  iapply wpk_done
  ipureintro
  exact hpost _ h1

/-! ## LOAD — read-only: any fractions; every resource returns.
    Pins ONLY memory components (the decomposition dividend: control,
    env, supplies all frame across a load). -/

@[step_law (kind := heapWP) (variant := load) (side := ground)
  (frontier := "heap/load")
  (trace := "{law := wpk_load, joint := heap/load, hyps := [pointsToBytes : resource, allocIs : resource, mrestIs : resource, side : ground]}")
  (lineage := "HeapLang PrimitiveLaws wp_load shape at memory-residual granularity: footprint points-to in, unchanged points-to out; control/env/supplies frame")]
theorem wpk_load [CerbStGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {loc : CerbLocation.Loc} {ty : ctype} {aid addr : Int}
    {al : CerbMem.Allocation} {bs : List CerbMem.AbsByte}
    {mv : CerbMem.MemValue} {mr : CerbMem.MemState}
    {dqm dqa dqb : DFrac}
    {k : CerbMem.Footprint × CerbMem.MemValue → KDriveExpr}
    (hbounds : CerbMem.isInBounds al addr
      (CerbMem.sizeofCtype ty) = true)
    (hatomic : CerbMem.isAtomicMemberAccess al ty addr = false)
    (hlen : bs.length = CerbMem.sizeofCtype ty)
    (hrecon : CerbMem.reconstructValue
        mr.lastUsedUnionMembers mr.funptrmap addr ty bs = mv)
    (hnotbool : Kit.isBoolTy ty = false) :
    (mrestIs (GF := GF) dqm mr ∗ allocIs aid dqa al
        ∗ pointsToBytes addr dqb bs) ∗
      ((mrestIs dqm mr ∗ allocIs aid dqa al ∗ pointsToBytes addr dqb bs)
        -∗ WP (k (.FP .R addr (CerbMem.sizeofCtype ty), mv))
              @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.loadM loc ty
          (.PV (.Prov_some aid) (.PVconcrete none addr)))) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbStInterp (GF := GF) σ ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs) : IProp GF) ⊢
      ⌜memRestOf σ = mr ∧
        σ.layout_state.allocations.get? aid = some al ∧
        (∀ i : Nat, (hi : i < bs.length) →
          σ.layout_state.bytemap.get? (addr + (i : Int)) = some bs[i]) ∧
        MemInv σ.layout_state⌝ ∗
      (CerbStInterp σ ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs)) := by
    intro σ
    iintro ⟨Hi, Hr, Ha, Hp⟩
    icases interp_mrest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h2, Hi, Ha⟩
    icases interp_bytes_lookup $$ [$Hi $Hp] with ⟨%h3, Hi, Hp⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr Ha Hp
    ipureintro
    exact ⟨h1, h2, h3, h4⟩
  have Happ : ∀ σ, (memRestOf σ = mr ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < bs.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some bs[i]) ∧
      MemInv σ.layout_state) →
      app (liftMem (CerbMem.loadM loc ty
        (.PV (.Prov_some aid) (.PVconcrete none addr)))) σ
        = (NDactive (.FP .R addr (CerbMem.sizeofCtype ty), mv),
           (fun σ => σ) σ) := by
    intro σ h
    obtain ⟨h1, h2, h3, h4⟩ := h
    have hload := Kit.mem_load_block (loc := loc) (um := none)
      (h4.contains_dead_false h2) h2 hbounds hatomic
      (readBytesFrom_of_pointwise hlen h3)
      (by rw [memRestOf_lastUsedUnionMembers h1,
        memRestOf_funptrmap h1])
      hnotbool
    rw [hrecon] at hload
    unfold liftMem
    exact app_liftND_active _ _ _ _ hload
  have Hupd : ∀ σ, (memRestOf σ = mr ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < bs.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some bs[i]) ∧
      MemInv σ.layout_state) →
      (CerbStInterp (GF := GF) σ ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs) : IProp GF) ⊢
      |==> (CerbStInterp ((fun σ => σ) σ) ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs)) := by
    intro σ _
    show (CerbStInterp (GF := GF) σ ∗ _ : IProp GF) ⊢
      |==> (CerbStInterp σ ∗ _)
    iintro H
    imodintro
    iexact H
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## STORE — scalar path: full-fraction range overwrite; the
    residual is READ (any fraction, serialization side condition)
    and does not move. -/

@[step_law (kind := heapWP) (variant := store) (side := ground)
  (frontier := "heap/store")
  (trace := "{law := wpk_store, joint := heap/store, hyps := [pointsToBytes : resource, allocIs : resource, mrestIs : resource, side : ground]}")
  (lineage := "HeapLang PrimitiveLaws wp_store shape at memory-residual granularity")]
theorem wpk_store [CerbStGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {loc : CerbLocation.Loc} {ty : ctype} {aid addr : Int}
    {al : CerbMem.Allocation} {mv : CerbMem.MemValue}
    {old new : List CerbMem.AbsByte} {mr : CerbMem.MemState}
    {dqm dqa : DFrac} {k : CerbMem.Footprint → KDriveExpr}
    (hcompat : CerbMem.ctypeMemCompatible ty
      (CerbMem.typeofMval mv) = true)
    (hbounds : CerbMem.isInBounds al addr
      (CerbMem.sizeofCtype ty) = true)
    (hro : al.isReadonly = .IsWritable)
    (hatomic : CerbMem.isAtomicMemberAccess al ty addr = false)
    (hbytes : CerbMem.memValueToBytes mr.funptrmap mv
      = (mr.funptrmap, new))
    (hlen : new.length = old.length) :
    (mrestIs (GF := GF) dqm mr ∗ allocIs aid dqa al
        ∗ pointsToBytes addr (.own 1) old) ∗
      ((mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) new)
        -∗ WP (k (.FP .W addr (CerbMem.sizeofCtype ty)))
              @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.storeM loc ty false
          (.PV (.Prov_some aid) (.PVconcrete none addr)) mv)) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbStInterp (GF := GF) σ ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) old) : IProp GF) ⊢
      ⌜memRestOf σ = mr ∧
        σ.layout_state.allocations.get? aid = some al ∧
        (∀ i : Nat, (hi : i < old.length) →
          σ.layout_state.bytemap.get? (addr + (i : Int))
            = some old[i]) ∧
        MemInv σ.layout_state⌝ ∗
      (CerbStInterp σ ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) old)) := by
    intro σ
    iintro ⟨Hi, Hr, Ha, Hp⟩
    icases interp_mrest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h2, Hi, Ha⟩
    icases interp_bytes_lookup $$ [$Hi $Hp] with ⟨%h3, Hi, Hp⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr Ha Hp
    ipureintro
    exact ⟨h1, h2, h3, h4⟩
  have Happ : ∀ σ, (memRestOf σ = mr ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < old.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some old[i]) ∧
      MemInv σ.layout_state) →
      app (liftMem (CerbMem.storeM loc ty false
        (.PV (.Prov_some aid) (.PVconcrete none addr)) mv)) σ
        = (NDactive (.FP .W addr (CerbMem.sizeofCtype ty)),
           (fun σ => { σ with layout_state :=
             (CerbMem.writeBytesTo σ.layout_state addr new) }) σ) := by
    intro σ h
    obtain ⟨h1, h2, h3, h4⟩ := h
    have hb' := hbytes
    rw [← memRestOf_funptrmap h1] at hb'
    have hstore := Kit.mem_store_block (loc := loc)
      hcompat h2 hbounds hro hatomic hb'
    unfold liftMem
    exact app_liftND_active _ _ _ _ hstore
  have Hupd : ∀ σ, (memRestOf σ = mr ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < old.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some old[i]) ∧
      MemInv σ.layout_state) →
      (CerbStInterp (GF := GF) σ ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) old) : IProp GF) ⊢
      |==> (CerbStInterp ((fun σ => { σ with layout_state :=
              (CerbMem.writeBytesTo σ.layout_state addr new) }) σ) ∗
        (mrestIs dqm mr ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) new)) := by
    intro σ h
    obtain ⟨h1, h2, h3, h4⟩ := h
    iintro ⟨Hi, Hr, Ha, Hp⟩
    imod interp_store_update new hlen h3 $$ [$Hi $Hp] with ⟨Hi, Hp⟩
    imodintro
    iframe Hi Hr Ha Hp
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## ALLOCATE — consumes the residual half (the bump counters
    move); control, env, supplies frame. -/

@[step_law (kind := heapWP) (variant := alloc) (side := ground)
  (frontier := "heap/alloc")
  (trace := "{law := wpk_alloc, joint := heap/alloc, hyps := [mrestIs : resource, side : ground]}")
  (lineage := "HeapLang wp_alloc shape: fresh points-to + allocIs minted by the frame-preserving update; only the memory residual consumed")]
theorem wpk_alloc [CerbStGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {tid : Nat} {pref : prefix0} {pvAlign : CerbMem.Provenance}
    {alignN : Int} {ty : ctype} {addrOpt : Option Int}
    {sz : Nat} {a : Int} {mr : CerbMem.MemState}
    {k : CerbMem.PointerValue → KDriveExpr}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (mr.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    mrestIs (GF := GF) stHalf mr ∗
      ((mrestIs stHalf (mrAlloc mr a)
          ∗ allocIs mr.nextAllocId (.own 1)
              { base := a, size := sz, ty := some ty, prefix_ := pref }
          ∗ pointsToBytes a (.own 1)
              (List.replicate sz
                { prov := .Prov_none, copyOffset := none,
                  value := none }))
        -∗ WP (k (.PV (.Prov_some mr.nextAllocId)
              (.PVconcrete none a))) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.allocateObject tid pref
          (.IV pvAlign alignN) ty addrOpt none)) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbStInterp (GF := GF) σ ∗ mrestIs stHalf mr : IProp GF) ⊢
      ⌜memRestOf σ = mr ∧ MemInv σ.layout_state⌝ ∗
      (CerbStInterp σ ∗ mrestIs stHalf mr) := by
    intro σ
    iintro ⟨Hi, Hr⟩
    icases interp_mrest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr
    ipureintro
    exact ⟨h1, h4⟩
  have Happ : ∀ σ, (memRestOf σ = mr ∧ MemInv σ.layout_state) →
      app (liftMem (CerbMem.allocateObject tid pref
        (.IV pvAlign alignN) ty addrOpt none)) σ
        = (NDactive (.PV (.Prov_some mr.nextAllocId)
             (.PVconcrete none a)),
           (fun σ => { σ with layout_state := (CerbMem.writeBytesTo
             ({ σ.layout_state with
               nextAllocId := σ.layout_state.nextAllocId + 1,
               lastAddress := a,
               allocations := σ.layout_state.allocations.insert
                 σ.layout_state.nextAllocId
                 { base := a, size := sz, ty := some ty,
                   prefix_ := pref } })
             a (List.replicate sz
                 { prov := .Prov_none, copyOffset := none,
                   value := none })) }) σ) := by
    intro σ h
    obtain ⟨h1, h4⟩ := h
    have haddrσ : ((CerbMem.alignDown
        (σ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a := by
      rw [memRestOf_lastAddress h1]
      exact haddr
    have halloc := Kit.mem_alloc_block (tid := tid) (pref := pref)
      (pv := pvAlign) (addrOpt := addrOpt) hsz haddrσ hnz
    have hv : (NDactive (CerbMem.PointerValue.PV
          (.Prov_some σ.layout_state.nextAllocId)
          (.PVconcrete none a)) :
            nd_action CerbMem.PointerValue String mem_error
              (mem_constraint CerbMem.IntegerValue) CerbMem.MemState)
        = NDactive (.PV (.Prov_some mr.nextAllocId)
            (.PVconcrete none a)) := by
      rw [memRestOf_nextAllocId h1]
    rw [hv] at halloc
    unfold liftMem
    exact app_liftND_active _ _ _ _ halloc
  have Hupd : ∀ σ, (memRestOf σ = mr ∧ MemInv σ.layout_state) →
      (CerbStInterp (GF := GF) σ ∗ mrestIs stHalf mr : IProp GF) ⊢
      |==> (CerbStInterp ((fun σ => { σ with layout_state :=
              (CerbMem.writeBytesTo
                ({ σ.layout_state with
                  nextAllocId := σ.layout_state.nextAllocId + 1,
                  lastAddress := a,
                  allocations := σ.layout_state.allocations.insert
                    σ.layout_state.nextAllocId
                    { base := a, size := sz, ty := some ty,
                      prefix_ := pref } })
                a (List.replicate sz
                    { prov := .Prov_none, copyOffset := none,
                      value := none })) }) σ) ∗
        (mrestIs stHalf (mrAlloc mr a)
          ∗ allocIs mr.nextAllocId (.own 1)
              { base := a, size := sz, ty := some ty, prefix_ := pref }
          ∗ pointsToBytes a (.own 1)
              (List.replicate sz
                { prov := .Prov_none, copyOffset := none,
                  value := none }))) := by
    intro σ h
    obtain ⟨h1, h4⟩ := h
    have haddrσ : ((CerbMem.alignDown
        (σ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a := by
      rw [memRestOf_lastAddress h1]
      exact haddr
    rw [← memRestOf_nextAllocId h1]
    exact interp_alloc_update h1 hsz haddrσ hnz
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## KILL — consumes the full allocation fragment and the residual
    half; the byte points-to stays as dead capital. -/

@[step_law (kind := heapWP) (variant := kill) (side := ground)
  (frontier := "heap/kill")
  (trace := "{law := wpk_kill, joint := heap/kill, hyps := [mrestIs : resource, allocIs : resource, side : ground]}")
  (lineage := "HeapLang wp_free shape: consume the footprint resources at deallocation")]
theorem wpk_kill [CerbStGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {loc : CerbLocation.Loc} {aid addr : Int}
    {al : CerbMem.Allocation} {um : Option identifier}
    {mr : CerbMem.MemState} {k : Unit → KDriveExpr}
    (hbase : (addr != al.base) = false) :
    (mrestIs (GF := GF) stHalf mr ∗ allocIs aid (.own 1) al) ∗
      (mrestIs stHalf (mrKill mr aid)
        -∗ WP (k ()) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.killM loc false
          (.PV (.Prov_some aid) (.PVconcrete um addr)))) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbStInterp (GF := GF) σ ∗
        (mrestIs stHalf mr ∗ allocIs aid (.own 1) al) : IProp GF) ⊢
      ⌜memRestOf σ = mr ∧
        σ.layout_state.allocations.get? aid = some al ∧
        MemInv σ.layout_state⌝ ∗
      (CerbStInterp σ ∗
        (mrestIs stHalf mr ∗ allocIs aid (.own 1) al)) := by
    intro σ
    iintro ⟨Hi, Hr, Ha⟩
    icases interp_mrest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h2, Hi, Ha⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr Ha
    ipureintro
    exact ⟨h1, h2, h4⟩
  have Happ : ∀ σ, (memRestOf σ = mr ∧
      σ.layout_state.allocations.get? aid = some al ∧
      MemInv σ.layout_state) →
      app (liftMem (CerbMem.killM loc false
        (.PV (.Prov_some aid) (.PVconcrete um addr)))) σ
        = (NDactive (),
           (fun σ => { σ with layout_state :=
             { σ.layout_state with
               deadAllocations :=
                 aid :: σ.layout_state.deadAllocations,
               allocations :=
                 σ.layout_state.allocations.erase aid } }) σ) := by
    intro σ h
    obtain ⟨h1, h2, h4⟩ := h
    have hkill := Kit.mem_kill_block (loc := loc) (um := um)
      (h4.contains_dead_false h2) h2 hbase
    unfold liftMem
    exact app_liftND_active _ _ _ _ hkill
  have Hupd : ∀ σ, (memRestOf σ = mr ∧
      σ.layout_state.allocations.get? aid = some al ∧
      MemInv σ.layout_state) →
      (CerbStInterp (GF := GF) σ ∗
        (mrestIs stHalf mr ∗ allocIs aid (.own 1) al) : IProp GF) ⊢
      |==> (CerbStInterp ((fun σ => { σ with layout_state :=
              { σ.layout_state with
                deadAllocations :=
                  aid :: σ.layout_state.deadAllocations,
                allocations :=
                  σ.layout_state.allocations.erase aid } }) σ) ∗
        mrestIs stHalf (mrKill mr aid)) := by
    intro σ h
    obtain ⟨h1, h2, h4⟩ := h
    iintro ⟨Hi, Hr, Ha⟩
    imod interp_kill_update h1 $$ [$Hi $Hr $Ha] with ⟨Hi, Hr⟩
    imodintro
    iframe Hi Hr
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## The registry-backing check (the R4 contract, re-homed from the
    retired CerbHeapWalk): every law the PerStepTactics op-rule macros
    apply must be REGISTERED — a law silently leaving the registry is
    build-fatal. -/
open Lean in
#eval show Lean.Elab.Term.TermElabM Unit from do
  let backing : List Name :=
    [``RelSem.CerbSt.wpk_load, ``RelSem.CerbSt.wpk_store,
     ``RelSem.CerbSt.wpk_alloc, ``RelSem.CerbSt.wpk_kill,
     ``RelSem.CerbSt.wpk_seq_ctl, ``RelSem.CerbSt.wpk_seq_ctl_env1,
     ``RelSem.CerbSt.wpk_seq_env_write,
     ``RelSem.CerbSt.wpk_get_done_ctl]
  for n in backing do
    let some _ ← RelSem.LawRegistry.byName? n
      | throwError "CerbStateWP registry-backing check: the op/state           rule {n} is NOT registered — the tactic layer may only           apply registered laws (R4)"
  Lean.logInfo s!"CerbStateWP registry-backing check:     {backing.length} macro-backing laws registered"

end CerbSt
end RelSem
