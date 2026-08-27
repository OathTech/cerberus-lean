/-
  RelSem.T4Walks — arc-18 R5 (2026-08-27): THE T4 EQUATION SUPPLY.

  NAMING (arc-18 R2, the walk→segment map in
  docs/2026-08-26_arc18-r2-donor-correspondence.md): "walk" is
  ENGINE-ROOM vocabulary — the drive/mint layer's term for a chain of
  evaluator rounds. The user-facing surface calls these SEGMENTS
  (RelSem/Segment.lean consumes each chain as one `Seg`).

  tests/verify/t4_struct_member.c — THE STRUCT-MEMBER FIXTURE (the
  arc-7 exit-criterion target): `int memb(int v)` stores v into
  `s.a`, 7 into the sibling `s.b`, and reads `s.a` back — member
  write/read of a symbolic v THROUGH a second member's write (frame
  across offsets at the pinned layout +0/+4, size 8).

  ONE walk (no loop — the whole run is a single straight-line
  segment): `w` — mkRdy through create-struct / store-unspecified /
  the two NEG-store cycles (each draws ONE fresh symbol at the OPEN
  seed — the arc-16 S4 collision diagnosis's supply-reading rounds,
  now minted under the apartness hypothesis) / the s.a read-back /
  kill / the return jump to the thread's terminal — terminal chain
  `w_chainrel`. Heap maps and supplies FREE; the argument value x
  SYMBOLIC (int-range).

  Fixture data below is DATA (symbols, addresses, byte images, the
  builder records); the program text is fixture-derived (the funs
  lookup), never transcribed. The byte-roundtrip lemmas are the
  T1AppEq recipe cloned fixture-locally (the T5Inv precedent — the
  retirement-scheduled files are NOT imported).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.DeriveState
import RelSem.RoundEval
import RelSem.ConstructLaws
import RelSem.SlateFiles
import RelSem.Kit.Map
import RelSem.CerbHeapWalk
-- the segment layer: registration attributes + the env-peel
-- discharger the obligation feeds consume
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.T4W

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)

/-! ## Fixture data (symbols, addresses, byte images) -/

def symV : sym := Symbol "" 1965435164061188486 (SD_Id "v")
def symS : sym := Symbol "" 9409450202036847209 (SD_Id "s")

/-- `struct S`'s C type (the parsed literal; tag from the pinned
    dump). -/
def structSCty : ctype := Ctype [] (Struct structSSym)

def vAddr : Int := 281474976710648
def errAddr : Int := 281474976710644
def sAddr : Int := 281474976710636   -- s (member .a at +0)
def bAddr : Int := 281474976710640   -- member .b (= s + 4)

def vPtr : CerbMem.PointerValue := .PV (.Prov_some 0) (.PVconcrete none vAddr)
def errPtr : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none errAddr)
def sPtr : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none sAddr)
def bPtr : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none bAddr)

def allocV : CerbMem.Allocation :=
  { base := vAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "errno" }
def allocS : CerbMem.Allocation :=
  { base := sAddr, size := 8, ty := some structSCty,
    prefix_ := PrefOther "Core" }

/-- The 4-byte little-endian image of a 32-bit int value. -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

/-- The int byte image as a list. -/
def i32 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

def uninitByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

abbrev intCty : ctype := Ctype [] (Basic (Integer (Signed Int_)))

abbrev mvi (v : Int) : CerbMem.MemValue :=
  CerbMem.MemValue.MVinteger (Signed Int_) (CerbMem.IntegerValue.IV .Prov_none v)

theorem i32_len (v : Int) : (i32 v).length = 4 := rfl

/-! ## Byte roundtrip at symbolic values (the T1AppEq recipe, cloned
    fixture-locally — the retirement-scheduled files are NOT
    imported; T5Inv precedent) -/

/-- THE BYTE ROUNDTRIP: 4 little-endian bytes of an int-range integer
    recombine (signed) to the integer. -/
