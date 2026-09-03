/-
  Integer and character constant decoding.
  Corresponds to: ocaml_frontend/decode.ml
  Reference: lean-c-semantics doesn't have a direct equivalent (parses from JSON).
-/

import AilSyntax

namespace CerbDecode

/-- Read a hex digit character to its numeric value.
    NOTE (sem:N11): returns 0 for a non-digit where upstream's
    read_digit (decode.ml:3-27) computes garbage (`int_of_char n - 48`);
    garbage-for-garbage is acceptable ONLY because every caller
    validates first — decode_integer_constant's input is
    lexer-guaranteed digits, and decode_character_constant_aux (below)
    validates its hex/octal spans before folding (fail-closed since
    arc-14 S1 F2; the pre-F2 char decode leaned on this silent 0 —
    that was sem:G5). -/
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

/-- Final wrap of a decoded character constant into char's value range —
    decode.ml:201-218: with signed char (DefaultImpl char_is_signed =
    true, ocaml_implementation.ml:257) the range is [min,max] =
    [-2^7, 2^7-1]; wrapI computes r = integerRem_f n (max-min+1) — where
    decode.ml:3 `integerRem_f = Big_int_Z.mod_big_int` is the EUCLIDEAN
    (always non-negative) remainder, = Lean's Int.emod — then subtracts
    the modulus when r > max. E.g. '\xFF' → 255 → -1 (survey finding 26;
    previously the wrap was missing entirely). -/
private def wrapChar (n : Int) : Int :=
  let min : Int := -(2 ^ (8 - 1))          -- decode.ml:208
  let max : Int := (2 ^ (8 - 1)) - 1
  let dlt := max - min + 1                 -- decode.ml:211
  let r := Int.emod n dlt                  -- decode.ml:212 (mod_big_int)
  if r ≤ max then r else r - dlt           -- decode.ml:213-217

/-- The single-character table — decode.ml:44-159: the "basic source and
    basic execution sets" (STD §5.2.1#2: letters, digits, the enumerated
    graphic characters, space, horizontal tab) plus the graphical
    extended ASCII characters upstream admits ($ @ `, decode.ml:155-159).
    Backslash is NOT here — it must arrive escaped ("\\\\"). -/
private def basicSourceChar (c : Char) : Bool :=
  ('A' ≤ c && c ≤ 'Z') || ('a' ≤ c && c ≤ 'z') || ('0' ≤ c && c ≤ '9') ||
  "!\"#%&'()*+,-./:;<=>?[]^_{|}~ \t$@`".contains c

/-- The pre-wrap decode — decode.ml:43-200 (decode_character_constant_aux),
    ported as the same exhaustive, fail-CLOSED table (arc-14 S1 F2,
    sem:G5: the previous version was fail-OPEN — multi-char constants
    silently returned the first char's code, invalid hex/octal digits
    folded in as 0 via readDigit's default, empty input returned 0; the
    oracle failwiths on all of these). Failure arms are loud panics
    mirroring upstream's `failwith` (fail-stop under
    LEAN_ABORT_ON_PANIC). -/
