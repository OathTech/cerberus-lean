/-
  RelSem.T1Rounds — V2 (2026-08-28): THE T1 ENGINE ROOM at the
  decomposed assertion layer — the per-round app equations of the
  `id(x)` harness run at an ABSTRACT env frame with CELL FACTS (the
  V1 demo's engine style, systematized through the Kit/EvalStep
  construct laws), plus the control-family inversion the wpk `_fam`
  rules consume.

  Provenance: the arena/state data is the arc-7 S5a T1 walk
  transcription (deleted at V0 with the walk rooms; re-derived here —
  every `rfl` below re-validates it against the generated machine).
  The x-sensitivity analysis (unchanged since the S5a discovery
  record): R3 (byte roundtrip) and R6 (the conv range check) are the
  only x-branching rounds; every other round is payload-opaque.

  V2 delta vs the deleted walks: rounds are stated at an ABSTRACT
  top frame `f₁` under `EnvWfFrame` with `lookup` CELL FACTS as
  hypotheses (what `envIs` fragments yield) — the per-cell locality
  the old concrete-env rounds could not express.

  House rules: no sorry, no axioms. (Imports CerbStateRA for the
  control projection vocabulary — ctlOf/EnvWf/EnvDom; no Iris
  assertions are STATED here.) Under the in-build audit.
-/

import RelSem.T1File
import RelSem.Machine
import RelSem.Cerberus
import RelSem.Call
import RelSem.Kit.Eval
import RelSem.Kit.EvalStep
import RelSem.Kit.Round
import RelSem.Kit.Mem
import RelSem.Kit.Map
import RelSem.MemLocal
import RelSem.ConstructLaws
import RelSem.PerStepPeel
import RelSem.Threaded
import RelSem.T1Threaded
import RelSem.CerbStateRA
import RelSem.CerbStateStep
import RelSem.SegRun

set_option autoImplicit false

namespace RelSem.T1

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt
open Lem_Basic_classes (ordCompare)

/-! ## Pinned program data (S5a transcription, revalidated by rfl) -/

abbrev aU : List annot := [Aloc CerbLocation.Loc.unknown]

def symX : sym := Symbol "" 16562859848569467201 (SD_Id "x")
def symA524 : sym := Symbol "" 1574597236902804563 (SD_Id "a_524")
def symA525 : sym := Symbol "" 3579765898737599443 (SD_Id "a_525")
def symA526 : sym := Symbol "" 13429216386455784360 (SD_Id "a_526")
def symRet : sym := Symbol "" 8833183227039990084 (SD_Id "ret_523")

def intCty : ctype := Ctype [] (Basic (Integer (Signed Int_)))

/-- x's parameter object: first allocation. -/
def xAddr : Int := 281474976710648
/-- errno object: second allocation. -/
def errAddr : Int := 281474976710644

def xPtr : CerbMem.PointerValue :=
  .PV (.Prov_some 0) (.PVconcrete none xAddr)
def errPtr : CerbMem.PointerValue :=
  .PV (.Prov_some 1) (.PVconcrete none errAddr)

def xPtrV : value := Vobject (OVpointer xPtr)

/-- The loaded specified integer value. -/
def loadedV (v : Int) : value :=
  Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV .Prov_none v)))

def patA499 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA524, BTy_object OTy_pointer))
def patA500 : generic_pattern sym :=
  Pattern aU (CaseBase (some symA525, BTy_loaded OTy_integer))
def patUnit : generic_pattern sym :=
  Pattern [] (CaseBase (none, BTy_unit))

abbrev RExpr := generic_expr core_run_annotation Unit sym

def loadE (pc pp : generic_pexpr Unit sym) : RExpr :=
  Expr aU (Eaction (Paction Pos (Action CerbLocation.Loc.unknown
    empty_annotation (Load0 pc pp NA))))

def bodyTail : RExpr :=
  Expr aU (Esseq patUnit
    (Expr aU (Erun empty_annotation symRet
      [Pexpr aU () (PEcall (Sym convLoadedIntSym)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEsym symA525)])]))
    (Expr aU (Esseq patUnit
      (Expr aU (Epure (Pexpr aU () (PEval Vunit))))
      (Expr aU (Esave (symRet, BTy_loaded OTy_integer)
        [(symA526, ((BTy_loaded OTy_integer, none),
          Pexpr aU () (PEundef CerbLocation.Loc.unknown
            UB088_reached_end_of_function)))]
        (Expr aU (Epure (Pexpr aU () (PEsym symA526)))))))))

def arena0 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (Expr aU (Ewseq patA499
      (Expr aU (Epure (Pexpr aU () (PEsym symX))))
      (loadE (Pexpr aU () (PEval (Vctype intCty)))
             (Pexpr aU () (PEsym symA524)))))))
    bodyTail)

def arena1 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (Expr aU (Ewseq patA499
      (Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (loadE (Pexpr aU () (PEval (Vctype intCty)))
             (Pexpr aU () (PEsym symA524)))))))
    bodyTail)

def arena2 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (loadE (Pexpr aU () (PEval (Vctype intCty)))
                            (Pexpr aU () (PEsym symA524)))))
    bodyTail)

def arena3 : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (loadE (Pexpr [] () (PEval (Vctype intCty)))
                            (Pexpr [] () (PEval xPtrV)))))
    bodyTail)

def arena4 (v : Int) : RExpr :=
  Expr aU (Esseq patA500
    (Expr aU (Ebound (Expr [] (Eannot
      [DA_pos [] (CerbMem.Footprint.FP .R xAddr 4)]
      (Expr [] (Epure (Pexpr [] () (PEval (loadedV v)))))))))
    bodyTail)

def arena5 (v : Int) : RExpr :=
  Expr aU (Esseq patA500
    (Expr [] (Epure (Pexpr [] () (PEval (loadedV v)))))
    bodyTail)

def arena7 : RExpr :=
  Expr aU (Epure (Pexpr aU () (PEsym symA526)))

def arena8 (v : Int) : RExpr :=
  Expr aU (Epure (Pexpr [] () (PEval (loadedV v))))

/-! ## The control family: one thread over `t1File`, arena + trace +
    counter CONTROL, frame/supplies/layout ABSTRACT -/