theorem roundtrip4 (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) :
    CerbMem.bytesToInt (i32 x) true = some x := by
  unfold i32 CerbMem.bytesToInt mkByte
  simp only [List.any, Option.isNone, Bool.or_false, CerbMem.bytesToInt.go]
  by_cases hx : x < 0
  · have hy0 : (0:Int) ≤ 4294967296 + x := by omega
    have hy1 : (0:Int) ≤ (4294967296 + x) / 256 := by omega
    have hy2 : (0:Int) ≤ (4294967296 + x) / 65536 := by omega
    have hy3 : (0:Int) ≤ (4294967296 + x) / 16777216 := by omega
    have d1 : (4294967296 + x) / 256 / 256 = (4294967296 + x) / 65536 := by omega
    have d2 : (4294967296 + x) / 65536 / 256 = (4294967296 + x) / 16777216 := by omega
    have d3 : (4294967296 + x) / 16777216 / 256 = 0 := by omega
    simp only [hx, if_true]
    simp [Int.shiftLeft_eq, Int.shiftRight_eq_div_pow, Int.toNat_of_nonneg hy0,
      Int.toNat_of_nonneg hy1, Int.toNat_of_nonneg hy2, Int.toNat_of_nonneg hy3]
    split <;> refine congrArg some ?_ <;> omega
  · have hx0 : (0:Int) ≤ x := by omega
    have hx1 : (0:Int) ≤ x / 256 := by omega
    have hx2 : (0:Int) ≤ x / 65536 := by omega
    have hx3 : (0:Int) ≤ x / 16777216 := by omega
    have d1 : x / 256 / 256 = x / 65536 := by omega
    have d2 : x / 65536 / 256 = x / 16777216 := by omega
    have d3 : x / 16777216 / 256 = 0 := by omega
    simp only [hx, if_false]
    simp [Int.shiftLeft_eq, Int.shiftRight_eq_div_pow, Int.toNat_of_nonneg hx0,
      Int.toNat_of_nonneg hx1, Int.toNat_of_nonneg hx2, Int.toNat_of_nonneg hx3]
    split <;> refine congrArg some ?_ <;> omega

/-- reconstructValue on an int-range byte image = the integer
    (address-generic — serves both the v-load and the s.a
    read-back). -/
theorem recon_i32 (addr v : Int) (h1 : -2147483648 ≤ v)
    (h2 : v ≤ 2147483647) :
    CerbMem.reconstructValue [] [] addr intCty (i32 v) = mvi v := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [show CerbMem.bytesToInt (i32 v) true = some v
    from roundtrip4 v h1 h2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, i32, mkByte]

/-- memValueToBytes at the symbolic int image. -/
theorem i2b_i32 (v : Int) :
    CerbMem.memValueToBytes [] (mvi v) = ([], i32 v) := rfl

/-! ## The builders -/

/-- `memb`'s Core body (fixture-derived — never transcribed). -/
def membBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) membT4Sym
      t4File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The concrete ready env (v bound to its argument object; the
    harness instantiation of the builder's free env binder). -/
def envRdy : Fmap sym value :=
  fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symV
    (Vobject (OVpointer vPtr)) fmapEmpty

/-- The ready thread (arena = memb's body; env parametric — the T5
    free-env builder discipline: symbolic-value lookups route through
    the lookup-pattern hypotheses + the env lane, never a
    materialized-spelling ground walk). -/
def thRdy (env : Fmap sym value) : thread_state :=
  { arena := membBody,
    stack0 := Stack_empty,
    errno := errPtr,
    exec_loc := ELoc_normal [(membT4Sym, CerbLocation.other "RelSem.callND")],
    current_loc := CerbLocation.other "RelSem.callND",
    env := [env],
    current_proc_opt := some membT4Sym }

/-- The ready memory at open maps (post-injection, post-errno; literal
    scalar fields — the T5W `mkRdy` builder discipline). -/
def memRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : CerbMem.MemState :=
  { CerbMem.initialMemState with
    nextAllocId := 2, lastAddress := errAddr,
    bytemap := bm, allocations := am }

/-- THE READY BUILDER (the walk's from-state). -/
def mkRdy (env : Fmap sym value)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t4File,
    core_extern := create_extern_symmap t4File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy env))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t4File)).labeled },
    layout_state := memRdy bm am,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-! ## THE WALK `w` — mkRdy through the whole run to the thread's
    terminal (terminal chain; ~56 rounds). The struct-layout facts
    (sizeof/alignof/member offsets/unspec image) are hypotheses
    because CerbMem computes them against the tag-table EXTERN — each
    is discharged from `htags` at the theorem (the rT vocabulary,
    arc-17 S3). The apartness bound `hscB` is the T4SeedApart guard's
    shadow at the builder's symbolic supply: both fresh draws (symc,
    symc + 1) stay below every static symbol number. -/

set_option Elab.async false in


