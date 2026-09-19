import CerbMem
import CerbGlobal
import CerbUtils
import CerbMemAllocatorProofs

/-! AUDITOR probe A (2026-09-19, audit/seam-hygiene at 34b8e15a8, fresh build).
    §1 the orchestrator's two rfl probes must FAIL (expect exactly two `rfl` errors below);
    §2 `failwithI` is opaque (#print); §3 the H3 trio's axioms; §4 oomKill definitional;
    §5 the auditor's OWN arm-reduction lemmas (item 2/4). -/

-- §1 (expected: 2 errors)
example : CerbMem.combineProv (.Prov_symbolic 0) .Prov_none = .Prov_none := by rfl
example : CerbMem.bytesToInt [] false = none := by rfl

-- §2
#print failwithI
#print axioms failwithI

-- §3
#print axioms CerbMem.allocator_below_request_kills
#print axioms CerbMem.allocator_active_sound
#print axioms CerbMem.oomKill
#check @CerbMem.allocator_below_request_kills

-- §4
example : CerbMem.oomKill = (Other (MerrOther "Concrete.allocator: failed (out of memory)") : kill_reason mem_error) := rfl
example : CerbUtils.STD_ "§6.2.2#3" (7 : Nat) = 7 := rfl
example (s : String) : CerbUtils.begin_timing s = () := rfl

-- §5 auditor's own arm reductions (each guard reduces to its default because has_switch … = false by rfl)
theorem audit_eqPtrval_none_none (loc : CerbLocation.Loc) (a1 a2 : Int) :
    CerbMem.eqPtrval loc (.PV .Prov_none (.PVconcrete none a1)) (.PV .Prov_none (.PVconcrete none a2))
      = CerbMem.memReturn (a1 == a2) := rfl
theorem audit_eqPtrval_device_device (loc : CerbLocation.Loc) (a1 a2 : Int) :
    CerbMem.eqPtrval loc (.PV .Prov_device (.PVconcrete none a1)) (.PV .Prov_device (.PVconcrete none a2))
      = CerbMem.memReturn (a1 == a2) := rfl
theorem audit_lePtrval_default (loc : CerbLocation.Loc) (a1 a2 : Int) :
    CerbMem.lePtrval loc (.PV .Prov_none (.PVconcrete none a1)) (.PV .Prov_none (.PVconcrete none a2))
      = CerbMem.memReturn (decide (a1 ≤ a2)) := rfl
theorem audit_ltPtrval_default (loc : CerbLocation.Loc) (a1 a2 : Int) :
    CerbMem.ltPtrval loc (.PV .Prov_none (.PVconcrete none a1)) (.PV .Prov_none (.PVconcrete none a2))
      = CerbMem.memReturn (decide (a1 < a2)) := rfl
-- intfromptr's concrete arm IS its default (the is_PNVI guard reduces)
theorem audit_intfromptr_concrete (loc : CerbLocation.Loc) (ty : ctype) (ity : integerType)
    (prov : CerbMem.Provenance) (addr : Int) :
    CerbMem.intfromptr loc ty ity (.PV prov (.PVconcrete none addr)) =
      (match CerbMem.minIval ity with
       | .IV _ ityMin =>
         match CerbMem.maxIval ity with
         | .IV _ ityMax =>
           if addr < ityMin || ityMax < addr then CerbMem.memFail MerrIntFromPtr loc
           else CerbMem.memReturn (.IV prov addr)) := rfl
-- the guard shape itself, stated abstractly with the named lemma
example {α : Type} (a b : α) :
    (if CerbGlobal.has_switch (.pointer_arith .PERMISSIVE) then a else b) = b := by
  rw [CerbGlobal.has_switch_pointer_arith_permissive_eq]; rfl
example {α : Type} (a b : α) (initOpt : Option CerbMem.MemValue) :
    (if initOpt.isNone && CerbGlobal.has_switch .zero_initialised then a else b) = b := by
  rw [CerbGlobal.has_switch_zero_initialised_eq, Bool.and_false]; rfl
