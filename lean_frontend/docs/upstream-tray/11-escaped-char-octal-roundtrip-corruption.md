# `escaped_char`/`decode_character_constant` round-trip corrupts stored chars (127 → 87)

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
reader already accepts (mirrors `Char.escaped`'s shape but in base 8):

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
