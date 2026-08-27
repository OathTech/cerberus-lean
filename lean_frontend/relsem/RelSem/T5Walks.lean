/-
  RelSem.T5Walks — arc-18 C3b (2026-08-26): THE T5 EQUATION SUPPLY.

  NAMING (arc-18 R2, the walk→segment map in
  docs/2026-08-26_arc18-r2-donor-correspondence.md): "walk" is
  ENGINE-ROOM vocabulary — the drive/mint layer's term for a chain of
  evaluator rounds. The user-facing surface calls these SEGMENTS
  (RelSem/Segment.lean consumes each chain as one `Seg`).

  The three builder walks whose ∀-fuel relative chains T5's
  invariant-family composition consumes (RelSem/T5.lean):

  * `e`  — THE ENTRY: the prologue (create s / store 0 / create i /
    store 0 / save registrations) from the ready builder `mkRdy` with
    the two heap maps FREE (the ∀ bm am form the CerbMemInterp walk
    rules consume) and free supplies — 22 rounds, `e_chainrel`.
  * `b`  — THE BODY: one full loop iteration from the loop-head
    builder `mkLH` (every varying component a free binder; all
    behavior from the 27-hypothesis pack) through the loop-closing
    Erun — 79 rounds, `b_chainrel`. The arc-17 S3 round-44 wall and
    the C3 §3.4 round-56 frontier are INSIDE this walk — both now
    ordinary minted rounds (the C3/C3b engine + registered-law
    record).
  * `bx` — THE EXIT: guard-false (`n ≤ iv`) through the break, the
    kills of i and s, the post-kill s-load and the return jump to the
    thread's terminal — 44 rounds + the terminal offer,
    `bx_chainrel` (terminal form: the composition's endpoint).

  Every round is an evaluator mint (zero hand-derived per-round
  equations); every emitted declaration is kernel-checked at its
  addDecl and swept by the in-build audit. Fixture data below is
  DATA (symbols, addresses, byte images, the builder records) — the
  program text is fixture-derived (the labeled-continuation lookup),
  never transcribed.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.DeriveState
import RelSem.RoundEval
import RelSem.ConstructLaws
import RelSem.SlateFiles
import RelSem.Kit.Map

set_option autoImplicit false

namespace RelSem.T5W

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open Lem_Basic_classes (ordCompare)

/-! ## Fixture data (symbols, addresses, byte images) -/

def symN : sym := Symbol "" 8148669997605808657 (SD_Id "n")
def symS : sym := Symbol "" 9409450202036847209 (SD_Id "s")
def symI : sym := Symbol "" 16900879642891266615 (SD_Id "i")
def symWhile : sym := Symbol "" 15846621060339386788 (SD_Id "while_531")

def nAddr : Int := 281474976710648
def errAddr : Int := 281474976710644
def sAddr : Int := 281474976710640
def iAddr : Int := 281474976710636

def nPtr : CerbMem.PointerValue := .PV (.Prov_some 0) (.PVconcrete none nAddr)
def errPtr : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none errAddr)
def sPtr : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none sAddr)
def iPtr : CerbMem.PointerValue := .PV (.Prov_some 3) (.PVconcrete none iAddr)

