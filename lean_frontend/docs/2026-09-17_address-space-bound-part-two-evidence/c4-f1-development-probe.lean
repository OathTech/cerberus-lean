import CerbND
import CerbCall
import Core
import Core_run_aux
import Driver
import LemLibTheorems
open Lem_Num Lem_Pervasives Lem_List Lem_Set Lem_Map Lem_Maybe Lem_Function
  Lem_Show Lem_Show_extra Lem_Bool Lem_Basic_classes Lem_Map_extra
  Lem_String_extra Lem_Num_extra Lem_Set_helpers Lem_Either Lem_Assert_extra
  Lem_Set_extra Lem_List_extra Lem_Relation Lem_Tuple Lem_String Lem_Word Mem
set_option autoImplicit false
namespace F1

def runOne {a info err cs st : Type} (m : ndM a info err cs st) (s : st) :
    nd_action a info err cs st × st :=
  match m with | ND f => f s

theorem runOne_bind_active {k : Nat} {a b cs err info st : Type}
    {m : ndM a info err cs st} {f : a → ndM b info err cs st} {s s' : st} {z : a}
    (h : runOne m s = (NDactive z, s')) :
    runOne (@nd_bind _ _ _ _ _ _ ⟨Nat.succ k⟩ m f) s = runOne (f z) s' := by
  rcases m with ⟨g⟩
  dsimp only [runOne] at h
  show runOne (nd_bind_lemFuel (Nat.succ k) (ND g) f) s = _
  unfold nd_bind_lemFuel
  dsimp only [runOne]
  rw [h]
  dsimp only
  rcases hf : f z with ⟨g'⟩
  rfl

/-- The errno allocation's address at top `top`: the 4-byte object aligned down to 4. -/
def errnoAddr (top : Int) : Int := top - 4 - (top - 4) % 4

/-- The allocator on the cold state: ACTIVE at `errnoAddr top` whenever `8 ≤ top`. -/
theorem allocator_errno (top : Int) (h : 8 ≤ top) :
    runOne (CerbMem.allocator 4 4) (CerbMem.initialMemState top) =
      (NDactive ((0 : Int), errnoAddr top),
       { CerbMem.initialMemState top with nextAllocId := 1, lastUsed := some 0, lastAddress := errnoAddr top }) := by
  have h1 : ¬ ((top - 4 : Int) < 0) := by omega
  have h2 : ¬ ((top - 4 - (top - 4) % 4 : Int) ≤ 0) := by omega
  simp only [runOne, CerbMem.allocator, CerbMem.initialMemState, errnoAddr]
  simp [h1]
  omega


/-- The errno pointer at top `top`: allocation id 0 at `errnoAddr top`. -/
def errnoPtr (top : Int) : CerbMem.PointerValue :=
  .PV (.Prov_some 0) (.PVconcrete none (errnoAddr top))

/-- drive's errno memory action (driver.lem:1860-1868 as FuelExemplar.setupTail states it). -/
def errnoAction [LemFuel] : CerbMem.memM CerbMem.PointerValue :=
  nd_bind (CerbMem.allocateObject fmapEmpty 0 (PrefOther "errno") (CerbMem.integerIval 4) signed_int none none)
    (fun (ptr_val : CerbMem.PointerValue) =>
      let zero := CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int))
      nd_bind (CerbMem.storeM fmapEmpty (CerbLocation.other "errno init") signed_int false ptr_val zero)
        (fun (_ : CerbMem.Footprint) => nd_return ptr_val))

/-- The errno allocation record. -/
def errnoAlloc (top : Int) : CerbMem.Allocation :=
  { base := errnoAddr top, size := 4, ty := some signed_int, isReadonly := .IsWritable, prefix_ := PrefOther "errno" }

/-- The memory state after the errno allocateObject (before the store): the allocator's update,
    the allocation record inserted at id 0, the 4 unspecified bytes written at the address. -/
def σalloc (top : Int) : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState top with
        nextAllocId := 1
        lastUsed := some 0
        lastAddress := errnoAddr top
        allocations := (CerbMem.initialMemState top).allocations.insert 0 (errnoAlloc top) }
    (errnoAddr top)
    (CerbMem.memValueToBytes fmapEmpty (CerbMem.initialMemState top).funptrmap (.MVunspecified signed_int)).snd

