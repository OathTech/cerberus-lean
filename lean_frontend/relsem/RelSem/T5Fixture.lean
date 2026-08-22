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

def symWhile : sym := Symbol "" 15846621060339386788 (SD_Id "while_531")

def symA532 : sym := Symbol "" 1342427191597093029 (SD_Id "a_532")
def symA533 : sym := Symbol "" 18213349194842787190 (SD_Id "a_533")
def symA534 : sym := Symbol "" 5254944664791163557 (SD_Id "a_534")
def symA535 : sym := Symbol "" 15754218577363027919 (SD_Id "a_535")
def symA537 : sym := Symbol "" 6477419756603697776 (SD_Id "a_537")
def symA538 : sym := Symbol "" 18319030617476695216 (SD_Id "a_538")
def symA542 : sym := Symbol "" 16217071427669230452 (SD_Id "a_542")
def symA543 : sym := Symbol "" 14641249357205542421 (SD_Id "a_543")
def symA544 : sym := Symbol "" 7590096031763635132 (SD_Id "a_544")
def symA545 : sym := Symbol "" 11067898428807828624 (SD_Id "a_545")
def symA549 : sym := Symbol "" 16629223912856532319 (SD_Id "a_549")
def symA550 : sym := Symbol "" 2567468451026663467 (SD_Id "a_550")
def symA551 : sym := Symbol "" 14409079311899709851 (SD_Id "a_551")
def symA555 : sym := Symbol "" 6806144180337321293 (SD_Id "a_555")
def symA556 : sym := Symbol "" 1097327803196824626 (SD_Id "a_556")
def symA557 : sym := Symbol "" 16397053867550904782 (SD_Id "a_557")
def symA558 : sym := Symbol "" 1656971181475828259 (SD_Id "a_558")
def symA559 : sym := Symbol "" 1862827267035441118 (SD_Id "a_559")
def symA560 : sym := Symbol "" 14386475981198921378 (SD_Id "a_560")
def symA564 : sym := Symbol "" 4998152064567917579 (SD_Id "a_564")
def symA565 : sym := Symbol "" 15936767184861729128 (SD_Id "a_565")
def symA566 : sym := Symbol "" 5557795442846871051 (SD_Id "a_566")
def symA567 : sym := Symbol "" 16496410563140706571 (SD_Id "a_567")
def symA568 : sym := Symbol "" 12129931134301626842 (SD_Id "a_568")

/-- The process sym-supply seed, STUCK form (the T4 anon1stuck
    discipline, design §11.2): the invariant family carries the stuck
    extern reads — `hdig`/`hfresh` (T5EnvHyp) pin them ONLY inside
    the small per-key lookup lemmas, never by rewriting a big state. -/
def seedT5 : Nat := rsD5.sym_supply

/-- The NEG-transform's j-th fresh unit-binder symbol (stuck form:
    digest and seed as the process reads them). -/
def unitSym (j : Nat) : sym :=
  Symbol (CerberusFresh.digest ()) (seedT5 + j) SD_None

/-- The while_531 labeled continuation (params, body) —
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

/-- The loop-head arena (the while_531 continuation body). -/
def whileBody : generic_expr core_run_annotation Unit sym := whileCont.2

/-! ### Walker-v2 state atoms (design §11.3): the fixture's pinned
    names the normalizer must never unfold. -/
attribute [app_state_atom] t5File sumBody whileBody rsD5 env0T5 th0T5
attribute [app_state_atom] RelSem.T1.memD3 RelSem.T1.memInj
  RelSem.T1.bmErrAlloc RelSem.T1.memErrAlloc RelSem.T1.mkByte

end RelSem.T5