derive_rounds wa (env : Fmap sym value)
  (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat) (x : Int)
  (htags : CerbTags.tagDefs () = t4File.tagDefs)
  (hdig : CerberusFresh.digest () = "")
  (hscB : symc + 1 < 229457971439601039)
  (hexcB : exc + 1 < 229457971439601039)
  (halV : am.get? 0 = some allocV)
  (hrdV : CerbMem.readBytesFrom (memRdy bm am) vAddr 4 = i32 x)
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env)
  (hlkV : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symV env
    = some (Vobject (OVpointer vPtr)))
  (hsz : CerbMem.sizeofCtype structSCty = 8)
  (halign : CerbMem.alignofIval structSCty
    = CerbMem.IntegerValue.IV .Prov_none 4)
  (hshiftA : CerbMem.memberShiftPtrval sPtr structSSym
    (Identifier CerbLocation.Loc.unknown "a") = sPtr)
  (hshiftB : CerbMem.memberShiftPtrval sPtr structSSym
    (Identifier CerbLocation.Loc.unknown "b") = bPtr)
  (hunspec : CerbMem.memValueToBytes [] (.MVunspecified structSCty)
    = ([], [CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
            CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
            CerbMem.paddingByte, CerbMem.paddingByte]))
  (hszI : CerbMem.sizeofCtype (Ctype [] (Basic (Integer (Signed Int_)))) = 4)
  (hrng1 : -2147483648 ≤ x) (hrng2 : x ≤ 2147483647)
  (hrecv : CerbMem.reconstructValue [] [] vAddr intCty (i32 x) = mvi x)
  (hrecs : CerbMem.reconstructValue [] [] sAddr intCty (i32 x) = mvi x)
  (hi2b : CerbMem.memValueToBytes [] (mvi x) = ([], i32 x))
  assuming htags hdig hscB hexcB halV hrdV hbuilt hlkV hsz halign hshiftA hshiftB
    hunspec hszI hrng1 hrng2 hrecv hrecs hi2b
  fencing fmapAddBy fmapLookupBy fmapElements CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t4File.tagDefs) 0 from (mkRdy env bm am tr aid exc symc ctr) upto 44 chain builder

/-! ## THE MID BUILDER (the walk-A/walk-B boundary — the T7 mkLH
    discipline: every varying component a free binder, so walk B's
    side conditions normalize SMALL terms; walk A's endpoint aligns
    to this builder at its own components BY RFL). The boundary sits
    inside the third source statement (`return s.a`): a_533 is bound,
    the member-shift/load/kill/return tail remains. -/

/-- Head thread of a driver state (total; projection helper). -/
def thOf (σ : driver_state) : thread_state :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ => th
  | [] => thRdy fmapEmpty

/-- The mid-boundary arena: walk A's own endpoint arena, projected
    (fixture-derived, binder-independent program text — never
    transcribed; the T5W `lh1Arena` recipe). -/
noncomputable def midArena : generic_expr core_run_annotation Unit sym :=
  (thOf (wa44 fmapEmpty Std.TreeMap.empty Std.TreeMap.empty [] 0 0 0 0 0)).arena

/-- THE MID BUILDER (walk B's from-state). -/
noncomputable def mkMid (env : Fmap sym value) (mem : CerbMem.MemState)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t4File,
    core_extern := create_extern_symmap t4File,
    core_state0 :=
      { thread_states := [(0, (none,
          { arena := midArena,
            stack0 := Stack_empty,
            errno := errPtr,
            exec_loc := ELoc_normal
              [(membT4Sym, CerbLocation.other "RelSem.callND")],
            current_loc := CerbLocation.Loc.unknown,
            env := [env],
            current_proc_opt := some membT4Sym }))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t4File)).labeled },
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-! ## THE TAIL WALK `wb` — the mid boundary through the s.a
    read-back / kill / the return jump to the thread's terminal
    (terminal chain). Every varying component free: the deep-ladder
    memory enters only at the composition, where the read facts
    discharge through the once-proved write-projection laws. -/

set_option Elab.async false in
derive_rounds wb (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (x : Int)
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env)
  (hlkS : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS env
    = some (Vobject (OVpointer sPtr)))
  (hdd2 : mem.deadAllocations.contains 2 = false)
  (halS2 : mem.allocations.get? 2 = some allocS)
  (hfpm : mem.funptrmap = [])
  (hlum : mem.lastUsedUnionMembers = [])
  (hrdS : CerbMem.readBytesFrom mem sAddr 4 = i32 x)
  (hrecs : CerbMem.reconstructValue [] [] sAddr intCty (i32 x) = mvi x)
  (hshiftA : CerbMem.memberShiftPtrval sPtr structSSym
    (Identifier CerbLocation.Loc.unknown "a") = sPtr)
  (hszI : CerbMem.sizeofCtype (Ctype [] (Basic (Integer (Signed Int_)))) = 4)
  (hrng1 : -2147483648 ≤ x) (hrng2 : x ≤ 2147483647)
  assuming hbuilt hlkS hdd2 halS2 hfpm hlum hrdS hrecs hshiftA
    hszI hrng1 hrng2
  fencing fmapAddBy fmapLookupBy fmapElements CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? Std.TreeMap.erase mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t4File.tagDefs) 0 from (mkMid env mem tr aid exc symc ctr) upto 18 chain builder

/-! ## Layout facts under the tag-global hypothesis (the T4AppEq
    recipe, cloned fixture-locally — retirement-scheduled files NOT
    imported): struct layout is computed against the tag-table
    EXTERN, so each fact carries `htags` and rewrites the read. -/

theorem alignofS_fuel_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.alignofCtype_lemFuel 999999
      (Ctype [] (Struct structSSym)) = 4 := by
  rw [CerbMem.alignofCtype_lemFuel, htags]
  rfl

