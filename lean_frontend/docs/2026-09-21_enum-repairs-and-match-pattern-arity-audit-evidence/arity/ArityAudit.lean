import Core_aux
import Core_typing
import Core_aux_lemMeasureProofs

set_option autoImplicit true
namespace ArityAudit

def key (i : Nat) : sym := sym.Symbol "audit" i SD_None
def leaf (i : Nat) : pattern := Pattern [] (CaseBase (some (key i), BTy_unit))
def tuple (ps : List pattern) : pattern := Pattern [] (CaseCtor Ctuple ps)
def flat (n : Nat) : pattern := tuple ((List.range n).map leaf)
def vals (n : Nat) : value := Vtuple (List.replicate n Vunit)
def wild : pattern := Pattern [] (CaseBase (none, BTy_unit))

-- General equation for the exact generated guard at any positive worker fuel.
theorem mismatch_worker (n : Nat) (ps : List pattern) (vs : List value)
    (h : (ps.length == vs.length) = false) :
    match_pattern_lemFuel (n + 1) (tuple ps) (Vtuple vs) = none := by
  simp [tuple, match_pattern_lemFuel, h]

-- Nested arity mismatches fail the whole match; fitting siblings do not leak bindings.
example : match_pattern (tuple [leaf 8, flat 2]) (Vtuple [Vunit, vals 3]) = none := rfl
example : match_pattern (tuple [flat 2, leaf 8]) (Vtuple [vals 3, Vunit]) = none := rfl
example : match_pattern (flat 0) (vals 0) = some [] := rfl
example : match_pattern (flat 0) (vals 1) = none := rfl
example : match_pattern (flat 1) (vals 0) = none := rfl

def body : expr Unit := Expr [] (Epure (Pexpr [] () (PEsym (key 0))))
def unitBody : expr Unit := Expr [] (Epure (Pexpr [] () (PEval Vunit)))

-- These unchanged substitutions accept an arity mismatch without consulting the matcher.
example : subst_pattern_val (flat 2) (vals 3) body = unitBody := rfl
example : subst_pattern (flat 2) (mk_value_pe (vals 3)) body = some unitBody := rfl
example : unsafe_subst_pattern (flat 2) (mk_value_pe (vals 3)) body = unitBody := rfl
example : match_pattern (flat 2) (vals 3) = none := rfl

-- Exercise the actual expression and pure-expression substitutions in select_case.
example : select_case subst_sym_expr (vals 3) [(flat 2, body), (wild, unitBody)] = some unitBody := rfl
example : select_case subst_sym_pexpr (vals 3)
    [(flat 2, Pexpr [] () (PEsym (key 0))), (wild, Pexpr [] () (PEval Vunit))]
    = some (Pexpr [] () (PEval Vunit)) := rfl
example : select_case subst_sym_expr (vals 2) [(flat 2, body)] = some unitBody := rfl

def typingOK (n : Nat) (p : pattern) : Bool :=
  match typecheck_pattern (BTy_tuple (List.replicate n BTy_unit)) p with
  | Result (_, Pattern _ (CaseCtor Ctuple ps)) => ps.length == n
  | _ => false

def typingMismatch (n : Nat) (p : pattern) : Bool :=
  match typecheck_pattern (BTy_tuple (List.replicate n BTy_unit)) p with
  | Exception (_, CORE_TYPING (MismatchExpected "Ctuple" (BTy_tuple ts) "tuple pattern of a different arity")) => ts.length == n
  | _ => false

#eval do
  let mut checks := 0
  for n in List.range 7 do
    for m in List.range 7 do
      let expected := if n == m then some ((List.range n).map fun i => (key i, Vunit)) else none
      let actual := match_pattern (flat n) (vals m)
      unless actual == expected do throw (IO.userError s!"flat matcher: {n}/{m}")
      checks := checks + 1
      let nestedP := tuple [leaf 20, flat n, leaf 21]
      let nestedV := Vtuple [Vunit, vals m, Vunit]
      let nestedExpected := if n == m then
        some ((key 20, Vunit) :: ((List.range n).map fun i => (key i, Vunit)) ++ [(key 21, Vunit)]) else none
      unless match_pattern nestedP nestedV == nestedExpected do throw (IO.userError s!"nested matcher: {n}/{m}")
      checks := checks + 1
      unless (if n == m then typingOK m (flat n) else typingMismatch m (flat n)) do
        throw (IO.userError s!"tuple typing: {n}/{m}")
      checks := checks + 1
      let chosen := select_case (fun _ _ b => b) (vals m) [(flat n, "first"), (wild, "fallback")]
      unless chosen == some (if n == m then "first" else "fallback") do
        throw (IO.userError s!"selector: {n}/{m}")
      checks := checks + 1
  IO.println s!"ArityAudit: {checks} checks passed (arities 0 through 6; flat, nested, typing, selector)"

-- Characterize the remaining typechecker defect on the freshly generated Lean model.
-- These are observations of wrong behavior, not assertions that it is desirable.
def unitPe : pexpr := Pexpr [] () (PEval Vunit)
#eval do
  let tys := BTy_tuple [BTy_unit, BTy_unit]
  let p := Pexpr [] () (PEctor Ctuple [unitPe, unitPe, unitPe])
  let result := typecheck_pexpr (fmapEmpty : Fmap sym (Unit × tag_definition)) empty_env tys p
  match result with
  | Result (Pexpr _ _ (PEctor Ctuple ps)) =>
      unless ps.length == 2 do throw (IO.userError "unexpected typed tuple result")
      IO.println s!"REMAINING DEFECT: typecheck_pexpr accepts 3 operands against 2 types and returns {ps.length} operands"
  | _ => throw (IO.userError "unexpected typing result")
  let expr1 : expr Unit := Expr [] (Eunseq [unitBody, unitBody, unitBody])
  match typecheck_expr Normal_callconv fmapEmpty empty_env tys expr1 with
  | Result (Expr _ (Eunseq es)) =>
      unless es.length == 2 do throw (IO.userError "unexpected typed unseq result")
      IO.println s!"REMAINING DEFECT: typecheck_expr accepts 3 unseq operands against 2 types and returns {es.length} operands"
  | _ => throw (IO.userError "unexpected unseq typing result")

#print axioms mismatch_worker
end ArityAudit