def allocN : CerbMem.Allocation :=
  { base := nAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
def allocS : CerbMem.Allocation :=
  { base := sAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "Core" }
def allocI : CerbMem.Allocation :=
  { base := iAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "Core" }

/-- The 4-byte little-endian image of a 32-bit int value. -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

abbrev intCty : ctype := Ctype [] (Basic (Integer (Signed Int_)))

abbrev mvi (v : Int) : CerbMem.MemValue :=
  CerbMem.MemValue.MVinteger (Signed Int_) (CerbMem.IntegerValue.IV .Prov_none v)

/-- The int byte image as a list (the read/store facts' vocabulary). -/
def i32 (v : Int) : List CerbMem.AbsByte :=
  [mkByte v 0, mkByte v 1, mkByte v 2, mkByte v 3]

/-! ## The builders -/

/-- `sum`'s Core body (fixture-derived — never transcribed). -/
def sumBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) sumT5Sym
      t5File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The while_531 labeled-continuation body (fixture-derived). -/
def whileBody : generic_expr core_run_annotation Unit sym :=
  match Lem_Maybe.bind0
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) sumT5Sym
        (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t5File)).labeled)
      (fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symWhile) with
  | some pb => pb.2
  | none => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread (arena = sum's body; n bound). -/
def thRdy : thread_state :=
  { arena := sumBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(sumT5Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
      (Vobject (OVpointer nPtr)) fmapEmpty],
    current_proc_opt := some sumT5Sym }

/-- THE READY BUILDER (the entry walk's from-state): heap maps and
    supplies free; the non-map memory fields are the concrete
    post-errno values — exactly the `setMaps rest bm am` shape the
    heap-route walk rules quantify. -/
def mkRdy (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t5File,
    core_extern := create_extern_symmap t5File,
    core_state0 :=
      { thread_states := [(0, (none, thRdy))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t5File)).labeled },
    layout_state :=
      { CerbMem.initialMemState with
        nextAllocId := 2, lastAddress := errAddr,
        bytemap := bm, allocations := am },
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-- THE LOOP-HEAD BUILDER (the body/exit walks' from-state): every
    varying component parametric — the invariant family `St`
    instantiates exactly these slots. -/
def mkLH (env : Fmap sym value) (mem : CerbMem.MemState)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t5File,
    core_extern := create_extern_symmap t5File,
    core_state0 :=
      { thread_states := [(0, (none,
          { arena := whileBody,
            stack0 := Stack_empty,
            errno := errPtr,
            current_loc := CerbLocation.Loc.unknown,
            exec_loc := ELoc_normal
              [(sumT5Sym, CerbLocation.other "RelSem.callND")],
            env := [env],
            current_proc_opt := some sumT5Sym }))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t5File)).labeled },
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }


/-! ## THE ENTRY WALK (22 rounds; ∀ bm am + free supplies) -/

set_option Elab.async false in
derive_rounds e (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (tr : List trace_event) (aid exc symc ctr : Nat)
  (hdig : CerberusFresh.digest () = "")
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  assuming hdig hscB hexcB
  fencing fmapAddBy CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get? mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t5File.tagDefs) 0 from (mkRdy bm am tr aid exc symc ctr) upto 22 chain builder

/-! ## The first-iteration loop head (arc-18 C3b, the measured seam):
    falling INTO `save while_531` leaves iteration 1's loop head at a
    DIFFERENT SPELLING from the stored continuation every later
    iteration jumps to (outer annotation hoist + partial forcing) —
    propositionally distinct states, so iteration 1 gets TWIN walks
    from its own builder. The arena is the ENTRY WALK'S OWN endpoint
    arena, projected (fixture-derived, binder-independent program
    text — never transcribed). -/

/-- Head thread of a driver state (total; the defaults never fire on
    walk emissions — the alignment rfls in RelSem/T5.lean are the
    loud check). -/
def thOf (σ : driver_state) : thread_state :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ => th
  | [] => thRdy

/-- Iteration 1's loop-head arena: e22's own. -/
noncomputable def lh1Arena : generic_expr core_run_annotation Unit sym :=
  (thOf (e22 Std.TreeMap.empty Std.TreeMap.empty [] 0 0 0 0)).arena

/-- The loop-head builder at the ENTRY spelling (iteration 1's body
    walk + the n = 0 exit walk start here; iterations ≥ 2 and the
    n ≥ 1 exit start at `mkLH`). -/
noncomputable def mkLH1 (env : Fmap sym value) (mem : CerbMem.MemState)
    (tr : List trace_event) (aid exc symc ctr : Nat) : driver_state :=
  { core_file := t5File,
    core_extern := create_extern_symmap t5File,
    core_state0 :=
      { thread_states := [(0, (none,
          { arena := lh1Arena,
            stack0 := Stack_empty,
            errno := errPtr,
            current_loc := CerbLocation.Loc.unknown,
            exec_loc := ELoc_normal
              [(sumT5Sym, CerbLocation.other "RelSem.callND")],
            env := [env],
            current_proc_opt := some sumT5Sym }))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := 1, aid_supply := aid, excluded_supply := exc,
        sym_supply := symc,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t5File)).labeled },
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := ctr }

/-! ## THE BODY WALK (79 rounds — one full iteration through the
    loop-closing Erun; the 27-hypothesis pack) -/

