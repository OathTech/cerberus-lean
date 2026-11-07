# `escaped_char`/`decode_character_constant` round-trip corrupts stored chars (127 → 87)

**Status (cerberus-lean fork):** fixed in the fork on 2026-11-07 as a fork-ahead delta (the oracle's `escaped_char`
mirrors the Lean engine's, which emitted `\xNN` since 2026-09-03 under the fork's ISO-fix register row R2, now
retired; every byte 0..255 round-trips on both engines; record
`lean_frontend/docs/2026-11-07_half-mirrors-oracle-record.md`; witness `scripts/check_half_mirrors.sh`, ladder row
1); Sent upstream (communicated privately, 2026-09-26), no public issue URL. The patch at the end is against
`rems-project/cerberus` at `c3ff8c53f` (`git apply --check` in the pristine checkout: OK, 2026-11-07); upstream's tip
carries the same text (the true-bug audit of 2026-11-04 re-observed 127 → 87 at `ae70925fc`).

**Addendum (2026-11-04/07), a stronger symptom than the silent corruption:** every stored byte whose DECIMAL
rendering contains an 8 or a 9 is a tool crash, not a wrong value — `Char.escaped 19 = "\\019"`, and `9` is not an
octal digit, so the octal validator refuses it: `snprintf(b, 4, "%c", 19)` dies with
`Failure("decode_character_constant, started like an octal constant, but failed: 019")` (rc 125; likewise 29, 39,
…, 199, and 0xC3 = 195, the usual UTF-8 lead byte, through `%s`). A sweep of all 256 values on the unfixed oracle:
18 → 16 and 200 → 128 silently (the validator's `'8'` off-by-one makes 18 a value instead of a crash), then the
crash at 19.

**Affected:** `ocaml_frontend/decode.ml:221-222` (`escaped_char` =
`Char.escaped`) composed with `decode.ml:184-197` (the octal reader),
via `frontend/model/formatted.lem:769-771` (`store_chars_in_array`).
Checked against `master` @ `b9aeedcb4`: `decode.ml` is byte-identical in
our checkout (diff-verified 2026-08-22); `formatted.lem`'s
`store_chars_in_array` is line-identical (our file differs from master
only in added `{lean}` target_rep declares elsewhere in the file).

## Description

`formatted.lem`'s `store_chars_in_array` — the path by which every
`printf`-family formatted character is written to memory — round-trips
each char through

```lem
Decode.decode_character_constant (Decode.escaped_char c)   (* formatted.lem:771 *)
```

`escaped_char` is OCaml's `Char.escaped`, which renders non-printables
as **decimal** `\ddd` (e.g. `Char.escaped '\127'` = `"\\127"`). The
decode side has no decimal path: a backslash followed by digits goes to
the **octal** reader (decode.ml:184-197), so the decimal digit string is
reinterpreted as octal: `"\\127"` → 0o127 = 87. Every stored char whose
`Char.escaped` form is `\ddd` with `ddd` not octal-self-valued is
silently corrupted (127 → 87, 200 → 128, …; chars whose escape is
symbolic — `\n`, `\t`, `\\` … — or printable round-trip correctly, which
is why common tests pass).

## Reproducer

```c
#include <stdio.h>
int main(void) {
  char buf[8];
  snprintf(buf, 8, "%c", 127);
  return buf[0];
}
```

```
$ cerberus --exec --batch r.c
Defined {value: "Specified(87)", stdout: "", stderr: "", blocked: "false"}
```

(verbatim, 2026-08-22, our build; the libc/`snprintf` path is stock
`runtime/libc` → builtin `vsnprintf` → `formatted.lem`.)

```
$ gcc r.c && ./a.out; echo $?
127
```

## Observed vs expected

- Observed: the stored char reads back as 87 (`'W'`).
- Expected: 127 (`snprintf`/`%c` must store the value unchanged).

## Impact

Silent data corruption of formatted output/storage for any non-printable
char in the ranges where decimal ≠ octal reading — `printf`/`sprintf`/
`snprintf` of binary-ish data, `%c` with values ≥ 128 or = 127, string
literals with such escapes flowing through the formatted path. No
diagnostic; the program continues with wrong bytes.

## Proposed remedy

Make the pair actually inverse. Smallest fix — emit octal, which the
reader already accepts (mirrors `Char.escaped`'s shape but in base 8;
the fork's own fix, below, emits hexadecimal `\xNN` instead, which the
reader's hexadecimal arm accepts at any length — either form round-trips):

```ocaml
(* decode.ml *)
let escaped_char c =
  match c with
  | '\\' -> "\\\\" | '\'' -> "\\'" | '\"' -> "\\\""
  | '\n' -> "\\n" | '\t' -> "\\t" | '\r' -> "\\r" | '\b' -> "\\b"
  | c when Char.code c < 32 || Char.code c > 126 ->
      Printf.sprintf "\\%03o" (Char.code c)
  | c -> String.make 1 c
```

(Alternatively: stop round-tripping through strings entirely —
`store_chars_in_array` could store `Char.code c` directly; the
encode/decode detour adds nothing but this bug.)

## Classification

**TRUE BUG.** The two functions are composed as an encode/decode pair on
an unconditional runtime path; they are not inverses, and the corruption
is silent. `Char.escaped`'s decimal convention is OCaml lexer syntax,
not C escape syntax — the decode side only ever speaks C.

## Provenance

Found by the arc-14 "immaculate pass" of our Lean port while correcting
the port's own `escaped_char` miscite (the port emits `\xNN` hex, which
decodes exactly — Lean returns 127, agreeing with gcc against the
oracle's 87). Differential pin:
tests/immaculate/libc/g5-escape-roundtrip.c (three-way verdict recorded
in the lane baseline).

## Fork status and patch (2026-11-07)

Fixed in the fork on 2026-11-07 ([USER 2026-11-04] agreed the fix pass under the standing bar; C17 7.21.6.1#8 is
explicit that `%c` writes the argument converted to `unsigned char`, unchanged). Before and after, verbatim (the
fork's oracle at `1e5f2cbca` = pristine `c3ff8c53f`, then the fixed tree; `--exec --batch` with the shipped
library; gcc 13.3.0 `-std=c11 -w -O0`):

```text
$ cerberus --exec --batch r.c        # snprintf(buf, 8, "%c", 127); return buf[0];
Defined {value: "Specified(87)", stdout: "", stderr: "", blocked: "false"}                       (before)
Defined {value: "Specified(127)", stdout: "", stderr: "", blocked: "false"}                      (after; = the Lean engine byte for byte; gcc exit 127)
$ cerberus --exec --batch c19.c      # snprintf(b, 4, "%c", 19); return b[0];
          Failure("decode_character_constant, started like an octal constant, but failed: 019")   (rc 125, before)
Defined {value: "Specified(19)", stdout: "", stderr: "", blocked: "false"}                       (after; gcc exit 19)
```

All 256 values through `snprintf("%c")`, read back as `unsigned char` and printed (the witness `rt_snprintf_c_all`):
the fixed oracle's line equals gcc's byte for byte (`0 1 2 … 255`, `bad=0`); the unfixed oracle dies at 19.

The patch (`escaped_char` as the right inverse of the decoder, mirroring the fork's Lean engine; the comment is
the fork's registration note and may be dropped):

```diff
--- a/ocaml_frontend/decode.ml
+++ b/ocaml_frontend/decode.ml
@@ -217,8 +217,34 @@
       sub r dlt in
   wrapI (decode_character_constant_aux str)
 
+(* FORK FIX (2026-11-07, upstream-tray report 11; a fork-ahead delta, registered in
+   scripts/fork_drift_manifest.txt): the one caller, formatted.lem store_chars_in_array (the
+   vsnprintf builtin's store), writes every formatted character to memory as
+   `decode_character_constant (escaped_char c)`, so this function must be a right inverse of
+   the decoder above. Upstream's `Char.escaped` renders a byte outside the printable range in
+   OCaml's DECIMAL `\ddd` syntax, which the decoder reads as OCTAL (127 -> "\127" -> 0o127 =
+   87, 200 -> 128: a silently corrupted store) or refuses (every decimal escape containing an 8
+   or a 9 -- "\019", "\199" -- is an uncaught Failure: a crash on `snprintf(b, n, "%c", 19)`);
+   C17 7.21.6.1#8 (%c: the argument converted to unsigned char is written). This mirrors the
+   Lean engine's CerbDecode.escaped_char arm for arm: the simple escapes the decoder names;
+   hexadecimal `\xNN` (lower case, unpadded -- the hexadecimal arm above accepts any length)
+   for every other byte outside 32..126; the byte itself otherwise (every printable ASCII byte
+   is in the single-character table above; backslash and both quotes take their escaped
+   forms). All 256 bytes round-trip (measured 2026-11-07, record
+   lean_frontend/docs/2026-11-07_half-mirrors-oracle-record.md). *)
 let escaped_char c =
-  Char.escaped c
+  match c with
+  | '\n' -> "\\n"
+  | '\t' -> "\\t"
+  | '\r' -> "\\r"
+  | '\\' -> "\\\\"
+  | '\'' -> "\\'"
+  | '"'  -> "\\\""
+  | c ->
+      let n = Char.code c in
+      if n < 32 || n > 126 then Printf.sprintf "\\x%x" n
+      else String.make 1 c
+
 
 let encode_character_constant n =
   (* TODO: fixing the encoding to ASCII for now *)
```
