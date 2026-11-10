# `decode_character_constant` crashes on a multi-character constant and on any non-ASCII byte in a string literal

**Loci at `c3ff8c53f` (2026-11-10):** `ocaml_frontend/decode.ml:199` (the catch-all `failwith`; the backtrace names
`:218`, the end of the function), `:197` (the octal validator's `failwith`, where universal character names land),
`:42` and `:224` (the two ASCII `TODO`s), read from the un-forked tree.

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
[… further lines cut; the count was not recorded at that date]
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
Fork status: the fork's engines crash as upstream does; an earlier plan to turn both crashes into declared refusals
([USER 2026-10-20]) is not being carried out — since the roadmap of 2026-11-10 they are reported, not refused in code.
The report above describes upstream as it stands.

## Re-run at `c3ff8c53f` (2026-11-10): still reproduces; universal character names and `u8` literals

(Un-forked upstream binary + runtime @ `c3ff8c53f`, both fork engines and gcc 13.3.0 `-std=c11 -w -O0`, all run on 2026-11-10; outputs verbatim. [AGENT 2026-11-10], the reporting slice.)

Both reproducers above still die on pristine upstream (exit 125; gcc exits 1 and 195). Today's lines for the string
literal:

```
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant: invalid char constant ==> \169")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Decode.decode_character_constant in file "ocaml_frontend/decode.ml", line 218, characters 8-43
[… 18 more lines cut]
```

Loci at `c3ff8c53f`: `ocaml_frontend/decode.ml:199` (the catch-all `failwith`), `:197` (the octal validator's),
`:42` and `:224` (the two ASCII `TODO`s). Not in this report before:

- Universal character names (C17 6.4.3) fall into the octal validator, in a character constant and in a string
  literal:

```c
int main(void) { return (unsigned char)'\u00e9'; }
```
```
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: u00e9")
[… 27 more lines cut]
```
```c
int main(void) { const char *s = "\U0001F600x"; return (unsigned char)s[0]; }
```
```
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: U0001F600")
[… 32 more lines cut]
```

  (both exit 125; gcc exits 169 and 240.)
- A `u8` string literal with a non-ASCII character dies like the plain one; `u8"ab"` is fine (98 on pristine and gcc):

```c
int main(void){ return (unsigned char)u8"é"[0]; }
```
```
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant: invalid char constant ==> \169")
[… 20 more lines cut]
```

  (exit 125; gcc exits 195.)

The same decoder is reached from the driver for program arguments: report
[74](74-program-argument-bytes-stored-through-character-decoder.md). Fork status: unchanged in both engines for every
program in this section (the Lean port stops with a mirrored, attributed message, exit 134). The fork has not changed
this behaviour.