theorem sizeofS_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.sizeofCtype structSCty = 8 := by
  show CerbMem.sizeofCtype_lemFuel (999999+1)
    (Ctype [] (Struct structSSym)) = 8
  rw [CerbMem.sizeofCtype_lemFuel, htags, alignofS_fuel_fact htags]
  rfl

theorem alignS_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.alignofIval structSCty
      = CerbMem.IntegerValue.IV .Prov_none 4 := by
  unfold CerbMem.alignofIval
  show CerbMem.integerIval (CerbMem.alignofCtype_lemFuel (999999+1)
    (Ctype [] (Struct structSSym))) = _
  rw [CerbMem.alignofCtype_lemFuel, htags]
  rfl

theorem shiftA_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.memberShiftPtrval sPtr structSSym
      (Identifier CerbLocation.Loc.unknown "a") = sPtr := by
  unfold CerbMem.memberShiftPtrval
  rw [htags]
  rfl

theorem shiftB_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.memberShiftPtrval sPtr structSSym
      (Identifier CerbLocation.Loc.unknown "b") = bPtr := by
  unfold CerbMem.memberShiftPtrval
  rw [htags]
  rfl

theorem unspecBytes_fact (htags : CerbTags.tagDefs () = t4File.tagDefs) :
    CerbMem.memValueToBytes [] (.MVunspecified structSCty)
      = ([], [CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
              CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
              CerbMem.paddingByte, CerbMem.paddingByte]) := by
  show CerbMem.memValueToBytes_lemFuel (999999+1) []
    (.MVunspecified (Ctype [] (Struct structSSym))) = _
  rw [CerbMem.memValueToBytes_lemFuel,
    show CerbMem.sizeofCtype (Ctype [] (Struct structSSym)) = 8
      from sizeofS_fact htags]
  rfl

/-! ## The harness spine (the T7W recipe at the t4 data; every stage
    equation registered as segment supply — seg_auto's feed) -/

end RelSem.T4W

namespace RelSem.T4

/-- T4's filesystem state (initial, as every slate fixture; RE-HOMED
    from the ambient statement file at arc-18 R5 — the statement
    text's `t4Fs` resolves here for both the live and the ambient
    route). -/
def t4Fs : CerbFS.FsState := CerbFS.fs_initial_state

end RelSem.T4

namespace RelSem.T4W

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open RelSem.T4 (t4Fs)
open Lem_Basic_classes (ordCompare)

/-- Stage 1: driver_globals (t4 has none). -/
derive_state_step dG4 (seed : Nat)
  from (driver_globals t4File.tagDefs false t4File)
  at (initial_driver_state_threaded seed t4File t4Fs)

/-! ### The rest ladder -/

abbrev rInit4 (seed : Nat) : driver_state :=
  restOf (initial_driver_state_threaded seed t4File t4Fs)
abbrev rGlob4 (seed : Nat) : driver_state := restOf (dG4 seed)
abbrev rArg4 (seed : Nat) : driver_state :=
  restAllocR (rGlob4 seed) vAddr
abbrev rErr4 (seed : Nat) : driver_state :=
  restAllocR (rArg4 seed) errAddr
/-- The ready rest (the driver loop's start; supplies at the
    canonical harness values). -/
abbrev rRdy4 (seed : Nat) : driver_state :=
  restOf (mkRdy envRdy Std.TreeMap.empty Std.TreeMap.empty [] 0 0 seed 0)

/-- The ready builder aligns with the harness rest at the canonical
    supplies. -/
theorem mkRdy_align (seed : Nat)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    setMaps (rRdy4 seed) bm am = mkRdy envRdy bm am [] 0 0 seed 0 := rfl

/-! ### The open-memory stage equations -/

@[seg_eq rest]
theorem k1_o (seed : Nat) : ∀ bm am,
    app (driver_globals t4File.tagDefs false t4File)
        (setMaps (rInit4 seed) bm am)
      = (NDactive 0, setMaps (rGlob4 seed) bm am) := fun _ _ => rfl

/-- The post-globals canonical representative (`nd_get` joint). -/
@[seg_canon]
theorem t4_canon (seed : Nat) : Seg.CanonAt (rGlob4 seed) (dG4 seed) :=
  rfl

@[seg_eq rest]
theorem k3_o (seed : Nat) : ∀ bm am,
    app (resolveFunSym (dG4 seed).core_file "memb")
        (setMaps (rGlob4 seed) bm am)
      = (NDactive membT4Sym, setMaps (rGlob4 seed) bm am) :=
  fun _ _ => rfl

@[seg_eq rest]
theorem k4_o (seed : Nat) : ∀ bm am,
    app (lookupFunBody (dG4 seed).core_file membT4Sym)
        (setMaps (rGlob4 seed) bm am)
      = (NDactive ([(symV, BTy_object OTy_pointer)], membBody),
         setMaps (rGlob4 seed) bm am) := fun _ _ => rfl

