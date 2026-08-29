/-
  RelSem.T5Guard — V3a continuation (2026-08-29): THE T5 LOOP-GUARD
  MACHINERY (work-order items (i)/(iv) at t5File) — the walk family,
  the guard chain restamped at t5File (the M1Guard/P02Guard
  template; z-stage pexpr constants shared), the loop-guard arena
  builder (extracted at the walk's own stop state, probe
  RelSem/T5WalkProbe.lean, log .v3a-logs/t5g.live), and the
  ∀-quantified guard anchors (branch/loop-head cut point; iteration
  data (iv, nv), trace, and counter all quantified — one anchor pair
  for EVERY iteration).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.M1Guard
import RelSem.SegLoop

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.T5S

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt RelSem.Seg
  RelSem.Slate
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr loadedV meLoad errPtr
  xPtrV)
open RelSem.P01 (xObjV le1pe le2pe and12pe if1pe symIsRepr
  symWrapI symConvInt)
open RelSem.P02 (convB)

/-! ## §1 The T5 walk family (the m1 family shape at t5File) -/

@[reducible] def t5gTh (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_normal
      [(sumT5Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some sumT5Sym }

@[reducible] def t5gσ (arena : RExpr) (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := t5File,
    core_extern := create_extern_symmap t5File,
    core_state0 :=
      { thread_states := [(0, (none, t5gTh arena f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t5File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

def t5CtlAt (arena : RExpr) (tr : List trace_event) (n : Nat) :
    driver_state :=
  ctlOf (t5gσ arena fmapEmpty 0 0 0 0 CerbMem.initialMemState tr n)

@[reducible] def t5gfam (arena : RExpr) (tr : List trace_event)
    (n : Nat) (p : Pack) : driver_state :=
  t5gσ arena p.f₁ p.tS p.aS p.eS p.sS p.ls tr n

/-- Control inversion at the T5 walk family. -/
@[seg_inv]
theorem t5g_inv {σ : driver_state} {arena : RExpr}
    {tr : List trace_event} {n : Nat}
    (h : ctlOf σ = t5CtlAt arena tr n) :
    ∃ p : Pack, σ = t5gfam arena tr n p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [t5CtlAt, ctlOf, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, t5gTh,
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

/-! ## §3 The guard chain at t5File (the P02Guard template at the
    aU/Loc.unknown spellings; z-stage constants shared with P01) -/

def t5clocC : Option CerbLocation.Loc :=
  some (CerbLocation.other "RelSem.callND")
def t5extC : Fmap sym sym := create_extern_symmap t5File

/-- Compare-verdict arm (aU spelling). -/
def t5gArm (k : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEctor Cspecified [Pexpr aU () (PEval (xObjV k))])

/-- One conv_int call operand at value `v` (aU spelling). -/
def t5convA (v : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym symConvInt)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xObjV v))])

/-- The guard-round redex (in-arena spelling; root aU). -/
def t5gz0 (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEif (Pexpr aU () (PEop op (t5convA v1) (t5convA v2)))
    (t5gArm 1) (t5gArm 0))

/-- Post-pull spelling (root re-annotated `[]`). -/
def t5gzA (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr aU () (PEop op (t5convA v1) (t5convA v2)))
    (t5gArm 1) (t5gArm 0))

/-- After step A: both conv calls inlined (P01's convB, shared). -/
def t5gzB (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr [] () (PEop op (convB v1) (convB v2)))
    (t5gArm 1) (t5gArm 0))

/-- After step B: bool-ctype test + is_representable inlined. -/
def t5gzC (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr [] () (PEop op (if1pe v1) (if1pe v2)))
    (t5gArm 1) (t5gArm 0))

/-! ### Steps A/B (value-generic, per-op) -/

theorem t5gsA_gt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzA OpGt v1 v2)
      = Result (Defined (t5gzB OpGt v1 v2)) := rfl

theorem t5gsA_lt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzA OpLt v1 v2)
      = Result (Defined (t5gzB OpLt v1 v2)) := rfl

theorem t5gsB_gt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzB OpGt v1 v2)
      = Result (Defined (t5gzC OpGt v1 v2)) := rfl

theorem t5gsB_lt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzB OpLt v1 v2)
      = Result (Defined (t5gzC OpLt v1 v2)) := rfl

/-! ### The verdict sub-evals (P01's sLe/sAnd/sIf at t5File) -/

