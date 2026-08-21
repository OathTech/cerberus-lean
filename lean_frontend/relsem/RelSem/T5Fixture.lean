/-
  RelSem.T5Fixture — arc-9 S2 (2026-08-20): T5 FIXTURE DATA (design §4
  file convention: the pinned program term, symbols, addresses —
  NOTHING with a by-block beyond rfl-pins; NOT counted by the
  proof-size bar).

  The program term is the drift-gated emitted Core
  (RelSem/SlateCore.lean sumT5Decl via RelSem/SlateFiles.lean t5File).
  Shared pinned prefix objects (the caller-protocol memory states,
  errno pointer, byte helpers) come from the T1 fixture layer — the
  T5 prefix is byte-identical to T1's (same argument address, same
  errno address; validated by the prefix rfl-pins in RelSem/T5.lean).

  House rules: no sorry, no axioms.
-/

import RelSem.SlateFiles
import RelSem.T1AppEq

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate
open RelSem.T1 (aU intCty loadedV mkByte xPtr xPtrV errPtr xAddr errAddr
  memD3 memInj rsD3 bmErrAlloc memErrAlloc allocX allocErr zeroByte
  uninitByte thG)

/-! ## Symbols (content-hashed ids from the pinned Core program;
    validated by the prefix/entry rfl-pins in RelSem/T5.lean) -/

def symN : sym := Symbol "" 8148669997605808657 (SD_Id "n")
def symS : sym := Symbol "" 9409450202036847209 (SD_Id "s")
def symI : sym := Symbol "" 16900879642891266615 (SD_Id "i")

/-! ## Addresses (deterministic allocations of the concrete memory
    model: the argument object and errno are the T1 addresses; `s` and
    `i` are the third and fourth allocations) -/

/-- n's parameter object: first allocation (= T1's xAddr). -/
abbrev nAddr : Int := RelSem.T1.xAddr
/-- s's object: third allocation. -/
def sAddr : Int := 281474976710640
/-- i's object: fourth allocation. -/
def iAddr : Int := 281474976710636

abbrev nPtr : CerbMem.PointerValue := xPtr
def sPtr : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none sAddr)
def iPtr : CerbMem.PointerValue := .PV (.Prov_some 3) (.PVconcrete none iAddr)

def sPtrV : value := Vobject (OVpointer sPtr)
def iPtrV : value := Vobject (OVpointer iPtr)

/-! ## The designated function's body (fixture-derived — never
    transcribed): the pinned t5File's `sum` proc body. -/

def sumBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
      sumT5Sym t5File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-! ## Harness frame (the T1 mkDr shape at the t5 file) -/

