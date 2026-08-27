/-
  RelSem.T5Seam — arc-18 R2 (2026-08-26): [F3] ACCEPTANCE — THE
  TWO-SPELLING LOOP-HEAD SEAM, NORMALIZED THROUGH THE LAYER.

  The C3b-measured seam: falling INTO `save while_531` leaves
  iteration 1's loop head at a DIFFERENT SPELLING from the stored
  continuation later iterations jump to (outer-annotation hoist +
  partial forcing — propositionally distinct states; the reason T5
  has five walks, not three, and TWIN builders `mkLH1`/`mkLH`).

  THE [F3] CONTRACT, demonstrated here: the seam is discharged
  ENGINE-SIDE against ONE declared invariant — the label's SPELLING
  TABLE (`JoinSpellings`) carries both builders, the layer's derived
  head family (`SegInv.St`) routes index 0 through the fall-in
  spelling and indices ≥ 1 through the stored spelling, and BOTH
  spellings' body obligations are stated over the ONE declaration —
  twin-builder vocabulary never reaches the user surface:

  * `t5SeamInv_St_eq` — THE NORMALIZATION, kernel-checked: the
    layer's derived family coincides with the landed C3b family
    `T5.St` at every index (the landed alignment rfls ARE the
    proof: `St0_align` = the fall-in leg, `St_align` = the stored).
  * `t5_seam_body0` — the k = 0 body obligation (the FALL-IN
    spelling underneath), discharged by the `bfirst` twin's chain.
  * `t5_seam_bodyS` — the k ≥ 1 body obligation (the STORED
    spelling underneath), discharged by the `b` twin's chain.
  Both obligations quote ONLY `(t5SeamInv p).St`.

  SCOPE (honest): the walk-pack facts enter as ONE bundled
  hypothesis (`BPack`) at each instance — their ∀-k closure over the
  concrete harness family is exactly the charter's R4 rung (the C3b
  corrected map's items 1-2); this file is the [F3] MECHANISM's
  acceptance, not T5-the-theorem (also R4).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T5Inv
import RelSem.Segment

set_option autoImplicit false

namespace RelSem.T5S

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit RelSem.T5W RelSem.T5
open Lem_Basic_classes (ordCompare)

/-! ## The declaration: ONE invariant at `while_531` -/

/-- T5's loop-head spelling table ([F3]): fall-in = the `mkLH1` twin
    (the entry walk's own endpoint arena), stored = `mkLH` (the
    labeled-continuation arena). THE seam lives here — and only
    here. -/
noncomputable def spell5 : Seg.JoinSpellings Seg.LoopComps where
  entry c := mkLH1 c.env c.mem c.tr c.aid c.exc c.symc c.ctr
  stored c := mkLH c.env c.mem c.tr c.aid c.exc c.symc c.ctr

/-- The declared invariant's components at the k-th visit: the landed
    C3b family's own projections (`T5.St` — s = triF k, i = k at the
    k-th head; never transcribed). -/
noncomputable def t5At (p : Pm) (k : Nat) : Seg.LoopComps :=
  { env := envOf (St p k), mem := (St p k).layout_state,
    tr := (St p k).trace,
    aid := (St p k).core_run_state0.aid_supply,
    exc := (St p k).core_run_state0.excluded_supply,
    symc := (St p k).core_run_state0.sym_supply,
    ctr := (St p k).dr_step_counter }

/-- THE MAP ENTRY: `while_531 ↦` the one declared invariant. -/
noncomputable def t5SeamInv (p : Pm) : Seg.SegInv :=
  { Comp := Seg.LoopComps, label := symWhile, spell := spell5,
    at_ := t5At p }

/-! ## THE NORMALIZATION (kernel-checked) -/

/-- [F3]: the layer's derived head family — index 0 through the
    FALL-IN spelling, indices ≥ 1 through the STORED — coincides
    definitionally with the landed C3b family. The landed alignment
    rfls are the whole proof: the seam is an index-routing fact of
    the declaration, not the user's problem. -/
theorem t5SeamInv_St_eq (p : Pm) : ∀ k, (t5SeamInv p).St k = St p k
  | 0 => (St0_align p).symm
  | k + 1 => (St_align p k).symm

/-! ## The discharge instances (both spellings, ONE declaration) -/

/-- The body walks' hypothesis pack, bundled (the fact list whose
    ∀-k closure is the R4 rung; identical for both twins). -/
