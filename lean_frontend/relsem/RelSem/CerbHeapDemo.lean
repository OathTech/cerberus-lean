/-
  RelSem.CerbHeapDemo — arc-16 S2 (2026-08-24): THE FRAMING
  DEMONSTRATION (charter success criterion 2). Design record:
  docs/2026-08-24_arc16-s2-cerbmem-heap-ra.md §7.

  Two allocations, A and B. The program stores into A, then loads
  from B. The theorem's shape IS the demonstration:

  * the load's result `mvB` is fixed by B's bytes and the rest state
    ALONE (its `hreconB` hypothesis mentions only `bsB` and `r`) —
    the store into A cannot touch it, by FRAMING, not by computation;
  * in the proof, the store step consumes exactly
    {rest, allocA, bytesA} while {allocB, bytesB} ride in the frame,
    and the load step consumes exactly {rest, allocB, bytesB} while
    A's updated resources ride in the frame — at NO point does
    reasoning about one allocation mention the other's footprint.

  Everything is symbolic (addresses, records, byte lists) — only the
  per-allocation side conditions are hypotheses; nothing here
  enumerates the heap (two-faces rule).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.CerbHeapWP

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.BI Iris.ProgramLogic

variable {GF : BundledGFunctors}

/-- Store to allocation A, then load from allocation B: B's read is
    untouched by A's write, with A's footprint never entering the
    load reasoning. -/
theorem two_alloc_frame [CerbHeapGS GF] {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF}
    -- allocation A (the store target)
    {locA : CerbLocation.Loc} {tyA : ctype} {aidA addrA : Int}
    {alA : CerbMem.Allocation} {mvA : CerbMem.MemValue}
    {oldA newA : List CerbMem.AbsByte} {dqaA : DFrac}
    -- allocation B (the load source)
    {locB : CerbLocation.Loc} {tyB : ctype} {aidB addrB : Int}
    {alB : CerbMem.Allocation} {bsB : List CerbMem.AbsByte}
    {mvB : CerbMem.MemValue} {dqaB dqbB : DFrac}
    -- the shared remainder
    {r : driver_state} {dqr : DFrac}
    {k : CerbMem.Footprint × CerbMem.MemValue → KDriveExpr}
    -- A's store side conditions
    (hcompatA : CerbMem.ctypeMemCompatible tyA
      (CerbMem.typeofMval mvA) = true)
    (hboundsA : CerbMem.isInBounds alA addrA
      (CerbMem.sizeofCtype tyA) = true)
    (hroA : alA.isReadonly = .IsWritable)
    (hatomicA : CerbMem.isAtomicMemberAccess alA tyA addrA = false)
    (hbytesA : CerbMem.memValueToBytes r.layout_state.funptrmap mvA
      = (r.layout_state.funptrmap, newA))
    (hlenA : newA.length = oldA.length)
    -- B's load side conditions (mention ONLY B and r)
    (hboundsB : CerbMem.isInBounds alB addrB
      (CerbMem.sizeofCtype tyB) = true)
    (hatomicB : CerbMem.isAtomicMemberAccess alB tyB addrB = false)
    (hlenB : bsB.length = CerbMem.sizeofCtype tyB)
    (hreconB : CerbMem.reconstructValue
        r.layout_state.lastUsedUnionMembers r.layout_state.funptrmap
        addrB tyB bsB = mvB)
    (hnotboolB : Kit.isBoolTy tyB = false) :
    (restIs (GF := GF) dqr r
        ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA (.own 1) oldA
        ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB) ∗
      ((restIs dqr r
          ∗ allocIs aidA dqaA alA ∗ pointsToBytes addrA (.own 1) newA
          ∗ allocIs aidB dqaB alB ∗ pointsToBytes addrB dqbB bsB)
        -∗ WP (k (.FP .R addrB (CerbMem.sizeofCtype tyB), mvB))
              @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq (liftMem (CerbMem.storeM locA tyA false
            (.PV (.Prov_some aidA) (.PVconcrete none addrA)) mvA))
          (fun _ => KExpr.seq (liftMem (CerbMem.loadM locB tyB
            (.PV (.Prov_some aidB) (.PVconcrete none addrB)))) k)
        : KDriveExpr) @ s ; E {{ Φ }} := by
  iintro ⟨⟨Hr, HaA, HpA, HaB, HpB⟩, Hcont⟩
  -- STEP 1: the store — consumes {rest, A}; {B} rides the frame.
  iapply wpk_store hcompatA hboundsA hroA hatomicA hbytesA hlenA
  isplitl [Hr HaA HpA]
  · iframe Hr HaA HpA
  iintro ⟨Hr, HaA, HpA⟩
  -- STEP 2: the load — consumes {rest, B}; A's updated resources
  -- ride the frame. Nothing below mentions A's footprint.
  iapply wpk_load hboundsB hatomicB hlenB hreconB hnotboolB
  isplitl [Hr HaB HpB]
  · iframe Hr HaB HpB
  iintro ⟨Hr, HaB, HpB⟩
  iapply Hcont
  iframe Hr HaA HpA HaB HpB

end Cerb
end RelSem
