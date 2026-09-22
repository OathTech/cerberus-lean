import Core_aux
import Core_typing
import Core_run
import Core_reduction
import Core_aux_lemMeasureProofs

/-! # MatchPatternArityTest — kernel facts for cerberus-sl hidden-state note item 7

`Core_aux.match_pattern` fails CLOSED on a tuple-arity mismatch (slice `fix/match-pattern-arity`,
2026-09-20; charter `docs/2026-09-20_charter-match-pattern-arity.md` §2 D3; record
`docs/2026-09-20_match-pattern-arity-record.md`). Before the fix the tuple arm
(`frontend/model/core_aux.lem:2033-2039`) zipped the sub-patterns against the components with
Lem's TRUNCATING `List.zip` (`lem-lean/library/list.lem:987-992`), so a pattern of arity 2 MATCHED a
value of arity 3, binding the prefix. The fix mirrors upstream's own guard in `simpl_match_pattern`
(`core_rewrite.lem:1287-1290`): `if List.length pats' <> List.length cvals' then Nothing else …`.

The consumer's contract (their note, item 7, verbatim): *"on an arity mismatch `match_pattern`
returns NO MATCH (`Nothing`), not an error, so that `select_case` CONTINUES to later arms (a
wildcard arm after a mismatching tuple pattern is selected), and a successful match keeps the
calculus's bindings and their order."* T1–T3 below are those three facts on concrete terms, by
term-mode `rfl` = `Eq.refl` (kernel-checked; `#print axioms` = `[propext]`, inherited from the model's definitions, pinned by `#guard_msgs`); T4 is the
negative control (the PRE-FIX answer is now provably NOT returned; the pre-fix quote is in the
record and printed by `main`); T5 pins the typechecker's twin guard (`core_typing.lem:182-186`) —
a RUNTIME evaluation, because the generated `typecheck_pattern` is a `partial def` (no kernel
equations), in the pure `exceptM` monad (no environment).

THE FUEL WRAPPER: `match_pattern g cval` IS `match_pattern_lemFuel (generic_pattern.lemSize g) g
cval` (generated `Core_aux.lean`, the MEASURED wrapper — `declare {lean} fuel_measure val
match_pattern = \`lemSize g\``, `core_aux.lem`), so every fact about `match_pattern` is a fact about
the worker at the pattern's own size; `T1_anyFuel` lifts T1 to EVERY fuel at or above the measure
through the sufficiency theorem `Core_aux_lemMeasureProofs.match_pattern_measure_sufficient`
(re-established in this slice with its statement unchanged).

No proof method beyond `rfl`/`rw`/`exact`/`nomatch`; no option bumps; kernel-only.

CLOSURE ROUND (2026-09-22; pre-merge audit `docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit.md`
R1/R2, orchestrator rulings): the SURROUNDING typing and binding paths, as RUNTIME witnesses on the
actual generated definitions plus kernel facts — the shapes are the audit's `ArityAudit.lean`
(evidence dir `…-audit-evidence/arity/`), reused verbatim. R1: `typecheck_pexpr`'s tuple-EXPRESSION
arm, `typecheck_expr`'s `Eunseq` and `Epar` arms REJECT an arity mismatch (both directions, nested) and
PRESERVE every operand of a fitting input byte-identically (erase the type annotation, compare). R2:
`subst_pattern_val`, `unsafe_subst_pattern`, `update_env_aux` return THE loud leaf
`Core_aux.tuple_arity_error` on a mismatch (the `maybe`-returning `subst_pattern` DECLINES: `none`, round 2) (kernel `rfl`: the leaf is `failwithI`, opaque, so the
equation is the statement that the result IS the leaf — never evaluated at runtime), fitting inputs
unchanged; the ordinary `Elet` through `Core_run.core_thread_step2` and the `PElet` route through
`Core_eval.step_eval_pexpr` give the SAME `Illformed_program` outcome (default = `--rewrite`). The two
runtime routes need an ambient `[LemFuel]`: `main` takes the fuel from its argument (the
`monadic-failstop-test` idiom; `scripts/test_unit.sh` passes it) — no fuel numeral in this file. -/

namespace MatchPatternArityTest

/-! ## Concrete terms -/

def s1 : sym := sym.Symbol "d" 1 SD_None
def s2 : sym := sym.Symbol "d" 2 SD_None
def s3 : sym := sym.Symbol "d" 3 SD_None
/-- `CaseBase (Just sym, _)` binds the whole component (`core_aux.lem` `match_pattern`, second arm). -/
def p1 : generic_pattern sym := Pattern [] (CaseBase (some s1, BTy_unit))
def p2 : generic_pattern sym := Pattern [] (CaseBase (some s2, BTy_boolean))
def p3 : generic_pattern sym := Pattern [] (CaseBase (some s3, BTy_boolean))
/-- the pair pattern `(s1, s2)` -/
def tup2 : generic_pattern sym := Pattern [] (CaseCtor Ctuple [p1, p2])
/-- the triple pattern `(s1, s2, s3)` -/
def tup3 : generic_pattern sym := Pattern [] (CaseCtor Ctuple [p1, p2, p3])
/-- the wildcard `_` -/
def wild : generic_pattern sym := Pattern [] (CaseBase (none, BTy_unit))
/-- the triple value `(unit, true, false)` -/
def v3 : value := Vtuple [Vunit, Vtrue, Vfalse]
/-- the pair value `(unit, true)` -/
def v2 : value := Vtuple [Vunit, Vtrue]

/-! ## T1 — arity mismatch is NO MATCH (`none`), both directions -/

/-- pair pattern on a triple value: `none` (pre-fix: `some [(s1, Vunit), (s2, Vtrue)]`, the prefix) -/
theorem T1a : match_pattern tup2 v3 = none := rfl
/-- triple pattern on a pair value: `none` (pre-fix: `some [(s1, Vunit), (s2, Vtrue)]`, the prefix) -/
theorem T1b : match_pattern tup3 v2 = none := rfl

/-- The wrapper IS the worker at the pattern's derived size (definitional; the MEASURED form). -/
theorem T1_wrapper : match_pattern tup2 v3 = match_pattern_lemFuel (generic_pattern.lemSize tup2) tup2 v3 := rfl
/-- T1a at EVERY fuel at or above the measure, through the sufficiency theorem. -/
theorem T1_anyFuel (n : Nat) (h : generic_pattern.lemSize tup2 ≤ n) : match_pattern_lemFuel n tup2 v3 = none := by
  rw [Core_aux_lemMeasureProofs.match_pattern_measure_sufficient tup2 v3 n h]
  exact T1a

/-! ## T2 — the selector CONTINUES to the next arm (`core_aux.lem` `select_case`, "trying the next branch") -/

/-- `case (unit, true, false) of | (s1, s2) => "pair arm" | _ => "wildcard arm"` selects the wildcard
    (pre-fix: `some "pair arm"`). The substitution is a stand-in for `subst_sym_expr`/`subst_sym_pexpr`
    (`select_case` is polymorphic in it). -/
theorem T2 : select_case (fun _ _ acc => acc) v3 [(tup2, "pair arm"), (wild, "wildcard arm")] = some "wildcard arm" := rfl

/-! ## T3 — a successful match keeps the bindings and their ORDER -/

/-- pair pattern on a pair value: the bindings, `s1` first — exactly today's answer. -/
theorem T3 : match_pattern tup2 v2 = some [(s1, Vunit), (s2, Vtrue)] := rfl
/-- …and through the selector's right fold (`select_case`'s `List.foldr (fun (sym, cval') acc -> subst_sym sym cval' acc) pe`),
    with `subst_sym := cons`: the arm body `[]` receives `(s1, Vunit)` then `(s2, Vtrue)` in that order. -/