@[reducible] def t1Th (arena : RExpr) (f₁ : Fmap sym value) : thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_normal [(idT1Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some idT1Sym }

@[reducible] def t1σ (arena : RExpr) (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t1File,
    core_extern := create_extern_symmap t1File,
    core_state0 :=
      { thread_states := [(0, (none, t1Th arena f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t1File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

/-- The canonical control image at (arena, trace, counter). -/
def t1CtlAt (arena : RExpr) (tr : List trace_event) (n : Nat) :
    driver_state :=
  ctlOf (t1σ arena fmapEmpty 0 0 0 0 CerbMem.initialMemState tr n)

theorem ctlOf_t1σ (arena : RExpr) (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) :
    ctlOf (t1σ arena f₁ tS aS eS sS ls tr n) = t1CtlAt arena tr n := rfl

/-- The family parameter pack (V2b: re-homed to the engine's
    `Seg.Pack` — same fields, so every pack literal and `{p with …}`
    update below is unchanged; the segment links are generic over
    the ONE pack shape). -/
abbrev T1P := RelSem.Seg.Pack

/-- The family, packaged (what the `_fam` rules consume). -/
@[reducible] def t1fam (arena : RExpr) (tr : List trace_event) (n : Nat)
    (p : T1P) : driver_state :=
  t1σ arena p.f₁ p.tS p.aS p.eS p.sS p.ls tr n

/-- THE CONTROL INVERSION at the T1 family (the demo `ctl_inv`
    pattern, at trace/counter parameters). -/
@[seg_inv]
theorem t1_inv {σ : driver_state} {arena : RExpr}
    {tr : List trace_event} {n : Nat}
    (h : ctlOf σ = t1CtlAt arena tr n) :
    ∃ p : T1P, σ = t1fam arena tr n p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t1CtlAt, ctlOf, t1σ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t1Th,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₁ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨⟨f₁, tS, aS, eS, sS, ls⟩, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

/-- Frame well-formedness from the family's `EnvWf`. -/
theorem t1fam_frame {arena : RExpr} {tr : List trace_event} {n : Nat}
    {p : T1P} (hwf : EnvWf (t1fam arena tr n p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env, t1fam, t1σ, t1Th])

/-- Family lookups are top-frame lookups. -/
theorem t1fam_lookup (arena : RExpr) (tr : List trace_event) (n : Nat)
    (p : T1P) (z : sym) :
    envLookup (t1fam arena tr n p) z
      = fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z p.f₁ := by
  show lookup_env z [p.f₁] = _
  cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z p.f₁ <;>
    simp [lookup_env, h]


/-! ## The STAGE-0 family: the state the harness setup writes.
    `current_loc` is `other "RelSem.callND"` (callFinishK's record);
    the first eval round resets it to `Loc.unknown` — every later
    stage lives in the `t1Th` family. -/

@[reducible] def t1Th0 (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(idT1Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some idT1Sym }

@[reducible] def t1σ0 (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState) : driver_state :=
  { core_file := t1File,
    core_extern := create_extern_symmap t1File,
    core_state0 :=
      { thread_states := [(0, (none, t1Th0 arena0 f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t1File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def t1Ctl0 : driver_state :=
  ctlOf (t1σ0 fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def t1fam0 (p : T1P) : driver_state :=
  t1σ0 p.f₁ p.tS p.aS p.eS p.sS p.ls

/-- Control inversion at the stage-0 family. -/
@[seg_inv]
theorem t1_inv0 {σ : driver_state} (h : ctlOf σ = t1Ctl0) :
    ∃ p : T1P, σ = t1fam0 p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t1Ctl0, ctlOf, t1σ0, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t1Th0,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₁ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨⟨f₁, tS, aS, eS, sS, ls⟩, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

/-- Frame well-formedness from the stage-0 family's `EnvWf`. -/
theorem t1fam0_frame {p : T1P} (hwf : EnvWf (t1fam0 p)) :
    EnvWfFrame p.f₁ :=
  hwf p.f₁ (by
    show p.f₁ ∈ thread0Env _
    simp [thread0Env, t1fam0, t1σ0, t1Th0])

/-! ## Argument bytes and the roundtrip (S5a salvage, revalidated) -/

/-- The AbsByte the store writes for byte `i` of the injected int
    (memValueToBytes MVinteger arm over intToBytes; spelled defeq to
    the stored term). -/
def mkByte (x : Int) (i : Nat) : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none,
    value := some ((((if x < 0 then (1 <<< 32) + x else x) >>> (i * 8)).toNat % 256).toUInt8) }

def xBytes (x : Int) : List CerbMem.AbsByte :=
  [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]

/-- THE BYTE ROUNDTRIP: 4 little-endian bytes of an int-range integer
    recombine (signed) to the integer. -/
theorem roundtrip_arith (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    CerbMem.bytesToInt [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] true
      = some x := by
  unfold CerbMem.bytesToInt mkByte
  simp only [List.any, Option.isNone, Bool.or_false, CerbMem.bytesToInt.go]
  by_cases hx : x < 0
  · have hy0 : (0:Int) ≤ 4294967296 + x := by omega
    have hy1 : (0:Int) ≤ (4294967296 + x) / 256 := by omega
    have hy2 : (0:Int) ≤ (4294967296 + x) / 65536 := by omega
    have hy3 : (0:Int) ≤ (4294967296 + x) / 16777216 := by omega
    have d1 : (4294967296 + x) / 256 / 256 = (4294967296 + x) / 65536 := by omega
    have d2 : (4294967296 + x) / 65536 / 256 = (4294967296 + x) / 16777216 := by omega
    have d3 : (4294967296 + x) / 16777216 / 256 = 0 := by omega
    simp only [hx, if_true, if_false, reduceIte]
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
    simp only [hx, if_true, if_false, reduceIte]
    simp [Int.shiftLeft_eq, Int.shiftRight_eq_div_pow, Int.toNat_of_nonneg hx0,
      Int.toNat_of_nonneg hx1, Int.toNat_of_nonneg hx2, Int.toNat_of_nonneg hx3]
    split <;> refine congrArg some ?_ <;> omega

/-! ## Memory-residual ladder (concrete; what the mrest token pins) -/

def allocX : CerbMem.Allocation :=
  { base := xAddr, size := 4, ty := some intCty,
    prefix_ := PrefOther "callND arg" }
def allocErr : CerbMem.Allocation :=
  { base := errAddr, size := 4, ty := some signed_int,
    prefix_ := PrefOther "errno" }

def zeroByte : CerbMem.AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := some 0 }
def zeroBytes : List CerbMem.AbsByte :=
  [zeroByte, zeroByte, zeroByte, zeroByte]

/-- The initial memory residual. -/
@[reducible] def mr0 : CerbMem.MemState := memRestOf
  (initial_driver_state_threaded 0 t1File t1Fs)
/-- After the argument allocation. -/
@[reducible] def mr1 : CerbMem.MemState := mrAlloc mr0 xAddr
/-- After the errno allocation. -/
@[reducible] def mr2 : CerbMem.MemState := mrAlloc mr1 errAddr

theorem sizeof_int_eq : CerbMem.sizeofCtype signed_int = 4 := rfl
theorem sizeof_intCty_eq : CerbMem.sizeofCtype intCty = 4 := rfl

/-- The serialized argument (integer arm: funptrmap passes through,
    bytes are x's little-endian chunks — ∀ fpm). -/
theorem memValueToBytes_int (fpm : CerbMem.Funptrmap) (x : Int) :
    CerbMem.memValueToBytes fpm
      (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval x))
      = (fpm, xBytes x) := rfl

/-- The caller protocol's memValue for an int argument. -/
theorem memValueFromValue_int (x : Int) :
    memValueFromValue t1File.tagDefs signed_int (intValue x)
      = some (CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval x)) := rfl


/-! ## The initial and post-globals families -/

/-- The initial family: the threaded initial state at layout `ls`
    (ctl+sup pin everything else; no threads). -/
def t1Init (seed : Nat) (ls : CerbMem.MemState) : driver_state :=
  { initial_driver_state_threaded seed t1File t1Fs with
      layout_state := ls }

/-- The globals thread at frame `f₀` (post-globals; the frame content
    is what ctl erases). -/
@[reducible] def thGf (f₀ : Fmap sym value) : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [f₀],
    current_proc_opt := none }

/-- The post-globals family. -/
@[reducible] def dGσ (f₀ : Fmap sym value) (tS aS eS sS : Nat)
    (ls : CerbMem.MemState) : driver_state :=
  { core_file := t1File,
    core_extern := create_extern_symmap t1File,
    core_state0 :=
      { thread_states := [(0, (none, thGf f₀))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t1File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

/-- The post-globals control image. -/
def dGCtl : driver_state :=
  ctlOf (dGσ fmapEmpty 0 0 0 0 CerbMem.initialMemState)

structure DGP where
  f₀ : Fmap sym value
  tS : Nat
  aS : Nat
  eS : Nat
  sS : Nat
  ls : CerbMem.MemState

@[reducible] def dGfam (p : DGP) : driver_state :=
  dGσ p.f₀ p.tS p.aS p.eS p.sS p.ls

theorem ctlOf_dGσ (f₀ : Fmap sym value) (tS aS eS sS : Nat)
    (ls : CerbMem.MemState) :
    ctlOf (dGσ f₀ tS aS eS sS ls) = dGCtl := rfl

/-- Control inversion at the post-globals family. -/
theorem dG_inv {σ : driver_state} (h : ctlOf σ = dGCtl) :
    ∃ p : DGP, σ = dGfam p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [dGCtl, ctlOf, dGσ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, thGf,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₀ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨⟨f₀, tS, aS, eS, sS, ls⟩, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

/-- Control inversion at the initial family (no threads; ctl leaves
    only supplies + layout free; the sup token pins the supplies). -/
theorem t1Init_inv {σ : driver_state} {seed : Nat}
    (h : ctlOf σ = ctlOf (t1Init 0 CerbMem.initialMemState))
    (hs : suppliesOf σ = suppliesOf (t1Init seed CerbMem.initialMemState)) :
    σ = t1Init seed σ.layout_state := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t1Init, ctlOf, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  have hs' := hs
  simp only [suppliesOf, t1Init, Supplies.mk.injEq] at hs'
  obtain ⟨hts, has, hes, hss⟩ := hs'
  cases ths with
  | cons t rest =>
    rw [show (initial_driver_state_threaded 0 t1File
        t1Fs).core_state0.thread_states
      = ([] : List (Nat × (Option thread_id × thread_state)))
      from rfl] at hths
    simp at hths
  | nil =>
    subst hcf hce hccs hfs htr hsa hbl hctr hio hlab hts has hes hss
    rfl

/-! ## The prefix stage equations (family-level; layout/seed
    abstract — the globals path never reads memory) -/

/-- k1: the globals stage at the initial family — thread 0 spawned,
    tid 0 returned, one tid drawn. -/
theorem k1_fam (seed : Nat) (ls : CerbMem.MemState) :
    app (driver_globals t1File.tagDefs false t1File)
        (t1Init seed ls)
      = (NDactive 0, dGσ fmapEmpty 1 0 0 seed ls) := rfl

/-- Core-file projection from a control pin (generic). -/
theorem coreFile_of_ctl {σ c : driver_state} (h : ctlOf σ = c) :
    σ.core_file = c.core_file := by
  rw [← h]; rfl

/-- k3: name resolution (state-preserving; σ-independent). -/
theorem k3_any (σ : driver_state) :
    app (resolveFunSym t1File "id") σ = (NDactive idT1Sym, σ) := rfl

/-- k4: the designated function's parameters and body. -/
theorem k4_any (σ : driver_state) :
    app (lookupFunBody t1File idT1Sym) σ
      = (NDactive ([(symX, BTy_object OTy_pointer)], arena0), σ) := rfl

/-- k5: the funinfo-declared parameter C types. -/
theorem k5_any (σ : driver_state) :
    app (lookupParamTys t1File idT1Sym) σ
      = (NDactive [signed_int], σ) := rfl


/-! ## The rounds (family-level app equations at the fused round atom;
    frames ABSTRACT, cell facts fed) -/

/-- The env comparator closure the machine's binds capture. -/
abbrev envCmp : sym → sym → LemOrdering :=
  fun s1 s2 => ordCompare s1 s2

/-- R0: the Ewseq's left pure operand evaluates — reads x's cell. -/
@[seg_round]
theorem t1r0 (p : T1P)
    (hwf : EnvWfFrame p.f₁)
    (hx : envLookup (t1fam arena0 [] 0 p) symX = some xPtrV) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam arena0 [] 0 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam arena1 [] 1 { p with }) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t1Th arena1 p.f₁)
    (rs' := (t1fam arena0 [] 0 p).core_run_state0) ?_).trans ?_
  · -- the eval step: the full-eval loop hits x's cell (aux2_sym_hit)
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (st' := (t1fam arena0 [] 0 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (t1fam arena0 [] 0 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (t1fam arena0 [] 0 p).core_run_state0) ?_).trans ?_
    · -- eval20: the aux2 loop under runEU
      show runEU (eval_pexpr_aux2 t1File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t1File) [p.f₁] (some p.ls) t1File
          (Pexpr aU () (PEsym symX))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symX) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env symX [p.f₁] = some xPtrV from hx)]
      rfl
    · rfl
  · rfl


/-- R0 at the STAGE-0 family (the round the setup state actually
    feeds; output lands in the `t1Th` family — the eval resets
    `current_loc`). -/
@[seg_round]
theorem t1r0v (p : T1P)
    (hwf : EnvWfFrame p.f₁)
    (hx : envLookup (t1fam0 p) symX = some xPtrV) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam0 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam arena1 [] 1 { p with }) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t1Th arena1 p.f₁)
    (rs' := (t1fam0 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Expr aU (Epure (Pexpr [] () (PEval xPtrV))))
      (st' := (t1fam0 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (t1fam0 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (t1fam0 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t1File.tagDefs _ _
          (create_extern_symmap t1File) [p.f₁] (some p.ls) t1File
          (Pexpr aU () (PEsym symX))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symX) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env symX [p.f₁] = some xPtrV from hx)]
      rfl
    · rfl
  · rfl


/-- The environment write the R1 bind performs (compiled-matcher
    spelling; the matcher splits on the VALUE first — concrete here). -/
theorem update_env_aux_a524 (f : Fmap sym value) :
    update_env_aux patA499 xPtrV f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA524 xPtrV f := rfl

/-- R1: the Ewseq binds a_524 (the birth round). -/
@[seg_round]
theorem t1r1 (p : T1P) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam arena1 [] 1 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam arena2 [] 2
           { p with f₁ := update_env_aux patA499 xPtrV p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- R2: the Load's pointer operand evaluates — reads a_524's cell. -/
@[seg_round]
theorem t1r2 (p : T1P)
    (ha : envLookup (t1fam arena2 [] 2 p) symA524 = some xPtrV) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam arena2 [] 2 p)
      = (NDactive (Sum.inl NOWAKEUP), t1fam arena3 [] 3 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t1Th arena3 p.f₁)
    (rs' := (t1fam arena2 [] 2 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Action CerbLocation.Loc.unknown empty_annotation
        (Load0 (mk_value_pe (Vctype intCty)) (mk_value_pe xPtrV) NA))
      (st' := (t1fam arena2 [] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Vctype intCty)
      (st' := (t1fam arena2 [] 2 p).core_run_state0) ?_).trans ?_
    · rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := xPtrV)
      (st' := (t1fam arena2 [] 2 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr xPtrV)
      (st' := (t1fam arena2 [] 2 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t1File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t1File) [p.f₁] (some p.ls) t1File
          (Pexpr aU () (PEsym symA524))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA524) (v := xPtrV)
        (env := [p.f₁]) rfl rfl
        (show lookup_env symA524 [p.f₁] = some xPtrV from ha)]
      rfl
    · rfl
  · rfl


/-! ## R3 — the load (the x-sensitive memory read; byte facts fed
    from the footprint) -/

/-- R3's trace event. -/
def meLoad (x : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty xPtr
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))

/-- The load's memory equation at footprint facts (state unchanged). -/
theorem loadX_eq_facts (x : Int) (ls : CerbMem.MemState)
    (hget : ls.allocations.get? 0 = some allocX)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : ls.lastUsedUnionMembers = [])
    (hfpm : ls.funptrmap = [])
    (hinv : MemInv ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (CerbMem.loadM CerbLocation.Loc.unknown intCty xPtr) ls
      = (NDactive (CerbMem.Footprint.FP .R xAddr 4,
          CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x)),
         ls) := by
  have hrecon : CerbMem.reconstructValue ls.lastUsedUnionMembers
      ls.funptrmap xAddr intCty (xBytes x)
      = CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none x) := by
    rw [hlum, hfpm]
    show CerbMem.reconstructValue_lemFuel (999999 + 1) [] [] xAddr
      (Ctype [] (Basic (Integer (Signed Int_)))) (xBytes x) = _
    rw [CerbMem.reconstructValue_lemFuel]
    simp only [CerberusImpl.is_signed_ity]
    rw [show xBytes x
        = [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3] from rfl,
      roundtrip_arith x h1 h2]
    simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, mkByte]
  exact Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
    (um := none) (hinv.contains_dead_false hget) hget rfl rfl
    (readBytesFrom_of_pointwise rfl hbytes) hrecon rfl

/-- R3: the load round — aid drawn, the read performed, the loaded
    value (EXACTLY x, by the roundtrip) lands in the arena, ME_load
    traced. The step counter does not move (action requests never
    bump it). -/
@[seg_round]
theorem t1r3 (x : Int) (p : T1P)
    (hget : p.ls.allocations.get? 0 = some allocX)
    (hbytes : ∀ i : Nat, (hi : i < (xBytes x).length) →
      p.ls.bytemap.get? (xAddr + (i : Int)) = some (xBytes x)[i])
    (hlum : p.ls.lastUsedUnionMembers = [])
    (hfpm : p.ls.funptrmap = [])
    (hinv : MemInv p.ls)
    (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam arena3 [] 3 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam (arena4 x) [meLoad x] 3 { p with aS := p.aS + 1 }) := by
  refine dnmsRoundM_adv rfl ?_
  apply (app_bind_active ?hreq).trans
  case hreq =>
    refine (app_bind_active rfl).trans ?_
    rw [perform_unfold]
    refine (app_bind_active aid_draw).trans ?_
    rw [ars_load_unfold]
    refine (app_bind_active (app_liftMem_active rfl
      (loadX_eq_facts x p.ls hget hbytes hlum hfpm hinv h1 h2))).trans ?_
    refine (app_bind_active (app_liftMem_active rfl
      mem_prefix_block)).trans ?_
    exact app_nd_update _ _
  rfl


/-- R4: the Eannot/Ebound wrapper around the loaded value strips. -/
@[seg_round]
theorem t1r4 (x : Int) (p : T1P) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam (arena4 x) [meLoad x] 3 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam (arena5 x) [meLoad x] 4 p) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-- The R5 bind's env write (compiled-matcher spelling). -/
theorem update_env_aux_a525 (x : Int) (f : Fmap sym value) :
    update_env_aux patA500 (loadedV x) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA525 (loadedV x) f := rfl

/-- R5: the Esseq binds a_525 — the body tail is exposed. -/
@[seg_round]
theorem t1r5 (x : Int) (p : T1P) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam (arena5 x) [meLoad x] 4 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam bodyTail [meLoad x] 5
           { p with f₁ := update_env_aux patA500 (loadedV x) p.f₁ }) := by
  refine dnmsRoundM_adv rfl ?_
  exact (advance_tau_misc).trans rfl

/-! ## R6 — the Erun jump: the conv_loaded_int chain at an ABSTRACT
    env (the S5a chain, ∀-env; only the head step consults the env —
    the a_525 lookup enters through `se_call`'s mapM) -/

def xIntV (x : Int) : value :=
  Vobject (OVinteger (CerbMem.IntegerValue.IV .Prov_none x))

def convPE : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA525)])

