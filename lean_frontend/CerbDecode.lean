/-
  Integer and character constant decoding.
  Corresponds to: ocaml_frontend/decode.ml
  Reference: lean-c-semantics doesn't have a direct equivalent (parses from JSON).
-/

import AilSyntax

namespace CerbDecode

/-- Read a hex digit character to its numeric value. -/
private def readDigit (c : Char) : Nat :=
  if '0' ≤ c && c ≤ '9' then c.toNat - '0'.toNat
  else if 'a' ≤ c && c ≤ 'f' then c.toNat - 'a'.toNat + 10
  else if 'A' ≤ c && c ≤ 'F' then c.toNat - 'A'.toNat + 10
  else 0

/-- Decode a C integer constant string to (basis, value).
    Corresponds to: Decode.decode_integer_constant in decode.ml -/
def decode_integer_constant (str : String) : basis × Int :=
  let chars := str.toList
  let (digits, basisN, b) := match chars with
    | '0' :: 'x' :: rest | '0' :: 'X' :: rest => (rest, 16, Hexadecimal)
    | '0' :: 'b' :: rest | '0' :: 'B' :: rest => (rest, 2, Binary)
    | '0' :: rest => (rest, 8, Octal)
    | _ => (chars, 10, Decimal)
  let val := digits.foldl (fun acc c => acc * basisN + readDigit c) 0
  (b, Int.ofNat val)

/-- Decode a C character constant string to its integer value (ASCII).
    Corresponds to: Decode.decode_character_constant in decode.ml -/
def decode_character_constant (str : String) : Int :=
  -- Simple escape sequences
  match str with
  | "\\a" => 7
  | "\\b" => 8
  | "\\f" => 12
  | "\\n" => 10
  | "\\r" => 13
  | "\\t" => 9
  | "\\v" => 11
  | "\\\\" => 92
  | "\\'" => 39
  | "\\\"" => 34
  | "\\0" => 0
  | _ =>
    if str.length == 1 then
      -- Single character — use ASCII value
      Int.ofNat str.front.toNat
    else if str.startsWith "\\x" then
      -- Hex escape: \xNN
      let hex := str.drop 2
      (decode_integer_constant ("0x" ++ hex)).2
    else if str.startsWith "\\" then
      -- Octal escape: \NNN
      let oct := str.drop 1
      (decode_integer_constant ("0" ++ oct)).2
    else if str.length > 0 then
      -- Single character
      Int.ofNat str.front.toNat
    else
      0  -- empty string

/-- Escape a character for display.
    Corresponds to: Decode.escaped_char (= Char.escaped in OCaml) -/
def escaped_char (c : Char) : String :=
  match c with
  | '\n' => "\\n"
  | '\t' => "\\t"
  | '\r' => "\\r"
  | '\\' => "\\\\"
  | '\'' => "\\'"
  | '\"' => "\\\""
  | c => if c.toNat < 32 || c.toNat > 126
    then s!"\\x{Nat.toDigits 16 c.toNat |>.asString}"
    else c.toString

end CerbDecode