theorem T3_select : select_case (fun s v acc => (s, v) :: acc) v2 [(tup2, ([] : List (sym × value))), (wild, [(s3, Vunit)])]
    = some [(s1, Vunit), (s2, Vtrue)] := rfl

/-! ## T4 — NEGATIVE CONTROL: the pre-fix answer is provably NOT returned any more

Pre-fix, verbatim from the probe of the matcher AS BUILT at `0c15a1c11` (= mainline `5407597d9`),
`.tmp/mpa/prefix-matcher-probe.log`, quoted in the record:
  `pre-fix match_pattern tup2 v3 = some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]`
  `pre-fix match_pattern tup3 v2 = some [(Symbol "d" 1 SD_None, Vunit), (Symbol "d" 2 SD_None, Vtrue)]`
Not a compiled decoy: the old matcher is not re-implemented here; the theorem below is the kernel's
word that the fixed matcher does not return it (if the guard were reverted, `T1a` fails to compile). -/
theorem T4_neg : match_pattern tup2 v3 ≠ some [(s1, Vunit), (s2, Vtrue)] :=
  fun h => nomatch (T1a.symm.trans h)

/-! ## Axiom pins: T1–T4 depend on exactly `[propext]` — the trio or fewer

The proofs are `Eq.refl`/`nomatch`; `propext` enters through the DEFINITIONS in the statements'
closure (the generated model — `match_pattern` itself reports it, pinned first), not through any
proof here (probe 2026-09-20: `lemListZip` carries `propext`; `generic_pattern.lemSize`, `lemListFoldr`,
`Lem_Maybe.bind0` and the types are axiom-free). `T1_anyFuel` adds the sufficiency theorem's — the trio. -/

/-- info: 'match_pattern' depends on axioms: [propext] -/
#guard_msgs in #print axioms match_pattern

/-- info: 'MatchPatternArityTest.T1a' depends on axioms: [propext] -/
#guard_msgs in #print axioms T1a
/-- info: 'MatchPatternArityTest.T1b' depends on axioms: [propext] -/
#guard_msgs in #print axioms T1b
/-- info: 'MatchPatternArityTest.T2' depends on axioms: [propext] -/
#guard_msgs in #print axioms T2
/-- info: 'MatchPatternArityTest.T3' depends on axioms: [propext] -/
#guard_msgs in #print axioms T3
/-- info: 'MatchPatternArityTest.T3_select' depends on axioms: [propext] -/
#guard_msgs in #print axioms T3_select
/-- info: 'MatchPatternArityTest.T4_neg' depends on axioms: [propext] -/
#guard_msgs in #print axioms T4_neg
/-- info: 'MatchPatternArityTest.T1_anyFuel' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms T1_anyFuel

