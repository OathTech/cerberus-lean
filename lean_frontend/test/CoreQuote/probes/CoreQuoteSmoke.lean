import CerbQuote
open CerbQuote
namespace CoreQuoteSmoke

def emptyFile : file core_run_annotation :=
  ⟨none, .Normal_callconv, .empty, .empty, .empty, .empty, [], .empty,
   .empty, .empty, .empty, .empty⟩

def symbol : sym := .Symbol "digest\x00\"\\λ\n" 7 (.SD_Id "name")
def cmpS : sym → sym → LemOrdering :=
  @Lem_Map.MapKeyType.mapKeyCompare sym (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1)
def cmpO : sym → sym → LemOrdering :=
  @Lem_Basic_classes.ordCompare sym instEq0Sym_1 instOrd0Sym_1
def expression (x : Float) : generic_pexpr Unit sym :=
  .Pexpr [.Amarker 81] () (.PEval (.Vobject (.OVfloating x)))
def floatingFile (x : Float) : file core_run_annotation :=
  { emptyFile with
    main := some symbol
    stdlib := .mk cmpS .Empty
    funs := .mk cmpO (.Node .Empty symbol (.Fun .BTy_unit [] (expression x)) .Empty 91) }

def require (b : Bool) (label : String) : IO Unit :=
  unless b do throw (IO.userError label)

#eval do
  for bits in [0, 0x8000000000000000, 1, 0x7ff0000000000000, 0xfff0000000000000] do
    let f := floatingFile (Float.ofBits bits)
    let src ← match moduleSource [] (translatedProvenance f) f with
      | .ok s => pure s
      | .error e => throw (IO.userError e.message)
    IO.FS.writeFile s!"../.tmp/core-quote-d1/Float{bits.toNat}.lean" (src ++
      "\n#eval do\n  match quotedCore.stdlib, quotedCore.funs with\n" ++
      "  | .mk _ .Empty, .mk _ (.Node .Empty s (.Fun .BTy_unit [] (.Pexpr [.Amarker 81] () (.PEval (.Vobject (.OVfloating f))))) .Empty 91) =>\n" ++
      s!"    if f.toBits.toNat != {bits.toNat} then throw (IO.userError \"float bits changed\")\n" ++
      "    match s, quotedCore.main with\n" ++
      "    | .Symbol d 7 (.SD_Id \"name\"), some (.Symbol d2 7 (.SD_Id \"name\")) =>\n" ++
      "      if d != \"digest\\x00\\\"\\\\λ\\n\" || d2 != d then throw (IO.userError \"string changed\")\n" ++
      "    | _, _ => throw (IO.userError \"symbol fields changed\")\n" ++
      "  | _, _ => throw (IO.userError \"representation changed\")\n")
  let nanFile := floatingFile (Float.ofBits 0x7ff8000000000001)
  match moduleSource [] (translatedProvenance nanFile) nanFile with
  | .error e => require (e.construct == "funs.Float.NaN") "wrong NaN refusal"
  | .ok _ => throw (IO.userError "NaN accepted")
  let f := floatingFile 0
  for p in [{translatedProvenance f with stdlib := none},
            {translatedProvenance f with tagDefs := some .S},
            {translatedProvenance f with funs := some .S}] do
    match quoteFile p f with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "bad provenance accepted")
  let libc := {emptyFile with funs := .mk symbol_compare .Empty}
  let linked := {f with funs := .mk symbol_compare (match f.funs with | .mk _ t => t | .empty => .Empty)}
  let p := linkProvenance (libcProvenance libc) (translatedProvenance f) linked
  require (p.funs == some Comparator.L) "libc first .mk lost its comparator"
  require ((linkProvenance (libcProvenance emptyFile) (translatedProvenance f) f).funs == some Comparator.O)
    "libc .empty failed to take program comparator"
  let .ok folded := linkedProvenance [translatedProvenance f, libcProvenance libc] linked
    | throw (IO.userError "link provenance refused")
  require (folded.funs == some Comparator.L) "reverse input fold changed libc precedence"
  let cmpE : identifier → identifier → LemOrdering := fun a b => match a, b with
    | .Identifier _ sa, .Identifier _ sb => @defaultCompare String String.instOrd sa sb
  let rightMkEmpty := {emptyFile with extern := .mk cmpE .Empty}
  require ((linkProvenance (translatedProvenance emptyFile)
    (translatedProvenance rightMkEmpty) emptyFile).extern == none) "extern was treated as union"
  match linkedProvenance ([] : List Provenance) emptyFile with
  | .error e => require (e.construct == "link") "wrong empty-link refusal"
  | .ok _ => throw (IO.userError "empty link provenance accepted")
  let annotation : core_run_annotation :=
    ⟨.Node (.Node .Empty (2, 3) .Empty 17) (5, 7) .Empty 29,
     .Node .Empty 11 .Empty 31, .Node .Empty 13 .Empty 37⟩
  let mixed := {f with
    tagDefs := .mk symbol_compare .Empty
    impl0 := .mk implementation_constant_compare .Empty
    extern := rightMkEmpty.extern
    loop_attributes1 := .mk (@defaultCompare Nat instOrdNat) .Empty
    funs := .mk cmpO (.Node .Empty symbol
      (.Proc .unknown none .BTy_unit [] (.Expr [] (.Eproc annotation (.Sym symbol) []))) .Empty 91)}
  let provenance := {translatedProvenance mixed with tagDefs := some .L}
  let source ← match moduleSource [] provenance mixed with
    | .ok src => pure src
    | .error e => throw (IO.userError e.message)
  for c in [Comparator.S, .O, .L, .I, .N, .E] do
    require ((source.splitOn c.term).length > 1) s!"missing exact comparator term {reprStr c}"
  IO.FS.writeFile "../.tmp/core-quote-d1/SetsAndComparators.lean" (source ++
    "\n#eval do\n  match quotedCore.funs with\n" ++
    "  | .mk _ (.Node .Empty _ (.Proc .unknown none .BTy_unit [] (.Expr [] (.Eproc a _ []))) .Empty 91) =>\n" ++
    "    match a.sb_before, a.dd_before, a.asw_before with\n" ++
    "    | .Node (.Node .Empty (2, 3) .Empty 17) (5, 7) .Empty 29, .Node .Empty 11 .Empty 31, .Node .Empty 13 .Empty 37 => pure ()\n" ++
    "    | _, _, _ => throw (IO.userError \"set representation changed\")\n" ++
    "  | _ => throw (IO.userError \"procedure representation changed\")\n")
  IO.println "D1 smoke: six positive modules emitted; NaN, provenance refusals and link rules passed"

end CoreQuoteSmoke
