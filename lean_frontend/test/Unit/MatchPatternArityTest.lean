import Core_aux
import Core_typing
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

No proof method beyond `rfl`/`rw`/`exact`/`nomatch`; no option bumps; kernel-only. -/

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

end MatchPatternArityTest

def main : IO UInt32 := do
  IO.println "match-pattern-arity-test: match_pattern / typecheck_pattern fail closed on tuple-arity mismatch (cerberus-sl item 7); T1–T4 kernel-checked at compile time"
  let mut failed := false
  for c in MatchPatternArityTest.checks do
    IO.println s!"{if c.ok then "PASS" else "FAIL"} {c.name}: got {c.got}; pre-fix: {c.preFix}"
    failed := failed || !c.ok
  if failed then
    IO.eprintln "match-pattern-arity-test: FAILED (a runtime witness disagrees with the fail-closed expectation)"
    return 1
  IO.println "match-pattern-arity-test: OK (8/8 runtime witnesses; kernel theorems T1a T1b T1_wrapper T1_anyFuel T2 T3 T3_select T4_neg compiled; #print axioms = [propext] on each, pinned by #guard_msgs)"
  return 0