/-! ## T5 — the typechecker's twin guard (runtime; `typecheck_pattern` is `partial`) -/

/-- Classify a `typecheck_pattern` result without printing locations or environments. -/
def classifyTyping : exceptM (typing_env × generic_pattern sym) (CerbLocation.Loc × cause) → String
  | Result (_, Pattern _ (CaseCtor Ctuple tpats)) => s!"Result (typed Ctuple pattern with {tpats.length} sub-patterns)"
  | Result _ => "Result (other)"
  | Exception (_, CORE_TYPING (MismatchExpected ctx (BTy_tuple bTys) found)) =>
      s!"Exception (CORE_TYPING (MismatchExpected {repr ctx} (BTy_tuple <{bTys.length} components>) {repr found}))"
  | Exception (_, CORE_TYPING _) => "Exception (CORE_TYPING other)"
  | Exception _ => "Exception (other)"

def isArityMismatch : exceptM (typing_env × generic_pattern sym) (CerbLocation.Loc × cause) → Bool
  | Exception (_, CORE_TYPING (MismatchExpected "Ctuple" (BTy_tuple _) "tuple pattern of a different arity")) => true
  | _ => false

def isTypedCtuple (n : Nat) : exceptM (typing_env × generic_pattern sym) (CerbLocation.Loc × cause) → Bool
  | Result (_, Pattern _ (CaseCtor Ctuple tpats)) => tpats.length == n
  | _ => false

/-- T5a: pair pattern against a triple type — REJECTED (pre-fix: `Result (typed Ctuple pattern with 2 sub-patterns)`). -/
def t5a := typecheck_pattern (BTy_tuple [BTy_unit, BTy_boolean, BTy_boolean]) tup2
/-- T5b: triple pattern against a pair type — REJECTED (pre-fix: `Result (typed Ctuple pattern with 2 sub-patterns)`,
    the third sub-pattern silently DROPPED from the typed pattern). -/
def t5b := typecheck_pattern (BTy_tuple [BTy_unit, BTy_boolean]) tup3
/-- T5c, positive control: pair pattern against a pair type — accepted, both sub-patterns kept (unchanged). -/
def t5c := typecheck_pattern (BTy_tuple [BTy_unit, BTy_boolean]) tup2

/-! ## Runtime witness (the exit code) -/

def showVal : value → String
  | Vunit => "Vunit" | Vtrue => "Vtrue" | Vfalse => "Vfalse"
  | Vtuple vs => "Vtuple [" ++ String.intercalate ", " (vs.map showVal) ++ "]"
  | _ => "<other>"
def showSym : sym → String
  | sym.Symbol d n _ => s!"Symbol {repr d} {n} SD_None"
def showRes : Option (List (sym × value)) → String
  | none => "none"
  | some bs => "some [" ++ String.intercalate ", " (bs.map fun (s, v) => s!"({showSym s}, {showVal v})") ++ "]"
/-- structural comparison on the concrete answers (`sym` compared by digest string, id and a `SD_None` tag) -/
def beqSym : sym → sym → Bool
  | sym.Symbol d n SD_None, sym.Symbol d' n' SD_None => d == d' && n == n'
  | _, _ => false
