/-
  RelSem.P02Guard — V2b: the generic guard/compare verdict chain for
  P02 (the P01 R10 template GENERALIZED over both operand values and
  the compare op; proved once, consumed by every guard round of every
  path). Mirror template: RelSem/P01Rounds.lean R10 block (z10a/b/c,
  sLe/sAnd/sIf/sGuard/s10c, p01cmp_eval_T/F).
-/

import RelSem.P02Rounds
import RelSem.SegRoundTac

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.P02

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt RelSem.Corpus
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty loadedV)
open RelSem.P01 (L0 xObjV le1pe le2pe and12pe if1pe symIsRepr symWrapI
  symConvInt)

/-- Program-node annots for the P02 fixture (`[Aloc L0]`). -/
def aL : List annot := [Aloc L0]

/-- The p02 cloc/ext spellings (defeq to the fam projections). -/
def clocC : Option CerbLocation.Loc :=
  some (CerbLocation.other "RelSem.callND")
def extC : Fmap sym sym := create_extern_symmap p02File

/-- Compare-verdict arm (the C `>`/`<` result literal). -/
def gArm (k : Int) : generic_pexpr Unit sym :=
  Pexpr aL () (PEctor Cspecified [Pexpr aL () (PEval (xObjV k))])

/-- One conv_int call operand at value `v` (in-arena spelling). -/
def convA (v : Int) : generic_pexpr Unit sym :=
  Pexpr aL () (PEcall (Sym symConvInt)
    [Pexpr aL () (PEval (Vctype intCty)), Pexpr aL () (PEval (xObjV v))])

/-- The guard-round redex (in-arena spelling). -/
def gz0 (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr aL () (PEif (Pexpr aL () (PEop op (convA v1) (convA v2)))
    (gArm 1) (gArm 0))

/-- Post-pull spelling (root re-annotated `[]`). -/
def gzA (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr aL () (PEop op (convA v1) (convA v2)))
    (gArm 1) (gArm 0))

/-- The conv body after step A (call inline), per operand — the z10b
    operand shape at value `v` (extracted verbatim from the P01
    template, `x → v`). -/
def convB (v : Int) : generic_pexpr Unit sym :=
  (Pexpr [] () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vctype intCty))) (Pexpr aU () (PEval (Vctype (Ctype [] (Basic (Integer Bool0)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEop OpEq (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (v)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (0)))))) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (1)))))))) (Pexpr aU () (PEif (Pexpr aU () (PEcall (Sym symIsRepr) [(Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (v)))))), (Pexpr aU () (PEval (Vctype intCty)))])) (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (v)))))) (Pexpr aU () (PEif (Pexpr aU () (PEis_unsigned (Pexpr aU () (PEval (Vctype intCty))))) (Pexpr aU () (PEcall (Sym symWrapI) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (v))))))])) (Pexpr aU () (PEcall (Impl Integer__conv_nonrepresentable_signed_integer) [(Pexpr aU () (PEval (Vctype intCty))), (Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none (v))))))]))))))))

/-- After step A: both conv calls inlined. -/
def gzB (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr [] () (PEop op (convB v1) (convB v2)))
    (gArm 1) (gArm 0))

/-- After step B: bool-ctype test + is_representable inlined — the
    operands are P01's `if1pe` shape. -/
def gzC (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr [] () (PEop op (if1pe v1) (if1pe v2)))
    (gArm 1) (gArm 0))

/-! ### Steps A/B (value-generic, per-op: the traversal cases on the
    op constructor, so `rfl` needs it concrete; values flow through) -/

theorem gsA_gt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzA OpGt v1 v2) = Result (Defined (gzB OpGt v1 v2)) := rfl

theorem gsA_lt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzA OpLt v1 v2) = Result (Defined (gzB OpLt v1 v2)) := rfl

theorem gsB_gt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzB OpGt v1 v2) = Result (Defined (gzC OpGt v1 v2)) := rfl

theorem gsB_lt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzB OpLt v1 v2) = Result (Defined (gzC OpLt v1 v2)) := rfl

/-! ### The verdict sub-evals (P01's sLe/sAnd/sIf mirrored at the p02
    spellings, both operands value-generic) -/