def z0 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEcase (Pexpr [] () (PEval (loadedV x)))
    [(Pattern aU (CaseCtor Cspecified [Pattern aU (CaseBase (some (Symbol "" 8148669997605808657 (SD_Id "n")), BTy_object OTy_integer))]),
      Pexpr aU () (PEctor Cspecified [Pexpr aU () (PEcall (Sym convIntSym)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEsym (Symbol "" 8148669997605808657 (SD_Id "n")))])])),
     (Pattern aU (CaseCtor Cunspecified [Pattern aU (CaseBase (none, BTy_ctype))]),
      Pexpr aU () (PEctor Cunspecified [Pexpr aU () (PEval (Vctype intCty))]))])

def z1 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified [Pexpr aU () (PEcall (Sym convIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xIntV x))])])

def convElse (x : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEif
    (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty)))))
    (Pexpr aU () (PEcall (Sym (Symbol "" 14671517598387306907 (SD_Id "wrapI")))
      [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xIntV x))]))
    (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer)
      [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xIntV x))])))

def z2 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified [Pexpr [] () (PEif
    (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty)))
      (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0))))))))
    (Pexpr aU () (PEif
      (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (xIntV x)))
        (Pexpr aU () (PEval (xIntV 0)))))
      (Pexpr aU () (PEval (xIntV 0)))
      (Pexpr aU () (PEval (xIntV 1)))))
    (Pexpr aU () (PEif
      (Pexpr aU () (PEcall (Sym isReprIntegerSym)
        [Pexpr aU () (PEval (xIntV x)), Pexpr aU () (PEval (Vctype intCty))]))
      (Pexpr aU () (PEval (xIntV x)))
      (convElse x))))])