def beqRes : Option (List (sym × value)) → Option (List (sym × value)) → Bool
  | none, none => true
  | some bs, some bs' => bs.length == bs'.length && (bs.zip bs').all fun ((s, v), (s', v')) => beqSym s s' && v == v'
  | _, _ => false

structure Check where
  name : String
  ok : Bool
  got : String
  preFix : String

def checks : List Check := [
  { name := "T1a match_pattern tup2 v3", ok := beqRes (match_pattern tup2 v3) none, got := showRes (match_pattern tup2 v3),
    preFix := "some [(Symbol \"d\" 1 SD_None, Vunit), (Symbol \"d\" 2 SD_None, Vtrue)] (the truncating prefix — the defect)" },
  { name := "T1b match_pattern tup3 v2", ok := beqRes (match_pattern tup3 v2) none, got := showRes (match_pattern tup3 v2),
    preFix := "some [(Symbol \"d\" 1 SD_None, Vunit), (Symbol \"d\" 2 SD_None, Vtrue)] (the truncating prefix — the defect)" },
  { name := "T2 select_case v3 [(tup2, pair arm), (wild, wildcard arm)]",
    ok := select_case (fun _ _ acc => acc) v3 [(tup2, "pair arm"), (wild, "wildcard arm")] == some "wildcard arm",
    got := repr (select_case (fun _ _ acc => acc) v3 [(tup2, "pair arm"), (wild, "wildcard arm")]) |>.pretty,
    preFix := "some \"pair arm\" (the pair arm selected on a triple)" },
  { name := "T3 match_pattern tup2 v2", ok := beqRes (match_pattern tup2 v2) (some [(s1, Vunit), (s2, Vtrue)]), got := showRes (match_pattern tup2 v2),
    preFix := "some [(Symbol \"d\" 1 SD_None, Vunit), (Symbol \"d\" 2 SD_None, Vtrue)] (unchanged)" },
  { name := "T3_select select_case cons v2 [(tup2, []), (wild, [(s3, Vunit)])]",
    ok := beqRes (select_case (fun s v acc => (s, v) :: acc) v2 [(tup2, []), (wild, [(s3, Vunit)])]) (some [(s1, Vunit), (s2, Vtrue)]),
    got := showRes (select_case (fun s v acc => (s, v) :: acc) v2 [(tup2, []), (wild, [(s3, Vunit)])]),
    preFix := "some [(Symbol \"d\" 1 SD_None, Vunit), (Symbol \"d\" 2 SD_None, Vtrue)] (unchanged)" },
  { name := "T5a typecheck_pattern (BTy_tuple [unit, boolean, boolean]) tup2", ok := isArityMismatch t5a, got := classifyTyping t5a,
    preFix := "Result (typed Ctuple pattern with 2 sub-patterns) (ACCEPTED — the defect)" },
  { name := "T5b typecheck_pattern (BTy_tuple [unit, boolean]) tup3", ok := isArityMismatch t5b, got := classifyTyping t5b,
    preFix := "Result (typed Ctuple pattern with 2 sub-patterns) (ACCEPTED, third sub-pattern DROPPED — the defect)" },
  { name := "T5c typecheck_pattern (BTy_tuple [unit, boolean]) tup2 (positive control)", ok := isTypedCtuple 2 t5c, got := classifyTyping t5c,
    preFix := "Result (typed Ctuple pattern with 2 sub-patterns) (unchanged)" } ]

/-! ## Closure round — R2: the tuple-BINDING helpers that never consult the matcher

Shapes = the audit's `ArityAudit.lean`. PRE-FIX (the model as built at `14457f1a0`; `.tmp/mpa/prefix-r1r2-probe.log`,
`.tmp/mpa/prefix-r2-env-probe.log`; the audit kernel-checked the same by `rfl`), verbatim:
  `pre-fix subst_pattern_val (flat 2) (vals 3) body = Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted]`
  `pre-fix unsafe_subst_pattern (flat 2) (mk_value_pe (vals 3)) body = Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted]`
  `pre-fix unsafe_subst_pattern (flat 2) (PEctor Ctuple [u,u,u]) body = Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted]`
  `pre-fix subst_pattern (flat 2) (mk_value_pe (vals 3)) body = some (Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted])`
  `pre-fix subst_pattern (flat 2) (PEctor Ctuple [u,u,u]) body = some (Epure (PEval Vunit)   [= unitBody: key 0 WAS substituted])`
  `pre-fix update_env_aux (flat 2) (vals 3) fmapEmpty : bound keys = [0, 1]`
  `pre-fix update_env_aux (flat 3) (vals 2) fmapEmpty : bound keys = [0, 1]`
— every helper substituted/bound the PREFIX. -/

def key (i : Nat) : sym := sym.Symbol "audit" i SD_None
def leaf (i : Nat) : pattern := Pattern [] (CaseBase (some (key i), BTy_unit))
def tuple (ps : List pattern) : pattern := Pattern [] (CaseCtor Ctuple ps)
def flat (n : Nat) : pattern := tuple ((List.range n).map leaf)
def vals (n : Nat) : value := Vtuple (List.replicate n Vunit)
def body : expr Unit := Expr [] (Epure (Pexpr [] () (PEsym (key 0))))
def unitBody : expr Unit := Expr [] (Epure (Pexpr [] () (PEval Vunit)))
def unitPe : pexpr := Pexpr [] () (PEval Vunit)
def pe3u : pexpr := Pexpr [] () (PEctor Ctuple [unitPe, unitPe, unitPe])
def emptyEnv : Fmap sym value := fmapEmpty

theorem R2_subst_pattern_val_23 : subst_pattern_val (flat 2) (vals 3) body = tuple_arity_error "subst_pattern_val" 2 3 := rfl
theorem R2_subst_pattern_val_32 : subst_pattern_val (flat 3) (vals 2) body = tuple_arity_error "subst_pattern_val" 3 2 := rfl
theorem R2_subst_pattern_val_fit : subst_pattern_val (flat 2) (vals 2) body = unitBody := rfl
theorem R2_unsafe_subst_pattern_val_23 : unsafe_subst_pattern (flat 2) (mk_value_pe (vals 3)) body = tuple_arity_error "unsafe_subst_pattern" 2 3 := rfl
theorem R2_unsafe_subst_pattern_pe_23 : unsafe_subst_pattern (flat 2) pe3u body = tuple_arity_error "unsafe_subst_pattern" 2 3 := rfl
theorem R2_unsafe_subst_pattern_fit : unsafe_subst_pattern (flat 2) (mk_value_pe (vals 2)) body = unitBody := rfl
/-! The `maybe`-returning `subst_pattern` DECLINES (closure round 2 ruling): `none` on a mismatch, at the top
level and nested (the value arms use `match_pattern` as the fit test), so `pure_propagation2`/`to_pure`
leave the binding to the runtime's `Illformed_program` route — one outcome KIND on every path. -/
theorem R2_subst_pattern_val_tuple_23 : subst_pattern (flat 2) (mk_value_pe (vals 3)) body = none := rfl
theorem R2_subst_pattern_val_tuple_32 : subst_pattern (flat 3) (mk_value_pe (vals 2)) body = none := rfl
theorem R2_subst_pattern_pe_23 : subst_pattern (flat 2) pe3u body = none := rfl
/-- nested: `((k0, k1), k5)` against `((unit, unit, unit), unit)` — declines, never the loud leaf -/
theorem R2_subst_pattern_nested_val : subst_pattern (tuple [flat 2, leaf 5]) (mk_value_pe (Vtuple [vals 3, Vunit])) body = none := rfl
theorem R2_subst_pattern_nested_pe : subst_pattern (tuple [flat 2, leaf 5]) (Pexpr [] () (PEctor Ctuple [pe3u, unitPe])) body = none := rfl
theorem R2_subst_pattern_fit : subst_pattern (flat 2) (mk_value_pe (vals 2)) body = some unitBody := rfl
theorem R2_subst_pattern_fit_pe : subst_pattern (flat 2) (Pexpr [] () (PEctor Ctuple [unitPe, unitPe])) body = some unitBody := rfl
theorem R2_update_env_aux_23 : update_env_aux (flat 2) (vals 3) emptyEnv = tuple_arity_error "update_env_aux" 2 3 := rfl
theorem R2_update_env_aux_32 : update_env_aux (flat 3) (vals 2) emptyEnv = tuple_arity_error "update_env_aux" 3 2 := rfl
/-- the matcher on the same shape, for the record: NO MATCH -/
theorem R2_matcher_23 : match_pattern (flat 2) (vals 3) = none := rfl