theorem t5sLe1 (v : Int) (h1 : -2147483648 ≤ v)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 t5File.tagDefs 4
      CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (le1pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd1 : decide ((-2147483648:Int) ≤ v) = true := decide_eq_true h1
  have harm : (if (decide ((-2147483648:Int) ≤ v)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
  conv => rhs; rw [← harm]
  rfl

theorem t5sLe2 (v : Int) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 t5File.tagDefs 4
      CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (le2pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd2 : decide (v ≤ (2147483647:Int)) = true := decide_eq_true h2
  have harm : (if (decide (v ≤ (2147483647:Int))) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
  conv => rhs; rw [← harm]
  rfl

theorem t5sAnd (v : Int) (h1 : -2147483648 ≤ v) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999997 t5File.tagDefs 3
      CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (and12pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sLe1 v h1 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sLe2 v h2 env memo)).trans ?_
    rfl

theorem t5sIf (v : Int) (h1 : -2147483648 ≤ v) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999998 t5File.tagDefs 2
      CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (if1pe v)
      = Result (Defined (Pexpr [] () (PEval (xObjV v)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (xObjV v) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sAnd v h1 h2 env memo)).trans ?_
    rfl

/-! ### The guard (compare application) per op/side -/

section Guard
variable (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)

include h1 h2 h3 h4

theorem t5GuardGtT (hgt : v2 < v1) :
    step_eval_pexpr_lemFuel 999999 t5File.tagDefs 1
      CerbLocation.Loc.unknown t5clocC t5extC env memo t5File false
      (Pexpr [] () (PEop OpGt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd : decide (v2 < v1) = true := decide_eq_true hgt
  have harm : (if (decide (v2 < v1)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vtrue
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v2 < v1)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem t5GuardGtF (hle : ¬ v2 < v1) :
    step_eval_pexpr_lemFuel 999999 t5File.tagDefs 1
      CerbLocation.Loc.unknown t5clocC t5extC env memo t5File false
      (Pexpr [] () (PEop OpGt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vfalse))) := by
  have hd : decide (v2 < v1) = false := decide_eq_false hle
  have harm : (if (decide (v2 < v1)) = true
      then Vtrue else Vfalse) = Vfalse := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vfalse : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vfalse
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v2 < v1)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem t5GuardLtT (hlt : v1 < v2) :
    step_eval_pexpr_lemFuel 999999 t5File.tagDefs 1
      CerbLocation.Loc.unknown t5clocC t5extC env memo t5File false
      (Pexpr [] () (PEop OpLt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd : decide (v1 < v2) = true := decide_eq_true hlt
  have harm : (if (decide (v1 < v2)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vtrue
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v1 < v2)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem t5GuardLtF (hge : ¬ v1 < v2) :
    step_eval_pexpr_lemFuel 999999 t5File.tagDefs 1
      CerbLocation.Loc.unknown t5clocC t5extC env memo t5File false
      (Pexpr [] () (PEop OpLt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vfalse))) := by
  have hd : decide (v1 < v2) = false := decide_eq_false hge
  have harm : (if (decide (v1 < v2)) = true
      then Vtrue else Vfalse) = Vfalse := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vfalse : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (t5sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vfalse
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v1 < v2)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

end Guard

/-! ### Step C (the whole verdict pexpr) per op/side -/

section StepC
variable (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)

include h1 h2 h3 h4

theorem t5sC_gt_T (hgt : v2 < v1) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzC OpGt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 1) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (t5GuardGtT v1 v2 h1 h2 h3 h4 env memo hgt)).trans ?_
    rfl

theorem t5sC_gt_F (hle : ¬ v2 < v1) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzC OpGt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 0) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (t5GuardGtF v1 v2 h1 h2 h3 h4 env memo hle)).trans ?_
    rfl

theorem t5sC_lt_T (hlt : v1 < v2) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzC OpLt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 1) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (t5GuardLtT v1 v2 h1 h2 h3 h4 env memo hlt)).trans ?_
    rfl

theorem t5sC_lt_F (hge : ¬ v1 < v2) :
    step_eval_pexpr t5File.tagDefs 0 CerbLocation.Loc.unknown t5clocC
      t5extC env memo t5File false (t5gzC OpLt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 0) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (t5GuardLtF v1 v2 h1 h2 h3 h4 env memo hge)).trans ?_
    rfl

end StepC

/-! ### The whole-loop faces (aux2 chains at runEU, per op/side) -/

section Loop
variable {A : Type} (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    {env : List (Fmap sym value)} {memo : Option CerbMem.MemState}
    {st : A}

include h1 h2 h3 h4

theorem t5cmp_gt_T (hgt : v2 < v1) :
    runEU (eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpGt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 1)))) st := by
  have h : eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpGt v1 v2)
      = Result (Defined (Sum.inr (loadedV 1))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gz0 OpGt v1 v2) = t5gzA OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzA] at h) (t5gsA_gt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzB OpGt v1 v2) = t5gzB OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzB] at h)
        (show _ = _ from t5gsB_gt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzC OpGt v1 v2) = t5gzC OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzC] at h)
        (t5sC_gt_T v1 v2 h1 h2 h3 h4 env memo hgt) (by rfl)))
  rw [h]