@[seg_eq rest]
theorem k5_o (seed : Nat) : ∀ bm am,
    app (lookupParamTys (dG4 seed).core_file membT4Sym)
        (setMaps (rGlob4 seed) bm am)
      = (NDactive [signed_int], setMaps (rGlob4 seed) bm am) :=
  fun _ _ => rfl

/-- The argument-object address arithmetic. -/
@[seg_fact]
theorem argAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rGlob4 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = vAddr := by
  rw [show (rGlob4 seed).layout_state.lastAddress
    = (281474976710655 : Int) from rfl]
  decide

/-- The memValue the caller protocol computes for the symbolic T4
    argument (state-free; rfl at open x — the T1 recipe). -/
theorem memValueFromValue_t4_eq (x : Int) :
    memValueFromValue t4File.tagDefs signed_int (intValue x)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval x)) := rfl

/-- Stage 6, THE ARGUMENT INJECTION at open maps (symbolic x). -/
@[seg_eq argobj]
theorem k6_o (seed : Nat) (x : Int) : ∀ bm am,
    app (injectArgs t4File.tagDefs 0
          [(symV, BTy_object OTy_pointer)] [signed_int] [intValue x])
        (setMaps (rGlob4 seed) bm am)
      = (NDactive [(symV, Vobject (OVpointer vPtr))],
         allocStoreState (restAllocR (rGlob4 seed) vAddr) bm am vAddr 4
           (i32 x) 0 allocV) := by
  intro bm am
  refine Laws.inject_ptr_arg1 (σ := setMaps (rGlob4 seed) bm am)
    (hmv := memValueFromValue_t4_eq x)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := vAddr)
      (by exact rfl) (argAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval x))
      (allocId := 0) (addr := vAddr) (alloc := allocV)
      (fpm := []) (bytes := i32 x)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 0 allocV).get? 0 = some allocV
        simp [Std.TreeMap.get?_eq_getElem?])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

@[seg_eq rest]
theorem k7_o (seed : Nat) : ∀ bm am,
    app get_thread_states (setMaps (rArg4 seed) bm am)
      = (NDactive ((dG4 seed).core_state0.thread_states),
         setMaps (rArg4 seed) bm am) :=
  fun _ _ => rfl

/-- The errno address arithmetic. -/
@[seg_fact]
theorem errAddr_fact (seed : Nat) :
    ((CerbMem.alignDown
        ((rArg4 seed).layout_state.lastAddress - 4).toNat
        ((4 : Int).toNat.max 1) : Nat) : Int) = errAddr := by
  rw [show (rArg4 seed).layout_state.lastAddress = vAddr from rfl]
  decide

/-- Stage 8, THE ERRNO BLOCK at open maps. -/
@[seg_eq argobj]
theorem k8_o (seed : Nat) : ∀ bm am,
    app (liftMem (nd_bind
        (CerbMem.allocateObject 0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun (ptr_val : CerbMem.PointerValue) =>
          let zero := CerbMem.integerValueMval (Signed Int_)
            (CerbMem.integerIval (0 : Int))
          nd_bind
            (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val zero)
            (fun (_ : CerbMem.Footprint) => nd_return ptr_val))))
      (setMaps (rArg4 seed) bm am)
      = (NDactive errPtr,
         allocStoreState (restAllocR (rArg4 seed) errAddr) bm am errAddr
           4 (i32 0) 1 allocErr) := by
  intro bm am
  refine Laws.callND_errno (σ := setMaps (rArg4 seed) bm am)
    (halloc := Kit.mem_alloc_block (sz := 4) (a := errAddr)
      (by exact rfl) (errAddr_fact seed) (by exact rfl))
    (hstore := Kit.mem_store_block (ty := signed_int)
      (mv := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval 0))
      (allocId := 1) (addr := errAddr) (alloc := allocErr)
      (fpm := []) (bytes := i32 0)
      (hcompat := by exact rfl)
      (hget := by
        rw [Kit.writeBytesTo_allocations]
        show (am.insert 1 allocErr).get? 1 = some allocErr
        simp [Std.TreeMap.get?_eq_getElem?])
      (hbounds := by exact rfl) (hro := rfl)
      (hatomic := by exact rfl)
      (hbytes := by
        rw [Kit.writeBytesTo_funptrmap]
        exact rfl))
    (hout := by
      simp only [writeBytesTo_eq]
      rfl)

/-- Stage 9, the thread setup (rest-only). -/
@[seg_eq rest]
theorem k9_o (seed : Nat) (th : thread_state) (hth : th = thRdy envRdy) :
    ∀ bm am,
    app (driver_update_thread_state 0 th : driverM Unit)
        (setMaps (rErr4 seed) bm am)
      = (NDactive (), setMaps (rRdy4 seed) bm am) := by
  subst hth; exact fun _ _ => rfl

/-! ## Obligation feeds (the mechanical layer the composition
    consumes — mem pins by rfl, reads by the registered
    read-over-write laws, env lookups by the layer's
    `seg_env_lookup` discharger, supply projections by rfl) -/