def z3 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified [Pexpr [] () (PEif
    (Pexpr [] () (PEop OpAnd
      (Pexpr [] () (PEop OpLe
        (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
        (Pexpr [] () (PEval (xIntV x)))))
      (Pexpr [] () (PEop OpLe
        (Pexpr [] () (PEval (xIntV x)))
        (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))]))))))
    (Pexpr aU () (PEval (xIntV x)))
    (convElse x))])

def z4 (x : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEval (loadedV x))

/-- s0: the conv call inlines — the a_525 lookup enters via the
    argument mapM (`se_call` + `se_sym_hit`). -/
theorem s0_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (ha : lookup_env symA525 env = some (loadedV x)) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t1File) env memo t1File false
      (Pexpr [] () (PEcall (Sym convLoadedIntSym)
        [Pexpr aU () (PEval (Vctype intCty)),
         Pexpr aU () (PEsym symA525)]))
      = Result (Defined (z0 x)) := by
  show step_eval_pexpr_lemFuel (999999 + 1) _ _ _ _ _ _ _ _ _ _ = _
  refine se_call (pes' := [Pexpr [] () (PEval (Vctype intCty)),
      Pexpr [] () (PEval (loadedV x))])
    (cvals := [Vctype intCty, loadedV x]) ?_ rfl rfl rfl
  exact eumapM_cons rfl
    (eumapM_cons (se_sym_hit (fuel := 999998) rfl ha) eumapM_nil)