theorem p02sLe1 (v : Int) (h1 : -2147483648 ≤ v)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 p02File.tagDefs 4 L0 clocC extC
      env memo p02File false (le1pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd1 : decide ((-2147483648:Int) ≤ v) = true := decide_eq_true h1
  have harm : (if (decide ((-2147483648:Int) ≤ v)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
  conv => rhs; rw [← harm]
  rfl

theorem p02sLe2 (v : Int) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 p02File.tagDefs 4 L0 clocC extC
      env memo p02File false (le2pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd2 : decide (v ≤ (2147483647:Int)) = true := decide_eq_true h2
  have harm : (if (decide (v ≤ (2147483647:Int))) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
  conv => rhs; rw [← harm]
  rfl

theorem p02sAnd (v : Int) (h1 : -2147483648 ≤ v) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999997 p02File.tagDefs 3 L0 clocC extC
      env memo p02File false (and12pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (p02sLe1 v h1 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (p02sLe2 v h2 env memo)).trans ?_
    rfl

theorem p02sIf (v : Int) (h1 : -2147483648 ≤ v) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999998 p02File.tagDefs 2 L0 clocC extC
      env memo p02File false (if1pe v)
      = Result (Defined (Pexpr [] () (PEval (xObjV v)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (xObjV v) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (p02sAnd v h1 h2 env memo)).trans ?_
    rfl

/-! ### The guard (compare application) per op/side -/

theorem p02GuardGtT (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647) (hgt : v2 < v1)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999999 p02File.tagDefs 1 L0 clocC extC
      env memo p02File false
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
    refine (eubind_defined (p02sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (p02sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vtrue
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v2 < v1)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem p02GuardGtF (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647) (hle : ¬ v2 < v1)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999999 p02File.tagDefs 1 L0 clocC extC
      env memo p02File false
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
    refine (eubind_defined (p02sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (p02sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vfalse
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v2 < v1)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem p02GuardLtT (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647) (hlt : v1 < v2)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999999 p02File.tagDefs 1 L0 clocC extC
      env memo p02File false
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
    refine (eubind_defined (p02sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (p02sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vtrue
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v1 < v2)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem p02GuardLtF (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647) (hge : ¬ v1 < v2)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999999 p02File.tagDefs 1 L0 clocC extC
      env memo p02File false
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
    refine (eubind_defined (p02sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (p02sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vfalse
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v1 < v2)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

/-! ### Step C (the whole verdict pexpr) per op/side -/

section StepC
variable (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)

include h1 h2 h3 h4

theorem p02sC_gt_T (hgt : v2 < v1) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzC OpGt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 1) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (p02GuardGtT v1 v2 h1 h2 h3 h4 hgt env memo)).trans ?_
    rfl

theorem p02sC_gt_F (hle : ¬ v2 < v1) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzC OpGt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 0) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (p02GuardGtF v1 v2 h1 h2 h3 h4 hle env memo)).trans ?_
    rfl

theorem p02sC_lt_T (hlt : v1 < v2) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzC OpLt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 1) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (p02GuardLtT v1 v2 h1 h2 h3 h4 hlt env memo)).trans ?_
    rfl

theorem p02sC_lt_F (hge : ¬ v1 < v2) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (gzC OpLt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 0) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (p02GuardLtF v1 v2 h1 h2 h3 h4 hge env memo)).trans ?_
    rfl

end StepC

/-! ### The whole-loop faces (aux2 chains at runEU, one per op/side;
    the tactic below consumes exactly these) -/

section Loop
variable {A : Type} (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    {env : List (Fmap sym value)} {memo : Option CerbMem.MemState}
    {st : A}

include h1 h2 h3 h4

theorem p02cmp_gt_T (hgt : v2 < v1) :
    runEU (eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpGt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 1)))) st := by
  have h : eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpGt v1 v2)
      = Result (Defined (Sum.inr (loadedV 1))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (gz0 OpGt v1 v2) = gzA OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [gzA] at h) (gsA_gt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzB OpGt v1 v2) = gzB OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [gzB] at h)
        (show _ = _ from gsB_gt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzC OpGt v1 v2) = gzC OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [gzC] at h)
        (p02sC_gt_T v1 v2 h1 h2 h3 h4 env memo hgt) (by rfl)))
  rw [h]

theorem p02cmp_gt_F (hle : ¬ v2 < v1) :
    runEU (eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpGt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 0)))) st := by
  have h : eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpGt v1 v2)
      = Result (Defined (Sum.inr (loadedV 0))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (gz0 OpGt v1 v2) = gzA OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [gzA] at h) (gsA_gt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzB OpGt v1 v2) = gzB OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [gzB] at h)
        (show _ = _ from gsB_gt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzC OpGt v1 v2) = gzC OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [gzC] at h)
        (p02sC_gt_F v1 v2 h1 h2 h3 h4 env memo hle) (by rfl)))
  rw [h]

theorem p02cmp_lt_T (hlt : v1 < v2) :
    runEU (eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpLt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 1)))) st := by
  have h : eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpLt v1 v2)
      = Result (Defined (Sum.inr (loadedV 1))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (gz0 OpLt v1 v2) = gzA OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [gzA] at h) (gsA_lt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzB OpLt v1 v2) = gzB OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [gzB] at h)
        (show _ = _ from gsB_lt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzC OpLt v1 v2) = gzC OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [gzC] at h)
        (p02sC_lt_T v1 v2 h1 h2 h3 h4 env memo hlt) (by rfl)))
  rw [h]

theorem p02cmp_lt_F (hge : ¬ v1 < v2) :
    runEU (eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpLt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 0)))) st := by
  have h : eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (gz0 OpLt v1 v2)
      = Result (Defined (Sum.inr (loadedV 0))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (gz0 OpLt v1 v2) = gzA OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [gzA] at h) (gsA_lt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzB OpLt v1 v2) = gzB OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [gzB] at h)
        (show _ = _ from gsB_lt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (gzC OpLt v1 v2) = gzC OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [gzC] at h)
        (p02sC_lt_F v1 v2 h1 h2 h3 h4 env memo hge) (by rfl)))
  rw [h]

