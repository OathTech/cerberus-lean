/- # Ctype_aux.are_compatible — executable pins of the array-bound arm (semantics-audit repairs D3, 2026-09-11)

  Finding 5 of `docs/2026-09-11_whole-project-semantics-audit.md`: the `Array/Array` arm of
  `are_compatible_aux` (frontend/model/ctype_aux.lem:97-104) read `match (n1_opt, n1_opt)` —
  the first bound compared with itself — so `int[1]` and `int[2]` were "compatible". Fixed to
  `(n1_opt, n2_opt)` (one token; STD §6.7.6.2#6: two array types are compatible when their
  element types are compatible and, if both have constant size, the sizes are equal). These are
  executable assertions on the reader-lifted Lean wrapper `Ctype_aux.are_compatible0 tagDefs`
  (the lem `are_compatible`, which passes `(tagDefs, tagDefs, [])` to the aux) — NOT theorems
  about program literals (charter §0, [USER 2026-09-08]).

  Cases: `int[1]`/`int[2]` false · `int[2]`/`int[2]` true · `int[]`/`int[2]` true · the same
  bounds NESTED as the member of `struct S` defined in TWO translation units (two tag symbols
  with different digests — `Symbol.from_same_translation_unit` is a digest compare — and the
  same name "S", both in one tag environment, as after linking): `{int a[1]}`/`{int a[2]}`
  false, `{int a[2]}`/`{int a[2]}` true. -/
import LemLib
import Ctype_aux

open Lem_Map

def intTy : ctype := ctype.Ctype [] (ctype_.Basic (basicType.Integer (integerType.Signed integerBaseType.Int_)))
def arr (n : Option Int) : ctype := ctype.Ctype [] (ctype_.Array0 intTy n)
def qty (t : ctype) : qualifiers × ctype := (no_qualifiers, t)

/-- A tag symbol: `digest` stands for the translation unit, `n` for the symbol number. -/
def tag (digest : String) (n : Nat) : sym := sym.Symbol digest n (symbol_description.SD_Id "S")

/-- `struct S { int a[n]; }` under tag `t`. -/
def structS (t : sym) (n : Option Int) : sym × (CerbLocation.Loc × tag_definition) :=
  (t, (CerbLocation.unknown,
       tag_definition.StructDef [(identifier.Identifier CerbLocation.unknown "a", (attributes.Attrs [], none, no_qualifiers, arr n))] none))

def check (name : String) (got expected : Bool) : IO Bool := do
  if got == expected then
    IO.println s!"  ok   {name} = {got}"
    return true
  else
    IO.println s!"  ✗ FAIL {name}: got {got}, expected {expected}"
    return false

def main : IO UInt32 := do
  IO.println "test: Ctype_aux.are_compatible0 — array-bound arm (finding 5 repair) + cross-TU struct member"
  let emptyTags : Fmap sym (CerbLocation.Loc × tag_definition) := fromList []
  let ac (tags : Fmap sym (CerbLocation.Loc × tag_definition)) (t1 t2 : ctype) : Bool :=
    are_compatible0 fmapEmpty tags (qty t1) (qty t2)   -- the enum reader first (program-data parameters E-A, 2026-09-20)
  let t1 := tag "tu-one" 1
  let t2 := tag "tu-two" 2
  let tags12 := fromList [structS t1 (some 1), structS t2 (some 2)]
  let tags22 := fromList [structS t1 (some 2), structS t2 (some 2)]
  let mut ok := true
  ok := (← check "int[1] vs int[2]" (ac emptyTags (arr (some 1)) (arr (some 2))) false) && ok
  ok := (← check "int[2] vs int[1]" (ac emptyTags (arr (some 2)) (arr (some 1))) false) && ok
  ok := (← check "int[2] vs int[2]" (ac emptyTags (arr (some 2)) (arr (some 2))) true) && ok
  ok := (← check "int[] vs int[2]  (§6.7.6.2#6)" (ac emptyTags (arr none) (arr (some 2))) true) && ok
  ok := (← check "int[2] vs int[]" (ac emptyTags (arr (some 2)) (arr none)) true) && ok
  ok := (← check "struct S{int a[1]} (TU1) vs struct S{int a[2]} (TU2)"
           (ac tags12 (ctype.Ctype [] (ctype_.Struct t1)) (ctype.Ctype [] (ctype_.Struct t2))) false) && ok
  ok := (← check "struct S{int a[2]} (TU1) vs struct S{int a[2]} (TU2)"
           (ac tags22 (ctype.Ctype [] (ctype_.Struct t1)) (ctype.Ctype [] (ctype_.Struct t2))) true) && ok
  ok := (← check "same-TU same tag (fast path)" (ac tags12 (ctype.Ctype [] (ctype_.Struct t1)) (ctype.Ctype [] (ctype_.Struct t1))) true) && ok
  if ok then
    IO.println "All are_compatible pins passed"
    return 0
  else
    IO.println "FAILED"
    return 1