/-! ## Closure round — R1: the typechecker's tuple-EXPRESSION paths (runtime; `partial def`s)

PRE-FIX (`14457f1a0`; `.tmp/mpa/prefix-r1r2-probe.log`), verbatim:
  `pre-fix typecheck_pexpr tys2 tup3 = Result (PEctor Ctuple with 2 operands)`
  `pre-fix typecheck_pexpr tys3 tup2 = Result (PEctor Ctuple with 2 operands)`
  `pre-fix typecheck_pexpr tysNested nested = Result (PEctor Ctuple with 2 operands)`
  `pre-fix typecheck_expr tys2 (Eunseq [u,u,u]) = Result (Eunseq with 2 operands)`
  `pre-fix typecheck_expr tys3 (Eunseq [u,u]) = Result (Eunseq with 2 operands)`
  `pre-fix typecheck_expr tys2 (Epar [u,u,u]) = Result (Epar with 2 operands)`
  `pre-fix typecheck_expr tys3 (Epar [u,u]) = Result (Epar with 2 operands)`
— accepted, and the typed program REBUILT with the surplus operand DELETED (the audit: an `error(<<<surplus>>>, 3)`
operand vanished under `--typecheck-core`). -/

def tagsEmpty : Fmap sym (CerbLocation.Loc × tag_definition) := fmapEmpty
def peU : pexpr := Pexpr [] () (PEval Vunit)
def peT : pexpr := Pexpr [] () (PEval Vtrue)
def peF : pexpr := Pexpr [] () (PEval Vfalse)
def tysUB : core_base_type := BTy_tuple [BTy_unit, BTy_boolean]
def tysUBB : core_base_type := BTy_tuple [BTy_unit, BTy_boolean, BTy_boolean]
def peUB : pexpr := Pexpr [] () (PEctor Ctuple [peU, peT])
def peUBB : pexpr := Pexpr [] () (PEctor Ctuple [peU, peT, peF])
def tysNested : core_base_type := BTy_tuple [BTy_unit, BTy_tuple [BTy_boolean, BTy_boolean]]
def peNestedBad : pexpr := Pexpr [] () (PEctor Ctuple [peU, Pexpr [] () (PEctor Ctuple [peT, peF, peF])])
def peNestedFit : pexpr := Pexpr [] () (PEctor Ctuple [peU, Pexpr [] () (PEctor Ctuple [peT, peF])])
def eU : expr Unit := Expr [] (Epure peU)
def eT : expr Unit := Expr [] (Epure peT)
def eF : expr Unit := Expr [] (Epure peF)

/-- erase the type annotation of a typed pure expression (the shapes these witnesses use) -/
partial def eraseP {b : Type} : generic_pexpr b sym → Option pexpr
  | Pexpr annots _ (PEval v) => some (Pexpr annots () (PEval v))
  | Pexpr annots _ (PEsym s) => some (Pexpr annots () (PEsym s))
  | Pexpr annots _ (PEctor c pes) => do let pes' ← pes.mapM eraseP; pure (Pexpr annots () (PEctor c pes'))
  | _ => none
partial def eraseE : generic_expr Unit core_base_type sym → Option (expr Unit)
  | Expr annots (Epure pe) => (eraseP pe).map fun pe' => Expr annots (Epure pe')
  | Expr annots (Eunseq es) => do let es' ← es.mapM eraseE; pure (Expr annots (Eunseq es'))
  | Expr annots (Epar es) => do let es' ← es.mapM eraseE; pure (Expr annots (Epar es'))
  | _ => none

def classifyPexprTyping : exceptM (generic_pexpr inferred sym) (CerbLocation.Loc × cause) → String
  | Result (Pexpr _ _ (PEctor Ctuple ps)) => s!"Result (PEctor Ctuple with {ps.length} operands)"
  | Result _ => "Result (other)"
  | Exception (_, CORE_TYPING (MismatchExpected ctx _ found)) => s!"Exception (MismatchExpected {repr ctx} _ {repr found})"
  | Exception _ => "Exception (other)"