/-- envOf (total; the walk-endpoint env projection). -/
def envOf (σ : driver_state) : Fmap sym value :=
  match (thOf σ).env with
  | e :: _ => e
  | [] => fmapEmpty

/-- Walk B applied at a state's own components (projections, never
    transcriptions — the T7 `atComps` discipline). -/
noncomputable def atComps
    (f : Fmap sym value → CerbMem.MemState → List trace_event →
      Nat → Nat → Nat → Nat → Int → driver_state)
    (σ : driver_state) (x : Int) : driver_state :=
  f (envOf σ) σ.layout_state σ.trace
    σ.core_run_state0.aid_supply σ.core_run_state0.excluded_supply
    σ.core_run_state0.sym_supply σ.dr_step_counter x

section Feeds
variable (env : Fmap sym value)
  (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat) (x : Int)

/-- The mid-boundary memory, pinned tidy (rfl — structure eta over the
    minted field-by-field ladder): create / store-unspec / member a
    (x) / member b (7). -/
def memCreate4 : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { memRdy bm am with
      nextAllocId := 3, lastAddress := sAddr,
      allocations := am.insert 2 allocS }
    sAddr (List.replicate 8 uninitByte)

def memUnspec4 : CerbMem.MemState :=
  CerbMem.writeBytesTo { memCreate4 bm am with funptrmap := [] }
    sAddr (List.replicate 8 CerbMem.paddingByte)

def memA4 : CerbMem.MemState :=
  CerbMem.writeBytesTo { memUnspec4 bm am with funptrmap := [] }
    sAddr (i32 x)

def memMid : CerbMem.MemState :=
  CerbMem.writeBytesTo { memA4 bm am x with funptrmap := [] }
    bAddr (i32 7)

theorem wa44_mem :
    (wa44 env bm am tr aid exc symc ctr x).layout_state
      = memMid bm am x := rfl

/-- Supply projections (rfl pins; the seed-bound transport). -/
theorem wa44_symc :
    (wa44 env bm am tr aid exc symc ctr x).core_run_state0.sym_supply
      = symc + 2 := rfl
theorem wa44_exc :
    (wa44 env bm am tr aid exc symc ctr x).core_run_state0.excluded_supply
      = exc + 2 := rfl

/-- The endpoint IS the mid builder at its own components
    (rfl-grade alignment at free binders — the T7 `e95_align`
    discipline). -/
theorem wa44_align :
    wa44 env bm am tr aid exc symc ctr x
      = mkMid (envOf (wa44 env bm am tr aid exc symc ctr x))
          (wa44 env bm am tr aid exc symc ctr x).layout_state
          (wa44 env bm am tr aid exc symc ctr x).trace
          (wa44 env bm am tr aid exc symc ctr x).core_run_state0.aid_supply
          (wa44 env bm am tr aid exc symc ctr x).core_run_state0.excluded_supply
          (wa44 env bm am tr aid exc symc ctr x).core_run_state0.sym_supply
          (wa44 env bm am tr aid exc symc ctr x).dr_step_counter := rfl

end Feeds

/-! ### The mid-memory discharge facts (walk B's hypothesis feed at
    the composed instantiation — reads through the once-proved
    write-projection laws) -/

section MidFacts
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation) (x : Int)

theorem memMid_dead :
    (memMid bm am x).deadAllocations.contains 2 = false := rfl

theorem memMid_fpm : (memMid bm am x).funptrmap = [] := rfl

theorem memMid_lum : (memMid bm am x).lastUsedUnionMembers = [] := rfl

theorem memMid_alloc :
    (memMid bm am x).allocations.get? 2 = some allocS := by
  show ((am.insert 2 allocS)).get? 2 = some allocS
  simp [Std.TreeMap.get?_eq_getElem?]

/-- The s.a read-back: disjoint over the b layer, exact hit at the
    a layer. -/
theorem memMid_rdS :
    CerbMem.readBytesFrom (memMid bm am x) sAddr 4 = i32 x := by
  show CerbMem.readBytesFrom
    (CerbMem.writeBytesTo { memA4 bm am x with funptrmap := [] }
      bAddr (i32 7)) sAddr 4 = i32 x
  rw [Kit.readBytesFrom_writeBytesTo_disjoint (Or.inr (by decide))]
  exact (Kit.readBytesFrom_congr_bytemap (m2 := memA4 bm am x)
    rfl).trans (Kit.readBytesFrom_writeBytesTo_hit rfl)

end MidFacts

/-! ## The composed whole-run segment (walk A + walk B through the
    once-proved composition rules; the mid boundary aligned by rfl) -/

/-- The T4 driver round computation. -/
abbrev C4 := Seg.dnmsC t4File.tagDefs 0

/-- The run's terminal value at the symbolic argument. -/
def vD4 (x : Int) : value :=
  Vloaded (LVspecified (OVinteger
    (CerbMem.IntegerValue.IV .Prov_none x)))