/-- The post-globals run-state at the t5 file (T1's rsD3 analog). -/
def rsD5 : core_run_state :=
  { initial_core_run_state (collect_labeled_continuations_NEW t5File)
      with tid_supply := 1 }

/-- Driver-state frame: only thread, memory, run-state, trace and step
    counter vary across rounds. -/
def mkDr5 (th : thread_state) (mem : CerbMem.MemState)
    (rs : core_run_state) (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t5File,
    core_extern := create_extern_symmap t5File,
    core_state0 := { thread_states := [(0, (none, th))], io := initial_io_state },
    core_run_state0 := rs,
    layout_state := mem,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

/-- The entry environment (callFinish's foldl over the bound argument;
    the T1 env0 shape at `n`). -/
def env0T5 : List (Fmap sym value) :=
  [(List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
      fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
        pv.1 pv.2 m)
    fmapEmpty [(symN, xPtrV)])]

/-- Thread at entry (post-prefix; T1's th0 shape at the sum body). -/
def th0T5 : thread_state :=
  { arena := sumBody, stack0 := Stack_empty, errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(sumT5Sym, CerbLocation.other "RelSem.callND")],
    env := env0T5, current_proc_opt := some sumT5Sym }

/-- dnms at the T5 tagDefs. -/
abbrev dnms5 (fuel : Nat) (acc : Fmap thread_id (List core_step2))
    (tids : List Nat) :=
  drive_nonmemory_steps_aux2_lemFuel fuel t5File.tagDefs acc tids

/-- The finalization tail (callFinish's continuation after driver2). -/
def finTail5 : Unit → driverM driver_result :=
  fun _ => nd_bind nd_get (fun (dr_st' : driver_state) =>
    nd_return (finalize t5File.tagDefs "callND" dr_st'))

/-! ## Arc-9 S3 additions: the loop fixture data (label syms from the
    labeled-continuation census; body-let syms from the loop-head env
    dumps — all content-hashed ids validated by the entry/iteration
    rfl walks). -/

def symWhile : sym := Symbol "" 5345818875920638407 (SD_Id "while_501")

def symA502 : sym := Symbol "" 8889381283917733902 (SD_Id "a_502")
def symA503 : sym := Symbol "" 14798685261839020542 (SD_Id "a_503")
def symA504 : sym := Symbol "" 13222863191375119694 (SD_Id "a_504")
def symA505 : sym := Symbol "" 15587187630708245497 (SD_Id "a_505")
def symA507 : sym := Symbol "" 3712579248453425038 (SD_Id "a_507")
def symA508 : sym := Symbol "" 6853313270503072038 (SD_Id "a_508")
def symA512 : sym := Symbol "" 17123687452746221040 (SD_Id "a_512")
def symA513 : sym := Symbol "" 4622258550668407059 (SD_Id "a_513")
def symA514 : sym := Symbol "" 7846888631986887727 (SD_Id "a_514")
def symA515 : sym := Symbol "" 18346162544558864837 (SD_Id "a_515")
def symA519 : sym := Symbol "" 238585015645548330 (SD_Id "a_519")
def symA520 : sym := Symbol "" 3474084476103638235 (SD_Id "a_520")
def symA521 : sym := Symbol "" 2151434721365532277 (SD_Id "a_521")
def symA525 : sym := Symbol "" 3579765898737599443 (SD_Id "a_525")
def symA526 : sym := Symbol "" 13429216386455784360 (SD_Id "a_526")
def symA527 : sym := Symbol "" 4139409277016632516 (SD_Id "a_527")
def symA528 : sym := Symbol "" 8935235297226827052 (SD_Id "a_528")
def symA529 : sym := Symbol "" 1680278659536745755 (SD_Id "a_529")
def symA530 : sym := Symbol "" 4915778119994869450 (SD_Id "a_530")
def symA534 : sym := Symbol "" 5254944664791163557 (SD_Id "a_534")
def symA535 : sym := Symbol "" 15754218577363027919 (SD_Id "a_535")
def symA536 : sym := Symbol "" 6464411467923874555 (SD_Id "a_536")
def symA537 : sym := Symbol "" 6477419756603697776 (SD_Id "a_537")
def symA538 : sym := Symbol "" 18319030617476695216 (SD_Id "a_538")

/-- The process sym-supply seed, STUCK form (the T4 anon1stuck
    discipline, design §11.2): the invariant family carries the stuck
    extern reads — `hdig`/`hfresh` (T5EnvHyp) pin them ONLY inside
    the small per-key lookup lemmas, never by rewriting a big state. -/
def seedT5 : Nat := rsD5.sym_supply

/-- The NEG-transform's j-th fresh unit-binder symbol (stuck form:
    digest and seed as the process reads them). -/
def unitSym (j : Nat) : sym :=
  Symbol (CerberusFresh.digest ()) (seedT5 + j) SD_None

/-- The while_501 labeled continuation (params, body) —
    fixture-derived from the collected labeled continuations, never
    transcribed. -/
def whileCont : List (sym × core_base_type)
    × generic_expr core_run_annotation Unit sym :=
  match Lem_Maybe.bind0
      (fmapLookupBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
        sumT5Sym (initial_core_run_state
          (collect_labeled_continuations_NEW t5File)).labeled)
      (fmapLookupBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
        symWhile) with
  | some pb => pb
  | none => ([], Expr [] (Epure (Pexpr [] () (PEval Vunit))))

/-- The loop-head arena (the while_501 continuation body). -/
def whileBody : generic_expr core_run_annotation Unit sym := whileCont.2

/-! ### Walker-v2 state atoms (design §11.3): the fixture's pinned
    names the normalizer must never unfold. -/
attribute [app_state_atom] t5File sumBody whileBody rsD5 env0T5 th0T5
attribute [app_state_atom] RelSem.T1.memD3 RelSem.T1.memInj
  RelSem.T1.bmErrAlloc RelSem.T1.memErrAlloc RelSem.T1.mkByte

end RelSem.T5