def classifyExprTyping : exceptM (generic_expr Unit core_base_type sym) (CerbLocation.Loc × cause) → String
  | Result (Expr _ (Eunseq es)) => s!"Result (Eunseq with {es.length} operands)"
  | Result (Expr _ (Epar es)) => s!"Result (Epar with {es.length} operands)"
  | Result _ => "Result (other)"
  | Exception (_, CORE_TYPING (MismatchExpected ctx _ found)) => s!"Exception (MismatchExpected {repr ctx} _ {repr found})"
  | Exception (_, CORE_TYPING (CoreTyping_TODO t)) => s!"Exception (CoreTyping_TODO {repr t})"
  | Exception _ => "Exception (other)"
def isTupleExprMismatch (ctx : String) : exceptM (generic_pexpr inferred sym) (CerbLocation.Loc × cause) → Bool
  | Exception (_, CORE_TYPING (MismatchExpected c (BTy_tuple _) found)) => c == ctx && found.endsWith "of a different arity"
  | _ => false
def isExprMismatch (ctx : String) : exceptM (generic_expr Unit core_base_type sym) (CerbLocation.Loc × cause) → Bool
  | Exception (_, CORE_TYPING (MismatchExpected c (BTy_tuple _) found)) => c == ctx && found.endsWith "of a different arity"
  | _ => false
/-- fitting input: accepted AND every operand preserved (byte-identical after erasing the annotation) -/
def preservedP (tys : core_base_type) (pe : pexpr) : Bool :=
  match typecheck_pexpr tagsEmpty empty_env tys pe with
  | Result r => eraseP r == some pe
  | _ => false
def preservedE (tys : core_base_type) (e : expr Unit) : Bool :=
  match typecheck_expr Normal_callconv tagsEmpty empty_env tys e with
  | Result r => eraseE r == some e
  | _ => false
def tP (tys : core_base_type) (pe : pexpr) := typecheck_pexpr tagsEmpty empty_env tys pe
def tE (tys : core_base_type) (e : expr Unit) := typecheck_expr Normal_callconv tagsEmpty empty_env tys e

/-! ## Closure round — R2: the ordinary `Elet` (Core_run) = the `PElet` route (Core_eval) on a mismatch

