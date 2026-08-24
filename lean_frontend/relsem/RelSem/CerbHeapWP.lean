/-
  RelSem.CerbHeapWP — arc-16 S2 (2026-08-24): THE RESOURCE-LEVEL WP
  RULES for the four CerbMem operations, over the per-step language
  (S1) under the heap interpretation (CerbHeapRA). Design record:
  docs/2026-08-24_arc16-s2-cerbmem-heap-ra.md §2.3 layer 2.

  Shape: ONE lifting skeleton (`wpk_seq_res_det`, proved from the
  generic `wp_lift_step` — the HeapLang primitive-law factoring:
  lineage wp_lift_atomic_step, nothing novel), then one rule per op.
  Each rule consumes FOOTPRINT resources only (restIs/allocIs/
  pointsToBytes); the physical evaluation enters through the arc-9
  law table (RelSem.Kit.Mem blocks — REUSED) composed with the
  committed lens equations (`app_liftND_active`), with the value-level
  side conditions (readback, serialization, bounds) as PURE
  hypotheses — kernel-computable per instance, the Caesium
  abst/mem_cast layering.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.CerbHeapRA

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.BI Iris.ProgramLogic

variable {GF : BundledGFunctors}

/-! ## Plumbing -/

/-- The interpretation, index-erased (HeapLang's `stateInterp_split`
    move; `.rfl` because our instance ignores ns/obs/nt). -/
theorem cerbStateInterp_eq [CerbHeapGS GF] {σ : driver_state}
    {ns : Nat} {obs : List Empty} {nt : Nat} :
    (stateInterp σ ns obs nt : IProp GF) ⊣⊢ CerbMemInterp σ := .rfl

/-- Transport of rest-projection components (all `rfl` after subst:
    `memRest` touches only the two heap maps). -/
theorem restOf_funptrmap {σ r : driver_state} (h : restOf σ = r) :
    σ.layout_state.funptrmap = r.layout_state.funptrmap := by
  subst h; rfl

theorem restOf_lastUsedUnionMembers {σ r : driver_state}
    (h : restOf σ = r) :
    σ.layout_state.lastUsedUnionMembers
      = r.layout_state.lastUsedUnionMembers := by
  subst h; rfl

theorem restOf_lastAddress {σ r : driver_state} (h : restOf σ = r) :
    σ.layout_state.lastAddress = r.layout_state.lastAddress := by
  subst h; rfl

theorem restOf_nextAllocId {σ r : driver_state} (h : restOf σ = r) :
    σ.layout_state.nextAllocId = r.layout_state.nextAllocId := by
  subst h; rfl

/-- The r-side image of `restAlloc` (what the alloc rule's client
    sees; σ-independent). -/
def restAllocR (r : driver_state) (a : Int) : driver_state :=
  { r with layout_state :=
      { r.layout_state with
        nextAllocId := r.layout_state.nextAllocId + 1,
        lastAddress := a } }

theorem restAlloc_eq {σ r : driver_state} (h : restOf σ = r) (a : Int) :
    restAlloc σ a = restAllocR r a := by
  subst h; rfl

/-- The r-side image of `restKill`. -/
def restKillR (r : driver_state) (aid : Int) : driver_state :=
  { r with layout_state :=
      { r.layout_state with
        deadAllocations := aid :: r.layout_state.deadAllocations } }

theorem restKill_eq {σ r : driver_state} (h : restOf σ = r)
    (aid : Int) :
    restKill σ aid = restKillR r aid := by
  subst h; rfl

/-! ## The lifting skeleton -/

/-- Resource-conditioned deterministic step: if the resources `R` pin
    enough of the physical state (`Pre`) to determine the leading
    atom's one `app` step, WP of the `seq` follows from WP of the
    continuation under the updated resources `R'`. Proved ONCE from
    the generic `wp_lift_step`; the four op rules instantiate it. -/
