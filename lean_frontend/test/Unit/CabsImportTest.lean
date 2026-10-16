import CabsImport
import CerbLocation

/-! Cabs JSON position import (2026-10-16, cerberus-caesium filing 2): the position
object `{file, line, col, lexing_file, lexing_line}` carries the LEXING position
(the preprocessed file the C lexer read) beside the SOURCE position (after cpp's
`#line` mapping). Checks, at runtime (exit 0 on pass):

- T1 `CabsImport.jsonToPos` imports all five fields losslessly;
- T2 fail-closed: a missing or ill-typed `lexing_file`/`lexing_line` is refused
  (a digit STRING is accepted as a number: the bridge's integers-as-strings
  convention, shared with `line`/`col` — T2d uses a non-numeric string),
  exactly as a missing source field is (controls on `col`);
- T3 `jsonToLoc` is lossless on a cursor-bearing region (both ends, both cursor ends);
- T4 no observable change: every printer and `getFilename` read the source triple,
  so positions differing only in the lexing pair print identically;
- T5 equality: `BEq Pos` distinguishes positions that differ only in the lexing pair
  and identifies positions equal in all five fields (the OCaml structural-equality
  mirror documented on `CerbLocation.Pos`); `compare` agrees on equals;
- T6 the committed oracle fixture `tests/fixtures/001-return-literal/cabs.json` is
  current: every position object carries the lexing fields and imports.
-/
open Lean (Json)

namespace CabsImportTest

def contains (hay needle : String) : Bool := (hay.splitOn needle).length > 1

def expectOk {α : Type} (label : String) (r : Except String α) (check : α → Bool) : IO Bool := do
  match r with
  | .ok v =>
    if check v then IO.println s!"PASS: {label}"; return true
    else IO.eprintln s!"FAIL: {label}: unexpected value"; return false
  | .error e => IO.eprintln s!"FAIL: {label}: unexpected error: {e}"; return false

def expectErr {α : Type} (label : String) (r : Except String α) (needle : String) : IO Bool := do
  match r with
  | .ok _ => IO.eprintln s!"FAIL: {label}: expected an error mentioning '{needle}', got a value"; return false
  | .error e =>
    if contains e needle then IO.println s!"PASS: {label} (refused: '{needle}')"; return true
    else IO.eprintln s!"FAIL: {label}: error does not mention '{needle}': {e}"; return false

def check (label : String) (b : Bool) : IO Bool := do
  if b then IO.println s!"PASS: {label}" else IO.eprintln s!"FAIL: {label}"
  return b

def parsePos (s : String) : Except String CerbLocation.Pos := do
  CabsImport.jsonToPos (← Json.parse s |>.mapError toString)

def parseLoc (s : String) : Except String CerbLocation.Loc := do
  CabsImport.jsonToLoc (← Json.parse s |>.mapError toString)

/-- The reference position: source `a.c:3:5`, read from preprocessed `a.i` line 40. -/
def p0 : CerbLocation.Pos :=
  { file := "a.c", line := 3, col := 5, lexingFile := "a.i", lexingLine := 40 }
/-- Same source triple, next preprocessed line (one source line reached through two
    `#line` regions): OCaml-unequal to `p0`. -/
def p1 : CerbLocation.Pos := { p0 with lexingLine := 41 }
def p2 : CerbLocation.Pos := { p0 with lexingFile := "b.i" }

def fullJson : String :=
  "{\"file\": \"a.c\", \"line\": 3, \"col\": 5, \"lexing_file\": \"a.i\", \"lexing_line\": 40}"

/-- Every object with the keys `file`, `line`, `col` (the recognition rule of
    `CabsImport.positionFiles`) must carry a string `lexing_file` and a number
    `lexing_line` and must import; returns the number of positions seen. -/
partial def checkPositions (j : Json) : Except String Nat :=
  match j with
  | .arr elems =>
    elems.foldl (fun (acc : Except String Nat) e => do return (← acc) + (← checkPositions e)) (pure 0)
  | .obj kvs =>
    let here : Except String Nat :=
      match kvs.get? "file", kvs.get? "line", kvs.get? "col" with
      | some _, some _, some _ =>
        match kvs.get? "lexing_file", kvs.get? "lexing_line" with
        | some (.str _), some (.num _) => do let _ ← CabsImport.jsonToPos j; pure 1
        | _, _ => throw s!"position object without well-typed lexing fields: {j}"
      | _, _, _ => pure 0
    kvs.foldl (fun (acc : Except String Nat) _ v => do return (← acc) + (← checkPositions v)) here
  | _ => pure 0

end CabsImportTest