PRE-FIX at the ORACLE (fork binary built at `14457f1a0`, the audit's `let-mismatch.core`; record §12):
default `Defined {value: "Specified(3)", …}` (the prefix bound) vs `--rewrite` (the rewriter's `PElet`)
`Error {msg: "ill-formed program: \`PElet: the pattern didn't match pe1'"}` — the two binding
mechanisms disagreed. -/

/-- `let (k0, k1) = (unit, unit, unit) in unit` as a Core_run arena -/
def eletArena : expr core_run_annotation :=
  Expr [] (Elet (flat 2) (mk_value_pe (vals 3)) (Expr [] (Epure unitPe)))
def eletArenaFit : expr core_run_annotation :=
  Expr [] (Elet (flat 2) (mk_value_pe (vals 2)) (Expr [] (Epure unitPe)))
/-- the same binding as the rewriter's `PElet` -/
def peletPe : pexpr := Pexpr [] () (PElet (flat 2) (mk_value_pe (vals 3)) unitPe)
def peletPeFit : pexpr := Pexpr [] () (PElet (flat 2) (mk_value_pe (vals 2)) unitPe)
/-- the address-space top of the (untouched) memory state — a TEST-CHOSEN named value, as
    `monadic-failstop-test` does; the step under test evaluates a `PEval` and never reads memory -/
def testAddressSpaceTop : Int := 0x10000

inductive RouteOutcome where
  | illformed (msg : String)
  | defined
  | other (what : String)
  deriving BEq, Repr

/-- the ordinary `Elet` step of `Core_run.core_thread_step2`, its `Step_eval` payload run on a default run state -/
def eletRoute (fuel : Nat) (arena : expr core_run_annotation) : RouteOutcome :=
  letI := LemFuel.mk fuel
  let thSt : thread_state := { (default : thread_state) with arena := arena, env := [emptyEnv] }
  let steps := core_thread_step2 tagsEmpty (CerbMem.initialMemState testAddressSpaceTop)
    (default : generic_file Unit core_run_annotation) fmapEmpty fmapEmpty 0 (none, thSt)
  match steps with
  | [Step_eval "Elet" m] =>
      match m (default : core_run_state) with
      | Exception (Illformed_program msg) => .illformed msg
      | Result (Defined _, _) => .defined
      | Result _ => .other "Result (not Defined)"
      | Exception _ => .other "Exception (other cause)"
  | _ => .other s!"{steps.length} step(s), not a single Step_eval Elet"
/-- the `PElet` route of `Core_eval.step_eval_pexpr` -/
def peletRoute (fuel : Nat) (pe : pexpr) : RouteOutcome :=
  letI := LemFuel.mk fuel
  match step_eval_pexpr tagsEmpty 0 CerbLocation.Loc.unknown none fmapEmpty [emptyEnv] none
      (default : generic_file Unit core_run_annotation) false pe with
  | Exception (Illformed_program msg) => .illformed msg
  | Result (Defined _) => .defined
  | Result _ => .other "Result (not Defined)"
  | Exception _ => .other "Exception (other cause)"

def isIllformed : RouteOutcome → Bool
  | .illformed _ => true
  | _ => false

/-! `Core_reduction.one_step` is THE engine the driver steps with (`driver.lem` `drive_core_thread2 →
Core_reduction.core_step2 → step_ctx → one_step`; the post-fix oracle backtrace on the audit's
`let-mismatch.core` names `Core_reduction.one_step`) — `Core_run.core_thread_step2` above is the
second engine. Its let-forms bind a VALUE through `update_env` in a pure `TAU` step; after the
closure round a non-fitting pattern yields `TAU_WITH_RUNSTATE` with the same `Illformed_program`
computation the `PElet` route produces. The two evaluators it takes are stubs — never called on a
`PEval` operand. -/
def stubEval : pexpr → stExceptUndefM pexpr core_run_state core_run_cause :=
  fun _ _ => Exception (Illformed_program "stub: not called")
def stubFull : pexpr → core_run_state → exceptM (t0 value × core_run_state) core_run_cause :=
  fun _ _ => Exception (Illformed_program "stub: not called")
def reductionRoute (label : String) (arena : expr core_run_annotation) : RouteOutcome :=
  match one_step0 stubEval stubFull [emptyEnv] arena with
  | some (TAU_WITH_RUNSTATE l m) =>
      if l != label then .other s!"TAU_WITH_RUNSTATE {l}" else
      match m (default : core_run_state) with
      | Exception (Illformed_program msg) => .illformed msg
      | Result (Defined _, _) => .defined
      | Result _ => .other "Result (not Defined)"
      | Exception _ => .other "Exception (other cause)"
  | some (TAU l _ _) => if l == label then .defined else .other s!"TAU {l}"
  | some _ => .other "another one_step shape"
  | none => .other "none"
def wseqArena : expr core_run_annotation :=
  Expr [] (Ewseq (flat 2) (Expr [] (Epure (mk_value_pe (vals 3)))) (Expr [] (Epure unitPe)))
def sseqArena : expr core_run_annotation :=
  Expr [] (Esseq (flat 2) (Expr [] (Epure (mk_value_pe (vals 3)))) (Expr [] (Epure unitPe)))

structure Check2 where
  name : String
  ok : Bool
  got : String
  preFix : String

def closureChecks (fuel : Nat) : List Check2 :=
  let elet := eletRoute fuel eletArena
  let pelet := peletRoute fuel peletPe
  [ { name := "R1 typecheck_pexpr (unit, boolean) (unit, true, false)", ok := isTupleExprMismatch "Ctuple" (tP tysUB peUBB), got := classifyPexprTyping (tP tysUB peUBB),
      preFix := "Result (PEctor Ctuple with 2 operands) — the third DELETED" },
    { name := "R1 typecheck_pexpr (unit, boolean, boolean) (unit, true)", ok := isTupleExprMismatch "Ctuple" (tP tysUBB peUB), got := classifyPexprTyping (tP tysUBB peUB),
      preFix := "Result (PEctor Ctuple with 2 operands) — the third TYPE dropped" },
    { name := "R1 typecheck_pexpr nested (unit, (boolean, boolean)) (unit, (true, false, false))", ok := isTupleExprMismatch "Ctuple" (tP tysNested peNestedBad), got := classifyPexprTyping (tP tysNested peNestedBad),
      preFix := "Result (PEctor Ctuple with 2 operands) — the inner surplus DELETED" },
    { name := "R1 typecheck_pexpr fitting (unit, boolean, boolean): operands preserved byte-identical", ok := preservedP tysUBB peUBB, got := classifyPexprTyping (tP tysUBB peUBB),
      preFix := "Result (PEctor Ctuple with 3 operands) (unchanged)" },
    { name := "R1 typecheck_pexpr fitting nested: operands preserved byte-identical", ok := preservedP tysNested peNestedFit, got := classifyPexprTyping (tP tysNested peNestedFit),
      preFix := "Result (unchanged)" },
    { name := "R1 typecheck_expr (unit, boolean) unseq(unit, true, false)", ok := isExprMismatch "Eunseq" (tE tysUB (Expr [] (Eunseq [eU, eT, eF]))), got := classifyExprTyping (tE tysUB (Expr [] (Eunseq [eU, eT, eF]))),
      preFix := "Result (Eunseq with 2 operands) — the third DELETED" },
    { name := "R1 typecheck_expr (unit, boolean, boolean) unseq(unit, true)", ok := isExprMismatch "Eunseq" (tE tysUBB (Expr [] (Eunseq [eU, eT]))), got := classifyExprTyping (tE tysUBB (Expr [] (Eunseq [eU, eT]))),
      preFix := "Result (Eunseq with 2 operands)" },
    { name := "R1 typecheck_expr fitting unseq(unit, true, false): operands preserved byte-identical", ok := preservedE tysUBB (Expr [] (Eunseq [eU, eT, eF])), got := classifyExprTyping (tE tysUBB (Expr [] (Eunseq [eU, eT, eF]))),
      preFix := "Result (Eunseq with 3 operands) (unchanged)" },
    { name := "R1 typecheck_expr (unit, boolean) par(unit, true, false)", ok := isExprMismatch "Epar" (tE tysUB (Expr [] (Epar [eU, eT, eF]))), got := classifyExprTyping (tE tysUB (Expr [] (Epar [eU, eT, eF]))),
      preFix := "Result (Epar with 2 operands) — the third DELETED" },
    { name := "R1 typecheck_expr (unit, boolean, boolean) par(unit, true)", ok := isExprMismatch "Epar" (tE tysUBB (Expr [] (Epar [eU, eT]))), got := classifyExprTyping (tE tysUBB (Expr [] (Epar [eU, eT]))),
      preFix := "Result (Epar with 2 operands)" },
    { name := "R1 typecheck_expr fitting par(unit, true, false): operands preserved byte-identical", ok := preservedE tysUBB (Expr [] (Epar [eU, eT, eF])), got := classifyExprTyping (tE tysUBB (Expr [] (Epar [eU, eT, eF]))),
      preFix := "Result (Epar with 3 operands) (unchanged)" },
    { name := "R2 Core_run Elet (k0, k1) = (unit, unit, unit): Illformed_program", ok := isIllformed elet, got := (repr elet).pretty,
      preFix := "the prefix bound, e2 stepped (oracle: Specified(3) on let-mismatch.core)" },
    { name := "R2 Core_eval PElet (k0, k1) = (unit, unit, unit): Illformed_program", ok := isIllformed pelet, got := (repr pelet).pretty,
      preFix := "Illformed_program \"PElet: the pattern didn't match pe1\" (already, via select_case)" },
    { name := "R2 default = rewrite: both routes Illformed_program", ok := isIllformed elet && isIllformed pelet, got := s!"Elet {(repr elet).pretty} / PElet {(repr pelet).pretty}",
      preFix := "DISAGREED: Elet bound the prefix, PElet failed" },
    { name := "R2 fitting (k0, k1) = (unit, unit): both routes Defined", ok := eletRoute fuel eletArenaFit == .defined && peletRoute fuel peletPeFit == .defined,
      got := s!"Elet {(repr (eletRoute fuel eletArenaFit)).pretty} / PElet {(repr (peletRoute fuel peletPeFit)).pretty}", preFix := "both Defined (unchanged)" },
    { name := "R2 Core_reduction one_step Elet (k0, k1) = (unit, unit, unit): Illformed_program (the driver's engine)", ok := isIllformed (reductionRoute "Elet" eletArena), got := (repr (reductionRoute "Elet" eletArena)).pretty,
      preFix := "TAU Elet with the prefix bound (oracle default: Specified(3) on let-mismatch.core)" },
    { name := "R2 Core_reduction one_step Ewseq (k0, k1) = pure (unit, unit, unit): Illformed_program", ok := isIllformed (reductionRoute "Ewseq" wseqArena), got := (repr (reductionRoute "Ewseq" wseqArena)).pretty,
      preFix := "TAU Ewseq with the prefix bound (oracle default: Specified(3) on unseq-weak-mismatch.core)" },
    { name := "R2 Core_reduction one_step Esseq (k0, k1) = pure (unit, unit, unit): Illformed_program", ok := isIllformed (reductionRoute "Esseq" sseqArena), got := (repr (reductionRoute "Esseq" sseqArena)).pretty,
      preFix := "TAU Esseq with the prefix bound (oracle default: Specified(3) on unseq-strong-mismatch.core)" },
    { name := "R2 Core_reduction one_step fitting Elet (k0, k1) = (unit, unit): TAU (unchanged)", ok := reductionRoute "Elet" eletArenaFit == .defined, got := (repr (reductionRoute "Elet" eletArenaFit)).pretty,
      preFix := "TAU Elet (unchanged)" } ]

end MatchPatternArityTest

def main (args : List String) : IO UInt32 := do
  -- the ambient fuel of the two Core_run/Core_eval routes comes from the caller (scripts/test_unit.sh), never from a numeral here
  let some fuel := args.head?.bind String.toNat?
    | IO.eprintln "match-pattern-arity-test: usage: match-pattern-arity-test <fuel : Nat> (the ambient LemFuel of the Elet/PElet runtime witnesses)"; return 2
  IO.println s!"match-pattern-arity-test: match_pattern / typecheck_pattern fail closed on tuple-arity mismatch (cerberus-sl item 7); T1–T4 kernel-checked at compile time; closure round R1/R2 witnesses at fuel {fuel}"
  let mut failed := false
  for c in MatchPatternArityTest.checks do
    IO.println s!"{if c.ok then "PASS" else "FAIL"} {c.name}: got {c.got}; pre-fix: {c.preFix}"
    failed := failed || !c.ok
  for c in MatchPatternArityTest.closureChecks fuel do
    IO.println s!"{if c.ok then "PASS" else "FAIL"} {c.name}: got {c.got}; pre-fix: {c.preFix}"
    failed := failed || !c.ok
  if failed then
    IO.eprintln "match-pattern-arity-test: FAILED (a runtime witness disagrees with the fail-closed expectation)"
    return 1
  IO.println "match-pattern-arity-test: OK (8/8 item-7 witnesses + 19/19 closure-round witnesses; kernel theorems T1a T1b T1_wrapper T1_anyFuel T2 T3 T3_select T4_neg and the R2_* equations (loud leaf / subst_pattern declines) compiled; #print axioms pinned by #guard_msgs: [propext] on T1a/T1b/T2/T3/T3_select/T4_neg, the trio on T1_anyFuel)"
  return 0
