/-!
Batch-protocol escaping, mirroring OCaml 5.4.0 `Bytes.unsafe_escape`
(`lib/ocaml/bytes.ml:170-212`). A byte is printed as a short escape, printable
ASCII, or three decimal digits. The two String producers have different
representations: model IO carries one byte per Char; diagnostics carry text.
-/

namespace CerbEscape

/-- Escape a code in the byte domain (0..255). Keeping the natural code here
preserves the old byte-carrier printer outside that domain too: it does not
silently truncate an invalid carrier or reinterpret it as UTF-8. Establishing
the model's byte-domain invariant belongs to the producer, not this printer. -/
private def code (n : Nat) : String :=
  match n with
  | 34 => "\\\""
  | 92 => "\\\\"
  | 10 => "\\n"
  | 9 => "\\t"
  | 13 => "\\r"
  | 8 => "\\b"
  | _ => if 32 ≤ n && n ≤ 126 then String.singleton (Char.ofNat n)
    else "\\" ++ String.singleton (Char.ofNat (48 + n / 100))
      ++ String.singleton (Char.ofNat (48 + (n / 10) % 10))
      ++ String.singleton (Char.ofNat (48 + n % 10))

/-- Escape actual bytes, including NUL and invalid UTF-8. -/
def bytes (s : ByteArray) : String :=
  s.foldl (fun acc b => acc ++ code b.toNat) ""

/-- Model stdout/stderr contain one Char per byte, not Unicode text.
For example, a carrier Char with code 255 denotes the single byte FF. -/
def byteChars (s : String) : String :=
  s.foldl (fun acc c => acc ++ code c.toNat) ""

/-- Diagnostics are Unicode text; escape their UTF-8 encoding. -/
def text (s : String) : String := bytes s.toUTF8

end CerbEscape