theorem wpk_seq_res_det [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {R R' : IProp GF} {Pre : driver_state → Prop}
    {Φ : DriveVal → IProp GF} {s : Stuckness} {E : CoPset}
    (Hext : ∀ σ, (CerbMemInterp (GF := GF) σ ∗ R : IProp GF) ⊢
      ⌜Pre σ⌝ ∗ (CerbMemInterp σ ∗ R))
    (Happ : ∀ σ, Pre σ → app m σ = (NDactive v, upd σ))
    (Hupd : ∀ σ, Pre σ → (CerbMemInterp (GF := GF) σ ∗ R : IProp GF) ⊢
      |==> (CerbMemInterp (upd σ) ∗ R')) :
    R ∗ (R' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  iintro ⟨HR, Hcont⟩
  iapply wp_lift_step rfl
  iintro %σ %ns %obs %obs' %nt Hσ
  icases cerbStateInterp_eq.1 $$ Hσ with Hσ
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
  icases cerbStateInterp_eq.2 $$ Hσ' with Hσ'
  iframe Hσ'
  simp only [Algebra.BigOpL.bigOpL_nil]
  iframe
  iapply Hcont $$ HR'

/-! ## LOAD — read-only: any fractions; every resource returns. -/

theorem wpk_load [CerbHeapGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {loc : CerbLocation.Loc} {ty : ctype} {aid addr : Int}
    {al : CerbMem.Allocation} {bs : List CerbMem.AbsByte}
    {mv : CerbMem.MemValue} {r : driver_state}
    {dqr dqa dqb : DFrac}
    {k : CerbMem.Footprint × CerbMem.MemValue → KDriveExpr}
    (hbounds : CerbMem.isInBounds al addr
      (CerbMem.sizeofCtype ty) = true)
    (hatomic : CerbMem.isAtomicMemberAccess al ty addr = false)
    (hlen : bs.length = CerbMem.sizeofCtype ty)
    (hrecon : CerbMem.reconstructValue
        r.layout_state.lastUsedUnionMembers r.layout_state.funptrmap
        addr ty bs = mv)
    (hnotbool : Kit.isBoolTy ty = false) :
    (restIs (GF := GF) dqr r ∗ allocIs aid dqa al
        ∗ pointsToBytes addr dqb bs) ∗
      ((restIs dqr r ∗ allocIs aid dqa al ∗ pointsToBytes addr dqb bs)
        -∗ WP (k (.FP .R addr (CerbMem.sizeofCtype ty), mv))
              @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.loadM loc ty
          (.PV (.Prov_some aid) (.PVconcrete none addr)))) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbMemInterp (GF := GF) σ ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs) : IProp GF) ⊢
      ⌜restOf σ = r ∧
        σ.layout_state.allocations.get? aid = some al ∧
        (∀ i : Nat, (hi : i < bs.length) →
          σ.layout_state.bytemap.get? (addr + (i : Int)) = some bs[i]) ∧
        MemInv σ.layout_state⌝ ∗
      (CerbMemInterp σ ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs)) := by
    intro σ
    iintro ⟨Hi, Hr, Ha, Hp⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h2, Hi, Ha⟩
    icases interp_bytes_lookup $$ [$Hi $Hp] with ⟨%h3, Hi, Hp⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr Ha Hp
    ipureintro
    exact ⟨h1, h2, h3, h4⟩
  have Happ : ∀ σ, (restOf σ = r ∧
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
      (by rw [restOf_lastUsedUnionMembers h1, restOf_funptrmap h1])
      hnotbool
    rw [hrecon] at hload
    unfold liftMem
    exact app_liftND_active _ _ _ _ hload
  have Hupd : ∀ σ, (restOf σ = r ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < bs.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some bs[i]) ∧
      MemInv σ.layout_state) →
      (CerbMemInterp (GF := GF) σ ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs) : IProp GF) ⊢
      |==> (CerbMemInterp ((fun σ => σ) σ) ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs)) := by
    intro σ _
    show (CerbMemInterp (GF := GF) σ ∗ _ : IProp GF) ⊢
      |==> (CerbMemInterp σ ∗ _)
    iintro H
    imodintro
    iexact H
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## STORE — scalar path (non-union pointer, non-locking,
    serialization leaves the funptrmap unchanged): full-fraction
    range overwrite. -/

