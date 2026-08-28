/-
  RelSem.M1Proof — V3a (2026-08-28): THE PERF-2 TIGHTENED-EXIT
  PROGRAM (m1_sgn — pre-registered BEFORE the construct-set
  extension, record docs/2026-08-29_v3a-loops-mechC.md §2).

  The exit's demand: a never-seen scalar program containing a
  construct OUTSIDE the probe set (branches), proved with ZERO
  generated per-round facts — the walk rides the construct package
  (mint-first `seg_run_c`), and the only registered facts are
  ANCHORS at the program's branch cut points (≤ 6 = 2·(2+0+0+1),
  k = 2 pre-stated), each stated over V1 fragments with quantified
  data values and path-condition hypotheses.

  THE PROOF SHAPE (professor reading): the callND caller protocol
  (P01's, at m1File — argument injection owns x's bytes), the body
  walk BY CONSTRUCT MINTING to the first branch, `by_cases hlt :
  x < 0`, per-arm guard anchors at the path condition, the second
  branch likewise (`by_cases hgt : 0 < x` on the else side), three
  terminals: sgn(x) = -1 / 1 / 0 by the readout. Every minted step
  is an instance of a once-proved construct characterization
  (RelSem/CStep.lean); cone exactly the classical trio.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.P01Proof
import RelSem.SegRoundTac
import RelSem.CorpusStatements

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.M1

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit RelSem.Corpus
  RelSem.Slate
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr errAddr xPtr errPtr xPtrV
  loadedV xBytes zeroBytes allocX allocXS allocErrS mr0 mr1 mr2 symX
  meLoad intRange memValueFromValue_int t1Proj wp_expr_eq
  birth_new birth_pres birth_rev birth_wfp
  birth_new' birth_pres' birth_rev' birth_wfp'
  DGP env0 al0 bs0)
open Iris Iris.BI Iris.ProgramLogic

/-! ## Statement data -/

/-- m1's pure model: sgn(x). -/
def sgnSpec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value
    = intValue (if x < 0 then -1 else if 0 < x then 1 else 0)

/-- **M1 (sgn)** — the canonical property at the house Cns shape:
    ∀ x ∈ intRange, every consistent outcome of callND(sgn, [x]) is
    Specified (sgn x). (The PERF-2 exit's target; a V3a exit
    instrument in the corpus statement SHAPE, not a frozen-corpus
    row.) -/
def M1Statement : Prop :=
  CorpusEnvHyp →
  ∀ (x : Int), intRange x →
    CallHarnessAdequateCns m1Prior m1File.tagDefs m1File "sgn"
      [intValue x] corpusFs (sgnSpec x)

/-! ## The m1 program projections (NO transcription: the entry arena
    and parameter symbol are read off the emitted decl) -/

/-- The parameter symbol (from the emitted decl, SlateCore). -/
def m1xSym : sym := Symbol "" 16562859848569467201 (SD_Id "x")

/-- The proc body = the callND entry arena, BY PROJECTION from the
    file (what `lookupFunBody` returns — zero hand transcription). -/
def m1ar0 : RExpr :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) sgnM1Sym
      m1File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-! ## The caller-protocol families (P01's, at m1File) -/

def m1Init (seed : Nat) (ls : CerbMem.MemState) : driver_state :=
  { initial_driver_state_threaded seed m1File corpusFs with
      layout_state := ls }

@[reducible] def m1thGf (f₀ : Fmap sym value) : thread_state :=
  { arena := Expr [] (Epure (Pexpr [] () (PEval Vunit))),
    stack0 := Stack_empty,
    errno := .PV .Prov_none (.PVnull intCty),
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_globals,
    env := [f₀],
    current_proc_opt := none }