private def decode_character_constant_aux (str : String) : Int :=
  match str with
  -- simple-escape-sequences — STD §5.2.2#2, decode.ml:146-153
  | "\\a" => 7
  | "\\b" => 8
  | "\\f" => 12
  | "\\n" => 10
  | "\\r" => 13
  | "\\t" => 9
  | "\\v" => 11
  -- escaped punctuation — decode.ml:115 ("\\\""), :119 ("\\'"), :135 ("\\\\")
  | "\\\\" => 92
  | "\\'" => 39
  | "\\\"" => 34
  -- ISO-fix register R1 (VALIDATION.md "ISO-fix register", [USER
  -- 2026-09-03]): '\?' — ISO C11 §6.4.4.4#1 lists \? among the simple
  -- escape sequences, #4 gives the value of '?' = 63; gcc agrees (exit 63;
  -- "a\?b" = 97 63 98 0). The oracle's decode.ml has NO "\\?" arm, so its
  -- catch-all routes '?' into the octal validator and FAILWITHS on legal C
  -- (uncaught exception, exit 125) — upstream tray 10 (+ the string-
  -- literal form, noodle E2). Pinned Lean-right/oracle-wrong in
  -- tests/immaculate: g5-decode-question, zd-e2-ptr-string-literals
  -- (ORACLE_CRASH pairs; they flip to MATCH and the entry RETIRES when
  -- upstream fixes tray 10). Under the zero-discrepancy rule this is the
  -- ONLY licence for a Lean≠oracle answer: the register entry, not a
  -- "deliberate divergence" label.
  | "\\?" => 63
  | _ =>
    if str.length == 1 then
      -- decode.ml:44-159: the enumerated single-character table;
      -- anything else falls through to failwith (:199-200)
      let c := str.front
      if basicSourceChar c then Int.ofNat c.toNat
      else panic! s!"decode_character_constant: invalid char constant ==> {str} (decode.ml:199-200)"
    else if str.startsWith "\\x" then
      -- Hexadecimal escape sequence — STD §6.4.4.4#9, decode.ml:169-183:
      -- every span char must be a hex digit, else failwith
      let hexs := (str.drop 2).toString
      if hexs.isEmpty then
        panic! "decode_character_constant, invalid constant: '\\x' (decode.ml:171-172)"
      else if hexs.toList.all (fun c =>
          ('0' ≤ c && c ≤ '9') || ('A' ≤ c && c ≤ 'F') || ('a' ≤ c && c ≤ 'f')) then
        (decode_integer_constant ("0x" ++ hexs)).2
      else
        panic! s!"decode_character_constant, started like an hexa constant, but failed: {hexs} (decode.ml:182-183)"
    else if str.startsWith "\\" && str.length ≥ 2 then
      -- Octal escape sequence — STD §6.4.4.4 octal-escape-sequence,
      -- decode.ml:184-197. QUIRK MIRRORED: upstream's validator accepts
      -- character codes 48..56 = '0'..'8' (decode.ml:188-191) — '8' is
      -- not an octal digit ('\8' is a constraint violation gcc
      -- rejects), and read_digit folds it in with value 8; kept
      -- deliberately for oracle parity (documented upstream quirk).
      let octs := (str.drop 1).toString
      if octs.toList.all (fun c => '0' ≤ c && c ≤ '8') then
        (decode_integer_constant ("0" ++ octs)).2
      else
        panic! s!"decode_character_constant, started like an octal constant, but failed: {octs} (decode.ml:196-197)"
    else if str.isEmpty then
      panic! "decode_character_constant: empty constant (decode.ml:162-163)"
    else
      -- multi-character constants and everything else — decode.ml:199-200
      -- (also subsumes the bare "\\" arm, decode.ml:165-167: length-1
      -- backslash fails in the single-char table above)
      panic! s!"decode_character_constant: invalid char constant ==> {str} (decode.ml:199-200)"

/-- Decode a C character constant string to its integer value (ASCII).
    Corresponds to: Decode.decode_character_constant in decode.ml:201-219
    — the aux decode followed by the final wrapI (decode.ml:219). -/
def decode_character_constant (str : String) : Int :=
  wrapChar (decode_character_constant_aux str)

/-- Escape a character for display — used by formatted.lem's
    store_chars_in_array, which round-trips every printf-stored char
    through `decode_character_constant (escaped_char c)`.

    DIVERGENCE from upstream, licensed by the ISO-fix register (below;
    arc-14 S1 F2, sem:S12; the old comment MIScited this as "= Char.escaped
    in OCaml"): upstream's
    escaped_char IS `Char.escaped` (decode.ml:221-222), which renders
    non-printables as DECIMAL "\ddd" — and decode's octal reader then
    reads that back as OCTAL, silently corrupting the round-trip for
    chars whose decimal digits ≠ octal value. MEASURED (arc-14 S0/S1
    three-way, tests/immaculate/libc/g5-escape-roundtrip.c):
    `snprintf(buf, 8, "%c", 127); return buf[0];` returns 87 on the
    oracle (Char.escaped 127 = "\127" → 0o127 = 87) but 127 on BOTH gcc
    and this backend (hex \xNN round-trips exactly).
    Lean-right/oracle-wrong — upstream tray 11.
    ISO-fix register R2 (VALIDATION.md "ISO-fix register", [USER 2026-09-03]):
    this is THE Lean-side round-trip site — `escaped_char` renders
    non-printables as hex `\xNN`, which `decode_character_constant` reads
    back exactly, so `%c` of 127 stores 127 (ISO C11 §7.21.6.1#8: the int
    argument converted to unsigned char is written unchanged); the oracle
    stores 87. Pinned Lean-right/oracle-wrong in tests/immaculate
    g5-escape-roundtrip (DIFF; flips to MATCH and the entry RETIRES when
    upstream fixes tray 11). -/
def escaped_char (c : Char) : String :=
  -- ISO-fix register R2
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