theorem wpk_store [CerbHeapGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {loc : CerbLocation.Loc} {ty : ctype} {aid addr : Int}
    {al : CerbMem.Allocation} {mv : CerbMem.MemValue}
    {old new : List CerbMem.AbsByte} {r : driver_state}
    {dqr dqa : DFrac} {k : CerbMem.Footprint → KDriveExpr}
    (hcompat : CerbMem.ctypeMemCompatible ty
      (CerbMem.typeofMval mv) = true)
    (hbounds : CerbMem.isInBounds al addr
      (CerbMem.sizeofCtype ty) = true)
    (hro : al.isReadonly = .IsWritable)
    (hatomic : CerbMem.isAtomicMemberAccess al ty addr = false)
    (hbytes : CerbMem.memValueToBytes r.layout_state.funptrmap mv
      = (r.layout_state.funptrmap, new))
    (hlen : new.length = old.length) :
    (restIs (GF := GF) dqr r ∗ allocIs aid dqa al
        ∗ pointsToBytes addr (.own 1) old) ∗
      ((restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) new)
        -∗ WP (k (.FP .W addr (CerbMem.sizeofCtype ty)))
              @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.storeM loc ty false
          (.PV (.Prov_some aid) (.PVconcrete none addr)) mv)) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbMemInterp (GF := GF) σ ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) old) : IProp GF) ⊢
      ⌜restOf σ = r ∧
        σ.layout_state.allocations.get? aid = some al ∧
        (∀ i : Nat, (hi : i < old.length) →
          σ.layout_state.bytemap.get? (addr + (i : Int))
            = some old[i]) ∧
        MemInv σ.layout_state⌝ ∗
      (CerbMemInterp σ ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) old)) := by
    intro σ
    iintro ⟨Hi, Hr, Ha, Hp⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h2, Hi, Ha⟩
    icases interp_bytes_lookup $$ [$Hi $Hp] with ⟨%h3, Hi, Hp⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr Ha Hp
    ipureintro
    exact ⟨h1, h2, h3, h4⟩
  have Happ : ∀ σ, (restOf σ = r ∧
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
    rw [← restOf_funptrmap h1] at hb'
    have hstore := Kit.mem_store_block (loc := loc)
      hcompat h2 hbounds hro hatomic hb'
    unfold liftMem
    exact app_liftND_active _ _ _ _ hstore
  have Hupd : ∀ σ, (restOf σ = r ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < old.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some old[i]) ∧
      MemInv σ.layout_state) →
      (CerbMemInterp (GF := GF) σ ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) old) : IProp GF) ⊢
      |==> (CerbMemInterp ((fun σ => { σ with layout_state :=
              (CerbMem.writeBytesTo σ.layout_state addr new) }) σ) ∗
        (restIs dqr r ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) new)) := by
    intro σ h
    obtain ⟨h1, h2, h3, h4⟩ := h
    iintro ⟨Hi, Hr, Ha, Hp⟩
    imod interp_store_update new hlen h3 $$ [$Hi $Hp] with ⟨Hi, Hp⟩
    imodintro
    iframe Hi Hr Ha Hp
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## ALLOCATE — fresh object, uninitialized path: consumes the rest
    half (the bump counters move), mints the allocation fragment and
    the range points-to at the model's deterministic address. -/

