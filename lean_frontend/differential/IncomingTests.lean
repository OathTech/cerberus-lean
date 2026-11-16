import Incoming

/-! Focused producer tests. These test static annotation construction and refusal;
    actual fault-rule and end-to-end differential tests live separately. -/

namespace CoreNice.Incoming.Tests

private def symbol (number : Nat) : sym := .Symbol "incoming-tests" number .SD_None
private def label := symbol 10
private def location : CerbLocation.Loc := .other "incoming-test-location"
private def done : expr Unit := .Expr [] (.Epure (.Pexpr [] () (.PEval .Vunit)))
private def jump (target : sym := label) : expr Unit :=
  .Expr [.Aloc location] (.Erun () target [] empty_nice_jump_info)
private def save (body : expr Unit) (name : sym := label) : expr Unit :=
  .Expr [.Aloc location] (.Esave (name, .BTy_unit) [] body empty_nice_label_info)
private def procedure (body : expr Unit) : fun_map_decl Unit :=
  .Proc .unknown none .BTy_unit [] body
private def program (body : expr Unit) : file Unit :=
  { (default : file Unit) with funs := fmapAddBy symbol_compare (symbol 1) (procedure body) .empty }

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def success {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error reason => throw (IO.userError reason)

private def refuses (name : String) (candidate : file Unit) : IO Unit :=
  match finalize candidate with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError s!"expected producer refusal: {name}")

private def erase (candidate : file Unit) : file Unit :=
  mapMetadataFile (fun _ _ _ => empty_nice_jump_info) (fun _ _ _ => empty_nice_label_info) candidate

private def keyTree {α β : Type} : Pmap α β → List (Option (α × Nat))
  | .Empty => [none]
  | .Node left key _ right height => some (key, height) :: keyTree left ++ keyTree right

def run : IO Unit := do
  let raw := program (save (.Expr [] (.Eunseq [jump, jump])))
  let finalized ← success (finalize raw)
  ensure (erase finalized.file == raw) "producer altered ordinary AST fields"
  ensure (finalized.stats == {
    procedures := 1, jumps := 2, labels := 1, allowedOrigins := 2,
    zeroIncomingLabels := 0, maxIncoming := 2 }) "incorrect conservative inventory counts"
  let inventory ← match finalized.procedures with
    | [one] => pure one
    | _ => throw (IO.userError "expected one procedure")
  ensure (inventory.jumps.map (·.info.nice_jump_origin) == [1, 2]) "unstable/duplicate static identities"
  ensure (inventory.jumps.all (·.info.nice_jump_location == location)) "jump location lost"
  ensure (inventory.labels.all (·.info.nice_label_location == location)) "label location lost"
  ensure (inventory.labels.map (·.info.nice_label_origins) == [[1, 2]]) "incomplete incoming set"
  -- Copies in separate procedure bodies must restart numbering independently.
  let two := { raw with
    stdlib := fmapAddBy symbol_compare (symbol 2) (procedure (save jump)) .empty }
  let twoFinal ← success (finalize two)
  ensure (twoFinal.procedures.map (fun p => p.jumps.map (·.info.nice_jump_origin)) == [[1], [1, 2]])
    "stdlib coverage or per-procedure numbering failed"
  ensure (erase twoFinal.file == two) "stdlib AST erasure changed"
  ensure (keyTree twoFinal.file.funs.rep == keyTree two.funs.rep) "procedure map key tree changed"
  -- A shadowing description does not make a second symbol identity.
  let aliasLabel : sym := .Symbol "incoming-tests" 10 (.SD_Id "same-key")
  let aliasTarget ← success (finalize (program (save (jump aliasLabel))))
  ensure (aliasTarget.stats.allowedOrigins == 1) "symbol identity used pretty description"
  refuses "duplicate label identity" (program (save (save done aliasLabel)))
  refuses "unresolved jump" (program jump)
  refuses "saved label under bound" (program (.Expr [] (.Ebound (save done))))
  refuses "saved label under nd" (program (.Expr [] (.End [save done])))
  refuses "saved label under annot" (program (.Expr [] (.Eannot [] (save done))))
  refuses "parallel procedure binding" (program (.Expr [] (.Epar [save jump])))
  -- A jump below an opaque collector node is supported when its target is outside.
  let bound ← success (finalize (program (save (.Expr [] (.Ebound jump)))))
  ensure (bound.stats.allowedOrigins == 1) "valid bound jump was missed"
  let global := { raw with globs := [(symbol 7, .GlobalDef (.BTy_unit, default) jump)] }
  refuses "global jump" global
  refuses "stdlib/funs conflict" { raw with
    stdlib := fmapAddBy symbol_compare (symbol 1) (procedure done) .empty }
  let identical ← success (finalize { raw with stdlib := raw.funs })
  ensure (identical.stats.procedures == 2) "identical duplicate definition refused"
  let external : identifier := .Identifier .unknown "external-procedure"
  let withAlias := { raw with
    extern := fmapAddBy defaultCompare external
      ([symbol 99], .LK_normal (symbol 1)) .empty }
  let aliased ← success (finalize withAlias)
  ensure (aliased.stats == finalized.stats) "declaration alias changed definition inventory"
  refuses "definition remapped by alias" { raw with
    extern := fmapAddBy defaultCompare external
      ([symbol 1], .LK_normal (symbol 99)) .empty }
  -- Post-finalization corruption is deliberately possible; no producer reruns.
  let corrupted := mapMetadataFile (fun _ _ info => info)
    (fun _ _ info => { info with nice_label_origins := [] }) finalized.file
  ensure (erase corrupted == raw) "mutation changed non-metadata fields"
  ensure (corrupted != finalized.file) "negative-control mutation did not take effect"
  ensure ((inspectFile corrupted).all (fun p =>
    p.labels.all (·.info.nice_label_origins.isEmpty))) "inspection read stale producer inventory"
  IO.println "PASS: comesfrom conservative producer construction/refusal tests"

end CoreNice.Incoming.Tests

#eval CoreNice.Incoming.Tests.run