theorem allocateObject_errno (k : Nat) (top : Int) (h : 8 ≤ top) :
    runOne (@CerbMem.allocateObject ⟨Nat.succ k⟩ fmapEmpty 0 (PrefOther "errno") (CerbMem.integerIval 4) signed_int none none)
        (CerbMem.initialMemState top) = (NDactive (errnoPtr top), σalloc top) := by
  have hsz : (CerbMem.sizeofCtype fmapEmpty signed_int : Int) = 4 := by decide
  unfold CerbMem.allocateObject
  simp only [CerbMem.integerIval]
  rw [hsz]
  exact (runOne_bind_active (allocator_errno top h)).trans rfl

/-- The store of `0` through the errno pointer on `σalloc top` is ACTIVE (its footprint). -/
theorem storeM_errno_active (k : Nat) (top : Int) :
    (runOne (@CerbMem.storeM ⟨Nat.succ k⟩ fmapEmpty (CerbLocation.other "errno init") signed_int false (errnoPtr top)
        (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int)))) (σalloc top)).1
      = NDactive (.FP .W (errnoAddr top) 4) := by
  have hcompat : CerbMem.ctypeMemCompatible signed_int
      (CerbMem.typeofMval (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int)))) = true := by decide
  have hget : (σalloc top).allocations.get? 0 = some (errnoAlloc top) := by
    first | rfl | decide | (simp [σalloc, CerbMem.writeBytesTo, CerbMem.initialMemState])
  have hsz : (CerbMem.sizeofCtype fmapEmpty signed_int : Int) = 4 := by decide
  have hbounds : CerbMem.isInBounds (errnoAlloc top) (errnoAddr top) 4 = true := by
    simp [CerbMem.isInBounds, errnoAlloc]
  have hro : (errnoAlloc top).isReadonly = .IsWritable := rfl
  have hatomic : @CerbMem.isAtomicMemberAccess ⟨Nat.succ k⟩ fmapEmpty (errnoAlloc top) signed_int (errnoAddr top) = false := rfl
  unfold CerbMem.storeM
  simp only [runOne, errnoPtr, hcompat, hget]
  simp only [hsz, hbounds, hro, hatomic, Bool.not_true, Bool.false_eq_true, if_false]


/-- The memory state after drive's whole errno action (allocate + store 0) at top `top`. -/
def σstore [LemFuel] (top : Int) : CerbMem.MemState :=
  (runOne (CerbMem.storeM fmapEmpty (CerbLocation.other "errno init") signed_int false (errnoPtr top)
      (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int)))) (σalloc top)).2

/-- THE errno lemma: on the cold state at any top ≥ 8, drive's errno action is ACTIVE with the errno pointer
    and leaves `σstore top`. -/
theorem errnoAction_active (k : Nat) (top : Int) (h : 8 ≤ top) :
    runOne (@errnoAction ⟨Nat.succ k⟩) (CerbMem.initialMemState top) = (NDactive (errnoPtr top), @σstore ⟨Nat.succ k⟩ top) := by
  unfold errnoAction
  rw [runOne_bind_active (allocateObject_errno k top h)]
  dsimp only
  rw [runOne_bind_active (Prod.ext (storeM_errno_active k top) rfl)]
  rfl

#print axioms errnoAction_active

/-! ## Is step_ctx lazy in the memory state on a pure-value arena? (the round_done `hsteps` rfl) -/
def mainSym : sym := Symbol "" 0 SD_None
def fortyTwo : value := Vloaded (LVspecified (OVinteger (CerbMem.integerIval 42)))
def mainBody : generic_expr core_run_annotation Unit sym := Expr [] (Epure (Pexpr [] () (PEval fortyTwo)))
def mainDecl : generic_fun_map_decl Unit core_run_annotation := Proc CerbLocation.unknown none BTy_unit [] mainBody
def exemplarFile : file core_run_annotation :=
  { main := some mainSym, calling_convention0 := default, tagDefs := default, stdlib := fmapEmpty, impl0 := fmapEmpty,
    globs := [], funs := fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) mainSym mainDecl fmapEmpty,
    extern := fmapEmpty, funinfo := fmapEmpty, loop_attributes1 := default, visible_objects_env0 := default }
def thS (top : Int) (env : List (Fmap sym value)) : thread_state :=
  { arena := mainBody, stack0 := Stack_empty, errno := errnoPtr top,
    current_loc := CerbLocation.other "Driver.drive",
    exec_loc := ELoc_normal [(mainSym, CerbLocation.other "Driver.drive")],
    env := env, current_proc_opt := some mainSym }
example (k : Nat) (top : Int) (σ : CerbMem.MemState) (env : List (Fmap sym value)) :
    @step_ctx ⟨Nat.succ k⟩ fmapEmpty σ exemplarFile (create_extern_symmap exemplarFile) 0 (none, thS top env)
      = [Step_done2 fortyTwo] := rfl
end F1