theorem t5cmp_gt_F (hle : ¬ v2 < v1) :
    runEU (eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpGt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 0)))) st := by
  have h : eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpGt v1 v2)
      = Result (Defined (Sum.inr (loadedV 0))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gz0 OpGt v1 v2) = t5gzA OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzA] at h) (t5gsA_gt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzB OpGt v1 v2) = t5gzB OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzB] at h)
        (show _ = _ from t5gsB_gt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzC OpGt v1 v2) = t5gzC OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzC] at h)
        (t5sC_gt_F v1 v2 h1 h2 h3 h4 env memo hle) (by rfl)))
  rw [h]

theorem t5cmp_lt_T (hlt : v1 < v2) :
    runEU (eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpLt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 1)))) st := by
  have h : eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpLt v1 v2)
      = Result (Defined (Sum.inr (loadedV 1))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gz0 OpLt v1 v2) = t5gzA OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzA] at h) (t5gsA_lt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzB OpLt v1 v2) = t5gzB OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzB] at h)
        (show _ = _ from t5gsB_lt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzC OpLt v1 v2) = t5gzC OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzC] at h)
        (t5sC_lt_T v1 v2 h1 h2 h3 h4 env memo hlt) (by rfl)))
  rw [h]

theorem t5cmp_lt_F (hge : ¬ v1 < v2) :
    runEU (eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpLt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 0)))) st := by
  have h : eval_pexpr_aux2 t5File.tagDefs CerbLocation.Loc.unknown
      t5clocC t5extC env memo t5File (t5gz0 OpLt v1 v2)
      = Result (Defined (Sum.inr (loadedV 0))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gz0 OpLt v1 v2) = t5gzA OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzA] at h) (t5gsA_lt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzB OpLt v1 v2) = t5gzB OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzB] at h)
        (show _ = _ from t5gsB_lt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (t5gzC OpLt v1 v2) = t5gzC OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [t5gzC] at h)
        (t5sC_lt_F v1 v2 h1 h2 h3 h4 env memo hge) (by rfl)))
  rw [h]

end Loop


/-! ## §3 The loop-guard arena (walk-extracted; the guard slot
    parameterized — `peG` = the compare redex, `t5gz0 OpLt iv nv`
    on entry, its verdict value after the anchor fires) -/