set_option Elab.async false in
derive_rounds b (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)
  (hdig : CerberusFresh.digest () = "")
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env)
  (hlkN : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN env
    = some (Vobject (OVpointer nPtr)))
  (hlkS : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS env
    = some (Vobject (OVpointer sPtr)))
  (hlkI : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symI env
    = some (Vobject (OVpointer iPtr)))
  (hdd0 : mem.deadAllocations.contains 0 = false)
  (hdd2 : mem.deadAllocations.contains 2 = false)
  (hdd3 : mem.deadAllocations.contains 3 = false)
  (halN : mem.allocations.get? 0 = some allocN)
  (halS : mem.allocations.get? 2 = some allocS)
  (halI : mem.allocations.get? 3 = some allocI)
  (hfpm : mem.funptrmap = [])
  (hlum : mem.lastUsedUnionMembers = [])
  (hrdN : CerbMem.readBytesFrom mem nAddr 4
    = [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3])
  (hrdS : CerbMem.readBytesFrom mem sAddr 4
    = [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3])
  (hrdI : CerbMem.readBytesFrom mem iAddr 4
    = [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3])
  (hrecN : CerbMem.reconstructValue [] [] nAddr intCty
    [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3] = mvi n)
  (hrecS : CerbMem.reconstructValue [] [] sAddr intCty
    [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3] = mvi sv)
  (hrecI : CerbMem.reconstructValue [] [] iAddr intCty
    [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3] = mvi iv)
  (hi2bS : CerbMem.memValueToBytes [] (mvi (sv + iv))
    = ([], [mkByte (sv + iv) 0, mkByte (sv + iv) 1,
            mkByte (sv + iv) 2, mkByte (sv + iv) 3]))
  (hi2bI : CerbMem.memValueToBytes [] (mvi (iv + 1))
    = ([], [mkByte (iv + 1) 0, mkByte (iv + 1) 1,
            mkByte (iv + 1) 2, mkByte (iv + 1) 3]))
  (hlt : iv < n) (hn1 : n ≤ 100)
  (hiv0 : 0 ≤ iv) (hsv0 : 0 ≤ sv) (hsv1 : sv ≤ 4950)
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  assuming hdig hbuilt hlkN hlkS hlkI hdd0 hdd2 hdd3 halN halS halI hfpm hlum
    hrdN hrdS hrdI hrecN hrecS hrecI hi2bS hi2bI hlt hn1 hiv0 hsv0 hsv1
    hscB hexcB
  fencing fmapAddBy CerbMem.writeBytesTo mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t5File.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 79 chain builder

/-! ## THE EXIT WALK (44 rounds + the terminal offer; guard false) -/

set_option Elab.async false in
derive_rounds bx (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)
  (hdig : CerberusFresh.digest () = "")
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env)
  (hlkN : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN env
    = some (Vobject (OVpointer nPtr)))
  (hlkS : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS env
    = some (Vobject (OVpointer sPtr)))
  (hlkI : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symI env
    = some (Vobject (OVpointer iPtr)))
  (hdd0 : mem.deadAllocations.contains 0 = false)
  (hdd2 : mem.deadAllocations.contains 2 = false)
  (hdd3 : mem.deadAllocations.contains 3 = false)
  (halN : mem.allocations.get? 0 = some allocN)
  (halS : mem.allocations.get? 2 = some allocS)
  (halI : mem.allocations.get? 3 = some allocI)
  (hfpm : mem.funptrmap = [])
  (hlum : mem.lastUsedUnionMembers = [])
  (hrdN : CerbMem.readBytesFrom mem nAddr 4
    = [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3])
  (hrdS : CerbMem.readBytesFrom mem sAddr 4
    = [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3])
  (hrdI : CerbMem.readBytesFrom mem iAddr 4
    = [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3])
  (hrecN : CerbMem.reconstructValue [] [] nAddr intCty
    [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3] = mvi n)
  (hrecS : CerbMem.reconstructValue [] [] sAddr intCty
    [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3] = mvi sv)
  (hrecI : CerbMem.reconstructValue [] [] iAddr intCty
    [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3] = mvi iv)
  (hge : n ≤ iv) (hn0 : 0 ≤ n) (hn1 : n ≤ 100)
  (hiv0 : 0 ≤ iv) (hiv1 : iv ≤ 100) (hsv0 : 0 ≤ sv) (hsv1 : sv ≤ 4950)
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  assuming hdig hbuilt hlkN hlkS hlkI hdd0 hdd2 hdd3 halN halS halI hfpm hlum
    hrdN hrdS hrdI hrecN hrecS hrecI hge hn0 hn1 hiv0 hiv1 hsv0 hsv1
    hscB hexcB
  fencing fmapAddBy CerbMem.writeBytesTo Std.TreeMap.erase mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t5File.tagDefs) 0 from (mkLH env mem tr aid exc symc ctr) upto 80 chain builder

/-! ## THE FIRST-ITERATION BODY WALK (78 rounds — the entry-spelled head runs one round shorter; the mkLH1 twin —
    round names `bfirst<k>`: the `b1<k>` scheme collides with the b
    walk's rounds 11+) -/