open CabsImportTest in
def main : IO UInt32 := do
  let mut ok := true
  -- T1: lossless import of all five fields
  ok := (← expectOk "T1 jsonToPos imports the five-field position" (parsePos fullJson)
    (fun p => p == p0 && p.lexingFile == "a.i" && p.lexingLine == 40)) && ok
  -- T2: fail-closed on the lexing pair, controls on the source triple
  ok := (← expectErr "T2a missing lexing_file"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"col\": 5, \"lexing_line\": 40}")
    "missing field 'lexing_file'") && ok
  ok := (← expectErr "T2b missing lexing_line"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"col\": 5, \"lexing_file\": \"a.i\"}")
    "missing field 'lexing_line'") && ok
  ok := (← expectErr "T2c lexing_file not a string"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"col\": 5, \"lexing_file\": 7, \"lexing_line\": 40}")
    "expected string") && ok
  ok := (← expectErr "T2d lexing_line not a nat (string)"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"col\": 5, \"lexing_file\": \"a.i\", \"lexing_line\": \"x\"}")
    "invalid nat string") && ok
  ok := (← expectErr "T2e lexing_line negative"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"col\": 5, \"lexing_file\": \"a.i\", \"lexing_line\": -1}")
    "negative number") && ok
  ok := (← expectErr "T2f lexing_line non-integer"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"col\": 5, \"lexing_file\": \"a.i\", \"lexing_line\": 40.5}")
    "non-integer number") && ok
  ok := (← expectErr "T2g old three-field shape (pre-2026-10-16 exporter) refused"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"col\": 5}")
    "missing field 'lexing_file'") && ok
  ok := (← expectErr "T2h control: missing col refused as before"
    (parsePos "{\"file\": \"a.c\", \"line\": 3, \"lexing_file\": \"a.i\", \"lexing_line\": 40}")
    "missing field 'col'") && ok
  -- T3: a cursor-bearing region round-trips both ends and both cursor ends
  let pj (p : CerbLocation.Pos) : String :=
    s!"\{\"file\": \"{p.file}\", \"line\": {p.line}, \"col\": {p.col}, \"lexing_file\": \"{p.lexingFile}\", \"lexing_line\": {p.lexingLine}}"
  let regionJson :=
    s!"\{\"tag\": \"Loc_region\", \"begin\": {pj p0}, \"end\": {pj p1}, \"cursor\": \{\"tag\": \"RegionCursor\", \"begin\": {pj p2}, \"end\": {pj p0}}}"
  ok := (← expectOk "T3 jsonToLoc is lossless on Loc_region + RegionCursor" (parseLoc regionJson)
    (fun l => l == .region p0 p1 (.regionCursor p2 p0))) && ok
  -- T4: printers and getFilename read the source triple only
  ok := (← check "T4a stringFromLocation (point) ignores the lexing pair"
    (CerbLocation.stringFromLocation (.point p0) == "a.c:3:5:" &&
     CerbLocation.stringFromLocation (.point p1) == "a.c:3:5:" &&
     CerbLocation.stringFromLocation (.point p2) == "a.c:3:5:")) && ok
  ok := (← check "T4b stringFromLocation (region + cursor) ignores the lexing pair"
    (CerbLocation.stringFromLocation (.region p0 p1 (.pointCursor p2)) == "a.c:3:5-5 (cursor: 3:5)")) && ok
  ok := (← check "T4c simpleLocation ignores the lexing pair"
    (CerbLocation.simpleLocation (.region p0 p1 .noCursor) == "<3:5--3:5>" &&
     CerbLocation.simpleLocation (.point p1) == "3:5")) && ok
  ok := (← check "T4d getFilename is the source file"
    (CerbLocation.getFilename (.point p2) == some "a.c")) && ok
  -- T5: equality over all five fields (OCaml structural (=) mirror)
  ok := (← check "T5a positions differing only in lexing_line are distinct" (p0 != p1)) && ok
  ok := (← check "T5b positions differing only in lexing_file are distinct" (p0 != p2)) && ok
  ok := (← check "T5c positions equal in all five fields are equal"
    (p0 == { file := "a.c", line := 3, col := 5, lexingFile := "a.i", lexingLine := 40 } &&
     compare p0 p0 == .eq)) && ok
  ok := (← check "T5d Loc equality follows Pos equality"
    ((CerbLocation.Loc.point p0 == .point p1) == false && (CerbLocation.Loc.point p0 == .point p0) == true)) && ok
  -- T6: the committed oracle fixture carries the fields on every position
  let fixture ← IO.FS.readFile "../tests/fixtures/001-return-literal/cabs.json"
  let shape : Except String Nat := do checkPositions (← Json.parse fixture |>.mapError toString)
  ok := (← expectOk "T6 committed fixture: every position carries the lexing fields" shape (· > 0)) && ok
  match shape with
  | .ok n => IO.println s!"T6: {n} position objects checked"
  | .error _ => pure ()
  if ok then
    IO.println "cabs-import-test: all checks passed"
    return 0
  else
    IO.eprintln "cabs-import-test: FAILED"
    return 1