def t5arG (peG : generic_pexpr Unit sym) : RExpr :=
generic_expr.Expr []
  (Eannot
    [DA_pos [] (CerbMem.Footprint.FP CerbMem.FootprintAccess.W (Int.ofNat 281474976710640) (Int.ofNat 4)),
      DA_pos [] (CerbMem.Footprint.FP CerbMem.FootprintAccess.W (Int.ofNat 281474976710636) (Int.ofNat 4))]
    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
      (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
          (Esseq
            (Pattern [Aloc CerbLocation.Loc.unknown]
              (CaseBase (some (Symbol "" 15754218577363027919 (SD_Id "a_535")), BTy_loaded OTy_integer)))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Ebound
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Ewseq
                    (Pattern [Aloc CerbLocation.Loc.unknown]
                      (CaseCtor Ctuple
                        [Pattern [Aloc CerbLocation.Loc.unknown]
                            (CaseBase (some (Symbol "" 6477419756603697776 (SD_Id "a_537")), BTy_loaded OTy_integer)),
                          Pattern [Aloc CerbLocation.Loc.unknown]
                            (CaseBase
                              (some (Symbol "" 18319030617476695216 (SD_Id "a_538")), BTy_loaded OTy_integer))]))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Eunseq
                        [generic_expr.Expr []
                            (Eannot
                              [DA_pos []
                                  (CerbMem.Footprint.FP CerbMem.FootprintAccess.R (Int.ofNat 281474976710648)
                                    (Int.ofNat 4)),
                                DA_pos []
                                  (CerbMem.Footprint.FP CerbMem.FootprintAccess.R (Int.ofNat 281474976710636)
                                    (Int.ofNat 4))]
                              (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                (Epure
                                  peG))),
                          generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                            (Epure
                              (Pexpr [] PUnit.unit
                                (PEval
                                  (Vloaded
                                    (LVspecified
                                      (OVinteger
                                        (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none (Int.ofNat 0))))))))]))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Epure
                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                          (PEcase
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEctor Ctuple
                                [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                    (PEsym (Symbol "" 6477419756603697776 (SD_Id "a_537"))),
                                  Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                    (PEsym (Symbol "" 18319030617476695216 (SD_Id "a_538")))]))
                            [(Pattern [Aloc CerbLocation.Loc.unknown]
                                  (CaseCtor Ctuple
                                    [Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseCtor Cspecified
                                          [Pattern [Aloc CerbLocation.Loc.unknown]
                                              (CaseBase
                                                (some (Symbol "" 17182549754735014329 (SD_Id "a_539")),
                                                  BTy_object OTy_integer))]),
                                      Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseCtor Cspecified
                                          [Pattern [Aloc CerbLocation.Loc.unknown]
                                              (CaseBase
                                                (some (Symbol "" 229457971439601039 (SD_Id "a_540")),
                                                  BTy_object OTy_integer))])]),
                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEif
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEop OpEq
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                                            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                              Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEsym (Symbol "" 17182549754735014329 (SD_Id "a_539")))]))
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                                            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                              Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEsym (Symbol "" 229457971439601039 (SD_Id "a_540")))]))))
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEctor Cspecified
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEval
                                              (Vobject
                                                (OVinteger
                                                  (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                    (Int.ofNat 1)))))]))
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEctor Cspecified
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEval
                                              (Vobject
                                                (OVinteger
                                                  (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                    (Int.ofNat 0)))))])))),
                              (Pattern [Aloc CerbLocation.Loc.unknown]
                                  (CaseBase (none, BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEctor Cunspecified
                                    [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                        (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_))))))]))]))))))))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Esseq
                (Pattern [Aloc CerbLocation.Loc.unknown]
                  (CaseBase (some (Symbol "" 1342427191597093029 (SD_Id "a_532")), BTy_boolean)))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Ecase
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEsym (Symbol "" 15754218577363027919 (SD_Id "a_535"))))
                    [(Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseCtor Cspecified
                            [Pattern [Aloc CerbLocation.Loc.unknown]
                                (CaseBase
                                  (some (Symbol "" 6464411467923874555 (SD_Id "a_536")), BTy_object OTy_integer))]),
                        generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Epure
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEif
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEnot
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEop OpEq
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 6464411467923874555 (SD_Id "a_536"))))
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEval
                                            (Vobject
                                              (OVinteger
                                                (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                  (Int.ofNat 1))))))))))
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vtrue))
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vfalse)))))),
                      (Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseCtor Cunspecified
                            [Pattern [Aloc CerbLocation.Loc.unknown] (CaseBase (none, BTy_ctype))]),
                        generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (End
                            [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vtrue))),
                              generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vfalse)))]))]))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Eif
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEsym (Symbol "" 1342427191597093029 (SD_Id "a_532"))))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Esseq (Pattern [Aloc CerbLocation.Loc.unknown] (CaseBase (none, BTy_loaded OTy_integer)))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Ebound
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Ewseq
                                (Pattern [Aloc CerbLocation.Loc.unknown]
                                  (CaseCtor Ctuple
                                    [Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseBase
                                          (some (Symbol "" 16629223912856532319 (SD_Id "a_549")),
                                            BTy_object OTy_pointer)),
                                      Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseBase
                                          (some (Symbol "" 16397053867550904782 (SD_Id "a_557")),
                                            BTy_loaded OTy_integer))]))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Eunseq
                                    [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                        (Epure
                                          (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEsym (Symbol "" 9409450202036847209 (SD_Id "s"))))),
                                      generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                        (Ewseq
                                          (Pattern [Aloc CerbLocation.Loc.unknown]
                                            (CaseCtor Ctuple
                                              [Pattern [Aloc CerbLocation.Loc.unknown]
                                                  (CaseBase
                                                    (some (Symbol "" 2567468451026663467 (SD_Id "a_550")),
                                                      BTy_loaded OTy_integer)),
                                                Pattern [Aloc CerbLocation.Loc.unknown]
                                                  (CaseBase
                                                    (some (Symbol "" 14409079311899709851 (SD_Id "a_551")),
                                                      BTy_loaded OTy_integer))]))
                                          (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                            (Eunseq
                                              [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                  (Ewseq
                                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                                      (CaseBase
                                                        (some (Symbol "" 6806144180337321293 (SD_Id "a_555")),
                                                          BTy_object OTy_pointer)))
                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                      (Epure
                                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEsym (Symbol "" 9409450202036847209 (SD_Id "s"))))))
                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                      (Eaction
                                                        (Paction polarity.Pos
                                                          (Action CerbLocation.Loc.unknown
                                                            { sb_before := [], dd_before := [], asw_before := [] }
                                                            (Load0
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEval
                                                                  (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))))
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEsym (Symbol "" 6806144180337321293 (SD_Id "a_555"))))
                                                              NA)))))),
                                                generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                  (Ewseq
                                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                                      (CaseBase
                                                        (some (Symbol "" 1097327803196824626 (SD_Id "a_556")),
                                                          BTy_object OTy_pointer)))
                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                      (Epure
                                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEsym (Symbol "" 16900879642891266615 (SD_Id "i"))))))
                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                      (Eaction
                                                        (Paction polarity.Pos
                                                          (Action CerbLocation.Loc.unknown
                                                            { sb_before := [], dd_before := [], asw_before := [] }
                                                            (Load0
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEval
                                                                  (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))))
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEsym (Symbol "" 1097327803196824626 (SD_Id "a_556"))))
                                                              NA))))))]))
                                          (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                            (Epure
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEcase
                                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEctor Ctuple
                                                      [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEsym (Symbol "" 2567468451026663467 (SD_Id "a_550"))),
                                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEsym (Symbol "" 14409079311899709851 (SD_Id "a_551")))]))
                                                  [(Pattern [Aloc CerbLocation.Loc.unknown]
                                                        (CaseCtor Ctuple
                                                          [Pattern [Aloc CerbLocation.Loc.unknown]
                                                              (CaseCtor Cspecified
                                                                [Pattern [Aloc CerbLocation.Loc.unknown]
                                                                    (CaseBase
                                                                      (some
                                                                          (Symbol "" 12833257241435994544
                                                                            (SD_Id "a_552")),
                                                                        BTy_object OTy_integer))]),
                                                            Pattern [Aloc CerbLocation.Loc.unknown]
                                                              (CaseCtor Cspecified
                                                                [Pattern [Aloc CerbLocation.Loc.unknown]
                                                                    (CaseBase
                                                                      (some
                                                                          (Symbol "" 9265274797817290020
                                                                            (SD_Id "a_553")),
                                                                        BTy_object OTy_integer))])]),
                                                      Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                        (PEctor Cspecified
                                                          [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                              (PEcatch_exceptional_condition (Signed Int_) IOpAdd
                                                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                  (PEconv_int (Signed Int_)
                                                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                      (PEsym
                                                                        (Symbol "" 12833257241435994544
                                                                          (SD_Id "a_552"))))))
                                                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                  (PEconv_int (Signed Int_)
                                                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                      (PEsym
                                                                        (Symbol "" 9265274797817290020
                                                                          (SD_Id "a_553")))))))])),
                                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                                        (CaseBase
                                                          (none,
                                                            BTy_tuple
                                                              [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
                                                      Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                        (PEundef CerbLocation.Loc.unknown
                                                          UB036_exceptional_condition))])))))]))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Ewseq (Pattern [Aloc CerbLocation.Loc.unknown] (CaseBase (none, BTy_unit)))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Eaction
                                        (Paction Neg0
                                          (Action CerbLocation.Loc.unknown
                                            { sb_before := [], dd_before := [], asw_before := [] }
                                            (Store0 false
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))))
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEsym (Symbol "" 16629223912856532319 (SD_Id "a_549"))))
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEcall (Sym (Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")))
                                                  [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEsym (Symbol "" 16397053867550904782 (SD_Id "a_557")))]))
                                              NA)))))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Epure
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEcall (Sym (Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")))
                                            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                              Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEsym (Symbol "" 16397053867550904782 (SD_Id "a_557")))]))))))))))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Esave (Symbol "" 1631266952700436883 (SD_Id "__cerb_continue0"), BTy_unit)
                                    [(Symbol "" 16900879642891266615 (SD_Id "i"), (BTy_object OTy_pointer, none),
                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 16900879642891266615 (SD_Id "i")))),
                                      (Symbol "" 9409450202036847209 (SD_Id "s"), (BTy_object OTy_pointer, none),
                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 9409450202036847209 (SD_Id "s"))))]
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Esseq
                                        (Pattern [Aloc CerbLocation.Loc.unknown]
                                          (CaseBase (none, BTy_loaded OTy_integer)))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Ebound
                                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                              (Ewseq
                                                (Pattern [Aloc CerbLocation.Loc.unknown]
                                                  (CaseCtor Ctuple
                                                    [Pattern [Aloc CerbLocation.Loc.unknown]
                                                        (CaseBase
                                                          (some (Symbol "" 1656971181475828259 (SD_Id "a_558")),
                                                            BTy_object OTy_pointer)),
                                                      Pattern [Aloc CerbLocation.Loc.unknown]
                                                        (CaseBase
                                                          (some (Symbol "" 15936767184861729128 (SD_Id "a_565")),
                                                            BTy_loaded OTy_integer))]))
                                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                  (Eunseq
                                                    [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                        (Epure
                                                          (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                            (PEsym (Symbol "" 16900879642891266615 (SD_Id "i"))))),
                                                      generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                        (Ewseq
                                                          (Pattern [Aloc CerbLocation.Loc.unknown]
                                                            (CaseCtor Ctuple
                                                              [Pattern [Aloc CerbLocation.Loc.unknown]
                                                                  (CaseBase
                                                                    (some
                                                                        (Symbol "" 1862827267035441118 (SD_Id "a_559")),
                                                                      BTy_loaded OTy_integer)),
                                                                Pattern [Aloc CerbLocation.Loc.unknown]
                                                                  (CaseBase
                                                                    (some
                                                                        (Symbol "" 14386475981198921378
                                                                          (SD_Id "a_560")),
                                                                      BTy_loaded OTy_integer))]))
                                                          (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                            (Eunseq
                                                              [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                                  (Ewseq
                                                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                                                      (CaseBase
                                                                        (some
                                                                            (Symbol "" 4998152064567917579
                                                                              (SD_Id "a_564")),
                                                                          BTy_object OTy_pointer)))
                                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                                      (Epure
                                                                        (Pexpr [Aloc CerbLocation.Loc.unknown]
                                                                          PUnit.unit
                                                                          (PEsym
                                                                            (Symbol "" 16900879642891266615
                                                                              (SD_Id "i"))))))
                                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                                      (Eaction
                                                                        (Paction polarity.Pos
                                                                          (Action CerbLocation.Loc.unknown
                                                                            { sb_before := [], dd_before := [],
                                                                              asw_before := [] }
                                                                            (Load0
                                                                              (Pexpr [Aloc CerbLocation.Loc.unknown]
                                                                                PUnit.unit
                                                                                (PEval
                                                                                  (Vctype
                                                                                    (Ctype []
                                                                                      (Basic
                                                                                        (Integer (Signed Int_)))))))
                                                                              (Pexpr [Aloc CerbLocation.Loc.unknown]
                                                                                PUnit.unit
                                                                                (PEsym
                                                                                  (Symbol "" 4998152064567917579
                                                                                    (SD_Id "a_564"))))
                                                                              NA)))))),
                                                                generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                                  (Epure
                                                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                      (PEctor Cspecified
                                                                        [Pexpr [Aloc CerbLocation.Loc.unknown]
                                                                            PUnit.unit
                                                                            (PEval
                                                                              (Vobject
                                                                                (OVinteger
                                                                                  (CerbMem.IntegerValue.IV
                                                                                    CerbMem.Provenance.Prov_none
                                                                                    (Int.ofNat 1)))))])))]))
                                                          (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                            (Epure
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEcase
                                                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                    (PEctor Ctuple
                                                                      [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                          (PEsym
                                                                            (Symbol "" 1862827267035441118
                                                                              (SD_Id "a_559"))),
                                                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                          (PEsym
                                                                            (Symbol "" 14386475981198921378
                                                                              (SD_Id "a_560")))]))
                                                                  [(Pattern [Aloc CerbLocation.Loc.unknown]
                                                                        (CaseCtor Ctuple
                                                                          [Pattern [Aloc CerbLocation.Loc.unknown]
                                                                              (CaseCtor Cspecified
                                                                                [Pattern [Aloc CerbLocation.Loc.unknown]
                                                                                    (CaseBase
                                                                                      (some
                                                                                          (Symbol "" 2433340024454083569
                                                                                            (SD_Id "a_561")),
                                                                                        BTy_object OTy_integer))]),
                                                                            Pattern [Aloc CerbLocation.Loc.unknown]
                                                                              (CaseCtor Cspecified
                                                                                [Pattern [Aloc CerbLocation.Loc.unknown]
                                                                                    (CaseBase
                                                                                      (some
                                                                                          (Symbol "" 7457282682047707106
                                                                                            (SD_Id "a_562")),
                                                                                        BTy_object OTy_integer))])]),
                                                                      Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                        (PEctor Cspecified
                                                                          [Pexpr [Aloc CerbLocation.Loc.unknown]
                                                                              PUnit.unit
                                                                              (PEcatch_exceptional_condition
                                                                                (Signed Int_) IOpAdd
                                                                                (Pexpr [Aloc CerbLocation.Loc.unknown]
                                                                                  PUnit.unit
                                                                                  (PEconv_int (Signed Int_)
                                                                                    (Pexpr
                                                                                      [Aloc CerbLocation.Loc.unknown]
                                                                                      PUnit.unit
                                                                                      (PEsym
                                                                                        (Symbol "" 2433340024454083569
                                                                                          (SD_Id "a_561"))))))
                                                                                (Pexpr [Aloc CerbLocation.Loc.unknown]
                                                                                  PUnit.unit
                                                                                  (PEconv_int (Signed Int_)
                                                                                    (Pexpr
                                                                                      [Aloc CerbLocation.Loc.unknown]
                                                                                      PUnit.unit
                                                                                      (PEsym
                                                                                        (Symbol "" 7457282682047707106
                                                                                          (SD_Id "a_562")))))))])),
                                                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                                                        (CaseBase
                                                                          (none,
                                                                            BTy_tuple
                                                                              [BTy_loaded OTy_integer,
                                                                                BTy_loaded OTy_integer])),
                                                                      Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                        (PEundef CerbLocation.Loc.unknown
                                                                          UB036_exceptional_condition))])))))]))
                                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                  (Ewseq
                                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                                      (CaseBase (none, BTy_unit)))
                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                      (Eaction
                                                        (Paction Neg0
                                                          (Action CerbLocation.Loc.unknown
                                                            { sb_before := [], dd_before := [], asw_before := [] }
                                                            (Store0 false
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEval
                                                                  (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))))
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEsym (Symbol "" 1656971181475828259 (SD_Id "a_558"))))
                                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEcall
                                                                  (Sym
                                                                    (Symbol "" 7499171796590179012
                                                                      (SD_Id "conv_loaded_int")))
                                                                  [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                      (PEval
                                                                        (Vctype
                                                                          (Ctype [] (Basic (Integer (Signed Int_)))))),
                                                                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                      (PEsym
                                                                        (Symbol "" 15936767184861729128
                                                                          (SD_Id "a_565")))]))
                                                              NA)))))
                                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                      (Epure
                                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEcall
                                                            (Sym
                                                              (Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")))
                                                            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEval
                                                                  (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                                              Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                                (PEsym
                                                                  (Symbol "" 15936767184861729128
                                                                    (SD_Id "a_565")))]))))))))))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Esave (Symbol "" 375068160770266825 (SD_Id "continue_529"), BTy_unit)
                                            [(Symbol "" 16900879642891266615 (SD_Id "i"),
                                                (BTy_object OTy_pointer, none),
                                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                  (PEsym (Symbol "" 16900879642891266615 (SD_Id "i")))),
                                              (Symbol "" 9409450202036847209 (SD_Id "s"),
                                                (BTy_object OTy_pointer, none),
                                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                  (PEsym (Symbol "" 9409450202036847209 (SD_Id "s"))))]
                                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                              (Epure
                                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                              (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))
                                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                              (Erun { sb_before := [], dd_before := [], asw_before := [] }
                                                (Symbol "" 15846621060339386788 (SD_Id "while_531"))
                                                [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEsym (Symbol "" 16900879642891266615 (SD_Id "i"))),
                                                  Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEsym (Symbol "" 9409450202036847209 (SD_Id "s")))]))))))))))))))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))))))
        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
          (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Esave (Symbol "" 6779067192211452020 (SD_Id "break_530"), BTy_unit)
                [(Symbol "" 16900879642891266615 (SD_Id "i"), (BTy_object OTy_pointer, none),
                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEsym (Symbol "" 16900879642891266615 (SD_Id "i")))),
                  (Symbol "" 9409450202036847209 (SD_Id "s"), (BTy_object OTy_pointer, none),
                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEsym (Symbol "" 9409450202036847209 (SD_Id "s"))))]
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Eaction
                        (Paction polarity.Pos
                          (Action CerbLocation.Loc.unknown { sb_before := [], dd_before := [], asw_before := [] }
                            (Kill (Static0 (Ctype [] (Basic (Integer (Signed Int_)))))
                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                (PEsym (Symbol "" 16900879642891266615 (SD_Id "i")))))))))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Esseq
                            (Pattern [Aloc CerbLocation.Loc.unknown]
                              (CaseBase
                                (some (Symbol "" 16496410563140706571 (SD_Id "a_567")), BTy_loaded OTy_integer)))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Ebound
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Ewseq
                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                      (CaseBase
                                        (some (Symbol "" 5557795442846871051 (SD_Id "a_566")), BTy_object OTy_pointer)))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Epure
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 9409450202036847209 (SD_Id "s"))))))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Eaction
                                        (Paction polarity.Pos
                                          (Action CerbLocation.Loc.unknown
                                            { sb_before := [], dd_before := [], asw_before := [] }
                                            (Load0
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))))
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEsym (Symbol "" 5557795442846871051 (SD_Id "a_566"))))
                                              NA)))))))))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Eaction
                                    (Paction polarity.Pos
                                      (Action CerbLocation.Loc.unknown
                                        { sb_before := [], dd_before := [], asw_before := [] }
                                        (Kill (Static0 (Ctype [] (Basic (Integer (Signed Int_)))))
                                          (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEsym (Symbol "" 9409450202036847209 (SD_Id "s")))))))))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Erun { sb_before := [], dd_before := [], asw_before := [] }
                                        (Symbol "" 14175359934856645572 (SD_Id "ret_528"))
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEcall (Sym (Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")))
                                              [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                  (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                  (PEsym (Symbol "" 16496410563140706571 (SD_Id "a_567")))])]))
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Eaction
                                            (Paction polarity.Pos
                                              (Action CerbLocation.Loc.unknown
                                                { sb_before := [], dd_before := [], asw_before := [] }
                                                (Kill (Static0 (Ctype [] (Basic (Integer (Signed Int_)))))
                                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEsym (Symbol "" 9409450202036847209 (SD_Id "s")))))))))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                              (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))
                                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                              (Esave
                                                (Symbol "" 14175359934856645572 (SD_Id "ret_528"),
                                                  BTy_loaded OTy_integer)
                                                [(Symbol "" 12129931134301626842 (SD_Id "a_568"),
                                                    (BTy_loaded OTy_integer, none),
                                                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))]
                                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                                  (Epure
                                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEsym
                                                        (Symbol "" 12129931134301626842
                                                          (SD_Id "a_568")))))))))))))))))))))))))))))