end Loop


/-! ### The checked-arith arm (case-selected `Cspecified [catch iop
    (conv v1) (conv v2)]`; the T2 sT2catch template at the CALL-form
    conv — mirrors the guard ladder one wrap deeper) -/

/-- The arm as `select_case` emits it (top `[]`, catch node retains
    the program annots, substituted value nodes retain the sym-node
    annots — probe-verified). -/
def armS (io : iop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified
    [Pexpr aL () (PEcatch_exceptional_condition (Signed Int_) io
      (convA v1) (convA v2))])

/-- After the conv calls inline (probe-walked: rebuilt nodes `[]`). -/
def armB' (io : iop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified
    [Pexpr [] () (PEcatch_exceptional_condition (Signed Int_) io
      (convB v1) (convB v2))])

/-- After the ctype tests + is_representable inline. -/
def armC' (io : iop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified
    [Pexpr [] () (PEcatch_exceptional_condition (Signed Int_) io
      (if1pe v1) (if1pe v2))])

theorem gsArmA_sub (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (armS IOpSub v1 v2)
      = Result (Defined (armB' IOpSub v1 v2)) := rfl

theorem gsArmA_add (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (armS IOpAdd v1 v2)
      = Result (Defined (armB' IOpAdd v1 v2)) := rfl

theorem gsArmB_sub (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (armB' IOpSub v1 v2)
      = Result (Defined (armC' IOpSub v1 v2)) := rfl

theorem gsArmB_add (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (armB' IOpAdd v1 v2)
      = Result (Defined (armC' IOpAdd v1 v2)) := rfl

/-- The catch step, SUB: convs from the operand ranges, the catch
    from the difference range (sT2catch mirrored at the call-form
    conv). -/
theorem gsArmC_sub (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (hs1 : -2147483648 ≤ v1 - v2) (hs2 : v1 - v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (armC' IOpSub v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV (v1 - v2))))) := by
  have hd1 : intLteb (-2147483648) (v1 - v2) = true :=
    RelSem.RoundEval.intLteb_true hs1
  have hd2 : intLteb (v1 - v2) 2147483647 = true :=
    RelSem.RoundEval.intLteb_true hs2
  show exception_undef_fmap (Pexpr [] ()) _ = _
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV (v1 - v2)) : generic_pexpr_ Unit sym))
    ?hctor).trans rfl
  case hctor =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (Vobject (OVinteger
        (.IV .Prov_none (v1 - v2))))) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hCatch
      case hCatch =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (Vobject (OVinteger
            (.IV .Prov_none (v1 - v2)))) : generic_pexpr_ Unit sym))
          ?hin).trans rfl
        case hin =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (p02sIf v1 h1 h2 env memo)).trans ?_
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (p02sIf v2 h3 h4 env memo)).trans ?_
          have harm : (if (intLteb (-2147483648) (v1 - v2)
                && intLteb (v1 - v2) 2147483647) = true
              then some (CerbMem.opIval IntSub
                (.IV .Prov_none v1) (.IV .Prov_none v2))
              else none)
              = some (.IV .Prov_none (v1 - v2)
                : CerbMem.IntegerValue) := by
            rw [hd1, hd2]; simp; rfl
          conv => rhs; rw [show (Result (Defined (PEval (Vobject
            (OVinteger (.IV .Prov_none (v1 - v2)))))) : exceptM
              (t0 (generic_pexpr_ Unit sym)) core_run_cause)
            = (match some (.IV .Prov_none (v1 - v2)
                : CerbMem.IntegerValue) with
               | some ival => exception_undef_return
                   (PEval (Vobject (OVinteger ival)))
               | none => except_return (undef CerbLocation.Loc.unknown
                   [UB036_exceptional_condition])) from rfl, ← harm]
          rfl
    rfl

/-- The catch step, ADD. -/
theorem gsArmC_add (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (hs1 : -2147483648 ≤ v1 + v2) (hs2 : v1 + v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (armC' IOpAdd v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV (v1 + v2))))) := by
  have hd1 : intLteb (-2147483648) (v1 + v2) = true :=
    RelSem.RoundEval.intLteb_true hs1
  have hd2 : intLteb (v1 + v2) 2147483647 = true :=
    RelSem.RoundEval.intLteb_true hs2
  show exception_undef_fmap (Pexpr [] ()) _ = _
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV (v1 + v2)) : generic_pexpr_ Unit sym))
    ?hctor).trans rfl
  case hctor =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (Vobject (OVinteger
        (.IV .Prov_none (v1 + v2))))) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hCatch
      case hCatch =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (Vobject (OVinteger
            (.IV .Prov_none (v1 + v2)))) : generic_pexpr_ Unit sym))
          ?hin).trans rfl
        case hin =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (p02sIf v1 h1 h2 env memo)).trans ?_
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (p02sIf v2 h3 h4 env memo)).trans ?_
          have harm : (if (intLteb (-2147483648) (v1 + v2)
                && intLteb (v1 + v2) 2147483647) = true
              then some (CerbMem.opIval IntAdd
                (.IV .Prov_none v1) (.IV .Prov_none v2))
              else none)
              = some (.IV .Prov_none (v1 + v2)
                : CerbMem.IntegerValue) := by
            rw [hd1, hd2]; simp; rfl
          conv => rhs; rw [show (Result (Defined (PEval (Vobject
            (OVinteger (.IV .Prov_none (v1 + v2)))))) : exceptM
              (t0 (generic_pexpr_ Unit sym)) core_run_cause)
            = (match some (.IV .Prov_none (v1 + v2)
                : CerbMem.IntegerValue) with
               | some ival => exception_undef_return
                   (PEval (Vobject (OVinteger ival)))
               | none => except_return (undef CerbLocation.Loc.unknown
                   [UB036_exceptional_condition])) from rfl, ← harm]
          rfl
    rfl

/-! ### The whole-arm loop faces (consumed as the skeleton's `hrest`
    after the case-select step) -/

section ArmLoop
variable (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    {env : List (Fmap sym value)} {memo : Option CerbMem.MemState}

include h1 h2 h3 h4

theorem p02arm_sub (hs1 : -2147483648 ≤ v1 - v2)
    (hs2 : v1 - v2 ≤ 2147483647) :
    eval_pexpr_aux2_lemFuel 999999 p02File.tagDefs L0 clocC extC env
      memo p02File (armS IOpSub v1 v2)
      = Result (Defined (Sum.inr (loadedV (v1 - v2)))) :=
  (aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (armS IOpSub v1 v2) = armS IOpSub v1 v2
        from rfl)
      (by intro a xs h; simp [armS] at h) (gsArmA_sub v1 v2 env memo)
      (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 (armB' IOpSub v1 v2)
        = armB' IOpSub v1 v2 from rfl)
      (by intro a xs h; simp [armB'] at h) (gsArmB_sub v1 v2 env memo)
      (by rfl)).trans
  (aux2_done 999996 _ _ _ _ _ _ _
      (show pull_constrained 0 (armC' IOpSub v1 v2)
        = armC' IOpSub v1 v2 from rfl)
      (by intro a xs h; simp [armC'] at h)
      (gsArmC_sub v1 v2 h1 h2 h3 h4 hs1 hs2 env memo) (by rfl)))

theorem p02arm_add (hs1 : -2147483648 ≤ v1 + v2)
    (hs2 : v1 + v2 ≤ 2147483647) :
    eval_pexpr_aux2_lemFuel 999999 p02File.tagDefs L0 clocC extC env
      memo p02File (armS IOpAdd v1 v2)
      = Result (Defined (Sum.inr (loadedV (v1 + v2)))) :=
  (aux2_step 999998 _ _ _ _ _ _ _
      (show pull_constrained 0 (armS IOpAdd v1 v2) = armS IOpAdd v1 v2
        from rfl)
      (by intro a xs h; simp [armS] at h) (gsArmA_add v1 v2 env memo)
      (by rfl)).trans
  ((aux2_step 999997 _ _ _ _ _ _ _
      (show pull_constrained 0 (armB' IOpAdd v1 v2)
        = armB' IOpAdd v1 v2 from rfl)
      (by intro a xs h; simp [armB'] at h) (gsArmB_add v1 v2 env memo)
      (by rfl)).trans
  (aux2_done 999996 _ _ _ _ _ _ _
      (show pull_constrained 0 (armC' IOpAdd v1 v2)
        = armC' IOpAdd v1 v2 from rfl)
      (by intro a xs h; simp [armC'] at h)
      (gsArmC_add v1 v2 h1 h2 h3 h4 hs1 hs2 env memo) (by rfl)))

end ArmLoop


/-! ### THE CHECKED-ADD WHOLE-LOOP (T2's t2add_eval PORTED — the add
    arm is the PRIMITIVE `PEconv_int` form, exactly T2's shape; one
    aux2_step for the cell-fed case select, one aux2_done for the
    catch. Consumed as ONE runEU-face refine — no per-step
    unification at the round (the r127 chain-shape fix). -/

def p02addArms : List (generic_pattern sym × generic_pexpr Unit sym) :=
  [(Pattern aL (CaseCtor Ctuple
      [Pattern aL (CaseCtor Cspecified
        [Pattern aL (CaseBase ((some p02s_a_652), BTy_object OTy_integer))]),
       Pattern aL (CaseCtor Cspecified
        [Pattern aL (CaseBase ((some p02s_a_653), BTy_object OTy_integer))])]),
    Pexpr aL () (PEctor Cspecified
      [Pexpr aL () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
        (Pexpr aL () (PEconv_int (Signed Int_)
          (Pexpr aL () (PEsym p02s_a_652))))
        (Pexpr aL () (PEconv_int (Signed Int_)
          (Pexpr aL () (PEsym p02s_a_653)))))])),
   (Pattern aL (CaseBase (none,
      BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
    Pexpr aL () (PEundef L0 UB036_exceptional_condition))]

/-- The add-round redex, pull-normal (root `[]`). -/
def p02addRedexP : generic_pexpr Unit sym :=
  Pexpr [] () (PEcase
    (Pexpr [] () (PEctor Ctuple
      [Pexpr aL () (PEsym p02s_a_650),
       Pexpr aL () (PEsym p02s_a_651)]))
    p02addArms)

/-- The selected arm at values (zT2b's shape at the P02 annots). -/
def p02zAdd (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEctor Cspecified
    [Pexpr aL () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
      (Pexpr aL () (PEconv_int (Signed Int_)
        (Pexpr aL () (PEval (xObjV v1)))))
      (Pexpr aL () (PEconv_int (Signed Int_)
        (Pexpr aL () (PEval (xObjV v2))))))])

/-- The primitive conv_int-of-value step (in-range identity;
    sT2conv at the p02 spellings). -/
theorem p02convV (v : Int) (h1 : -2147483648 ≤ v)
    (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999998 p02File.tagDefs 2 L0 clocC extC
      env memo p02File false
      (Pexpr aL () (PEconv_int (Signed Int_)
        (Pexpr aL () (PEval (xObjV v)))))
      = Result (Defined (Pexpr [] () (PEval (xObjV v)))) := by
  have hd1 : intLteb (-2147483648) v = true :=
    RelSem.RoundEval.intLteb_true h1
  have hd2 : intLteb v 2147483647 = true :=
    RelSem.RoundEval.intLteb_true h2
  have harm : (if (intLteb (-2147483648) v && intLteb v 2147483647)
      = true then CerbMem.integerIval v
      else mk_wrapI (Signed Int_) (CerbMem.integerIval v))
      = (.IV .Prov_none v : CerbMem.IntegerValue) := by
    rw [hd1, hd2]; simp; rfl
  conv => rhs; rw [show (xObjV v)
    = Vobject (OVinteger (.IV .Prov_none v)) from rfl, ← harm]
  rfl

/-- The case-select step at the two cells (sT2a ported). -/
theorem p02sAddCase (v1 v2 : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (h650 : lookup_env p02s_a_650 env = some (loadedV v1))
    (h651 : lookup_env p02s_a_651 env = some (loadedV v2)) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false p02addRedexP
      = Result (Defined (p02zAdd v1 v2)) :=
  se_case_sel
    (se_ctor_tuple
      (pes' := [Pexpr [] () (PEval (loadedV v1)),
                Pexpr [] () (PEval (loadedV v2))])
      (cvals := [loadedV v1, loadedV v2])
      (eumapM_cons (se_sym_hit (fuel := 999997) rfl h650)
        (eumapM_cons (se_sym_hit (fuel := 999997) rfl h651)
          eumapM_nil)) rfl)
    rfl

/-- The CHECKED-ADD catch step (sT2catch ported). -/
theorem p02sAddCatch (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (hs1 : -2147483648 ≤ v1 + v2) (hs2 : v1 + v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (p02zAdd v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV (v1 + v2))))) := by
  have hd1 : intLteb (-2147483648) (v1 + v2) = true :=
    RelSem.RoundEval.intLteb_true hs1
  have hd2 : intLteb (v1 + v2) 2147483647 = true :=
    RelSem.RoundEval.intLteb_true hs2
  show exception_undef_fmap (Pexpr [] ()) _ = _
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV (v1 + v2)) : generic_pexpr_ Unit sym))
    ?hctor).trans rfl
  case hctor =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (Vobject (OVinteger
        (.IV .Prov_none (v1 + v2))))) : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hCatch
      case hCatch =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (Vobject (OVinteger
            (.IV .Prov_none (v1 + v2)))) : generic_pexpr_ Unit sym))
          ?hin).trans rfl
        case hin =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (p02convV v1 h1 h2 env memo)).trans ?_
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (p02convV v2 h3 h4 env memo)).trans ?_
          have harm : (if (intLteb (-2147483648) (v1 + v2)
                && intLteb (v1 + v2) 2147483647) = true
              then some (CerbMem.opIval IntAdd
                (.IV .Prov_none v1) (.IV .Prov_none v2))
              else none)
              = some (.IV .Prov_none (v1 + v2)
                : CerbMem.IntegerValue) := by
            rw [hd1, hd2]; simp; rfl
          conv => rhs; rw [show (Result (Defined (PEval (Vobject
            (OVinteger (.IV .Prov_none (v1 + v2)))))) : exceptM
              (t0 (generic_pexpr_ Unit sym)) core_run_cause)
            = (match some (.IV .Prov_none (v1 + v2)
                : CerbMem.IntegerValue) with
               | some ival => exception_undef_return
                   (PEval (Vobject (OVinteger ival)))
               | none => except_return (undef CerbLocation.Loc.unknown
                   [UB036_exceptional_condition])) from rfl, ← harm]
          rfl
    rfl

section AddLoop
variable {A : Type} (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    {env : List (Fmap sym value)} {memo : Option CerbMem.MemState}
    {st : A}

include h1 h2 h3 h4

/-- The whole checked-add loop at the two cells (runEU face; the
    round leaf consumes exactly this). -/
theorem p02add_evalR (hs1 : -2147483648 ≤ v1 + v2)
    (hs2 : v1 + v2 ≤ 2147483647)
    (h650 : lookup_env p02s_a_650 env = some (loadedV v1))
    (h651 : lookup_env p02s_a_651 env = some (loadedV v2)) :
    runEU (eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (Pexpr aL () (PEcase
        (Pexpr aL () (PEctor Ctuple
          [Pexpr aL () (PEsym p02s_a_650),
           Pexpr aL () (PEsym p02s_a_651)]))
        p02addArms))) st
      = runEU (Result (Defined (Sum.inr (loadedV (v1 + v2))))) st := by
  have h : eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File (Pexpr aL () (PEcase
        (Pexpr aL () (PEctor Ctuple
          [Pexpr aL () (PEsym p02s_a_650),
           Pexpr aL () (PEsym p02s_a_651)]))
        p02addArms))
      = Result (Defined (Sum.inr (loadedV (v1 + v2)))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (Pexpr aL () (PEcase
          (Pexpr aL () (PEctor Ctuple
            [Pexpr aL () (PEsym p02s_a_650),
             Pexpr aL () (PEsym p02s_a_651)]))
          p02addArms)) = p02addRedexP from rfl)
        (by intro a xs h; simp [p02addRedexP] at h)
        (p02sAddCase v1 v2 env memo h650 h651) (by rfl)).trans
    (aux2_done 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (p02zAdd v1 v2) = p02zAdd v1 v2
          from rfl)
        (by intro a xs h; simp [p02zAdd] at h)
        (p02sAddCatch v1 v2 h1 h2 h3 h4 hs1 hs2 env memo) (by rfl))
  rw [h]

end AddLoop

/-! ### THE RET-CONV CHAIN (T1's R6 convChain ported to p02File; the
    Erun argument's conv_loaded_int CALL at the a_657 cell) -/

def convLI : sym := Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")

def p02convPE : generic_pexpr Unit sym :=
  Pexpr aL () (PEcall (Sym convLI)
    [Pexpr aL () (PEval (Vctype intCty)), Pexpr aL () (PEsym p02s_a_657)])

def p02convPE_p : generic_pexpr Unit sym :=
  Pexpr [] () (PEcall (Sym convLI)
    [Pexpr aL () (PEval (Vctype intCty)), Pexpr aL () (PEsym p02s_a_657)])

/-- s0: the conv call inlines (the a_657 lookup via the arg mapM). -/
theorem p02conv_s0 (v : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (ha : lookup_env p02s_a_657 env = some (loadedV v)) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false p02convPE_p
      = Result (Defined (RelSem.T1.z0 v)) := by
  show step_eval_pexpr_lemFuel (999999 + 1) _ _ _ _ _ _ _ _ _ _ = _
  refine se_call (pes' := [Pexpr [] () (PEval (Vctype intCty)),
      Pexpr [] () (PEval (loadedV v))])
    (cvals := [Vctype intCty, loadedV v]) ?_ rfl rfl rfl
  exact eumapM_cons rfl
    (eumapM_cons (se_sym_hit (fuel := 999998) rfl ha) eumapM_nil)

theorem p02conv_s1 (v : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (RelSem.T1.z0 v) = Result (Defined (RelSem.T1.z1 v)) := rfl

theorem p02conv_s2 (v : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (RelSem.T1.z1 v) = Result (Defined (RelSem.T1.z2 v)) := rfl

theorem p02conv_s3 (v : Int) (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (RelSem.T1.z2 v) = Result (Defined (RelSem.T1.z3 v)) := rfl

/-- s4: the range check (T1's s4_eq at the p02 spellings). -/
theorem p02conv_s4 (v : Int) (h1 : -2147483648 ≤ v)
    (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr p02File.tagDefs 0 L0 clocC extC env memo p02File
      false (RelSem.T1.z3 v) = Result (Defined (RelSem.T1.z4 v)) := by
  have hd1 : decide ((-2147483648:Int) ≤ v) = true := decide_eq_true h1
  have hd2 : decide (v ≤ (2147483647:Int)) = true := decide_eq_true h2
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV v) : generic_pexpr_ Unit sym)) ?hBody).trans ?_
  case hBody =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (z := [(Pexpr [] () (PEval (RelSem.T1.xIntV v))
        : generic_pexpr Unit sym)])
      ?hMap).trans ?_
    case hMap =>
      apply eumapM_one ?hIf
      case hIf =>
        change exception_undef_bind _ _ = _
        refine (eubind_defined
          (z := (PEval (RelSem.T1.xIntV v) : generic_pexpr_ Unit sym))
          ?hIfBody).trans ?_
        case hIfBody =>
          change exception_undef_bind _ _ = _
          refine (eubind_defined
            (z := (Pexpr [] () (PEval Vtrue) : generic_pexpr Unit sym))
            ?hCond).trans ?_
          case hCond =>
            change exception_undef_bind _ _ = _
            refine (eubind_defined
              (z := (PEval Vtrue : generic_pexpr_ Unit sym))
              ?hCondBody).trans ?_
            case hCondBody =>
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue)
                  : generic_pexpr Unit sym))
                ?hLe1).trans ?_
              case hLe1 =>
                show step_eval_pexpr_lemFuel 999997 p02File.tagDefs
                  (0+1+1+1) L0 clocC extC env memo p02File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEctor Civmin
                      [Pexpr aU () (PEval (Vctype intCty))]))
                    (Pexpr [] () (PEval (RelSem.T1.xIntV v)))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide ((-2147483648:Int) ≤ v)) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
                conv => rhs; rw [← harm]
                rfl
              change exception_undef_bind _ _ = _
              refine (eubind_defined
                (z := (Pexpr [] () (PEval Vtrue)
                  : generic_pexpr Unit sym))
                ?hLe2).trans ?_
              case hLe2 =>
                show step_eval_pexpr_lemFuel 999997 p02File.tagDefs
                  (0+1+1+1) L0 clocC extC env memo p02File false
                  (Pexpr [] () (PEop OpLe
                    (Pexpr [] () (PEval (RelSem.T1.xIntV v)))
                    (Pexpr [] () (PEctor Civmax
                      [Pexpr aU () (PEval (Vctype intCty))]))))
                  = Result (Defined (Pexpr [] () (PEval Vtrue)))
                have harm : (if (decide (v ≤ (2147483647:Int))) = true
                    then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
                conv => rhs; rw [← harm]
                rfl
              rfl
            rfl
          rfl
        rfl
    rfl
  rfl

/-- The whole conv loop (runEU face). -/
theorem p02conv_chainR {A : Type} (v : Int) (h1 : -2147483648 ≤ v)
    (h2 : v ≤ 2147483647)
    {env : List (Fmap sym value)} {memo : Option CerbMem.MemState}
    {st : A}
    (ha : lookup_env p02s_a_657 env = some (loadedV v)) :
    runEU (eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File p02convPE) st
      = runEU (Result (Defined (Sum.inr (loadedV v)))) st := by
  have h : eval_pexpr_aux2 p02File.tagDefs L0 clocC extC env memo
      p02File p02convPE = Result (Defined (Sum.inr (loadedV v))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 p02convPE = p02convPE_p from rfl)
        (by intro a xs h; simp [p02convPE_p] at h)
        (p02conv_s0 v env memo ha) (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _ (RelSem.T1.pull_z0 v)
        (by intro a xs h; simp [RelSem.T1.z0] at h)
        (p02conv_s1 v env memo) (by rfl)).trans
    ((aux2_step 999997 _ _ _ _ _ _ _ (RelSem.T1.pull_z1 v)
        (by intro a xs h; simp [RelSem.T1.z1] at h)
        (p02conv_s2 v env memo) (by rfl)).trans
    ((aux2_step 999996 _ _ _ _ _ _ _ (RelSem.T1.pull_z2 v)
        (by intro a xs h; simp [RelSem.T1.z2] at h)
        (p02conv_s3 v env memo) (by rfl)).trans
    (aux2_done 999995 _ _ _ _ _ _ _ (RelSem.T1.pull_z3 v)
        (by intro a xs h; simp [RelSem.T1.z3] at h)
        (p02conv_s4 v h1 h2 env memo) (by rfl)))))
  rw [h]

/-- The full-eval face of the ret-conv chain (T1Rounds
    `fullEval_conv` ported to p02File: the Erun argument's
    conv_loaded_int call at the a_657 cell, ∀-run-state; consumed by
    `seg_round_conv_ret`). -/
theorem p02fullEval_conv (v : Int) (h1 : -2147483648 ≤ v)
    (h2 : v ≤ 2147483647) (ar : RExpr) (f₁ : Fmap sym value)
    (ls : CerbMem.MemState) (st : core_run_state)
    (ha : lookup_env p02s_a_657 [f₁] = some (loadedV v)) :
    full_eval_pexpr p02File.tagDefs (p02Th ar f₁) extC ls p02File
        p02convPE st
      = Result (Defined (loadedV v), st) := by
  show stExceptUndef_bind _ _ _ = _
  refine (RelSem.Kit.stub_defined (z := Sum.inr (loadedV v))
    (st' := st) ?_).trans ?_
  · show runEU (eval_pexpr_aux2 p02File.tagDefs L0 clocC extC
        [f₁] (some ls) p02File p02convPE) _ = _
    rw [p02conv_chainR v h1 h2 ha]
    rfl
  · rfl

/-! ### The class tactics (DETERMINISTIC per-variant; the
    backtracking `first`-storm over arena-sized goals is the measured
    pathology — see the slice record §5) -/

/-- Deterministic conditioned-round tactic (guard_gtT). -/
macro "seg_round_guard_gtT" : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.P02.p02cmp_gt_T _ _ ?_ ?_
                       ?_ ?_ ?_).trans ?_
                     all_goals first | assumption | omega | rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-- Deterministic conditioned-round tactic (guard_gtF). -/
macro "seg_round_guard_gtF" : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.P02.p02cmp_gt_F _ _ ?_ ?_
                       ?_ ?_ ?_).trans ?_
                     all_goals first | assumption | omega | rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-- Deterministic conditioned-round tactic (guard_ltT). -/
macro "seg_round_guard_ltT" : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.P02.p02cmp_lt_T _ _ ?_ ?_
                       ?_ ?_ ?_).trans ?_
                     all_goals first | assumption | omega | rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-- Deterministic conditioned-round tactic (guard_ltF). -/
macro "seg_round_guard_ltF" : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.P02.p02cmp_lt_F _ _ ?_ ?_
                       ?_ ?_ ?_).trans ?_
                     all_goals first | assumption | omega | rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-- Deterministic conditioned-round tactic (arith_sub). -/
macro "seg_round_arith_sub" : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.Seg.runEU_aux2_step_then
                       (peP := ?_) (pe' := ?_) (z := ?_)
                       ?_ ?_ ?_ ?_).trans ?_
                     rotate_left 3
                     · rfl
                     · seg_se_step
                     · rfl
                     · refine RelSem.P02.p02arm_sub _ _ ?_ ?_
                         ?_ ?_ ?_ ?_
                       all_goals first | assumption | omega
                     · rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-- Deterministic conditioned-round tactic (arith_add). -/
macro "seg_round_arith_add" : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.Seg.runEU_aux2_step_then
                       (peP := ?_) (pe' := ?_) (z := ?_)
                       ?_ ?_ ?_ ?_).trans ?_
                     rotate_left 3
                     · rfl
                     · seg_se_step
                     · rfl
                     · refine RelSem.P02.p02arm_add _ _ ?_ ?_
                         ?_ ?_ ?_ ?_
                       all_goals first | assumption | omega
                     · rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-! ### PERF-1 (2026-08-28): the ARM-FORM committed keys — the r127
    lesson mechanized. The dispatch key inventory goes one level
    below op/verdict, to the arm's OPERAND FORM: primitive
    `PEconv_int` (the checked-ADD loop — `p02add_evalR` leaf),
    literal-first-operand unary minus (the r257 form — one
    case-select step, GROUND rest), conv-CALL operands (the existing
    `seg_round_arith_{sub,add}`), and the `RS_EVAL[Erun]` ret-conv
    class (`p02fullEval_conv` leaf). Committed choice per key
    (Lithium interpreter.v syntax-directed selection): the generator
    reads the key AND the values off the transcript diff and feeds
    them as tactic arguments — at most one candidate per goal shape;
    a form the generator cannot key is a LOUD generation-time error,
    never an iteration over wrong candidates. -/

/-- Checked-ADD at the PRIMITIVE `PEconv_int` arm (r127-class).
    Values are generator-fed (the `.trans` middle carries `v1 + v2`,
    so the caller commits them — PERF-0 probe finding). -/
macro "seg_round_arith_add_prim" v1:term:max v2:term:max : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.P02.p02add_evalR $v1 $v2
                       ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_).trans ?_
                     all_goals first | assumption | omega | rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-- The literal-first-operand unary-minus checked-SUB arm (the r257
    form: single-cell case scrutinee, all values literal — one
    case-select step at the cell read, then the rest of the loop is
    a CLOSED computation). -/
macro "seg_round_neg_lit" : tactic =>
  `(tactic| (seg_discover
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
               rotate_left 2
               · refine (stub_defined (z := ?_) (st' := ?_)
                   ?_).trans ?_
                 rotate_left 2
                 · refine (stub_defined (z := ?_) (st' := ?_)
                     ?_).trans ?_
                   rotate_left 2
                   · show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _)
                       _ = _
                     refine (RelSem.Seg.runEU_aux2_step_then
                       (peP := ?_) (pe' := ?_) (z := ?_)
                       ?_ ?_ ?_ ?_).trans ?_
                     rotate_left 3
                     · rfl
                     · refine se_case_sel (pa := ?_) (pb := ())
                         (cval := ?_) (a2 := ?_) (b2 := ?_)
                         (pe2 := ?_) ?_ ?_
                       rotate_left 5
                       · refine se_sym_hit (v := ?_) ?_ ?_
                         rotate_left 1
                         · assumption
                         · rfl
                       · rfl
                     · rfl
                     · rfl
                     · rfl
                   · rfl
                 · rfl
               · rfl
             · rfl))

/-- The `RS_EVAL[Erun]` ret-conv round (r130-class): the Erun jump
    with the conv_loaded_int argument evaluated through the PROVED
    whole conv loop (`p02conv_chainR` via `p02fullEval_conv`). The
    value is generator-fed; its range side conditions close by omega
    from the round's path-condition/range hypotheses. Scaffold:
    T1Rounds `t1r6`. -/
macro "seg_round_conv_ret" v:term:max : tactic =>
  `(tactic| (seg_discover
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
                     apply (stub_defined
                       (RelSem.P02.p02fullEval_conv $v
                         (by omega) (by omega) _ _ _ _
                         (by assumption))).trans
                     rfl
                   rfl
                 rfl
             rfl))

end RelSem.P02