theorem wpk_alloc [CerbHeapGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {tid : Nat} {pref : prefix0} {pvAlign : CerbMem.Provenance}
    {alignN : Int} {ty : ctype} {addrOpt : Option Int}
    {sz : Nat} {a : Int} {r : driver_state}
    {k : CerbMem.PointerValue → KDriveExpr}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (r.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    restIs (GF := GF) restHalf r ∗
      ((restIs restHalf (restAllocR r a)
          ∗ allocIs r.layout_state.nextAllocId (.own 1)
              { base := a, size := sz, ty := some ty, prefix_ := pref }
          ∗ pointsToBytes a (.own 1)
              (List.replicate sz
                { prov := .Prov_none, copyOffset := none,
                  value := none }))
        -∗ WP (k (.PV (.Prov_some r.layout_state.nextAllocId)
              (.PVconcrete none a))) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.allocateObject tid pref
          (.IV pvAlign alignN) ty addrOpt none)) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbMemInterp (GF := GF) σ ∗ restIs restHalf r : IProp GF) ⊢
      ⌜restOf σ = r ∧ MemInv σ.layout_state⌝ ∗
      (CerbMemInterp σ ∗ restIs restHalf r) := by
    intro σ
    iintro ⟨Hi, Hr⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr
    ipureintro
    exact ⟨h1, h4⟩
  have Happ : ∀ σ, (restOf σ = r ∧ MemInv σ.layout_state) →
      app (liftMem (CerbMem.allocateObject tid pref
        (.IV pvAlign alignN) ty addrOpt none)) σ
        = (NDactive (.PV (.Prov_some r.layout_state.nextAllocId)
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
      rw [restOf_lastAddress h1]
      exact haddr
    have halloc := Kit.mem_alloc_block (tid := tid) (pref := pref)
      (pv := pvAlign) (addrOpt := addrOpt) hsz haddrσ hnz
    have hv : (NDactive (CerbMem.PointerValue.PV
          (.Prov_some σ.layout_state.nextAllocId)
          (.PVconcrete none a)) :
            nd_action CerbMem.PointerValue String mem_error
              (mem_constraint CerbMem.IntegerValue) CerbMem.MemState)
        = NDactive (.PV (.Prov_some r.layout_state.nextAllocId)
            (.PVconcrete none a)) := by
      rw [restOf_nextAllocId h1]
    rw [hv] at halloc
    unfold liftMem
    exact app_liftND_active _ _ _ _ halloc
  have Hupd : ∀ σ, (restOf σ = r ∧ MemInv σ.layout_state) →
      (CerbMemInterp (GF := GF) σ ∗ restIs restHalf r : IProp GF) ⊢
      |==> (CerbMemInterp ((fun σ => { σ with layout_state :=
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
        (restIs restHalf (restAllocR r a)
          ∗ allocIs r.layout_state.nextAllocId (.own 1)
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
      rw [restOf_lastAddress h1]
      exact haddr
    rw [← restAlloc_eq h1 a, ← restOf_nextAllocId h1]
    exact interp_alloc_update haddrσ hnz (hsz := hsz)
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## KILL — non-dynamic path: consumes the full allocation fragment
    (the freeable token) and the rest half; the byte points-to stays
    with the prover as dead capital (study deviation D2). -/

theorem wpk_kill [CerbHeapGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    {loc : CerbLocation.Loc} {aid addr : Int}
    {al : CerbMem.Allocation} {um : Option identifier}
    {r : driver_state} {k : Unit → KDriveExpr}
    (hbase : (addr != al.base) = false) :
    (restIs (GF := GF) restHalf r ∗ allocIs aid (.own 1) al) ∗
      (restIs restHalf (restKillR r aid)
        -∗ WP (k ()) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.killM loc false
          (.PV (.Prov_some aid) (.PVconcrete um addr)))) k
        : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hext : ∀ σ,
      (CerbMemInterp (GF := GF) σ ∗
        (restIs restHalf r ∗ allocIs aid (.own 1) al) : IProp GF) ⊢
      ⌜restOf σ = r ∧
        σ.layout_state.allocations.get? aid = some al ∧
        MemInv σ.layout_state⌝ ∗
      (CerbMemInterp σ ∗
        (restIs restHalf r ∗ allocIs aid (.own 1) al)) := by
    intro σ
    iintro ⟨Hi, Hr, Ha⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h2, Hi, Ha⟩
    icases interp_meminv $$ Hi with ⟨%h4, Hi⟩
    iframe Hi Hr Ha
    ipureintro
    exact ⟨h1, h2, h4⟩
  have Happ : ∀ σ, (restOf σ = r ∧
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
  have Hupd : ∀ σ, (restOf σ = r ∧
      σ.layout_state.allocations.get? aid = some al ∧
      MemInv σ.layout_state) →
      (CerbMemInterp (GF := GF) σ ∗
        (restIs restHalf r ∗ allocIs aid (.own 1) al) : IProp GF) ⊢
      |==> (CerbMemInterp ((fun σ => { σ with layout_state :=
              { σ.layout_state with
                deadAllocations :=
                  aid :: σ.layout_state.deadAllocations,
                allocations :=
                  σ.layout_state.allocations.erase aid } }) σ) ∗
        restIs restHalf (restKillR r aid)) := by
    intro σ h
    obtain ⟨h1, h2, h4⟩ := h
    rw [← restKill_eq h1 aid]
    exact interp_kill_update
  exact wpk_seq_res_det Hext Happ Hupd

/-! ## Adequacy (the plumbing face: the authoritative maps appear
    here and in the interpretation only — never in client rules) -/

/-- Heap-interpretation adequacy: allocate the three ghost components
    from the initial physical state (the `heap_adequacy` template),
    hand the client the initial FOOTPRINT (big-ops over the initial
    maps + the rest half), conclude `adequate`. -/
theorem cerbHeap_adequacy [CerbHeapGpreS GF] (e : KDriveExpr)
    (σ : driver_state) (φ : DriveVal → Prop)
    (hinv : MemInv σ.layout_state)
    (Hwp : ∀ [CerbHeapGS GF],
      (iprop(([∗map] a ↦ b ∈ bytesOf σ.layout_state, (a ↦ b)) ∗
        ([∗map] aid ↦ al ∈ allocsOf σ.layout_state,
          allocIs aid (.own 1) al) ∗
        restIs restHalf (restOf σ)) : IProp GF) ⊢
        WP e @ Stuckness.NotStuck ; ⊤ {{ v, ⌜φ v⌝ }}) :
    adequate Stuckness.NotStuck e σ (fun v _ => φ v) := by
  refine wp_adequacy (GF := GF) Stuckness.NotStuck e σ φ @fun iinv κs => ?_
  imod (genHeap_init (H := CerbHeapF) (bytesOf σ.layout_state))
    with ⟨%Gb, Hbi, Hbp, -⟩
  imod (ghost_map_alloc (H := CerbHeapF) (allocsOf σ.layout_state))
    with ⟨%γa, Hai, Hap⟩
  imod (ghost_var_alloc (GF := GF) (restOf σ)) with ⟨%γr, Hr⟩
  have hsplit := ghost_var_split (GF := GF) γr (restOf σ)
    (1 : Qp).half (1 : Qp).half
  rw [Qp.half_add_half] at hsplit
  icases hsplit $$ Hr with ⟨Hr1, Hr2⟩
  imodintro
  iexists (fun σ' _ => iprop(
    genHeapInterp (G := Gb) (bytesOf σ'.layout_state) ∗
    (γa ↪●MAP allocsOf σ'.layout_state) ∗
    (γr ↪VAR{restHalf} restOf σ') ∗
    ⌜MemInv σ'.layout_state⌝)), (fun _ => iprop(True))
  have hconvB : (iprop([∗map] a ↦ b ∈ bytesOf σ.layout_state,
        (pointsTo (G := Gb) a (.own 1) b)) : IProp GF)
      = iprop([∗map] a ↦ b ∈ bytesOf σ.layout_state,
          (pointsTo (G := CerbHeapGS.bytes
            (self := ⟨Gb, γa, γr⟩)) a (.own 1) b)) := rfl
  have hconvA : (iprop([∗map] k ↦ v ∈ allocsOf σ.layout_state,
        (γa ↪◯MAP[k] v)) : IProp GF)
      = iprop([∗map] aid ↦ al ∈ allocsOf σ.layout_state,
          @allocIs GF ⟨Gb, γa, γr⟩ aid (.own 1) al) := rfl
  have hconvR : ((γr ↪VAR{restHalf} restOf σ) : IProp GF)
      = @restIs GF ⟨Gb, γa, γr⟩ restHalf (restOf σ) := rfl
  icases hconvB $$ Hbp with Hbp
  icases hconvA $$ Hap with Hap
  icases hconvR $$ Hr2 with Hr2
  ihave Hwpres := @Hwp ⟨Gb, γa, γr⟩ $$ [$Hbp $Hap $Hr2]
  simp only []
  isplitr [Hwpres]
  · iframe Hbi Hai Hr1
    ipureintro
    exact hinv
  · iapply Hwpres

/-- The statement-facing bridge (mirror of S1's `kAdequate_of_wp` on
    the heap route): WP under footprint resources ⇒ every
    production-runner outcome of the denoted program satisfies the
    postcondition. -/
theorem kAdequateHeap_of_wp [CerbHeapGpreS GF] (e : KDriveExpr)
    (σ : driver_state) (φ : DriveVal → Prop)
    (hinv : MemInv σ.layout_state)
    (Hwp : ∀ [CerbHeapGS GF],
      (iprop(([∗map] a ↦ b ∈ bytesOf σ.layout_state, (a ↦ b)) ∗
        ([∗map] aid ↦ al ∈ allocsOf σ.layout_state,
          allocIs aid (.own 1) al) ∗
        restIs restHalf (restOf σ)) : IProp GF) ⊢
        WP e @ Stuckness.NotStuck ; ⊤ {{ v, ⌜φ v⌝ }}) :
    ∀ (out : nd_status driver_result driver_error driver_state)
      (tr : List String) (σ' : driver_state),
      (out, tr, σ') ∈ CerbND.runND e.denote σ →
      φ (Outcome.ofStatus out) := by
  have Had := cerbHeap_adequacy e σ φ hinv Hwp
  intro out tr σ' hmem
  exact Had.adequate_result [] σ' (Outcome.ofStatus out)
    (ksteps_erased (ksteps_of_runND hmem))

end Cerb
end RelSem
