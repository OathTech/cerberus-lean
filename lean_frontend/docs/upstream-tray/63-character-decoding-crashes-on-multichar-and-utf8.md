# `decode_character_constant` crashes on a multi-character constant and on any non-ASCII byte in a string literal

**Affected:** `ocaml_frontend/decode.ml:218` (`decode_character_constant`: `failwith ("decode_character_constant:
invalid char constant ==> " ^ …)` for every constant that is not a single ASCII character or a recognised escape),
`decode.ml:42` (`TODO: making the implementation choice of using ASCII for now`) and `:224` (`TODO: fixing the
encoding to ASCII for now`). Reached from `Translation.translate_constant` for character constants and from the
string-literal path for each character of a string literal. Checked at the fork's merge-base `b9aeedcb4`; the Lean
port's `CerbDecode` seam mirrors the `failwith` and panics with the same text.

## Description

Measured 2026-10-20 on the fork @ `3ac3ff336` (`scripts/test_exec.sh`; both engines; gcc 13 for the value):

```c
int main(void){ return 'ab' == 0x6162; }     /* gcc 1 (multi-character constant: implementation-defined, §6.4.4.4#10) */
```
```text
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant: invalid char constant ==> ab")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Decode.decode_character_constant in file "ocaml_frontend/decode.ml", line 218, characters 8-43
```

```c
int main(void){ return (unsigned char)"é"[0]; }     /* gcc 195: the first UTF-8 byte */
```
```text
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant: invalid char constant ==> \169")
```
(both exit 125.) `sizeof("é")` is 3 on both engines (the lexer keeps the bytes); only the value decoding fails.
`'\377'`, `'\xff'`, `u8"ab"` and plain ASCII are fine. Witnesses:
`tests/parity-probes/uncertainty/Q-character-decoding/`.

## Expected

A multi-character constant is implementation-defined (§6.4.4.4#10): either a documented value (gcc: the bytes
packed big-endian into an `int`) or a diagnostic, not an uncaught exception. A string literal's bytes are the
source bytes in the execution character set (§6.4.5#6): a non-ASCII byte should decode to its value (the lexer
already carries it), or the ASCII restriction should be a diagnostic.

## Origin

Found by the fork's upstream-uncertainty survey (2026-10-20, `lean_frontend/docs/2026-10-20_upstream-uncertainty-survey-record.md`,
cluster Q) from decode.ml's `ASCII for now` markers. Classification: TRUE BUG (crash on valid C) for the string
literal; UNCLEAR / implementation-defined for the multi-character constant (a diagnostic would be conforming).
Fork plan ([USER 2026-10-20]): both crashes become declared refusals (a refinement: an unspecified stop turned into
a specified one), queued behind the cerberus-caesium deliveries. The report above describes upstream as it stands.
