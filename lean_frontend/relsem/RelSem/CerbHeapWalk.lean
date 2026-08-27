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
-- RelSem.Threaded is the SEMANTICS-SIDE homed module since arc-18 C4
-- (relsemcore/RelSem/Threaded.lean); the reified call spine (`callK`)
-- it used to re-export from the proof package now comes from
-- RelSem.PerStepCall explicitly.
import RelSem.Threaded
import RelSem.PerStepCall
-- for `wp_expose`/`wp_side` (the interpretation-generic tactic
-- pieces the walk macros expand to)
import RelSem.PerStepTactics

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
@[step_law (kind := heapWalk) (variant := rest) (side := fed)
  (frontier := "walk/rest")
  (trace := "{law := wpk_seq_rest_ecast, joint := walk/rest, hyps := [h : fed(open-mem equation), he : rfl, hlay : rfl]}")
  (lineage := "footprint walk: rest-only step — the atom is rest-determined, every heap fragment frames (HeapLang pure-step analogue at the machine-state remainder)")]
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
@[step_law (kind := heapWalk) (variant := read1) (side := fed)
  (frontier := "walk/read1")
  (trace := "{law := wpk_seq_read1_ecast, joint := walk/read1, hyps := [h : fed(open-mem equation + footprint facts), he : rfl, hlay : rfl]}")
  (lineage := "footprint walk: one-object read step at any fraction; the rest of the heap frames (the framing rule made per-step)")]
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

/-- `writeBytesTo` never touches the bump allocator's mark (the
    projection the chained address arithmetic reads). -/
theorem writeBytesTo_lastAddress (m : CerbMem.MemState) (a : Int)
    (bs : List CerbMem.AbsByte) :
    (CerbMem.writeBytesTo m a bs).lastAddress = m.lastAddress := by
  rw [writeBytesTo_eq]

/-- `writeBytesTo` never touches the allocation counter. -/
theorem writeBytesTo_nextAllocId (m : CerbMem.MemState) (a : Int)
    (bs : List CerbMem.AbsByte) :
    (CerbMem.writeBytesTo m a bs).nextAllocId = m.nextAllocId := by
  rw [writeBytesTo_eq]