@[reducible] def m1dGσ (f₀ : Fmap sym value) (tS aS eS sS : Nat)
    (ls : CerbMem.MemState) : driver_state :=
  { core_file := m1File,
    core_extern := create_extern_symmap m1File,
    core_state0 :=
      { thread_states := [(0, (none, m1thGf f₀))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW m1File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def m1dGCtl : driver_state :=
  ctlOf (m1dGσ fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def m1dGfam (p : DGP) : driver_state :=
  m1dGσ p.f₀ p.tS p.aS p.eS p.sS p.ls

theorem m1dG_inv {σ : driver_state} (h : ctlOf σ = m1dGCtl) :
    ∃ p : DGP, σ = m1dGfam p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [m1dGCtl, ctlOf, m1dGσ, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, m1thGf,
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

theorem m1Init_inv {σ : driver_state} {seed : Nat}
    (h : ctlOf σ = ctlOf (m1Init 0 CerbMem.initialMemState))
    (hs : suppliesOf σ
      = suppliesOf (m1Init seed CerbMem.initialMemState)) :
    σ = m1Init seed σ.layout_state := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [m1Init, ctlOf, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  have hs' := hs
  simp only [suppliesOf, m1Init, Supplies.mk.injEq] at hs'
  obtain ⟨hts, has, hes, hss⟩ := hs'
  cases ths with
  | cons t rest =>
    rw [show (initial_driver_state_threaded 0 m1File
        corpusFs).core_state0.thread_states
      = ([] : List (Nat × (Option thread_id × thread_state)))
      from rfl] at hths
    simp at hths
  | nil =>
    subst hcf hce hccs hfs htr hsa hbl hctr hio hlab hts has hes hss
    rfl

/-! ## The stage laws (rfl at the projections) -/

theorem m1k1_fam (seed : Nat) (ls : CerbMem.MemState) :
    app (driver_globals m1File.tagDefs false m1File)
        (m1Init seed ls)
      = (NDactive 0, m1dGσ fmapEmpty 1 0 0 seed ls) := rfl

theorem m1k3_any (σ : driver_state) :
    app (resolveFunSym m1File "sgn") σ
      = (NDactive sgnM1Sym, σ) := rfl

theorem m1k4_any (σ : driver_state) :
    app (lookupFunBody m1File sgnM1Sym) σ
      = (NDactive ([(m1xSym, BTy_object OTy_pointer)], m1ar0), σ) := rfl

theorem m1k5_any (σ : driver_state) :
    app (lookupParamTys m1File sgnM1Sym) σ
      = (NDactive [signed_int], σ) := rfl

theorem m1_init_ctl_eq (seed : Nat) :
    ctlOf (initial_driver_state_threaded seed m1File corpusFs)
      = ctlOf (m1Init 0 CerbMem.initialMemState) := rfl

theorem m1_init_sup_eq (seed : Nat) :
    suppliesOf (initial_driver_state_threaded seed m1File corpusFs)
      = suppliesOf (m1Init seed CerbMem.initialMemState) := rfl

theorem m1_init_mrest_eq (seed : Nat) :
    memRestOf (initial_driver_state_threaded seed m1File corpusFs)
      = mr0 := rfl

/-! ## The inject/errno memory-stage laws (k6/k8 at m1File) -/

theorem m1k6_fam (x : Int) (σ : driver_state)
    (hmr : memRestOf σ = mr0) (hinv : MemInv σ.layout_state) :
    app (injectArgs m1File.tagDefs 0
          [(m1xSym, BTy_object OTy_pointer)] [signed_int]
          [intValue x]) σ
      = (NDactive [(m1xSym, xPtrV)],
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

theorem m1k8_fam (x : Int) (σ : driver_state)
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
      (CerbMem.integerIval (0 : Int)))
    rfl hget1 rfl rfl rfl
    (by rw [Kit.writeBytesTo_funptrmap])
  rw [show errPtr = CerbMem.PointerValue.PV
      (.Prov_some σ.layout_state.nextAllocId)
      (.PVconcrete none errAddr) from by rw [h0]; rfl]
  exact RelSem.Laws.callND_errno halloc hstore rfl

/-! ## The body-entry family -/

@[reducible] def m1Th0 (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal
      [(sgnM1Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some sgnM1Sym }

@[reducible] def m1σ0 (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState) : driver_state :=
  { core_file := m1File,
    core_extern := create_extern_symmap m1File,
    core_state0 :=
      { thread_states := [(0, (none, m1Th0 m1ar0 f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW m1File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def m1Ctl0 : driver_state :=
  ctlOf (m1σ0 fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def m1fam0 (p : T1P) : driver_state :=
  m1σ0 p.f₁ p.tS p.aS p.eS p.sS p.ls

theorem m1_inv0 {σ : driver_state} (h : ctlOf σ = m1Ctl0) :
    ∃ p : T1P, σ = m1fam0 p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [m1Ctl0, ctlOf, m1σ0, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, m1Th0,
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


/-! ## Ledger literal + the WP -/

/-- After the setup (x's cell, bound to m1's parameter symbol). -/
@[reducible] def m1pd1 : List Int := [symNum m1xSym]

theorem m1_wp (x : Int) (hx1 : -2147483648 ≤ x)
    (hx2 : x ≤ 2147483647) (seed : Nat) [inst : CerbStGS CerbStS]
    (hbody : ∀ [CerbStGS CerbStS],
      (Seg.Ctx.interp (GF := CerbStS)
        ⟨m1Ctl0, ⟨1, 0, 0, seed⟩, [(m1xSym, xPtrV)], mr2, al0,
          bs0 x⟩) ⊢
        WP (dnmsK m1File.tagDefs 1000000 fmapEmpty 0 []
          (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
            KExpr.seq (driver2Rest m1File.tagDefs false
                (driver2_lemFuel 999999 m1File.tagDefs) tid_steps)
              (fun _ => KExpr.seq nd_get (fun dr_st' =>
                KExpr.done (Outcome.value
                  (finalize m1File.tagDefs "callND" dr_st')))))))
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result,
              o = Outcome.value r ∧ sgnSpec x r⌝ }}) :
    (ctlIs (GF := CerbStS) stHalf
        (ctlOf (initial_driver_state_threaded seed m1File corpusFs)) ∗
      supIs stHalf
        (suppliesOf (initial_driver_state_threaded seed m1File corpusFs)) ∗
      mrestIs stHalf
        (memRestOf (initial_driver_state_threaded seed m1File corpusFs)) ∗
      domIs stHalf ([] : List Int)) ⊢
      WP (callK2 m1File.tagDefs m1File "sgn" [intValue x])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ sgnSpec x r⌝ }} := by
  iintro ⟨Hc, Hs, Hm, Hd⟩
  rw [m1_init_ctl_eq seed, m1_init_sup_eq seed,
    m1_init_mrest_eq seed]
  -- §1 THE CALLER PROTOCOL ------------------------------------------
  iapply (wpk_seq_ctl_sup_lk (GF := CerbStS)
    (upd := fun σ => m1dGσ fmapEmpty 1 0 0 seed σ.layout_state)
    (c' := m1dGCtl) (S' := ⟨1, 0, 0, seed⟩)
    (fun σ hσ hwf hsup => by
      rw [m1Init_inv hσ hsup]; exact m1k1_fam seed _)
    (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl)
    (fun σ hσ hwf hsup z => by
      rw [m1Init_inv hσ hsup]; rfl)
    (fun σ hσ hwf hsup => by
      rw [m1Init_inv hσ hsup]
      intro f hf
      cases hf with
      | head => exact Or.inl rfl
      | tail _ h => cases h))
  isplitl [Hc Hs]
  · iframe Hc Hs
  iintro ⟨Hc, Hs⟩
  iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun σ => σ)
    (c := m1dGCtl)
    (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
      ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
    (fun σ _ _ => app_nd_get σ) ?hwp1)
  case hwp1 =>
    intro σv hσv hwfv
    rw [show σv.core_file = m1File
      from RelSem.T1.coreFile_of_ctl hσv]
    iintro ⟨Hc, Hs, Hm, Hd⟩
    iapply (wpk_seq_read_ctl (GF := CerbStS)
      (g := fun _ => sgnM1Sym) (c := m1dGCtl)
      (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
        ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
      (fun σ _ _ => m1k3_any σ) ?hwp2)
    case hwp2 =>
      intro σv2 hσv2 hwfv2
      iintro ⟨Hc, Hs, Hm, Hd⟩
      iapply (wpk_seq_read_ctl (GF := CerbStS)
        (g := fun _ => ([(m1xSym, BTy_object OTy_pointer)], m1ar0))
        (c := m1dGCtl)
        (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
          ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
        (fun σ _ _ => m1k4_any σ) ?hwp3)
      case hwp3 =>
        intro σv3 hσv3 hwfv3
        iintro ⟨Hc, Hs, Hm, Hd⟩
        iapply (wpk_seq_read_ctl (GF := CerbStS)
          (g := fun _ => [signed_int]) (c := m1dGCtl)
          (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
            ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
          (fun σ _ _ => m1k5_any σ) ?hwp4)
        case hwp4 =>
          intro σv4 hσv4 hwfv4
          iintro ⟨Hc, Hs, Hm, Hd⟩
          iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := mr0)
            (ty := signed_int) (pref := PrefOther "callND arg")
            (alignN := 4) (sz := 4) (aNew := xAddr)
            (newBytes := xBytes x)
            rfl rfl rfl rfl
            (fun σ hmr hinv => m1k6_fam x σ hmr hinv))
          isplitl [Hm]
          · iexact Hm
          iintro ⟨Hm, Hax, Hpx⟩
          rw [show mrAlloc mr0 xAddr = mr1 from rfl]
          iapply (wpk_seq_read_ctl_dom (GF := CerbStS)
            (g := fun σ => σ.core_state0.thread_states)
            (c := m1dGCtl)
            (d := ([] : List Int))
            (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
              ∗ mrestIs stHalf mr1
              ∗ allocIs mr0.nextAllocId (.own 1) allocXS
              ∗ pointsToBytes xAddr (.own 1) (xBytes x)))
            (fun σ _ _ => RelSem.Laws.get_ths_eq σ) ?hwp5)
          case hwp5 =>
            intro σv5 hσv5 hwfv5 hdomv5
            obtain ⟨pv, rfl⟩ := m1dG_inv hσv5
            have hf₀ : EnvWfFrame pv.f₀ := hwfv5 pv.f₀ (by
              show pv.f₀ ∈ thread0Env _
              simp [thread0Env])
            have hf₀none : ∀ z : sym,
                lookup_env z [pv.f₀] = none := by
              intro z
              cases hz : lookup_env z [pv.f₀] with
              | none => rfl
              | some v =>
                exact absurd (hdomv5 z v hz) (by simp)
            iintro ⟨Hc, Hd, Hs, Hm, Hax, Hpx⟩
            iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := mr1)
              (ty := signed_int) (pref := PrefOther "errno")
              (alignN := 4) (sz := 4) (aNew := errAddr)
              (newBytes := zeroBytes)
              rfl rfl rfl rfl
              (fun σ hmr hinv => m1k8_fam x σ hmr hinv))
            isplitl [Hm]
            · iexact Hm
            iintro ⟨Hm, Hae, Hpe⟩
            rw [show mrAlloc mr1 errAddr = mr2 from rfl]
            -- §2 THE SETUP: x's cell is BORN --------------------
            iapply (wpk_seq_birth1 (GF := CerbStS) (x := m1xSym)
              (vNew := xPtrV) (d := ([] : List Int))
              (c := m1dGCtl) (c' := m1Ctl0)
              (upd := fun σ =>
                { σ with core_state0 := (update_thread_state 0
                    (m1Th0 m1ar0
                      (fmapAddBy (fun (s1 s2 : sym) =>
                        Lem_Basic_classes.ordCompare s1 s2)
                        m1xSym xPtrV pv.f₀))
                    σ.core_state0) })
              (by simp)
              ?happ2
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := m1dG_inv hσ; rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := m1dG_inv hσ
                exact birth_new' rfl hf₀)
              (fun σ hσ hwf hdm z v' hzv => by
                exact absurd (hdm z v' hzv) (by simp))
              (fun σ hσ hwf hdm z v' hzv => by
                obtain ⟨pw, rfl⟩ := m1dG_inv hσ
                rcases birth_rev' rfl (b := m1xSym) (v := xPtrV) hf₀
                    z v' hzv with ⟨v₀, hv₀⟩ | hnum
                · rw [hf₀none z] at hv₀; cases hv₀
                · exact Or.inr hnum)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := m1dG_inv hσ
                intro f hf
                cases hf with
                | head => exact birth_wfp' rfl hf₀
                | tail _ h => cases h))
            case happ2 =>
              intro σ hσ hwf hdm
              exact RelSem.Laws.driver_update_ts 0 _ σ rfl
            isplitl [Hc Hd]
            · iframe Hc Hd
            iintro ⟨Hc, Hd, HX⟩
            -- §3 THE BODY -----------------------------------------
            iapply (wpk_seq_read_ctl (GF := CerbStS)
              (g := fun σ => σ)
              (c := m1Ctl0)
              (R := iprop(supIs (GF := CerbStS) stHalf
                  ⟨1, 0, 0, seed⟩
                ∗ mrestIs stHalf mr2
                ∗ domIs stHalf m1pd1
                ∗ envIs m1xSym (.own 1) xPtrV
                ∗ allocIs mr0.nextAllocId (.own 1) allocXS
                ∗ pointsToBytes xAddr (.own 1) (xBytes x)
                ∗ allocIs mr1.nextAllocId (.own 1) allocErrS
                ∗ pointsToBytes errAddr (.own 1) zeroBytes))
              (fun σ _ _ => app_nd_get σ) ?hwp6)
            case hwp6 =>
              intro σv6 hσv6 hwfv6
              rw [show List.map Prod.fst
                  σv6.core_state0.thread_states = [0] from by
                obtain ⟨pw, rfl⟩ := m1_inv0 hσv6; rfl]
              iintro ⟨Hc, Hs, Hm, Hd, HX, Hax, Hpx, Hae, Hpe⟩
              iapply (wp_expr_eq (GF := CerbStS)
                (e' := dnmsK m1File.tagDefs 1000000 fmapEmpty 0 []
                  (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
                    KExpr.seq (driver2Rest m1File.tagDefs false
                        (driver2_lemFuel 999999 m1File.tagDefs)
                        tid_steps)
                      (fun _ => KExpr.seq nd_get (fun dr_st' =>
                        KExpr.done (Outcome.value
                          (finalize m1File.tagDefs "callND"
                            dr_st'))))))) ?heq)
              case heq => rfl
              iapply hbody
              isimp only [Seg.Ctx.interp, Seg.SegCtx, Seg.envCells,
                Seg.allocCells, Seg.byteCells, Seg.domOf,
                List.map_cons, List.map_nil]
              iframe Hc Hs Hm Hd HX Hax Hpx Hae Hpe
            iframe Hc Hs Hm Hd HX Hax Hpx Hae Hpe
          iframe Hc Hd Hs Hm Hax Hpx
        iframe Hc Hs Hm Hd
      iframe Hc Hs Hm Hd
    iframe Hc Hs Hm Hd
  iframe Hc Hs Hm Hd

end RelSem.M1