structure BPack (env : Fmap sym value) (mem : CerbMem.MemState)
    (exc symc : Nat) (n sv iv : Int) : Prop where
  hdig : CerberusFresh.digest () = ""
  hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env
  hlkN : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN env
    = some (Vobject (OVpointer nPtr))
  hlkS : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS env
    = some (Vobject (OVpointer sPtr))
  hlkI : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symI env
    = some (Vobject (OVpointer iPtr))
  hdd0 : mem.deadAllocations.contains 0 = false
  hdd2 : mem.deadAllocations.contains 2 = false
  hdd3 : mem.deadAllocations.contains 3 = false
  halN : mem.allocations.get? 0 = some allocN
  halS : mem.allocations.get? 2 = some allocS
  halI : mem.allocations.get? 3 = some allocI
  hfpm : mem.funptrmap = []
  hlum : mem.lastUsedUnionMembers = []
  hrdN : CerbMem.readBytesFrom mem nAddr 4
    = [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3]
  hrdS : CerbMem.readBytesFrom mem sAddr 4
    = [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3]
  hrdI : CerbMem.readBytesFrom mem iAddr 4
    = [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3]
  hrecN : CerbMem.reconstructValue [] [] nAddr intCty
    [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3] = mvi n
  hrecS : CerbMem.reconstructValue [] [] sAddr intCty
    [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3] = mvi sv
  hrecI : CerbMem.reconstructValue [] [] iAddr intCty
    [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3] = mvi iv
  hi2bS : CerbMem.memValueToBytes [] (mvi (sv + iv))
    = ([], [mkByte (sv + iv) 0, mkByte (sv + iv) 1,
            mkByte (sv + iv) 2, mkByte (sv + iv) 3])
  hi2bI : CerbMem.memValueToBytes [] (mvi (iv + 1))
    = ([], [mkByte (iv + 1) 0, mkByte (iv + 1) 1,
            mkByte (iv + 1) 2, mkByte (iv + 1) 3])
  hlt : iv < n
  hn1 : n ≤ 100
  hiv0 : 0 ≤ iv
  hsv0 : 0 ≤ sv
  hsv1 : sv ≤ 4950
  hscB : symc < 1152921504606846976
  hexcB : exc < 1152921504606846976

/-- The T5 driver round computation. -/
abbrev C5 := Seg.dnmsC t5File.tagDefs 0

/-- [F3] INSTANCE 1 — the FALL-IN spelling's body obligation (k = 0),
    stated over the ONE declared invariant, discharged by the
    `bfirst` twin's 78-round chain. No twin-builder name appears in
    the statement. -/
theorem t5_seam_body0 (p : Pm)
    (hp : BPack (envOf (St p 0)) (St p 0).layout_state
      (St p 0).core_run_state0.excluded_supply
      (St p 0).core_run_state0.sym_supply p.n (triF 0) 0) :
    Seg.Seg C5 78 ((t5SeamInv p).St 0) ((t5SeamInv p).St 1) := by
  rw [t5SeamInv_St_eq p 0, t5SeamInv_St_eq p 1]
  exact Seg.Seg.of_chain (C := C5) (k := 78)
    (s := St p 0) (s' := St p 1)
    (bfirst_chainrel (envOf (St p 0)) (St p 0).layout_state
      (St p 0).trace (St p 0).core_run_state0.aid_supply
      (St p 0).core_run_state0.excluded_supply
      (St p 0).core_run_state0.sym_supply (St p 0).dr_step_counter
      p.n (triF 0) 0
      hp.hdig hp.hbuilt hp.hlkN hp.hlkS hp.hlkI hp.hdd0 hp.hdd2
      hp.hdd3 hp.halN hp.halS hp.halI hp.hfpm hp.hlum hp.hrdN
      hp.hrdS hp.hrdI hp.hrecN hp.hrecS hp.hrecI hp.hi2bS hp.hi2bI
      hp.hlt hp.hn1 hp.hiv0 hp.hsv0 hp.hsv1 hp.hscB hp.hexcB)

/-- [F3] INSTANCE 2 — the STORED spelling's body obligation (k ≥ 1),
    stated over the SAME declaration, discharged by the `b` twin's
    79-round chain. -/
theorem t5_seam_bodyS (p : Pm) (k : Nat)
    (hp : BPack (envOf (St p (k + 1))) (St p (k + 1)).layout_state
      (St p (k + 1)).core_run_state0.excluded_supply
      (St p (k + 1)).core_run_state0.sym_supply
      p.n (triF (k + 1)) (k + 1)) :
    Seg.Seg C5 79 ((t5SeamInv p).St (k + 1))
      ((t5SeamInv p).St (k + 2)) := by
  rw [t5SeamInv_St_eq p (k + 1), t5SeamInv_St_eq p (k + 2),
    St_align p k]
  exact Seg.Seg.of_chain (C := C5) (k := 79)
    (b_chainrel (envOf (St p (k + 1))) (St p (k + 1)).layout_state
      (St p (k + 1)).trace
      (St p (k + 1)).core_run_state0.aid_supply
      (St p (k + 1)).core_run_state0.excluded_supply
      (St p (k + 1)).core_run_state0.sym_supply
      (St p (k + 1)).dr_step_counter
      p.n (triF (k + 1)) (k + 1)
      hp.hdig hp.hbuilt hp.hlkN hp.hlkS hp.hlkI hp.hdd0 hp.hdd2
      hp.hdd3 hp.halN hp.halS hp.halI hp.hfpm hp.hlum hp.hrdN
      hp.hrdS hp.hrdI hp.hrecN hp.hrecS hp.hrecI hp.hi2bS hp.hi2bI
      hp.hlt hp.hn1 hp.hiv0 hp.hsv0 hp.hsv1 hp.hscB hp.hexcB)

end RelSem.T5S