set_option Elab.async false in
derive_rounds bfirst (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)
  (hdig : CerberusFresh.digest () = "")
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env)
  (hlkN : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN env
    = some (Vobject (OVpointer nPtr)))
  (hlkS : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS env
    = some (Vobject (OVpointer sPtr)))
  (hlkI : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symI env
    = some (Vobject (OVpointer iPtr)))
  (hdd0 : mem.deadAllocations.contains 0 = false)
  (hdd2 : mem.deadAllocations.contains 2 = false)
  (hdd3 : mem.deadAllocations.contains 3 = false)
  (halN : mem.allocations.get? 0 = some allocN)
  (halS : mem.allocations.get? 2 = some allocS)
  (halI : mem.allocations.get? 3 = some allocI)
  (hfpm : mem.funptrmap = [])
  (hlum : mem.lastUsedUnionMembers = [])
  (hrdN : CerbMem.readBytesFrom mem nAddr 4
    = [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3])
  (hrdS : CerbMem.readBytesFrom mem sAddr 4
    = [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3])
  (hrdI : CerbMem.readBytesFrom mem iAddr 4
    = [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3])
  (hrecN : CerbMem.reconstructValue [] [] nAddr intCty
    [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3] = mvi n)
  (hrecS : CerbMem.reconstructValue [] [] sAddr intCty
    [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3] = mvi sv)
  (hrecI : CerbMem.reconstructValue [] [] iAddr intCty
    [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3] = mvi iv)
  (hi2bS : CerbMem.memValueToBytes [] (mvi (sv + iv))
    = ([], [mkByte (sv + iv) 0, mkByte (sv + iv) 1,
            mkByte (sv + iv) 2, mkByte (sv + iv) 3]))
  (hi2bI : CerbMem.memValueToBytes [] (mvi (iv + 1))
    = ([], [mkByte (iv + 1) 0, mkByte (iv + 1) 1,
            mkByte (iv + 1) 2, mkByte (iv + 1) 3]))
  (hlt : iv < n) (hn1 : n ≤ 100)
  (hiv0 : 0 ≤ iv) (hsv0 : 0 ≤ sv) (hsv1 : sv ≤ 4950)
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  assuming hdig hbuilt hlkN hlkS hlkI hdd0 hdd2 hdd3 halN halS halI hfpm hlum
    hrdN hrdS hrdI hrecN hrecS hrecI hi2bS hi2bI hlt hn1 hiv0 hsv0 hsv1
    hscB hexcB
  fencing fmapAddBy CerbMem.writeBytesTo mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t5File.tagDefs) 0 from (mkLH1 env mem tr aid exc symc ctr) upto 78 chain builder


/-! ## THE n = 0 EXIT WALK (the mkLH1 twin; guard false at the
    entry-spelled loop head; round names `bxzero<k>`) -/

set_option Elab.async false in
derive_rounds bxzero (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)
  (hdig : CerberusFresh.digest () = "")
  (hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO env)
  (hlkN : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN env
    = some (Vobject (OVpointer nPtr)))
  (hlkS : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS env
    = some (Vobject (OVpointer sPtr)))
  (hlkI : fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symI env
    = some (Vobject (OVpointer iPtr)))
  (hdd0 : mem.deadAllocations.contains 0 = false)
  (hdd2 : mem.deadAllocations.contains 2 = false)
  (hdd3 : mem.deadAllocations.contains 3 = false)
  (halN : mem.allocations.get? 0 = some allocN)
  (halS : mem.allocations.get? 2 = some allocS)
  (halI : mem.allocations.get? 3 = some allocI)
  (hfpm : mem.funptrmap = [])
  (hlum : mem.lastUsedUnionMembers = [])
  (hrdN : CerbMem.readBytesFrom mem nAddr 4
    = [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3])
  (hrdS : CerbMem.readBytesFrom mem sAddr 4
    = [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3])
  (hrdI : CerbMem.readBytesFrom mem iAddr 4
    = [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3])
  (hrecN : CerbMem.reconstructValue [] [] nAddr intCty
    [mkByte n 0, mkByte n 1, mkByte n 2, mkByte n 3] = mvi n)
  (hrecS : CerbMem.reconstructValue [] [] sAddr intCty
    [mkByte sv 0, mkByte sv 1, mkByte sv 2, mkByte sv 3] = mvi sv)
  (hrecI : CerbMem.reconstructValue [] [] iAddr intCty
    [mkByte iv 0, mkByte iv 1, mkByte iv 2, mkByte iv 3] = mvi iv)
  (hge : n ≤ iv) (hn0 : 0 ≤ n) (hn1 : n ≤ 100)
  (hiv0 : 0 ≤ iv) (hiv1 : iv ≤ 100) (hsv0 : 0 ≤ sv) (hsv1 : sv ≤ 4950)
  (hscB : symc < 1152921504606846976)
  (hexcB : exc < 1152921504606846976)
  assuming hdig hbuilt hlkN hlkS hlkI hdd0 hdd2 hdd3 halN halS halI hfpm hlum
    hrdN hrdS hrdI hrecN hrecS hrecI hge hn0 hn1 hiv0 hiv1 hsv0 hsv1
    hscB hexcB
  fencing fmapAddBy CerbMem.writeBytesTo Std.TreeMap.erase mkByte mk_conv_int mk_call_catch_exceptional_condition mk_wrapI
  using (t5File.tagDefs) 0 from (mkLH1 env mem tr aid exc symc ctr) upto 46 chain builder

end RelSem.T5W