/-! ## §4 THE LOOP-GUARD ANCHORS (loop-head cut point; the iteration
    data (iv, nv), the trace, and the counter are QUANTIFIED — one
    anchor pair covers every iteration of every run) -/

/-- LOOP GUARD (i < n), TRUE side. -/
@[seg_round]
theorem t5gT (iv nv : Int) (h1 : -2147483648 ≤ iv)
    (h2 : iv ≤ 2147483647) (h3 : -2147483648 ≤ nv)
    (h4 : nv ≤ 2147483647) (hlt : iv < nv)
    (tr : List trace_event) (ctr : Nat) (p : Pack) :
    app (dnmsRoundM t5File.tagDefs 0)
        (t5gfam (t5arG (t5gz0 OpLt iv nv)) tr ctr p)
      = (NDactive (Sum.inl NOWAKEUP),
         t5gfam (t5arG (Pexpr [] () (PEval (loadedV 1))))
           tr (ctr + 1) p) := by
  seg_discover
  refine ((advance_runstate_eval (th' := ?_)
    (rs' := ?_) ?_).trans ?_)
  rotate_left 2
  · seg_peels
    focus
      show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _) _ = _
      refine (t5cmp_lt_T iv nv ?_ ?_ ?_ ?_ ?_).trans ?_
      all_goals first | assumption | omega | rfl
    all_goals rfl
  · rfl

/-- LOOP GUARD (i < n), FALSE side. -/
@[seg_round]
theorem t5gF (iv nv : Int) (h1 : -2147483648 ≤ iv)
    (h2 : iv ≤ 2147483647) (h3 : -2147483648 ≤ nv)
    (h4 : nv ≤ 2147483647) (hge : ¬ iv < nv)
    (tr : List trace_event) (ctr : Nat) (p : Pack) :
    app (dnmsRoundM t5File.tagDefs 0)
        (t5gfam (t5arG (t5gz0 OpLt iv nv)) tr ctr p)
      = (NDactive (Sum.inl NOWAKEUP),
         t5gfam (t5arG (Pexpr [] () (PEval (loadedV 0))))
           tr (ctr + 1) p) := by
  seg_discover
  refine ((advance_runstate_eval (th' := ?_)
    (rs' := ?_) ?_).trans ?_)
  rotate_left 2
  · seg_peels
    focus
      show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _) _ = _
      refine (t5cmp_lt_F iv nv ?_ ?_ ?_ ?_ ?_).trans ?_
      all_goals first | assumption | omega | rfl
    all_goals rfl
  · rfl

end RelSem.T5S
