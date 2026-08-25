/-
  RelSem.CerbHeapWalk — arc-18 C2 (2026-08-25): THE HEAP-ROUTE WALK
  SUBSTRATE — the rules and adequacy bridges that let the threaded
  harness walks run over `CerbMemInterp` (the ONE state
  interpretation, charter Q2 FULL) instead of whole-state OwnP.

  THE STRUCTURAL POINT (why the walks change shape at all): under a
  footprint interpretation there is deliberately NO resource that
  pins the whole physical state — an `app` equation at one closed σ
  is unusable; every step must be characterized by what the prover's
  resources actually pin (the rest cell + footprint points-to /
  allocation fragments). The walks' equation supply therefore moves
  to OPEN-MEMORY form: per-stage equations `∀ bm am, app m
  (setMaps ρ bm am) = (NDactive v, setMaps ρ' bm am)` (memory maps
  free, rest concrete), with memory reads entering as pointwise
  footprint hypotheses. Measured feasibility (C2 probes): pure driver
  rounds and harness stages close by the SAME `rfl` at fully open
  maps; load rounds route through `Kit.mem_load_block` + pointwise
  facts — the generated code never forces the maps except through
  the memory lens.

  The rule set (each an instance of the S2 lifting skeleton
  `wpk_seq_res_det`; lineage: HeapLang PrimitiveLaws — one rule per
  footprint shape, the frame carrying everything else implicitly):

  * `wpk_seq_rest`  — rest-only step: the atom neither reads nor
    writes the heap maps; consumes/returns the rest half. EVERY byte
    and allocation fragment in the context rides the frame.
  * `wpk_seq_read1` — read step: the atom reads ONE allocation record
    + ONE byte range (any fractions), rest may move; the footprint
    returns unchanged. Everything else — other objects' points-to —
    rides the frame (the framing dividend, visible per step).
  * `wpk_get_done_pure` — the harness terminal (`nd_get` feeding the
    pure readout): the postcondition holds for EVERY state the rest
    half admits.
  * `wpk_arg_object` — the caller-protocol alloc+store compound (the
    `injectArgs`/errno object-creation shape): consumes the rest
    half, MINTS `allocIs` + `pointsToBytes` for the new object (the
    frame-preserving update at allocation — "double allocation is
    unconstructible", the SL can't-happen pattern).

  Adequacy: `kCallHarnessAdequateThrHeap_of_wp` — the threaded faces
  discharged through `kAdequateHeap_of_wp` (S2); the initial physical
  maps are EMPTY, so the client hypothesis is exactly the rest half
  of the initial state (the whole-state big-sep collapses to emp —
  the HeapLang `heap_adequacy` precedent at an empty initial heap).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.CerbHeapWP
import RelSem.Threaded

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.BI Iris.ProgramLogic

/-! ## The rest-patch algebra (pure) -/

/-- A rest-shaped state with the two heap maps spliced in. The walks'
    open-memory equations are stated at this decomposition. -/
def setMaps (ρ : driver_state) (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : driver_state :=
  { ρ with layout_state :=
      { ρ.layout_state with bytemap := bm, allocations := am } }

/-- The successor state a rest-patch step produces: the target rest
    with the CURRENT physical heap maps carried through. -/
def patchRest (σ ρ' : driver_state) : driver_state :=
  { ρ' with layout_state := σ.layout_state }

/-- Any state decomposes as its rest image with its own maps spliced
    in (structure eta, definitional). -/
theorem restOf_decompose {σ ρ : driver_state} (h : restOf σ = ρ) :
    σ = setMaps ρ σ.layout_state.bytemap σ.layout_state.allocations := by
  subst h; rfl

/-- The ∃-form of the decomposition (fresh map variables — the form
    `obtain ⟨bm, am, rfl⟩` consumes). -/
theorem exists_setMaps_of_restOf {σ ρ : driver_state}
    (h : restOf σ = ρ) :
    ∃ bm am, σ = setMaps ρ bm am :=
  ⟨σ.layout_state.bytemap, σ.layout_state.allocations,
   restOf_decompose h⟩

/-- Patching a decomposed state to a layout-compatible rest re-splices
    the same maps. -/
theorem patchRest_setMaps {ρ ρ' : driver_state}
    (hlay : ρ'.layout_state = ρ.layout_state)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    patchRest (setMaps ρ bm am) ρ' = setMaps ρ' bm am := by
  unfold patchRest setMaps
  rw [hlay]

/-- The rest image of a rest-patched state is the target rest. -/
theorem restOf_patchRest {σ ρ ρ' : driver_state}
    (h : restOf σ = ρ) (hlay : ρ'.layout_state = ρ.layout_state) :
    restOf (patchRest σ ρ') = ρ' := by
  have hm : memRest σ.layout_state = ρ'.layout_state := by
    rw [hlay, ← h]; rfl
  show { ρ' with layout_state := memRest σ.layout_state } = ρ'
  rw [hm]

/-! ## The happ adapters: open-memory equations → footprint-conditioned
    step characterizations -/

/-- Rest-only adapter: a stage equation at open maps characterizes the
    atom at EVERY state the rest half admits. -/
theorem happ_rest_of_open {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {v : α} {ρ ρ' : driver_state}
    (hlay : ρ'.layout_state = ρ.layout_state)
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, setMaps ρ' bm am)) :
    ∀ σ, restOf σ = ρ → app m σ = (NDactive v, patchRest σ ρ') := by
  intro σ hr
  obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hr
  rw [patchRest_setMaps hlay]
  exact h bm am

/-- One-object read adapter: an equation at open maps under one
    allocation lookup + one pointwise byte range characterizes the
    atom at every state the rest half + that footprint admit. -/
theorem happ_read1_of_open {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {v : α} {ρ ρ' : driver_state} {aid addr : Int}
    {al : CerbMem.Allocation} {bs : List CerbMem.AbsByte}
    (hlay : ρ'.layout_state = ρ.layout_state)
    (h : ∀ bm am, am.get? aid = some al →
        (∀ i : Nat, (hi : i < bs.length) →
          bm.get? (addr + (i : Int)) = some bs[i]) →
        app m (setMaps ρ bm am) = (NDactive v, setMaps ρ' bm am)) :
    ∀ σ, restOf σ = ρ →
      σ.layout_state.allocations.get? aid = some al →
      (∀ i : Nat, (hi : i < bs.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some bs[i]) →
      app m σ = (NDactive v, patchRest σ ρ') := by
  intro σ hr hget hb
  obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hr
  rw [patchRest_setMaps hlay]
  exact h bm am hget hb

/-! ## The walk rules -/

variable {GF : BundledGFunctors}

/-- REST-ONLY STEP: the atom is characterized by the rest alone and
    carries the heap maps through untouched. The prover's byte and
    allocation fragments — ALL of them — ride the frame. -/
theorem wpk_seq_rest [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hlay : ρ'.layout_state = ρ.layout_state)
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, setMaps ρ' bm am)) :
    restIs (GF := GF) restHalf ρ ∗
      (restIs restHalf ρ' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  have Happ := happ_rest_of_open hlay h
  refine wpk_seq_res_det (Pre := fun σ => restOf σ = ρ)
    (upd := fun σ => patchRest σ ρ') ?_ (fun σ hp => Happ σ hp) ?_
  · intro σ
    iintro ⟨Hi, Hr⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    iframe Hi Hr
    ipureintro
    exact h1
  · intro σ hp
    rw [CerbMemInterp_congr (σ' := patchRest σ ρ')
      (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
      (R := ρ') rfl rfl (restOf_patchRest hp hlay)]
    unfold CerbMemInterp restIs
    iintro ⟨⟨Hb, Ha, Hri, %Hinv⟩, Hrp⟩
    imod ghost_var_update_halves ρ' _ _ _ $$ Hri Hrp with ⟨Hri, Hrp⟩
    imodintro
    iframe Hb Ha Hri Hrp
    ipureintro
    exact Hinv

/-- `wpk_seq_rest` with the goal expression given up to a definitional
    cast (the tactic-facing ecast hook, as `wpk_seq_active_ecast`). -/
theorem wpk_seq_rest_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, setMaps ρ' bm am))
    (he : e0 = KExpr.seq m k)
    (hlay : ρ'.layout_state = ρ.layout_state) :
    restIs (GF := GF) restHalf ρ ∗
      (restIs restHalf ρ' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_rest hlay h

/-- ONE-OBJECT READ STEP: the atom reads exactly one allocation record
    and one byte range (any fractions — reads never need full
    ownership); the rest may move; the read footprint returns
    unchanged. Every OTHER object's fragments ride the frame — this
    is the rule whose instances make the framing dividend visible in
    the walks (e.g. T1's whole driver-loop step reads only the
    argument object; the errno object frames). -/
theorem wpk_seq_read1 [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aid addr : Int} {al : CerbMem.Allocation}
    {bs : List CerbMem.AbsByte} {dqa dqb : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hlay : ρ'.layout_state = ρ.layout_state)
    (h : ∀ bm am, am.get? aid = some al →
        (∀ i : Nat, (hi : i < bs.length) →
          bm.get? (addr + (i : Int)) = some bs[i]) →
        app m (setMaps ρ bm am) = (NDactive v, setMaps ρ' bm am)) :
    (restIs (GF := GF) restHalf ρ ∗ allocIs aid dqa al
        ∗ pointsToBytes addr dqb bs) ∗
      ((restIs restHalf ρ' ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  have Happ := happ_read1_of_open hlay h
  refine wpk_seq_res_det
    (R := iprop(restIs restHalf ρ ∗ allocIs aid dqa al
      ∗ pointsToBytes addr dqb bs))
    (R' := iprop(restIs restHalf ρ' ∗ allocIs aid dqa al
      ∗ pointsToBytes addr dqb bs))
    (Pre := fun σ => restOf σ = ρ ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < bs.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some bs[i]))
    (upd := fun σ => patchRest σ ρ')
    ?_ (fun σ hp => Happ σ hp.1 hp.2.1 hp.2.2) ?_
  · intro σ
    iintro ⟨Hi, Hr, Ha, Hp⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h2, Hi, Ha⟩
    icases interp_bytes_lookup $$ [$Hi $Hp] with ⟨%h3, Hi, Hp⟩
    iframe Hi Hr Ha Hp
    ipureintro
    exact ⟨h1, h2, h3⟩
  · intro σ hp
    rw [CerbMemInterp_congr (σ' := patchRest σ ρ')
      (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
      (R := ρ') rfl rfl (restOf_patchRest hp.1 hlay)]
    unfold CerbMemInterp restIs
    iintro ⟨⟨Hb, Ha, Hri, %Hinv⟩, Hrp, Hal, Hpt⟩
    imod ghost_var_update_halves ρ' _ _ _ $$ Hri Hrp with ⟨Hri, Hrp⟩
    imodintro
    iframe Hb Ha Hri Hrp Hal Hpt
    ipureintro
    exact Hinv

/-- `wpk_seq_read1`'s ecast hook. -/
theorem wpk_seq_read1_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aid addr : Int} {al : CerbMem.Allocation}
    {bs : List CerbMem.AbsByte} {dqa dqb : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, am.get? aid = some al →
        (∀ i : Nat, (hi : i < bs.length) →
          bm.get? (addr + (i : Int)) = some bs[i]) →
        app m (setMaps ρ bm am) = (NDactive v, setMaps ρ' bm am))
    (he : e0 = KExpr.seq m k)
    (hlay : ρ'.layout_state = ρ.layout_state) :
    (restIs (GF := GF) restHalf ρ ∗ allocIs aid dqa al
        ∗ pointsToBytes addr dqb bs) ∗
      ((restIs restHalf ρ' ∗ allocIs aid dqa al
          ∗ pointsToBytes addr dqb bs)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_read1 hlay h

/-- THE HARNESS TERMINAL: `nd_get` feeding a pure readout. The
    successor VALUE is the machine state itself, which the footprint
    logic deliberately does not pin — so the rule asks the
    postcondition to hold for EVERY state the rest half admits (for
    the harness readouts this is `rfl`-uniform: `finalize`'s result
    projections read only the rest). -/
theorem wpk_get_done_pure [CerbHeapGS GF]
    {g : driver_state → DriveVal} {ρ : driver_state}
    {φ : DriveVal → Prop} {s : Stuckness} {E : CoPset}
    (hpost : ∀ bm am, φ (g (setMaps ρ bm am))) :
    restIs (GF := GF) restHalf ρ ⊢
      WP (KExpr.seq nd_get (fun σ => KExpr.done (g σ)) : KDriveExpr)
        @ s ; E {{ o, ⌜φ o⌝ }} := by
  have hrest : ∀ σ : driver_state,
      app (nd_get : ndM driver_state step_kind driver_error
        mem_iv_constraint driver_state) σ = (NDactive σ, σ) :=
    fun σ => rfl
  iintro Hr
  iapply wp_lift_step rfl
  iintro %σ %ns %obs %obs' %nt Hσ
  icases cerbStateInterp_eq.1 $$ Hσ with Hσ
  icases interp_rest_agree $$ [$Hσ $Hr] with ⟨%h1, Hσ, Hr⟩
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
  icases cerbStateInterp_eq.2 $$ Hσ with Hσ
  iframe Hσ
  simp only [Algebra.BigOpL.bigOpL_nil]
  iframe
  iapply wpk_done
  ipureintro
  obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf h1
  exact hpost bm am

/-! ## The caller-protocol object-creation compound (alloc + store of
    one fresh object inside ONE harness atom — the `injectArgs` and
    errno shapes). The fixture supplies the OPEN-MEMORY app equation
    (derived from the registered construct laws + Kit mem blocks at
    open maps); the rule does the ghost minting: the fresh `allocIs`
    fragment and the stored range's `pointsToBytes` come out of the
    frame-preserving updates at allocation (freshness certified by
    `MemInv`, Caesium's heap_alloc pattern — "double allocation is
    unconstructible"). -/

/-- The uninitialized byte the allocator writes (the
    `mem_alloc_block` RHS literal). -/
def uninitB : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-- The double-write byte image of an alloc+store compound at open
    maps (alloc writes the uninitialized range, the store overwrites
    it). -/
def allocStoreBytes (bm : Std.TreeMap Int CerbMem.AbsByte) (a : Int)
    (sz : Nat) (stored : List CerbMem.AbsByte) :
    Std.TreeMap Int CerbMem.AbsByte :=
  writeList (writeList bm a (List.replicate sz uninitB)) a stored

/-- The successor state of an alloc+store compound at the
    decomposition: target rest, extended maps. -/
def allocStoreState (ρ' : driver_state)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) (a : Int) (sz : Nat)
    (stored : List CerbMem.AbsByte) (nid : Int)
    (al : CerbMem.Allocation) : driver_state :=
  setMaps ρ' (allocStoreBytes bm a sz stored) (am.insert nid al)

/-- `restOf` ignores the maps a `setMaps` splices. -/
theorem restOf_setMaps (ρ : driver_state)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    restOf (setMaps ρ bm am) = restOf ρ := rfl

/-- `MemInv` across an alloc+store compound (the two S2 preservation
    lemmas composed once, at the walk's writeList spelling). -/
theorem MemInv_alloc_store {ms : CerbMem.MemState} (h : MemInv ms)
    {pref : prefix0} {ty : ctype} {alignN : Int} {sz : Nat} {a : Int}
    {stored : List CerbMem.AbsByte}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (ms.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false)
    (hlen : stored.length = sz) :
    MemInv { ms with
      nextAllocId := ms.nextAllocId + 1,
      lastAddress := a,
      allocations := ms.allocations.insert ms.nextAllocId
        { base := a, size := sz, ty := some ty, prefix_ := pref },
      bytemap := writeList (writeList ms.bytemap a
        (List.replicate sz uninitB)) a stored } := by
  have h1 := h.alloc (pref := pref) (alignN := alignN) hsz haddr hnz
  rw [writeBytesTo_eq] at h1
  have h2 := h1.store (fpm := ms.funptrmap) (newBs := stored)
    (oldBs := List.replicate sz uninitB)
    (by simpa using hlen)
    (fun i hi => by
      show (writeList ms.bytemap a (List.replicate sz uninitB)).get?
        (a + (i : Int)) = _
      simp only [List.length_replicate] at hi
      rw [writeList_get?_in _ _ _ _ (by omega)
        (by simp only [List.length_replicate]; omega)]
      have hidx : (a + (i : Int) - a).toNat = i := by omega
      rw [hidx]
      simp [uninitB, hi])
  rw [writeBytesTo_eq] at h2
  exact h2

/-- OBJECT-CREATION STEP: consumes the rest half (the allocator
    counters move), MINTS the fresh allocation fragment + the stored
    range's points-to. `h` is the fixture's open-memory equation for
    the whole atom; freshness of the ghost inserts comes from
    `MemInv`, never from the fixture. -/
theorem wpk_seq_alloc_store [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ : driver_state}
    {ty : ctype} {pref : prefix0} {alignN : Int} {sz : Nat} {a : Int}
    {stored : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hρ : restOf ρ = ρ)
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (ρ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false)
    (hlen : stored.length = sz)
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, allocStoreState (restAllocR ρ a) bm am a sz
            stored ρ.layout_state.nextAllocId
            { base := a, size := sz, ty := some ty, prefix_ := pref })) :
    restIs (GF := GF) restHalf ρ ∗
      ((restIs restHalf (restAllocR ρ a)
          ∗ allocIs ρ.layout_state.nextAllocId (.own 1)
              { base := a, size := sz, ty := some ty, prefix_ := pref }
          ∗ pointsToBytes a (.own 1) stored)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det
    (R := iprop(restIs restHalf ρ))
    (R' := iprop(restIs restHalf (restAllocR ρ a)
      ∗ allocIs ρ.layout_state.nextAllocId (.own 1)
          { base := a, size := sz, ty := some ty, prefix_ := pref }
      ∗ pointsToBytes a (.own 1) stored))
    (Pre := fun σ => restOf σ = ρ ∧ MemInv σ.layout_state)
    (upd := fun σ => allocStoreState (restAllocR ρ a)
      σ.layout_state.bytemap σ.layout_state.allocations a sz stored
      ρ.layout_state.nextAllocId
      { base := a, size := sz, ty := some ty, prefix_ := pref })
    ?_ ?_ ?_
  · intro σ
    iintro ⟨Hi, Hr⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_meminv $$ Hi with ⟨%h2, Hi⟩
    iframe Hi Hr
    ipureintro
    exact ⟨h1, h2⟩
  · intro σ hp
    obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hp.1
    exact h bm am
  · intro σ hp
    obtain ⟨hr, hinv⟩ := hp
    obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hr
    -- component images of the successor
    have hB : bytesOf (allocStoreState (restAllocR ρ a)
        (setMaps ρ bm am).layout_state.bytemap
        (setMaps ρ bm am).layout_state.allocations a sz stored
        ρ.layout_state.nextAllocId
        { base := a, size := sz, ty := some ty,
          prefix_ := pref }).layout_state
        = extWriteList (extWriteList
            (bytesOf (setMaps ρ bm am).layout_state) a
            (List.replicate sz uninitB)) a stored := by
      show toExt (allocStoreBytes bm a sz stored) = _
      unfold allocStoreBytes
      rw [toExt_writeList, toExt_writeList]
      rfl
    have hA : allocsOf (allocStoreState (restAllocR ρ a)
        (setMaps ρ bm am).layout_state.bytemap
        (setMaps ρ bm am).layout_state.allocations a sz stored
        ρ.layout_state.nextAllocId
        { base := a, size := sz, ty := some ty,
          prefix_ := pref }).layout_state
        = Std.PartialMap.insert (M := CerbHeapF)
            (allocsOf (setMaps ρ bm am).layout_state)
            ρ.layout_state.nextAllocId
            { base := a, size := sz, ty := some ty, prefix_ := pref } := by
      show toExt (am.insert ρ.layout_state.nextAllocId _) = _
      exact toExt_insert ..
    have hR : restOf (allocStoreState (restAllocR ρ a)
        (setMaps ρ bm am).layout_state.bytemap
        (setMaps ρ bm am).layout_state.allocations a sz stored
        ρ.layout_state.nextAllocId
        { base := a, size := sz, ty := some ty,
          prefix_ := pref }) = restAllocR ρ a := by
      show restOf (setMaps (restAllocR ρ a) _ _) = _
      rw [restOf_setMaps]
      show restAllocR (restOf ρ) a = restAllocR ρ a
      rw [hρ]
    rw [CerbMemInterp_congr
      (σ' := allocStoreState (restAllocR ρ a)
        (setMaps ρ bm am).layout_state.bytemap
        (setMaps ρ bm am).layout_state.allocations a sz stored
        ρ.layout_state.nextAllocId
        { base := a, size := sz, ty := some ty, prefix_ := pref })
      hB hA hR]
    unfold CerbMemInterp restIs allocIs
    iintro ⟨⟨Hb, Ha, Hri, %Hinv'⟩, Hrp⟩
    -- byte ghost: fresh range (MemInv freshness), then overwrite
    have hfreshB : ∀ i : Nat,
        i < (List.replicate sz uninitB).length →
        Std.PartialMap.get? (M := CerbHeapF)
          (bytesOf (setMaps ρ bm am).layout_state)
          (a + (i : Int)) = none := by
      intro i hi
      show (toExt bm)[(a + (i : Int))]? = none
      rw [toExt_getElem?, ← Std.TreeMap.get?_eq_getElem?]
      refine hinv.bytemap_below_none ?_
      show a + (i : Int) < (setMaps ρ bm am).layout_state.lastAddress
      show a + (i : Int) < ρ.layout_state.lastAddress
      have hrange : a + sz ≤ ρ.layout_state.lastAddress :=
        alloc_range_le haddr hnz
      simp only [List.length_replicate] at hi
      omega
    imod bytes_alloc_ghost _ hfreshB $$ Hb with ⟨Hb, Hpts⟩
    imod bytes_update_ghost stored
      (by simpa using hlen) $$ [$Hb $Hpts] with ⟨Hb, Hpts⟩
    -- alloc ghost: fresh id (MemInv freshness)
    have hfreshA : Std.PartialMap.get? (M := CerbHeapF)
        (allocsOf (setMaps ρ bm am).layout_state)
        ρ.layout_state.nextAllocId = none := by
      show (toExt am)[ρ.layout_state.nextAllocId]? = none
      rw [toExt_getElem?, ← Std.TreeMap.get?_eq_getElem?]
      exact hinv.next_fresh
    imod ghost_map_insert _ _ hfreshA $$ Ha with ⟨Ha, Hfrag⟩
    -- rest ghost: both halves move to the post-alloc rest
    imod ghost_var_update_halves (restAllocR ρ a) _ _ _ $$ Hri Hrp
      with ⟨Hri, Hrp⟩
    imodintro
    iframe Hb Ha Hri Hrp Hfrag Hpts
    ipureintro
    -- MemInv preservation: the composed pure lemma at the spliced
    -- layout (fields defeq through the setMaps projections)
    exact MemInv_alloc_store hinv (pref := pref) (ty := ty)
      (alignN := alignN) hsz haddr hnz hlen

/-- `wpk_seq_alloc_store`'s ecast hook. -/
theorem wpk_seq_alloc_store_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ : driver_state}
    {ty : ctype} {pref : prefix0} {alignN : Int} {sz : Nat} {a : Int}
    {stored : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, allocStoreState (restAllocR ρ a) bm am a sz
            stored ρ.layout_state.nextAllocId
            { base := a, size := sz, ty := some ty, prefix_ := pref }))
    (he : e0 = KExpr.seq m k)
    (hρ : restOf ρ = ρ)
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (ρ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false)
    (hlen : stored.length = sz) :
    restIs (GF := GF) restHalf ρ ∗
      ((restIs restHalf (restAllocR ρ a)
          ∗ allocIs ρ.layout_state.nextAllocId (.own 1)
              { base := a, size := sz, ty := some ty, prefix_ := pref }
          ∗ pointsToBytes a (.own 1) stored)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_alloc_store hρ hsz haddr hnz hlen h

/-- `wpk_get_done_pure`'s ecast hook. -/
theorem wpk_get_done_pure_ecast [CerbHeapGS GF]
    {g : driver_state → DriveVal} {e0 : KDriveExpr} {ρ : driver_state}
    {φ : DriveVal → Prop} {s : Stuckness} {E : CoPset}
    (hpost : ∀ bm am, φ (g (setMaps ρ bm am)))
    (he : e0 = KExpr.seq nd_get (fun σ => KExpr.done (g σ))) :
    restIs (GF := GF) restHalf ρ ⊢
      WP e0 @ s ; E {{ o, ⌜φ o⌝ }} :=
  he ▸ wpk_get_done_pure hpost

/-! ## The closed functor bundle (the HeapLangS template at the
    CerbHeap resource: indices 0-3 the invariant/credit machinery,
    4-6 the GenHeap byte map, 7 the allocation ghost map, 8 the rest
    ghost cell). Final theorem discharges instantiate here. -/

def CerbHeapS : BundledGFunctors
  | 0 => ⟨InvMapF, by infer_instance⟩
  | 1 => ⟨constOF CoPsetDisjL, by infer_instance⟩
  | 2 => ⟨constOF (DisjointLeibnizSet PosSet), by infer_instance⟩
  | 3 => ⟨Auth.AuthURF (constOF Credit), by infer_instance⟩
  | 4 => ⟨constOF (HeapView Int (Agree (DiscreteO CerbMem.AbsByte))
            CerbHeapF), by infer_instance⟩
  | 5 => ⟨constOF (HeapView Int (Agree (DiscreteO GName)) CerbHeapF),
          by infer_instance⟩
  | 6 => ⟨constOF MetaUR, by infer_instance⟩
  | 7 => ⟨constOF (HeapView Int (Agree (DiscreteO CerbMem.Allocation))
            CerbHeapF), by infer_instance⟩
  | 8 => ⟨GhostVarF driver_state, by infer_instance⟩
  | _ => ⟨constOF Unit, by infer_instance⟩

instance instCerbHeapGpreS_CerbHeapS : CerbHeapGpreS CerbHeapS where
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
  rest_pre := @GhostVarG.mk _ _ ⟨8, rfl⟩

/-! ## The initial-state adequacy face: the initial physical maps are
    EMPTY, so the whole-state big-sep collapses and the client's
    entire capital is the rest half. -/

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

/-- The initial byte image is the empty extensional map. -/
theorem bytesOf_initial :
    bytesOf CerbMem.initialMemState
      = (∅ : CerbHeapF CerbMem.AbsByte) := by
  apply Std.ExtTreeMap.ext_getElem?
  intro k
  rfl

/-- The initial allocation image is the empty extensional map. -/
theorem allocsOf_initial :
    allocsOf CerbMem.initialMemState
      = (∅ : CerbHeapF CerbMem.Allocation) := by
  apply Std.ExtTreeMap.ext_getElem?
  intro k
  rfl

/-- THE THREADED HEAP-ROUTE ADEQUACY BRIDGE: WP over the per-step
    instance under `CerbMemInterp`, from the initial footprint (= the
    rest half; the initial maps are empty) ⇒ the threaded headline
    face. The statement-layer twin of the retired OwnP bridge — the
    CONCLUSION is byte-identical. -/
theorem kCallHarnessAdequateThrHeap_of_wp {GF : BundledGFunctors}
    [CerbHeapGpreS GF] (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbHeapGS GF],
      (restIs (GF := GF) restHalf
          (restOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequateThr seed tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  rw [← callK_denote] at hmem
  have hφ := kAdequateHeap_of_wp (GF := GF)
    (callK tagDefs file1 fname args)
    (initial_driver_state_threaded seed file1 fs)
    (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r)
    MemInv_initial
    (by
      intro inst
      iintro ⟨Hb, Ha, Hr⟩
      iclear Hb
      iclear Ha
      iapply Hwp $$ Hr)
    out tr st' hmem
  obtain ⟨r, hr, hs⟩ := hφ
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- The UB-freedom face on the heap route. -/
theorem kCallHarnessUBFreeThrHeap_of_wp {GF : BundledGFunctors}
    [CerbHeapGpreS GF] (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbHeapGS GF],
      (restIs (GF := GF) restHalf
          (restOf (initial_driver_state_threaded seed file1 fs))) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFreeThr seed tagDefs file1 fname args fs :=
  callHarnessUBFreeThr_of_adequateThr
    (kCallHarnessAdequateThrHeap_of_wp seed tagDefs file1 fname args fs
      spec Hwp)

end Cerb
end RelSem