/-- Walk A's endpoint at the harness instantiation (the canonical
    supplies; env := the concrete ready env). -/
noncomputable abbrev midAt (seed : Nat) (x : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : driver_state :=
  wa44 envRdy bm am [] 0 0 seed 0 x

/-- THE WHOLE-RUN TERMINAL SEGMENT: walk A's 44-round chain into walk
    B's 12-round terminal chain at the aligned mid boundary — the
    Hoare sequence rule at the equation calculus, budgets adding. -/
theorem t4_run_seg (seed : Nat) (x : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (htags : CerbTags.tagDefs () = t4File.tagDefs)
    (hdig : CerberusFresh.digest () = "")
    (hap : seed + 1 < 229457971439601039)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (halV : am.get? 0 = some allocV)
    (hb : ∀ i : Nat, (hi : i < (i32 x).length) →
      bm.get? (vAddr + (i : Int)) = some ((i32 x)[i])) :
    Seg.SegDone C4 (44 + 14)
      (mkRdy envRdy bm am [] 0 0 seed 0)
      (NDactive (fmapAddBy defaultCompare 0
        [Step_done2 (vD4 x)] fmapEmpty),
       atComps wb12 (midAt seed x bm am) x) := by
  refine (Seg.Seg.of_chain (C := C4) (k := 44)
    (wa_chainrel envRdy bm am [] 0 0 seed 0 x htags hdig
      (by omega) (by omega) halV
      (readBytesFrom_of_pointwise rfl (fun i hi => hb i hi))
      (by rfl) (by rfl)
      (sizeofS_fact htags) (alignS_fact htags) (shiftA_fact htags)
      (shiftB_fact htags) (unspecBytes_fact htags) rfl hx1 hx2
      (recon_i32 vAddr x hx1 hx2) (recon_i32 sAddr x hx1 hx2)
      (i2b_i32 x))).trans_done ?_
  rw [wa44_align envRdy bm am [] 0 0 seed 0 x]
  refine Seg.SegDone.of_chain (C := C4) (k := 14) ?_
  exact wb_chainrel (envOf (midAt seed x bm am))
    (midAt seed x bm am).layout_state
    (midAt seed x bm am).trace
    (midAt seed x bm am).core_run_state0.aid_supply
    (midAt seed x bm am).core_run_state0.excluded_supply
    (midAt seed x bm am).core_run_state0.sym_supply
    (midAt seed x bm am).dr_step_counter x
    (by rfl)
    (by seg_env_lookup)
    (by rfl)
    (by rw [wa44_mem]; exact memMid_alloc bm am x)
    (by rfl) (by rfl)
    (by rw [wa44_mem]; exact memMid_rdS bm am x)
    (recon_i32 sAddr x hx1 hx2)
    (shiftA_fact htags)
    rfl hx1 hx2

/-! ## The final state, its fixed rest, and the scratch1p feed -/

/-- THE FINAL STATE of the driver atom (post-`prepare_exit`) — the
    scratch1p rule's fixture function `F`. -/
noncomputable def t4Fin (seed : Nat) (x : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) : driver_state :=
  { atComps wb12 (midAt seed x bm am) x with
    core_state0 := prepare_exit
      (atComps wb12 (midAt seed x bm am) x).core_state0 (vD4 x) }

/-- THE FIXED FINAL REST (the walk's ρ'; canonical at zeroed maps). -/
noncomputable def rDone4 (seed : Nat) (x : Int) : driver_state :=
  restOf (t4Fin seed x Std.TreeMap.empty Std.TreeMap.empty)

/-- The final rest is MAP-INDEPENDENT (walk B's rest fields project
    map-free through the mid memory's scalar pins). -/
@[seg_fact]
theorem t4Fin_rest (seed : Nat) (x : Int) : ∀ bm am,
    restOf (t4Fin seed x bm am) = rDone4 seed x := fun _ _ => rfl

/-- The final scratch byte image (member .a = x, member .b = 7). -/
def finalS (x : Int) : List CerbMem.AbsByte := i32 x ++ i32 7

/-- The final allocation table (the scratch1p insert-erase chain at
    nidS = 2). -/
@[seg_fact]
theorem t4Fin_allocs (seed : Nat) (x : Int) : ∀ bm am,
    (t4Fin seed x bm am).layout_state.allocations
      = (am.insert 2 allocS).erase 2 := fun _ _ => rfl

/-- Final bytes outside the scratch range read the harness map
    (stated at the rule's length spelling so unification pins the
    final image before the binder domains are compared). -/
@[seg_fact]
theorem t4Fin_out (seed : Nat) (x : Int) : ∀ bm am (a : Int),
    ¬(sAddr ≤ a ∧ a < sAddr + (finalS x).length) →
    (t4Fin seed x bm am).layout_state.bytemap.get? a = bm.get? a := by
  intro bm am a hs
  have hlen : (finalS x).length = 8 := rfl
  rw [hlen] at hs
  show (writeList (writeList (writeList (writeList bm sAddr
      (List.replicate 8 uninitByte)) sAddr
      (List.replicate 8 CerbMem.paddingByte)) sAddr (i32 x)) bAddr
      (i32 7)).get? a = bm.get? a
  rw [writeList_get?_notin _ _ _ _ (by
      rw [i32_len]
      show a < bAddr ∨ bAddr + (4 : Int) ≤ a
      have h1 : (sAddr : Int) = 281474976710636 := rfl
      have h2 : (bAddr : Int) = 281474976710640 := rfl
      omega),
    writeList_get?_notin _ _ _ _ (by
      rw [i32_len]
      show a < sAddr ∨ sAddr + (4 : Int) ≤ a
      have h1 : (sAddr : Int) = 281474976710636 := rfl
      omega),
    writeList_get?_notin _ _ _ _ (by
      simp only [List.length_replicate]
      show a < sAddr ∨ sAddr + (8 : Int) ≤ a
      have h1 : (sAddr : Int) = 281474976710636 := rfl
      omega),
    writeList_get?_notin _ _ _ _ (by
      simp only [List.length_replicate]
      show a < sAddr ∨ sAddr + (8 : Int) ≤ a
      have h1 : (sAddr : Int) = 281474976710636 := rfl
      omega)]

/-- Final scratch-range bytes: member .a's x image below the .b
    offset, member .b's 7 image above it. -/
@[seg_fact]
theorem t4Fin_inS (seed : Nat) (x : Int) :
    ∀ bm am (i : Nat), i < (finalS x).length →
    (t4Fin seed x bm am).layout_state.bytemap.get? (sAddr + (i : Int))
      = (finalS x)[i]? := by
  intro bm am i hi
  have hlen : (finalS x).length = 8 := rfl
  rw [hlen] at hi
  show (writeList (writeList (writeList (writeList bm sAddr
      (List.replicate 8 uninitByte)) sAddr
      (List.replicate 8 CerbMem.paddingByte)) sAddr (i32 x)) bAddr
      (i32 7)).get? (sAddr + (i : Int)) = (finalS x)[i]?
  have hs : (sAddr : Int) = 281474976710636 := rfl
  have hbb : (bAddr : Int) = 281474976710640 := rfl
  by_cases h4 : i < 4
  · rw [writeList_get?_notin _ _ _ _ (by rw [i32_len]; omega),
      writeList_get?_in _ _ _ _ (by omega) (by rw [i32_len]; omega)]
    have hidx : ((sAddr + (i : Int)) - sAddr).toNat = i := by omega
    rw [hidx]
    show (i32 x)[i]? = (finalS x)[i]?
    rw [show (finalS x) = i32 x ++ i32 7 from rfl,
      List.getElem?_append_left (by rw [i32_len]; omega)]
  · rw [writeList_get?_in _ _ _ _ (by omega) (by rw [i32_len]; omega)]
    have hidx : ((sAddr + (i : Int)) - bAddr).toNat = i - 4 := by omega
    rw [hidx]
    show (i32 7)[i - 4]? = (finalS x)[i]?
    rw [show (finalS x) = i32 x ++ i32 7 from rfl,
      List.getElem?_append_right (by rw [i32_len]; omega), i32_len]

/-- Geometry: the scratch image is nonempty. -/
@[seg_fact]
theorem t4_szS1 (x : Int) : 1 ≤ (finalS x).length := by
  show (1 : Nat) ≤ 8
  omega

/-- Geometry: the scratch range sits at or below the ready water
    mark. -/
@[seg_fact]
theorem t4_rangeS (seed : Nat) (x : Int) :
    sAddr + ((finalS x).length : Int)
      ≤ ((rRdy4 seed).layout_state.lastAddress : Int) := by
  rw [show (finalS x).length = 8 from rfl,
    show ((rRdy4 seed).layout_state.lastAddress : Int) = errAddr
      from rfl, show (sAddr : Int) = 281474976710636 from rfl,
    show (errAddr : Int) = 281474976710644 from rfl]
  omega

/-- ρ' scalar pin: the bump counter moved by the scratch create. -/
@[seg_fact]
theorem rDone4_nid (seed : Nat) (x : Int) :
    ((rDone4 seed x).layout_state.nextAllocId : Int)
      = ((rRdy4 seed).layout_state.nextAllocId : Int) + 1 := rfl

/-- ρ' scalar pin: the water mark at the scratch. -/
@[seg_fact]
theorem rDone4_last (seed : Nat) (x : Int) :
    ((rDone4 seed x).layout_state.lastAddress : Int) = sAddr := rfl

/-- ρ' scalar pin: the scratch id on the dead list. -/
@[seg_fact]
theorem rDone4_dead (seed : Nat) (x : Int) :
    (rDone4 seed x).layout_state.deadAllocations
      = 2 :: (rRdy4 seed).layout_state.deadAllocations := rfl


end RelSem.T4W