theorem s1_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t1File) env memo t1File false (z0 x)
      = Result (Defined (z1 x)) := rfl

theorem s2_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t1File) env memo t1File false (z1 x)
      = Result (Defined (z2 x)) := rfl

theorem s3_eq (x : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t1File) env memo t1File false (z2 x)
      = Result (Defined (z3 x)) := rfl


/-- s4: the range check (the path hypotheses enter). -/
theorem s4_eq (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t1File.tagDefs 0 CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t1File) env memo t1File false (z3 x)
      = Result (Defined (z4 x)) := by
  have hd1 : decide ((-2147483648:Int) ≤ x) = true := decide_eq_true h1
  have hd2 : decide (x ≤ (2147483647:Int)) = true := decide_eq_true h2
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV x) : generic_pexpr_ Unit sym)) ?hBody).trans ?_
  case hBody =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (xIntV x)) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hIf
      case hIf =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (xIntV x) : generic_pexpr_ Unit sym)) ?hIfBody).trans ?_
        case hIfBody =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
            ?hCond).trans ?_
          case hCond =>
            change exception_undef_bind _ _ = _
            refine (eubind_defined
              (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hCondBody).trans ?_
            case hCondBody =>
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe1).trans ?_
              case hLe1 =>
                show step_eval_pexpr_lemFuel 999997 t1File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t1File) env memo t1File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEctor Civmin [Pexpr aU () (PEval (Vctype intCty))]))
                    (Pexpr [] () (PEval (xIntV x)))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide ((-2147483648:Int) ≤ x)) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
                conv => rhs; rw [← harm]
                rfl
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
                ?hLe2).trans ?_
              case hLe2 =>
                show step_eval_pexpr_lemFuel 999997 t1File.tagDefs (0+1+1+1)
                  CerbLocation.Loc.unknown (some (CerbLocation.other "RelSem.callND"))
                  (create_extern_symmap t1File) env memo t1File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEval (xIntV x)))
                    (Pexpr [] () (PEctor Civmax [Pexpr aU () (PEval (Vctype intCty))]))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide (x ≤ (2147483647:Int))) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
                conv => rhs; rw [← harm]
                rfl
              rfl
            rfl
          rfl
        rfl
    rfl
  rfl