/-- `get?` through an insert at a DIFFERENT key (the comparator form
    the fixtures' allocation-table reads need). -/
theorem tm_get?_insert_ne {V : Type} (t : Std.TreeMap Int V)
    {k k' : Int} (h : k ≠ k') (v : V) :
    (t.insert k v).get? k' = t.get? k' := by
  simp only [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert]
  rw [if_neg]
  intro hc
  exact h (Std.LawfulEqCmp.eq_of_compare hc)

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

/-- A rest-shaped state stays rest-shaped across the alloc counters
    move. -/
theorem restOf_restAllocR {ρ : driver_state} (hρ : restOf ρ = ρ)
    (a : Int) : restOf (restAllocR ρ a) = restAllocR ρ a := by
  show { restAllocR ρ a with
    layout_state := memRest (restAllocR ρ a).layout_state }
    = restAllocR ρ a
  show restAllocR { ρ with layout_state := memRest ρ.layout_state } a
    = restAllocR ρ a
  rw [show ({ ρ with layout_state := memRest ρ.layout_state }
    : driver_state) = restOf ρ from rfl, hρ]

/-- THE OBJECT-CREATION GHOST MOVE, factored once (both compound
    rules instantiate it): at a decomposed state, the alloc+store
    interpretation update — fresh `allocIs` + stored `pointsToBytes`
    minted by the frame-preserving updates, freshness from `MemInv`. -/
theorem interp_alloc_store [CerbHeapGS GF] {ρ : driver_state}
    {bm : Std.TreeMap Int CerbMem.AbsByte}
    {am : Std.TreeMap Int CerbMem.Allocation}
    {ty : ctype} {pref : prefix0} {alignN : Int} {sz : Nat} {a : Int}
    {stored : List CerbMem.AbsByte}
    (hρ : restOf ρ = ρ)
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (ρ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false)
    (hlen : stored.length = sz)
    (hinv : MemInv (setMaps ρ bm am).layout_state) :
    (CerbMemInterp (GF := GF) (setMaps ρ bm am)
      ∗ restIs restHalf ρ : IProp GF) ⊢ |==>
      (CerbMemInterp (allocStoreState (restAllocR ρ a) bm am a sz
          stored ρ.layout_state.nextAllocId
          { base := a, size := sz, ty := some ty, prefix_ := pref })
        ∗ (restIs restHalf (restAllocR ρ a)
           ∗ allocIs ρ.layout_state.nextAllocId (.own 1)
               { base := a, size := sz, ty := some ty, prefix_ := pref }
           ∗ pointsToBytes a (.own 1) stored)) := by
  have hB : bytesOf (allocStoreState (restAllocR ρ a)
      bm am a sz stored ρ.layout_state.nextAllocId
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
      bm am a sz stored ρ.layout_state.nextAllocId
      { base := a, size := sz, ty := some ty,
        prefix_ := pref }).layout_state
      = Std.PartialMap.insert (M := CerbHeapF)
          (allocsOf (setMaps ρ bm am).layout_state)
          ρ.layout_state.nextAllocId
          { base := a, size := sz, ty := some ty, prefix_ := pref } := by
    show toExt (am.insert ρ.layout_state.nextAllocId _) = _
    exact toExt_insert ..
  have hR : restOf (allocStoreState (restAllocR ρ a)
      bm am a sz stored ρ.layout_state.nextAllocId
      { base := a, size := sz, ty := some ty,
        prefix_ := pref }) = restAllocR ρ a := by
    show restOf (setMaps (restAllocR ρ a) _ _) = _
    rw [restOf_setMaps]
    exact restOf_restAllocR hρ a
  rw [CerbMemInterp_congr
    (σ' := allocStoreState (restAllocR ρ a)
      bm am a sz stored ρ.layout_state.nextAllocId
      { base := a, size := sz, ty := some ty, prefix_ := pref })
    hB hA hR]
  unfold CerbMemInterp restIs allocIs
  iintro ⟨⟨Hb, Ha, Hri, %Hinv'⟩, Hrp⟩
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
  have hfreshA : Std.PartialMap.get? (M := CerbHeapF)
      (allocsOf (setMaps ρ bm am).layout_state)
      ρ.layout_state.nextAllocId = none := by
    show (toExt am)[ρ.layout_state.nextAllocId]? = none
    rw [toExt_getElem?, ← Std.TreeMap.get?_eq_getElem?]
    exact hinv.next_fresh
  imod ghost_map_insert _ _ hfreshA $$ Ha with ⟨Ha, Hfrag⟩
  imod ghost_var_update_halves (restAllocR ρ a) _ _ _ $$ Hri Hrp
    with ⟨Hri, Hrp⟩
  imodintro
  iframe Hb Ha Hri Hrp Hfrag Hpts
  ipureintro
  exact MemInv_alloc_store hinv (pref := pref) (ty := ty)
    (alignN := alignN) hsz haddr hnz hlen

/-- OBJECT-CREATION STEP: consumes the rest half (the allocator
    counters move), MINTS the fresh allocation fragment + the stored
    range's points-to. `h` is the fixture's open-memory equation for
    the whole atom; freshness of the ghost inserts comes from
    `MemInv`, never from the fixture. -/
theorem wpk_seq_alloc_store [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ : driver_state}
    {ty : ctype} {pref : prefix0} {alignN : Int} {sz : Nat} {a : Int}
    {nid : Int} {al : CerbMem.Allocation}
    {stored : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hρ : restOf ρ = ρ)
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (ρ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false)
    (hlen : stored.length = sz)
    -- the canonical-spelling knobs: the fixture names the minted
    -- fragments in its own vocabulary (rfl at instances)
    (hnid : nid = ρ.layout_state.nextAllocId)
    (hal : al = { base := a, size := sz, ty := some ty, prefix_ := pref })
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, allocStoreState (restAllocR ρ a) bm am a sz
            stored nid al)) :
    restIs (GF := GF) restHalf ρ ∗
      ((restIs restHalf (restAllocR ρ a)
          ∗ allocIs nid (.own 1) al
          ∗ pointsToBytes a (.own 1) stored)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  subst hnid
  subst hal
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
    exact interp_alloc_store hρ hsz haddr hnz hlen hinv

/-- `wpk_seq_alloc_store`'s ecast hook. -/
@[step_law (kind := heapWalk) (variant := allocStore) (side := fed)
  (frontier := "walk/alloc-store")
  (trace := "{law := wpk_seq_alloc_store_ecast, joint := walk/alloc-store, hyps := [h : fed, he : rfl, hrho/hsz/hnz/hlen/hnid/hal : rfl, haddr : ground]}")
  (lineage := "footprint walk: object creation mints allocIs + pointsToBytes by the frame-preserving update; freshness from MemInv (Caesium heap_alloc — double allocation unconstructible)")]
theorem wpk_seq_alloc_store_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ : driver_state}
    {ty : ctype} {pref : prefix0} {alignN : Int} {sz : Nat} {a : Int}
    {nid : Int} {al : CerbMem.Allocation}
    {stored : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, allocStoreState (restAllocR ρ a) bm am a sz
            stored nid al))
    (he : e0 = KExpr.seq m k)
    (hρ : restOf ρ = ρ)
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (ρ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false)
    (hlen : stored.length = sz)
    (hnid : nid = ρ.layout_state.nextAllocId)
    (hal : al = { base := a, size := sz, ty := some ty,
                  prefix_ := pref }) :
    restIs (GF := GF) restHalf ρ ∗
      ((restIs restHalf (restAllocR ρ a)
          ∗ allocIs nid (.own 1) al
          ∗ pointsToBytes a (.own 1) stored)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_alloc_store hρ hsz haddr hnz hlen hnid hal h

/-- TWO-OBJECT CREATION STEP (the two-argument caller protocol: both
    injections live in ONE `injectArgs` atom): the factored ghost
    move applied twice — the mid-state is again a decomposition
    (`allocStoreState` IS `setMaps`), so the second application runs
    at the moved rest with the extended maps. -/
theorem wpk_seq_alloc_store2 [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ : driver_state}
    {tyA tyB : ctype} {prefA prefB : prefix0} {alignA alignB : Int}
    {szA szB : Nat} {aA aB : Int}
    {nidA nidB : Int} {alA alB : CerbMem.Allocation}
    {storedA storedB : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hρ : restOf ρ = ρ)
    (hszA : (CerbMem.sizeofCtype tyA).max 1 = szA)
    (haddrA : ((CerbMem.alignDown
        (ρ.layout_state.lastAddress - szA).toNat
        (alignA.toNat.max 1) : Nat) : Int) = aA)
    (hnzA : (aA == (0 : Int)) = false)
    (hlenA : storedA.length = szA)
    (hnidA : nidA = ρ.layout_state.nextAllocId)
    (halA : alA = { base := aA, size := szA, ty := some tyA,
                    prefix_ := prefA })
    (hszB : (CerbMem.sizeofCtype tyB).max 1 = szB)
    (haddrB : ((CerbMem.alignDown ((aA : Int) - szB).toNat
        (alignB.toNat.max 1) : Nat) : Int) = aB)
    (hnzB : (aB == (0 : Int)) = false)
    (hlenB : storedB.length = szB)
    (hnidB : nidB = ρ.layout_state.nextAllocId + 1)
    (halB : alB = { base := aB, size := szB, ty := some tyB,
                    prefix_ := prefB })
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, allocStoreState
            (restAllocR (restAllocR ρ aA) aB)
            (allocStoreBytes bm aA szA storedA) (am.insert nidA alA)
            aB szB storedB nidB alB)) :
    restIs (GF := GF) restHalf ρ ∗
      ((restIs restHalf (restAllocR (restAllocR ρ aA) aB)
          ∗ allocIs nidA (.own 1) alA
          ∗ pointsToBytes aA (.own 1) storedA
          ∗ allocIs nidB (.own 1) alB
          ∗ pointsToBytes aB (.own 1) storedB)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  subst hnidA; subst halA; subst hnidB; subst halB
  refine wpk_seq_res_det
    (R := iprop(restIs restHalf ρ))
    (R' := iprop(restIs restHalf (restAllocR (restAllocR ρ aA) aB)
      ∗ allocIs ρ.layout_state.nextAllocId (.own 1)
          { base := aA, size := szA, ty := some tyA, prefix_ := prefA }
      ∗ pointsToBytes aA (.own 1) storedA
      ∗ allocIs (ρ.layout_state.nextAllocId + 1) (.own 1)
          { base := aB, size := szB, ty := some tyB, prefix_ := prefB }
      ∗ pointsToBytes aB (.own 1) storedB))
    (Pre := fun σ => restOf σ = ρ ∧ MemInv σ.layout_state)
    (upd := fun σ => allocStoreState
      (restAllocR (restAllocR ρ aA) aB)
      (allocStoreBytes σ.layout_state.bytemap aA szA storedA)
      (σ.layout_state.allocations.insert ρ.layout_state.nextAllocId
        { base := aA, size := szA, ty := some tyA, prefix_ := prefA })
      aB szB storedB (ρ.layout_state.nextAllocId + 1)
      { base := aB, size := szB, ty := some tyB, prefix_ := prefB })
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
    -- application 1: the A object at ρ
    iintro ⟨Hi, Hr⟩
    imod (interp_alloc_store (ty := tyA) (pref := prefA)
      (alignN := alignA) hρ hszA haddrA hnzA hlenA hinv)
      $$ [$Hi $Hr] with ⟨Hi, Hr, HalA, HptA⟩
    -- application 2: the B object at the moved rest; the mid-state
    -- IS a decomposition (allocStoreState = setMaps by definition)
    have hρ2 : restOf (restAllocR ρ aA) = restAllocR ρ aA :=
      restOf_restAllocR hρ aA
    have haddrB' : ((CerbMem.alignDown
        ((restAllocR ρ aA).layout_state.lastAddress - szB).toNat
        (alignB.toNat.max 1) : Nat) : Int) = aB := haddrB
    have hinv2 : MemInv (setMaps (restAllocR ρ aA)
        (allocStoreBytes bm aA szA storedA)
        (am.insert ρ.layout_state.nextAllocId
          { base := aA, size := szA, ty := some tyA,
            prefix_ := prefA })).layout_state :=
      MemInv_alloc_store hinv (pref := prefA) (ty := tyA)
        (alignN := alignA) hszA haddrA hnzA hlenA
    have hmid : (CerbMemInterp (GF := GF)
        (allocStoreState (restAllocR ρ aA) bm am aA szA storedA
          ρ.layout_state.nextAllocId
          { base := aA, size := szA, ty := some tyA,
            prefix_ := prefA }) : IProp GF)
        = CerbMemInterp (setMaps (restAllocR ρ aA)
            (allocStoreBytes bm aA szA storedA)
            (am.insert ρ.layout_state.nextAllocId
              { base := aA, size := szA, ty := some tyA,
                prefix_ := prefA })) := rfl
    icases hmid $$ Hi with Hi
    imod (interp_alloc_store (ρ := restAllocR ρ aA)
      (ty := tyB) (pref := prefB) (alignN := alignB)
      (bm := allocStoreBytes bm aA szA storedA)
      (am := am.insert ρ.layout_state.nextAllocId
        { base := aA, size := szA, ty := some tyA, prefix_ := prefA })
      hρ2 hszB haddrB' hnzB hlenB hinv2)
      $$ [$Hi $Hr] with ⟨Hi, Hr, HalB, HptB⟩
    have hfin : (CerbMemInterp (GF := GF)
        (allocStoreState (restAllocR (restAllocR ρ aA) aB)
          (allocStoreBytes bm aA szA storedA)
          (am.insert ρ.layout_state.nextAllocId
            { base := aA, size := szA, ty := some tyA,
              prefix_ := prefA })
          aB szB storedB (restAllocR ρ aA).layout_state.nextAllocId
          { base := aB, size := szB, ty := some tyB,
            prefix_ := prefB }) : IProp GF)
        = CerbMemInterp (allocStoreState
            (restAllocR (restAllocR ρ aA) aB)
            (allocStoreBytes
              (setMaps ρ bm am).layout_state.bytemap aA szA storedA)
            ((setMaps ρ bm am).layout_state.allocations.insert
              ρ.layout_state.nextAllocId
              { base := aA, size := szA, ty := some tyA,
                prefix_ := prefA })
            aB szB storedB (ρ.layout_state.nextAllocId + 1)
            { base := aB, size := szB, ty := some tyB,
              prefix_ := prefB }) := rfl
    icases hfin $$ Hi with Hi
    have halBconv : (allocIs (GF := GF)
        (restAllocR ρ aA).layout_state.nextAllocId (.own 1)
        { base := aB, size := szB, ty := some tyB,
          prefix_ := prefB } : IProp GF)
        = allocIs (ρ.layout_state.nextAllocId + 1) (.own 1)
            { base := aB, size := szB, ty := some tyB,
              prefix_ := prefB } := rfl
    icases halBconv $$ HalB with HalB
    imodintro
    iframe Hi Hr HalA HptA HalB HptB

/-- `wpk_seq_alloc_store2`'s ecast hook. -/
@[step_law (kind := heapWalk) (variant := allocStore2) (side := fed)
  (frontier := "walk/alloc-store2")
  (trace := "{law := wpk_seq_alloc_store2_ecast, joint := walk/alloc-store2, hyps := [h : fed, he : rfl, ground facts x2]}")
  (lineage := "footprint walk: the two-object creation compound (the factored ghost move applied twice; the mid-state is again a decomposition)")]
theorem wpk_seq_alloc_store2_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ : driver_state}
    {tyA tyB : ctype} {prefA prefB : prefix0} {alignA alignB : Int}
    {szA szB : Nat} {aA aB : Int}
    {nidA nidB : Int} {alA alB : CerbMem.Allocation}
    {storedA storedB : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, app m (setMaps ρ bm am)
        = (NDactive v, allocStoreState
            (restAllocR (restAllocR ρ aA) aB)
            (allocStoreBytes bm aA szA storedA) (am.insert nidA alA)
            aB szB storedB nidB alB))
    (he : e0 = KExpr.seq m k)
    (hρ : restOf ρ = ρ)
    (hszA : (CerbMem.sizeofCtype tyA).max 1 = szA)
    (haddrA : ((CerbMem.alignDown
        (ρ.layout_state.lastAddress - szA).toNat
        (alignA.toNat.max 1) : Nat) : Int) = aA)
    (hnzA : (aA == (0 : Int)) = false)
    (hlenA : storedA.length = szA)
    (hnidA : nidA = ρ.layout_state.nextAllocId)
    (halA : alA = { base := aA, size := szA, ty := some tyA,
                    prefix_ := prefA })
    (hszB : (CerbMem.sizeofCtype tyB).max 1 = szB)
    (haddrB : ((CerbMem.alignDown ((aA : Int) - szB).toNat
        (alignB.toNat.max 1) : Nat) : Int) = aB)
    (hnzB : (aB == (0 : Int)) = false)
    (hlenB : storedB.length = szB)
    (hnidB : nidB = ρ.layout_state.nextAllocId + 1)
    (halB : alB = { base := aB, size := szB, ty := some tyB,
                    prefix_ := prefB }) :
    restIs (GF := GF) restHalf ρ ∗
      ((restIs restHalf (restAllocR (restAllocR ρ aA) aB)
          ∗ allocIs nidA (.own 1) alA
          ∗ pointsToBytes aA (.own 1) storedA
          ∗ allocIs nidB (.own 1) alB
          ∗ pointsToBytes aB (.own 1) storedB)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_alloc_store2 hρ hszA haddrA hnzA hlenA hnidA halA
    hszB haddrB hnzB hlenB hnidB halB h

/-- TWO-OBJECT READ STEP (the two-argument fixtures' driver loop:
    both argument objects read; everything ELSE — the errno object —
    rides the frame). -/
theorem wpk_seq_read2 [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aidA addrA aidB addrB : Int} {alA alB : CerbMem.Allocation}
    {bsA bsB : List CerbMem.AbsByte} {dqaA dqbA dqaB dqbB : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hlay : ρ'.layout_state = ρ.layout_state)
    (h : ∀ bm am, am.get? aidA = some alA → am.get? aidB = some alB →
        (∀ i : Nat, (hi : i < bsA.length) →
          bm.get? (addrA + (i : Int)) = some bsA[i]) →
        (∀ i : Nat, (hi : i < bsB.length) →
          bm.get? (addrB + (i : Int)) = some bsB[i]) →
        app m (setMaps ρ bm am) = (NDactive v, setMaps ρ' bm am)) :
    (restIs (GF := GF) restHalf ρ
        ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA dqbA bsA
        ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB) ∗
      ((restIs restHalf ρ'
          ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA dqbA bsA
          ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det
    (R := iprop(restIs restHalf ρ
      ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA dqbA bsA
      ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB))
    (R' := iprop(restIs restHalf ρ'
      ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA dqbA bsA
      ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB))
    (Pre := fun σ => restOf σ = ρ ∧
      (σ.layout_state.allocations.get? aidA = some alA ∧
       σ.layout_state.allocations.get? aidB = some alB) ∧
      (∀ i : Nat, (hi : i < bsA.length) →
        σ.layout_state.bytemap.get? (addrA + (i : Int)) = some bsA[i]) ∧
      (∀ i : Nat, (hi : i < bsB.length) →
        σ.layout_state.bytemap.get? (addrB + (i : Int)) = some bsB[i]))
    (upd := fun σ => patchRest σ ρ')
    ?_ ?_ ?_
  · intro σ
    iintro ⟨Hi, Hr, HaA, HpA, HaB, HpB⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_alloc_lookup $$ [$Hi $HaA] with ⟨%h2, Hi, HaA⟩
    icases interp_alloc_lookup $$ [$Hi $HaB] with ⟨%h3, Hi, HaB⟩
    icases interp_bytes_lookup $$ [$Hi $HpA] with ⟨%h4, Hi, HpA⟩
    icases interp_bytes_lookup $$ [$Hi $HpB] with ⟨%h5, Hi, HpB⟩
    iframe Hi Hr HaA HpA HaB HpB
    ipureintro
    exact ⟨h1, ⟨h2, h3⟩, h4, h5⟩
  · intro σ hp
    obtain ⟨hr, ⟨hgA, hgB⟩, hbA, hbB⟩ := hp
    obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hr
    rw [patchRest_setMaps hlay]
    exact h bm am hgA hgB hbA hbB
  · intro σ hp
    rw [CerbMemInterp_congr (σ' := patchRest σ ρ')
      (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
      (R := ρ') rfl rfl (restOf_patchRest hp.1 hlay)]
    unfold CerbMemInterp restIs
    iintro ⟨⟨Hb, Ha, Hri, %Hinv⟩, Hrp, HaA, HpA, HaB, HpB⟩
    imod ghost_var_update_halves ρ' _ _ _ $$ Hri Hrp with ⟨Hri, Hrp⟩
    imodintro
    iframe Hb Ha Hri Hrp HaA HpA HaB HpB
    ipureintro
    exact Hinv

/-- `wpk_seq_read2`'s ecast hook. -/
@[step_law (kind := heapWalk) (variant := read2) (side := fed)
  (frontier := "walk/read2")
  (trace := "{law := wpk_seq_read2_ecast, joint := walk/read2, hyps := [h : fed, he : rfl, hlay : rfl]}")
  (lineage := "footprint walk: two-object read step (the two-argument fixtures' loop shape)")]
theorem wpk_seq_read2_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aidA addrA aidB addrB : Int} {alA alB : CerbMem.Allocation}
    {bsA bsB : List CerbMem.AbsByte} {dqaA dqbA dqaB dqbB : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, am.get? aidA = some alA → am.get? aidB = some alB →
        (∀ i : Nat, (hi : i < bsA.length) →
          bm.get? (addrA + (i : Int)) = some bsA[i]) →
        (∀ i : Nat, (hi : i < bsB.length) →
          bm.get? (addrB + (i : Int)) = some bsB[i]) →
        app m (setMaps ρ bm am) = (NDactive v, setMaps ρ' bm am))
    (he : e0 = KExpr.seq m k)
    (hlay : ρ'.layout_state = ρ.layout_state) :
    (restIs (GF := GF) restHalf ρ
        ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA dqbA bsA
        ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB) ∗
      ((restIs restHalf ρ'
          ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA dqbA bsA
          ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_read2 hlay h

/-- SCRATCH-OBJECT STEP (the create/store/load/kill loop shape): the
    atom reads one object's footprint AND creates, uses, and kills a
    SCRATCH object entirely within itself. Ghost accounting: the
    allocation fragment is minted by the insert and consumed by the
    delete (net zero — the scratch allocation is unobservable
    outside); the scratch object's final bytes stay minted and are
    handed to the prover as DEAD CAPITAL (the physical model keeps
    killed bytes — S2 deviation D2 — and no rule accepts them
    without a live `allocIs`, so use-after-free stays unprovable). -/
theorem wpk_seq_scratch1 [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aidV addrV : Int} {alV : CerbMem.Allocation}
    {bsV : List CerbMem.AbsByte} {dqa dqb : DFrac}
    {tyS : ctype} {prefS : prefix0} {alignS : Int} {szS : Nat}
    {aS nidS : Int} {alS : CerbMem.Allocation}
    {storedS : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hρ' : restOf ρ' = ρ')
    (hlayK : ρ'.layout_state = { ρ.layout_state with
      nextAllocId := ρ.layout_state.nextAllocId + 1,
      lastAddress := aS,
      deadAllocations := nidS :: ρ.layout_state.deadAllocations })
    (hszS : (CerbMem.sizeofCtype tyS).max 1 = szS)
    (haddrS : ((CerbMem.alignDown
        (ρ.layout_state.lastAddress - szS).toNat
        (alignS.toNat.max 1) : Nat) : Int) = aS)
    (hnzS : (aS == (0 : Int)) = false)
    (hlenS : storedS.length = szS)
    (hnidS : nidS = ρ.layout_state.nextAllocId)
    (halS : alS = { base := aS, size := szS, ty := some tyS,
                    prefix_ := prefS })
    (h : ∀ bm am, am.get? aidV = some alV →
        (∀ i : Nat, (hi : i < bsV.length) →
          bm.get? (addrV + (i : Int)) = some bsV[i]) →
        app m (setMaps ρ bm am)
          = (NDactive v, setMaps ρ'
              (allocStoreBytes bm aS szS storedS)
              ((am.insert nidS alS).erase nidS))) :
    (restIs (GF := GF) restHalf ρ ∗ allocIs aidV dqa alV
        ∗ pointsToBytes addrV dqb bsV) ∗
      ((restIs restHalf ρ' ∗ allocIs aidV dqa alV
          ∗ pointsToBytes addrV dqb bsV
          ∗ pointsToBytes aS (.own 1) storedS)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  subst hnidS
  subst halS
  refine wpk_seq_res_det
    (R := iprop(restIs restHalf ρ ∗ allocIs aidV dqa alV
      ∗ pointsToBytes addrV dqb bsV))
    (R' := iprop(restIs restHalf ρ' ∗ allocIs aidV dqa alV
      ∗ pointsToBytes addrV dqb bsV
      ∗ pointsToBytes aS (.own 1) storedS))
    (Pre := fun σ => (restOf σ = ρ ∧ MemInv σ.layout_state) ∧
      σ.layout_state.allocations.get? aidV = some alV ∧
      (∀ i : Nat, (hi : i < bsV.length) →
        σ.layout_state.bytemap.get? (addrV + (i : Int)) = some bsV[i]))
    (upd := fun σ => setMaps ρ'
      (allocStoreBytes σ.layout_state.bytemap aS szS storedS)
      ((σ.layout_state.allocations.insert ρ.layout_state.nextAllocId
        { base := aS, size := szS, ty := some tyS,
          prefix_ := prefS }).erase ρ.layout_state.nextAllocId))
    ?_ ?_ ?_
  · intro σ
    iintro ⟨Hi, Hr, Ha, Hp⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_meminv $$ Hi with ⟨%h2, Hi⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h3, Hi, Ha⟩
    icases interp_bytes_lookup $$ [$Hi $Hp] with ⟨%h4, Hi, Hp⟩
    iframe Hi Hr Ha Hp
    ipureintro
    exact ⟨⟨h1, h2⟩, h3, h4⟩
  · intro σ hp
    obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hp.1.1
    exact h bm am hp.2.1 hp.2.2
  · intro σ hp
    obtain ⟨⟨hr, hinv⟩, -, -⟩ := hp
    obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hr
    show (CerbMemInterp (GF := GF) (setMaps ρ bm am)
        ∗ (restIs restHalf ρ ∗ allocIs aidV dqa alV
          ∗ pointsToBytes addrV dqb bsV) : IProp GF) ⊢
      |==> (CerbMemInterp (setMaps ρ'
          (allocStoreBytes bm aS szS storedS)
          ((am.insert ρ.layout_state.nextAllocId
            { base := aS, size := szS, ty := some tyS,
              prefix_ := prefS }).erase
            ρ.layout_state.nextAllocId))
        ∗ (restIs restHalf ρ' ∗ allocIs aidV dqa alV
          ∗ pointsToBytes addrV dqb bsV
          ∗ pointsToBytes aS (.own 1) storedS))
    have hB : bytesOf (setMaps ρ'
        (allocStoreBytes bm aS szS storedS)
        ((am.insert ρ.layout_state.nextAllocId
          { base := aS, size := szS, ty := some tyS,
            prefix_ := prefS }).erase
          ρ.layout_state.nextAllocId)).layout_state
        = extWriteList (extWriteList
            (bytesOf (setMaps ρ bm am).layout_state) aS
            (List.replicate szS uninitB)) aS storedS := by
      show toExt (allocStoreBytes bm aS szS storedS) = _
      unfold allocStoreBytes
      rw [toExt_writeList, toExt_writeList]
      rfl
    have hA : allocsOf (setMaps ρ'
        (allocStoreBytes bm aS szS storedS)
        ((am.insert ρ.layout_state.nextAllocId
          { base := aS, size := szS, ty := some tyS,
            prefix_ := prefS }).erase
          ρ.layout_state.nextAllocId)).layout_state
        = Std.PartialMap.delete (M := CerbHeapF)
            (Std.PartialMap.insert (M := CerbHeapF)
              (allocsOf (setMaps ρ bm am).layout_state)
              ρ.layout_state.nextAllocId
              { base := aS, size := szS, ty := some tyS,
                prefix_ := prefS })
            ρ.layout_state.nextAllocId := by
      show toExt ((am.insert ρ.layout_state.nextAllocId _).erase
        ρ.layout_state.nextAllocId) = _
      rw [toExt_erase, toExt_insert]
      rfl
    have hR : restOf (setMaps ρ'
        (allocStoreBytes bm aS szS storedS)
        ((am.insert ρ.layout_state.nextAllocId
          { base := aS, size := szS, ty := some tyS,
            prefix_ := prefS }).erase
          ρ.layout_state.nextAllocId)) = ρ' := by
      rw [restOf_setMaps]
      exact hρ'
    rw [CerbMemInterp_congr
      (σ' := setMaps ρ'
        (allocStoreBytes bm aS szS storedS)
        ((am.insert ρ.layout_state.nextAllocId
          { base := aS, size := szS, ty := some tyS,
            prefix_ := prefS }).erase
          ρ.layout_state.nextAllocId))
      hB hA hR]
    unfold CerbMemInterp restIs allocIs
    iintro ⟨⟨Hb, Ha, Hri, %Hinv'⟩, Hrp, HaV, HpV⟩
    -- byte ghost: fresh scratch range, then the stored overwrite
    have hfreshB : ∀ i : Nat,
        i < (List.replicate szS uninitB).length →
        Std.PartialMap.get? (M := CerbHeapF)
          (bytesOf (setMaps ρ bm am).layout_state)
          (aS + (i : Int)) = none := by
      intro i hi
      show (toExt bm)[(aS + (i : Int))]? = none
      rw [toExt_getElem?, ← Std.TreeMap.get?_eq_getElem?]
      refine hinv.bytemap_below_none ?_
      show aS + (i : Int) < (setMaps ρ bm am).layout_state.lastAddress
      show aS + (i : Int) < ρ.layout_state.lastAddress
      have hrange : aS + szS ≤ ρ.layout_state.lastAddress :=
        alloc_range_le haddrS hnzS
      simp only [List.length_replicate] at hi
      omega
    imod bytes_alloc_ghost _ hfreshB $$ Hb with ⟨Hb, Hpts⟩
    imod bytes_update_ghost storedS
      (by simpa using hlenS) $$ [$Hb $Hpts] with ⟨Hb, Hpts⟩
    -- alloc ghost: mint the scratch fragment, then consume it at the
    -- kill (net zero — the can't-happen pattern closing over itself)
    have hfreshA : Std.PartialMap.get? (M := CerbHeapF)
        (allocsOf (setMaps ρ bm am).layout_state)
        ρ.layout_state.nextAllocId = none := by
      show (toExt am)[ρ.layout_state.nextAllocId]? = none
      rw [toExt_getElem?, ← Std.TreeMap.get?_eq_getElem?]
      exact hinv.next_fresh
    imod ghost_map_insert _ _ hfreshA $$ Ha with ⟨Ha, Hfrag⟩
    imod ghost_map_delete _ _ $$ Ha Hfrag with Ha
    -- rest ghost
    imod ghost_var_update_halves ρ' _ _ _ $$ Hri Hrp with ⟨Hri, Hrp⟩
    imodintro
    iframe Hb Ha Hri Hrp HaV HpV Hpts
    ipureintro
    -- MemInv: alloc+store then kill
    have h1 := MemInv_alloc_store hinv (pref := prefS) (ty := tyS)
      (alignN := alignS) hszS haddrS hnzS hlenS
    have h2 := h1.kill (aid := ρ.layout_state.nextAllocId)
      (al := { base := aS, size := szS, ty := some tyS,
               prefix_ := prefS })
      (by
        show ((am.insert ρ.layout_state.nextAllocId _).get?
          ρ.layout_state.nextAllocId) = _
        simp [Std.TreeMap.get?_eq_getElem?, Std.TreeMap.getElem?_insert])
    show MemInv { ρ'.layout_state with
      bytemap := allocStoreBytes bm aS szS storedS,
      allocations := (am.insert ρ.layout_state.nextAllocId
        { base := aS, size := szS, ty := some tyS,
          prefix_ := prefS }).erase ρ.layout_state.nextAllocId }
    rw [hlayK]
    exact h2

/-- `wpk_seq_scratch1`'s ecast hook. -/
@[step_law (kind := heapWalk) (variant := scratch1) (side := fed)
  (frontier := "walk/scratch1")
  (trace := "{law := wpk_seq_scratch1_ecast, joint := walk/scratch1, hyps := [h : fed, he : rfl, ground facts]}")
  (lineage := "footprint walk: scratch-object step — the allocation fragment is minted and consumed inside the rule (net unobservable), dead bytes out as D2 dead capital")]
theorem wpk_seq_scratch1_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aidV addrV : Int} {alV : CerbMem.Allocation}
    {bsV : List CerbMem.AbsByte} {dqa dqb : DFrac}
    {tyS : ctype} {prefS : prefix0} {alignS : Int} {szS : Nat}
    {aS nidS : Int} {alS : CerbMem.Allocation}
    {storedS : List CerbMem.AbsByte}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, am.get? aidV = some alV →
        (∀ i : Nat, (hi : i < bsV.length) →
          bm.get? (addrV + (i : Int)) = some bsV[i]) →
        app m (setMaps ρ bm am)
          = (NDactive v, setMaps ρ'
              (allocStoreBytes bm aS szS storedS)
              ((am.insert nidS alS).erase nidS)))
    (he : e0 = KExpr.seq m k)
    (hρ' : restOf ρ' = ρ')
    (hlayK : ρ'.layout_state = { ρ.layout_state with
      nextAllocId := ρ.layout_state.nextAllocId + 1,
      lastAddress := aS,
      deadAllocations := nidS :: ρ.layout_state.deadAllocations })
    (hszS : (CerbMem.sizeofCtype tyS).max 1 = szS)
    (haddrS : ((CerbMem.alignDown
        (ρ.layout_state.lastAddress - szS).toNat
        (alignS.toNat.max 1) : Nat) : Int) = aS)
    (hnzS : (aS == (0 : Int)) = false)
    (hlenS : storedS.length = szS)
    (hnidS : nidS = ρ.layout_state.nextAllocId)
    (halS : alS = { base := aS, size := szS, ty := some tyS,
                    prefix_ := prefS }) :
    (restIs (GF := GF) restHalf ρ ∗ allocIs aidV dqa alV
        ∗ pointsToBytes addrV dqb bsV) ∗
      ((restIs restHalf ρ' ∗ allocIs aidV dqa alV
          ∗ pointsToBytes addrV dqb bsV
          ∗ pointsToBytes aS (.own 1) storedS)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_scratch1 hρ' hlayK hszS haddrS hnzS hlenS hnidS halS h

/-- READ-WRITE OBJECT STEP (arc-18 R2 — the loop atom over a caller
    object: the driver atom READS one object's footprint and
    RE-WRITES the same range, possibly many times — one `writeList`
    layer per loop-iteration store; no allocation moves). Ghost
    accounting: the full-fraction points-to is updated through the
    ladder (`bytes_update_seq_ghost`), landing at the LAST write's
    image; the allocation fragment rides through; `MemInv` is
    preserved by the store fold (`MemInv.writeSeq_pres` — writes land
    on the already-mapped range the points-to certifies). Lineage:
    HeapLang wp_store at the machine-atom granularity; the C3b
    scratch2 design note's pointwise-ladder prescription. -/
theorem wpk_seq_write1 [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aid addr : Int} {al : CerbMem.Allocation}
    {bsIn : List CerbMem.AbsByte} {ws : List (List CerbMem.AbsByte)}
    {dqa : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hρ' : restOf ρ' = ρ')
    (hlay : ρ'.layout_state = ρ.layout_state)
    (hlens : ∀ w ∈ ws, w.length = bsIn.length)
    (h : ∀ bm am, am.get? aid = some al →
        (∀ i : Nat, (hi : i < bsIn.length) →
          bm.get? (addr + (i : Int)) = some bsIn[i]) →
        app m (setMaps ρ bm am)
          = (NDactive v, setMaps ρ' (writeSeq bm addr ws) am)) :
    (restIs (GF := GF) restHalf ρ ∗ allocIs aid dqa al
        ∗ pointsToBytes addr (.own 1) bsIn) ∗
      ((restIs restHalf ρ' ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) (ws.getLastD bsIn))
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det
    (R := iprop(restIs restHalf ρ ∗ allocIs aid dqa al
      ∗ pointsToBytes addr (.own 1) bsIn))
    (R' := iprop(restIs restHalf ρ' ∗ allocIs aid dqa al
      ∗ pointsToBytes addr (.own 1) (ws.getLastD bsIn)))
    (Pre := fun σ => (restOf σ = ρ ∧ MemInv σ.layout_state) ∧
      σ.layout_state.allocations.get? aid = some al ∧
      (∀ i : Nat, (hi : i < bsIn.length) →
        σ.layout_state.bytemap.get? (addr + (i : Int)) = some bsIn[i]))
    (upd := fun σ => setMaps ρ'
      (writeSeq σ.layout_state.bytemap addr ws)
      σ.layout_state.allocations)
    ?_ ?_ ?_
  · intro σ
    iintro ⟨Hi, Hr, Ha, Hp⟩
    icases interp_rest_agree $$ [$Hi $Hr] with ⟨%h1, Hi, Hr⟩
    icases interp_meminv $$ Hi with ⟨%h2, Hi⟩
    icases interp_alloc_lookup $$ [$Hi $Ha] with ⟨%h3, Hi, Ha⟩
    icases interp_bytes_lookup $$ [$Hi $Hp] with ⟨%h4, Hi, Hp⟩
    iframe Hi Hr Ha Hp
    ipureintro
    exact ⟨⟨h1, h2⟩, h3, h4⟩
  · intro σ hp
    obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hp.1.1
    exact h bm am hp.2.1 hp.2.2
  · intro σ hp
    obtain ⟨⟨hr, hinv⟩, -, hbs⟩ := hp
    obtain ⟨bm, am, rfl⟩ := exists_setMaps_of_restOf hr
    show (CerbMemInterp (GF := GF) (setMaps ρ bm am)
        ∗ (restIs restHalf ρ ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) bsIn) : IProp GF) ⊢
      |==> (CerbMemInterp (setMaps ρ' (writeSeq bm addr ws) am)
        ∗ (restIs restHalf ρ' ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) (ws.getLastD bsIn)))
    have hB : bytesOf (setMaps ρ'
        (writeSeq bm addr ws) am).layout_state
        = extWriteSeq (bytesOf (setMaps ρ bm am).layout_state) addr
            ws := by
      show toExt (writeSeq bm addr ws) = _
      exact toExt_writeSeq bm addr ws
    have hA : allocsOf (setMaps ρ'
        (writeSeq bm addr ws) am).layout_state
        = allocsOf (setMaps ρ bm am).layout_state := rfl
    have hR : restOf (setMaps ρ' (writeSeq bm addr ws) am) = ρ' := by
      rw [restOf_setMaps]
      exact hρ'
    rw [CerbMemInterp_congr
      (σ' := setMaps ρ' (writeSeq bm addr ws) am) hB hA hR]
    unfold CerbMemInterp restIs
    iintro ⟨⟨Hb, Ha, Hri, %Hinv'⟩, Hrp, HaV, HpV⟩
    imod bytes_update_seq_ghost ws hlens $$ [$Hb $HpV]
      with ⟨Hb, HpV⟩
    imod ghost_var_update_halves ρ' _ _ _ $$ Hri Hrp with ⟨Hri, Hrp⟩
    imodintro
    iframe Hb Ha Hri Hrp HaV HpV
    ipureintro
    -- MemInv across the ladder, transported to the ρ'-layout record
    have hpres := hinv.writeSeq_pres (a := addr) (old := bsIn)
      (fun i hi => hbs i hi) ws hlens
    show MemInv { ρ'.layout_state with
      bytemap := writeSeq bm addr ws, allocations := am }
    rw [hlay]
    exact hpres

/-- `wpk_seq_write1`'s ecast hook. -/
@[step_law (kind := heapWalk) (variant := write1) (side := fed)
  (frontier := "walk/write1")
  (trace := "{law := wpk_seq_write1_ecast, joint := walk/write1, hyps := [h : fed(open-mem ladder equation + footprint facts), he : rfl, hlens : rfl]}")
  (lineage := "footprint walk: read-write object step — the loop atom's per-iteration store ladder; ghost update by fold, MemInv by store fold (HeapLang wp_store at atom granularity)")]
theorem wpk_seq_write1_ecast [CerbHeapGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {v : α} {ρ ρ' : driver_state}
    {aid addr : Int} {al : CerbMem.Allocation}
    {bsIn : List CerbMem.AbsByte} {ws : List (List CerbMem.AbsByte)}
    {dqa : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (h : ∀ bm am, am.get? aid = some al →
        (∀ i : Nat, (hi : i < bsIn.length) →
          bm.get? (addr + (i : Int)) = some bsIn[i]) →
        app m (setMaps ρ bm am)
          = (NDactive v, setMaps ρ' (writeSeq bm addr ws) am))
    (he : e0 = KExpr.seq m k)
    (hρ' : restOf ρ' = ρ')
    (hlay : ρ'.layout_state = ρ.layout_state)
    (hlens : ∀ w ∈ ws, w.length = bsIn.length) :
    (restIs (GF := GF) restHalf ρ ∗ allocIs aid dqa al
        ∗ pointsToBytes addr (.own 1) bsIn) ∗
      ((restIs restHalf ρ' ∗ allocIs aid dqa al
          ∗ pointsToBytes addr (.own 1) (ws.getLastD bsIn))
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_write1 hρ' hlay hlens h

/-- MID-WALK STATE READ (`nd_get` feeding further stages): the value
    is the machine state, which the footprint logic does not pin —
    but the harness continuations consume it only through REST
    projections, so the successor expression is the same at every
    state the rest half admits (`hk`, `rfl` at fixtures: the
    projections reduce). `c` is the canonical representative the
    walk continues at. -/
theorem wpk_seq_get [CerbHeapGS GF]
    {k : driver_state → KDriveExpr} (c : driver_state)
    {ρ : driver_state} {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    (hk : ∀ bm am, k (setMaps ρ bm am) = k c) :
    restIs (GF := GF) restHalf ρ ∗
      (restIs restHalf ρ -∗ WP (k c) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq nd_get k : KDriveExpr) @ s ; E {{ Φ }} := by
  have hrest : ∀ σ : driver_state,
      app (nd_get : ndM driver_state step_kind driver_error
        mem_iv_constraint driver_state) σ = (NDactive σ, σ) :=
    fun σ => rfl
  iintro ⟨Hr, Hcont⟩
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
  obtain ⟨bm, am, hσeq⟩ := exists_setMaps_of_restOf h1
  rw [hσeq, hk bm am]
  iapply Hcont $$ Hr

/-- `wpk_seq_get`'s ecast hook. -/
@[step_law (kind := heapWalk) (variant := get) (side := rfl)
  (frontier := "walk/get")
  (trace := "{law := wpk_seq_get_ecast, joint := walk/get, hyps := [hk : rfl, he : rfl]}")
  (lineage := "footprint walk: mid-walk state read — continuations consume the state only through rest projections, so the successor is uniform over the rest fiber")]
theorem wpk_seq_get_ecast [CerbHeapGS GF]
    {k : driver_state → KDriveExpr} (c : driver_state)
    {e0 : KDriveExpr} {ρ : driver_state} {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    (hk : ∀ bm am, k (setMaps ρ bm am) = k c)
    (he : e0 = KExpr.seq nd_get k) :
    restIs (GF := GF) restHalf ρ ∗
      (restIs restHalf ρ -∗ WP (k c) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ wpk_seq_get c hk

/-- `wpk_get_done_pure`'s ecast hook. -/
@[step_law (kind := heapWalk) (variant := getDone) (side := fed)
  (frontier := "walk/get-done")
  (trace := "{law := wpk_get_done_pure_ecast, joint := walk/get-done, hyps := [hpost : fed, he : rfl]}")
  (lineage := "footprint walk: the harness terminal — the postcondition holds at every state the rest half admits")]
theorem wpk_get_done_pure_ecast [CerbHeapGS GF]
    {g : driver_state → DriveVal} {e0 : KDriveExpr} {ρ : driver_state}
    {φ : DriveVal → Prop} {s : Stuckness} {E : CoPset}
    (hpost : ∀ bm am, φ (g (setMaps ρ bm am)))
    (he : e0 = KExpr.seq nd_get (fun σ => KExpr.done (g σ))) :
    restIs (GF := GF) restHalf ρ ⊢
      WP e0 @ s ; E {{ o, ⌜φ o⌝ }} :=
  he ▸ wpk_get_done_pure hpost

/-! ## The walk macros (the heap-route `wp_step` family — thin
    appliers of the rules above, exactly the PerStepTactics mold:
    apply the named law, frame the named resources, compute the side
    conditions) -/

/-- One rest-only step by an open-memory stage equation. -/
macro "wp_rest" e:term:max h:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_rest_ecast $e ?wpe ?wplay
             rotate_left
             rotate_left
             iframe $h:ident
             case wpe => rfl
             case wplay => rfl
             iintro $h:ident))

/-- The mid-walk state read (`nd_get`): continue at the canonical
    representative `c`. -/
macro "wp_get" c:term:max h:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_get_ecast $c ?wpk ?wpe
             rotate_left
             rotate_left
             iframe $h:ident
             case wpe => rfl
             case wpk => intro bm am; rfl
             iintro $h:ident))

/-- One read step over one object's footprint (rest + allocIs +
    pointsToBytes; everything else frames). -/
macro "wp_read1" e:term:max hr:ident ha:ident hp:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_read1_ecast $e ?wpe ?wplay
             rotate_left
             rotate_left
             iframe $hr:ident $ha:ident $hp:ident
             case wpe => rfl
             case wplay => rfl
             iintro ⟨$hr:ident, $ha:ident, $hp:ident⟩))

/-- One object-creation step (alloc+store compound): consumes the
    rest half, mints `allocIs` (named `hal`) + `pointsToBytes`
    (named `hpt`). `ha` is the fixture's address-arithmetic fact. -/
macro "wp_argobj" e:term:max ha:term:max h:ident hal:ident hpt:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_alloc_store_ecast $e ?wpe ?wprho ?wpsz ?wpaddr ?wpnz ?wplen ?wpnid ?wpal
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             iframe $h:ident
             case wpe => rfl
             case wprho => rfl
             case wpnid => rfl
             case wpal => rfl
             case wpsz => rfl
             case wpaddr => exact $ha
             case wpnz => wp_side
             case wplen => rfl
             iintro ⟨$h:ident, $hal:ident, $hpt:ident⟩))

/-- Two-object creation step (both argument injections in one atom):
    mints `hal1`/`hpt1` and `hal2`/`hpt2`. `ha1`/`ha2` are the two
    address-arithmetic facts. -/
macro "wp_argobj2" e:term:max ha1:term:max ha2:term:max h:ident
    hal1:ident hpt1:ident hal2:ident hpt2:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_alloc_store2_ecast $e ?wpe ?wprho ?wpszA ?wpaddrA ?wpnzA ?wplenA ?wpnidA ?wpalA ?wpszB ?wpaddrB ?wpnzB ?wplenB ?wpnidB ?wpalB
             rotate_left; rotate_left; rotate_left; rotate_left
             rotate_left; rotate_left; rotate_left; rotate_left
             rotate_left; rotate_left; rotate_left; rotate_left
             rotate_left; rotate_left
             iframe $h:ident
             case wpe => rfl
             case wprho => rfl
             case wpnidA => rfl
             case wpalA => rfl
             case wpnidB => rfl
             case wpalB => rfl
             case wpszA => rfl
             case wpaddrA => exact $ha1
             case wpnzA => wp_side
             case wplenA => rfl
             case wpszB => rfl
             case wpaddrB => exact $ha2
             case wpnzB => wp_side
             case wplenB => rfl
             iintro ⟨$h:ident, $hal1:ident, $hpt1:ident, $hal2:ident, $hpt2:ident⟩))

/-- Two-object read step (rest + two footprints; everything else
    frames). -/
macro "wp_read2" e:term:max hr:ident ha1:ident hp1:ident
    ha2:ident hp2:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_read2_ecast $e ?wpe ?wplay
             rotate_left
             rotate_left
             iframe $hr:ident $ha1:ident $hp1:ident $ha2:ident $hp2:ident
             case wpe => rfl
             case wplay => rfl
             iintro ⟨$hr:ident, $ha1:ident, $hp1:ident, $ha2:ident, $hp2:ident⟩))

/-- Read-write object step (the loop atom's store ladder): reads and
    re-writes one object's range; the points-to moves to the LAST
    write's image (named `hpOut`). -/
macro "wp_write1" e:term:max hr:ident ha:ident hp:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_write1_ecast $e ?wpe ?wprho ?wplay ?wplens
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             iframe $hr:ident $ha:ident $hp:ident
             case wpe => rfl
             case wprho => rfl
             case wplay => rfl
             case wplens => first | rfl | decide
             iintro ⟨$hr:ident, $ha:ident, $hp:ident⟩))

/-- Scratch-object step (create/store/load/kill within one atom):
    reads the `hr`/`haV`/`hpV` footprint, mints the dead scratch
    bytes as `hptS`. `ha` is the scratch address-arithmetic fact. -/
macro "wp_scratch1" e:term:max ha:term:max hr:ident haV:ident
    hpV:ident hptS:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_scratch1_ecast $e ?wpe ?wprho ?wplayk ?wpsz ?wpaddr ?wpnz ?wplen ?wpnid ?wpal
             rotate_left; rotate_left; rotate_left
             rotate_left; rotate_left; rotate_left
             rotate_left; rotate_left; rotate_left
             iframe $hr:ident $haV:ident $hpV:ident
             case wpe => rfl
             case wprho => rfl
             case wpnid => rfl
             case wpal => rfl
             case wplayk => rfl
             case wpsz => rfl
             case wpaddr => exact $ha
             case wpnz => wp_side
             case wplen => rfl
             iintro ⟨$hr:ident, $haV:ident, $hpV:ident, $hptS:ident⟩))

/-- The harness terminal: `nd_get` + the pure readout. -/
macro "wp_fin" hp:term:max h:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_get_done_pure_ecast ?wpp ?wpe
             rotate_left
             rotate_left
             iframe $h:ident
             case wpe => rfl
             case wpp => exact $hp))

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

/-! ## The registry-backing check (the C1 handoff's macro-side
    conversion, adjudicated): the walk macros stay THIN NAMED
    APPLIERS, and every law they apply is a REGISTERED heapWalk/heapWP
    entry — this check makes a law silently leaving the registry
    build-fatal (the registry stays the source of truth; the full
    goal-form-query applier is arc-19's search machinery). -/
open Lean in
#eval show Lean.Elab.Term.TermElabM Unit from do
  let backing : List Name :=
    [``RelSem.Cerb.wpk_seq_rest_ecast, ``RelSem.Cerb.wpk_seq_read1_ecast,
     ``RelSem.Cerb.wpk_seq_read2_ecast,
     ``RelSem.Cerb.wpk_seq_alloc_store_ecast,
     ``RelSem.Cerb.wpk_seq_alloc_store2_ecast,
     ``RelSem.Cerb.wpk_seq_scratch1_ecast,
     ``RelSem.Cerb.wpk_seq_write1_ecast,
     ``RelSem.Cerb.wpk_seq_get_ecast,
     ``RelSem.Cerb.wpk_get_done_pure_ecast,
     -- the heap op-rule macros' backing laws (wp_load/store/alloc/kill)
     ``RelSem.Cerb.wpk_load, ``RelSem.Cerb.wpk_store,
     ``RelSem.Cerb.wpk_alloc, ``RelSem.Cerb.wpk_kill]
  for n in backing do
    let some _ ← RelSem.LawRegistry.byName? n
      | throwError "CerbHeapWalk registry-backing check: the walk/op           macro law {n} is NOT registered — the tactic layer may only           apply registered laws (R4)"
  Lean.logInfo s!"CerbHeapWalk registry-backing check:     {backing.length} macro-backing laws registered"

end Cerb
end RelSem