/-- convPE in pull-normal form (top annots stripped). -/
def convPE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLoadedIntSym)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEsym symA525)])

theorem pull_convPE : pull_constrained 0 convPE = convPE_p := rfl
theorem pull_z0 (x : Int) : pull_constrained 0 (z0 x) = z0 x := rfl
theorem pull_z1 (x : Int) : pull_constrained 0 (z1 x) = z1 x := rfl
theorem pull_z2 (x : Int) : pull_constrained 0 (z2 x) = z2 x := rfl
theorem pull_z3 (x : Int) : pull_constrained 0 (z3 x) = z3 x := rfl

/-- The whole conv loop at an abstract env (four steps + the exit). -/
theorem convChain_eq (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (ha : lookup_env symA525 env = some (loadedV x)) :
    eval_pexpr_aux2 t1File.tagDefs CerbLocation.Loc.unknown
      (some (CerbLocation.other "RelSem.callND"))
      (create_extern_symmap t1File) env memo t1File convPE
      = Result (Defined (Sum.inr (loadedV x))) :=
  (aux2_step 999999 _ _ _ _ _ _ _ pull_convPE
      (by intro a xs h; simp [convPE_p] at h) (s0_eq x env memo ha)
      (by rfl)).trans
  ((aux2_step 999998 _ _ _ _ _ _ _ (pull_z0 x)
      (by intro a xs h; simp [z0] at h) (s1_eq x env memo) (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _ (pull_z1 x)
      (by intro a xs h; simp [z1] at h) (s2_eq x env memo) (by rfl)).trans
  ((aux2_step 999996 _ _ _ _ _ _ _ (pull_z2 x)
      (by intro a xs h; simp [z2] at h) (s3_eq x env memo) (by rfl)).trans
  (aux2_done 999995 _ _ _ _ _ _ _ (pull_z3 x)
      (by intro a xs h; simp [z3] at h) (s4_eq x h1 h2 env memo) (by rfl)))))


/-- The full-eval face of the conv chain (the Erun argument's
    evaluation, ∀-run-state). -/
theorem fullEval_conv (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (f₁ : Fmap sym value)
    (ls : CerbMem.MemState) (st : core_run_state)
    (ha : lookup_env symA525 [f₁] = some (loadedV x)) :
    full_eval_pexpr t1File.tagDefs (t1Th bodyTail f₁)
        (create_extern_symmap t1File) ls t1File convPE st
      = Result (Defined (loadedV x), st) := by
  show stExceptUndef_bind _ _ _ = _
  refine (stub_defined (z := Sum.inr (loadedV x)) (st' := st) ?_).trans ?_
  · show runEU (eval_pexpr_aux2 t1File.tagDefs CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND"))
        (create_extern_symmap t1File) [f₁] (some ls) t1File convPE) _ = _
    rw [convChain_eq x h1 h2 [f₁] (some ls) ha]
    rfl
  · rfl

/-- The R6 bind's env write. -/
theorem update_env_aux_a526 (x : Int) (f : Fmap sym value) :
    update_env_aux (mk_sym_pat symA526 (BTy_loaded OTy_integer))
        (loadedV x) f
      = @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) symA526 (loadedV x) f := rfl

/-- R6: the Erun jump — the conv chain evaluates (reads a_525),
    the jump to ret_523's continuation binds a_526. -/
@[seg_round]
theorem t1r6 (x : Int) (h1 : -2147483648 ≤ x) (h2 : x ≤ 2147483647)
    (p : T1P)
    (ha : envLookup (t1fam bodyTail [meLoad x] 5 p) symA525
      = some (loadedV x)) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam bodyTail [meLoad x] 5 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam arena7 [meLoad x] 6
           { p with f₁ :=
               (update_env_aux
                 (mk_sym_pat symA526 (BTy_loaded OTy_integer))
                 (loadedV x) p.f₁) }) := by
  refine dnmsRoundM_adv rfl ?_
  refine (app_bind_active rfl).trans ?_
  apply (app_bind_active (liftCore_run_defined ?hM)).trans
  case hM =>
    change stExceptUndef_bind _ _ _ = _
    apply RelSem.Laws.erun_jump_m ?hres ?hk
    case hres => rfl
    case hk =>
      change stExceptUndef_bind _ _ _ = _
      apply (stub_defined ?hFold).trans
      case hFold =>
        change stExceptUndef_bind _ _ _ = _
        apply (stub_defined ?hElem).trans
        case hElem =>
          change stExceptUndef_bind _ _ _ = _
          apply (stub_defined (fullEval_conv x h1 h2 p.f₁ p.ls _
            (ha))).trans
          rfl
        rfl
      rfl
  rfl

/-- R7: a_526 evaluates (the terminal value reaches the arena). -/
@[seg_round]
theorem t1r7 (x : Int) (p : T1P)
    (ha : envLookup (t1fam arena7 [meLoad x] 6 p) symA526
      = some (loadedV x)) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam arena7 [meLoad x] 6 p)
      = (NDactive (Sum.inl NOWAKEUP),
         t1fam (arena8 x) [meLoad x] 7 p) := by
  refine dnmsRoundM_adv rfl ?_
  refine (advance_runstate_eval (th' := t1Th (arena8 x) p.f₁)
    (rs' := (t1fam arena7 [meLoad x] 6 p).core_run_state0) ?_).trans ?_
  · show stExceptUndef_bind _ _ _ = _
    refine (stub_defined
      (z := Expr aU (Epure (Pexpr [] () (PEval (loadedV x)))))
      (st' := (t1fam arena7 [meLoad x] 6 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := loadedV x)
      (st' := (t1fam arena7 [meLoad x] 6 p).core_run_state0) ?_).trans rfl
    show stExceptUndef_bind _ _ _ = _
    refine (stub_defined (z := Sum.inr (loadedV x))
      (st' := (t1fam arena7 [meLoad x] 6 p).core_run_state0) ?_).trans ?_
    · show runEU (eval_pexpr_aux2 t1File.tagDefs
          CerbLocation.Loc.unknown
          (some (CerbLocation.other "RelSem.callND"))
          (create_extern_symmap t1File) [p.f₁] (some p.ls) t1File
          (Pexpr aU () (PEsym symA526))) _ = _
      rw [aux2_sym_hit (a := aU) (a' := []) (z := symA526)
        (v := loadedV x) (env := [p.f₁]) rfl rfl
        (show lookup_env symA526 [p.f₁] = some (loadedV x) from ha)]
      rfl
    · rfl
  · rfl

/-- R8 (terminal): the fully-evaluated thread offers exactly the done
    step. -/
@[seg_round]
theorem t1r8 (x : Int) (p : T1P) :
    app (dnmsRoundM t1File.tagDefs 0) (t1fam (arena8 x) [meLoad x] 7 p)
      = (NDactive (Sum.inr [Step_done2 (loadedV x)]),
         t1fam (arena8 x) [meLoad x] 7 p) := by
  refine (dnmsRoundM_inr rfl).trans ?_
  rfl


/-! ## BIRTH LEGS (generic over the born symbol; promoted to a Kit
    home when a second program consumes them) -/

/-- Comparator reflexivity (digest+number agree with themselves). -/
theorem symCmpO_refl (z : sym) : RelSem.Kit.symCmpO z z = .eq := by
  obtain ⟨d, n, sd⟩ := z
  exact (RelSem.Kit.symCmpO_eq_iff d d n n sd sd).2 ⟨rfl, rfl⟩

/-- The captured comparator of the generated bind's insert. -/
theorem mapKeyCompare_is_symCmpO :
    lemCmpToOrd (@Lem_Map.mapKeyCompare sym _) = RelSem.Kit.symCmpO :=
  rfl

/-- Birth NEW: the just-bound cell reads back. -/
theorem birth_new {b : sym} {v : value} {f : Fmap sym value}
    (hb : EnvWfFrame f) :
    lookup_env b [@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
      (@Lem_Map.mapKeyCompare sym _) b v f] = some v := by
  rw [show lookup_env b [@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
      (@Lem_Map.mapKeyCompare sym _) b v f]
    = fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b
        (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) b v f) from by
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b
        (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) b v f) <;>
      simp [lookup_env, h]]
  cases hb with
  | inl he =>
    subst he
    exact @RelSem.Kit.fmapLookupBy_addBy_empty_eq sym value
      Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _)
      (@Lem_Map.mapKeyCompare sym _) RelSem.Kit.instTransCmpSymCmpO
      b b v (by rw [mapKeyCompare_is_symCmpO]; exact
        symCmpO_refl b)
  | inr hbuilt =>
    exact @RelSem.Kit.fmapLookupBy_addBy_eq sym value
      Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
      RelSem.Kit.instTransCmpSymCmpO _ _ b b v f hbuilt
      (symCmpO_refl b)

/-- Birth PRESERVE: every binding survives the insert (the born
    symbol's cmp-class is UNBOUND — supplied from the ledger). -/
theorem birth_pres {b : sym} {v : value} {f : Fmap sym value}
    (hb : EnvWfFrame f)
    (hsh : ∀ z : sym, RelSem.Kit.symCmpO b z = .eq →
      lookup_env z [f] = none) :
    ∀ z v', lookup_env z [f] = some v' →
      lookup_env z [@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
        (@Lem_Map.mapKeyCompare sym _) b v f] = some v' := by
  intro z v' hz
  have hlk : ∀ (g : Fmap sym value) (w : Option value),
      (fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z g = w) →
      lookup_env z [g] = w := by
    intro g w hw
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z g <;>
      simp [lookup_env, h] <;> simp [h] at hw <;> exact hw
  have hzf : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z f
      = some v' := by
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z f
    · simp [lookup_env, h] at hz
    · simp [lookup_env, h] at hz; rw [hz]
  by_cases hcmp : RelSem.Kit.symCmpO b z = .eq
  · exact absurd (hsh z hcmp) (by rw [hz]; simp)
  · cases hb with
    | inl he =>
      subst he
      rw [show fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z
          (Fmap.empty : Fmap sym value) = none from rfl] at hzf
      cases hzf
    | inr hbuilt =>
      refine hlk _ (some v') ?_
      rw [@RelSem.Kit.fmapLookupBy_addBy_ne sym value
        Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
        RelSem.Kit.instTransCmpSymCmpO _ _ b z v f hbuilt hcmp]
      exact hzf

/-- Birth REVERSE: every binding after the insert was bound before,
    or is in the born symbol's number class. -/
theorem birth_rev {b : sym} {v : value} {f : Fmap sym value}
    (hb : EnvWfFrame f) :
    ∀ z v', lookup_env z
        [@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) b v f] = some v' →
      (∃ v₀, lookup_env z [f] = some v₀) ∨ symNum z = symNum b := by
  intro z v' hz
  by_cases hcmp : RelSem.Kit.symCmpO b z = .eq
  · right
    obtain ⟨d1, n1, sd1⟩ := b
    obtain ⟨d2, n2, sd2⟩ := z
    obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 d2 n1 n2
      sd1 sd2).1 hcmp
    simp [symNum, hn]
  · left
    have hzin : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z
        (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
          (@Lem_Map.mapKeyCompare sym _) b v f) = some v' := by
      cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z
          (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
            (@Lem_Map.mapKeyCompare sym _) b v f)
      · simp [lookup_env, h] at hz
      · simp [lookup_env, h] at hz; rw [hz]
    cases hb with
    | inl he =>
      subst he
      rw [show (Fmap.empty : Fmap sym value) = fmapEmpty from rfl,
        @RelSem.Kit.fmapLookupBy_addBy_empty_ne sym value
          Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _)
          (@Lem_Map.mapKeyCompare sym _) RelSem.Kit.instTransCmpSymCmpO
          b z v (by rw [mapKeyCompare_is_symCmpO]; exact hcmp)] at hzin
      cases hzin
    | inr hbuilt =>
      rw [@RelSem.Kit.fmapLookupBy_addBy_ne sym value
        Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
        RelSem.Kit.instTransCmpSymCmpO _ _ b z v f hbuilt hcmp] at hzin
      exact ⟨v', by simp [lookup_env, hzin]⟩

/-- Birth WF: well-formedness survives the insert. -/
theorem birth_wfp {b : sym} {v : value} {f : Fmap sym value}
    (hb : EnvWfFrame f) :
    EnvWfFrame (@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
      (@Lem_Map.mapKeyCompare sym _) b v f) := by
  cases hb with
  | inl he =>
    subst he
    exact Or.inr (by
      rw [← mapKeyCompare_is_symCmpO,
        show (Fmap.empty : Fmap sym value) = fmapEmpty from rfl]
      exact @RelSem.Kit.fmapAddBy_built_empty sym value
        Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _)
        b v)
  | inr hbuilt =>
    exact Or.inr (@RelSem.Kit.fmapAddBy_built sym value
      Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
      (@Lem_Map.mapKeyCompare sym _) b v f hbuilt)


/-! ## The memory-stage Happ equations (residual-fact conditioned;
    what the `wpk_seq_alloc_store` instances feed) -/

@[reducible] def allocXS : CerbMem.Allocation :=
  { base := xAddr, size := (4 : Nat), ty := some signed_int,
    prefix_ := PrefOther "callND arg" }
@[reducible] def allocErrS : CerbMem.Allocation :=
  { base := errAddr, size := (4 : Nat), ty := some signed_int,
    prefix_ := PrefOther "errno" }

/-- k6: the argument injection at residual facts — allocate x's
    object, store the serialized argument, bind the pointer. -/
theorem k6_fam (x : Int) (σ : driver_state)
    (hmr : memRestOf σ = mr0) (hinv : MemInv σ.layout_state) :
    app (injectArgs t1File.tagDefs 0
          [(symX, BTy_object OTy_pointer)] [signed_int] [intValue x]) σ
      = (NDactive [(symX, xPtrV)],
         { σ with layout_state :=
             (layoutAllocStore σ.layout_state xAddr 4 allocXS
               (xBytes x)) }) := by
  have hlast : σ.layout_state.lastAddress = mr0.lastAddress := by
    rw [show σ.layout_state.lastAddress = (memRestOf σ).lastAddress
      from rfl, hmr]
  have h0 : σ.layout_state.nextAllocId = 0 := by
    rw [show σ.layout_state.nextAllocId = (memRestOf σ).nextAllocId
      from rfl, hmr]
    rfl
  have halloc := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "callND arg") (pv := .Prov_none)
    (alignN := 4) (ty := signed_int) (mem := σ.layout_state)
    (addrOpt := none) (sz := 4) (a := xAddr)
    rfl (by rw [hlast]; rfl) rfl
  have hget1 : (CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := xAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocXS })
      xAddr (List.replicate 4 uninitB)).allocations.get?
        σ.layout_state.nextAllocId
      = some allocXS := by
    rw [Kit.writeBytesTo_allocations]
    exact Kit.tm_get?_insert_eq _ _ _
  have hstore := Kit.mem_store_block
    (loc := CerbLocation.other "callND arg init") (ty := signed_int)
    (allocId := σ.layout_state.nextAllocId) (addr := xAddr)
    (alloc := allocXS)
    (mem := CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := xAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocXS })
      xAddr (List.replicate 4 uninitB))
    (mv := CerbMem.integerValueMval (Signed Int_)
      (CerbMem.integerIval x))
    rfl hget1 rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  rw [show xPtrV = Vobject (OVpointer
      (.PV (.Prov_some σ.layout_state.nextAllocId)
        (.PVconcrete none xAddr))) from by rw [h0]; rfl]
  exact RelSem.Laws.inject_ptr_arg1 (memValueFromValue_int x)
    halloc hstore rfl

/-- k8: the errno block at residual facts. -/
theorem k8_fam (x : Int) (σ : driver_state)
    (hmr : memRestOf σ = mr1) (hinv : MemInv σ.layout_state) :
    app (liftMem (nd_bind
        (CerbMem.allocateObject 0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun (ptr_val : CerbMem.PointerValue) =>
          let zero := CerbMem.integerValueMval (Signed Int_)
            (CerbMem.integerIval (0 : Int))
          nd_bind
            (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val zero)
            (fun (_ : CerbMem.Footprint) => nd_return ptr_val)))) σ
      = (NDactive errPtr,
         { σ with layout_state :=
             (layoutAllocStore σ.layout_state errAddr 4 allocErrS
               zeroBytes) }) := by
  have hlast : σ.layout_state.lastAddress = mr1.lastAddress := by
    rw [show σ.layout_state.lastAddress = (memRestOf σ).lastAddress
      from rfl, hmr]
  have h0 : σ.layout_state.nextAllocId = 1 := by
    rw [show σ.layout_state.nextAllocId = (memRestOf σ).nextAllocId
      from rfl, hmr]
    rfl
  have halloc := Kit.mem_alloc_block (tid := 0)
    (pref := PrefOther "errno") (pv := .Prov_none)
    (alignN := 4) (ty := signed_int) (mem := σ.layout_state)
    (addrOpt := none) (sz := 4) (a := errAddr)
    rfl (by rw [hlast]; rfl) rfl
  have hget1 : (CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := errAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocErrS })
      errAddr (List.replicate 4 uninitB)).allocations.get?
        σ.layout_state.nextAllocId
      = some allocErrS := by
    rw [Kit.writeBytesTo_allocations]
    exact Kit.tm_get?_insert_eq _ _ _
  have hstore := Kit.mem_store_block
    (loc := CerbLocation.other "errno init") (ty := signed_int)
    (allocId := σ.layout_state.nextAllocId) (addr := errAddr)
    (alloc := allocErrS)
    (mem := CerbMem.writeBytesTo
      ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := errAddr,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId allocErrS })
      errAddr (List.replicate 4 uninitB))
    (mv := CerbMem.integerValueMval (Signed Int_)
      (CerbMem.integerIval 0))
    rfl hget1 rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  rw [show errPtr = (.PV (.Prov_some σ.layout_state.nextAllocId)
      (.PVconcrete none errAddr) : CerbMem.PointerValue)
    from by rw [h0]; rfl]
  exact RelSem.Laws.callND_errno halloc hstore rfl

end RelSem.T1
