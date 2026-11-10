# A backslash or a non-ASCII byte in a program argument (`--args`) crashes the tool: `prepare_main_args` stores every `argv` byte through the character-constant decoder

**Affected:** `frontend/model/driver.lem` @ `c3ff8c53f`, `prepare_main_args` (`:1628-…`), `:1633-1636`:

```
        List.map (fun c ->
          (* TODO: fixing impl choice here (ASCII) *)
          Mem.integer_mval Ctype.Char (Decode.decode_character_constant (String.toString [c]))
        ) (String.toCharList arg_str) in
```

and `ocaml_frontend/decode.ml` `decode_character_constant` (the `failwith`s at `:167` and `:199`). The Lean port mirrors
both and stops with the same text.

## Description

The strings `argv[1]`…`argv[argc-1]` are built by passing each byte of each argument, as a one-character string, to
`decode_character_constant` — the function that decodes the spelling of a C character constant. A byte that is not the
spelling of a constant on its own has no value there: a backslash is the start of an escape sequence with nothing after
it, and a byte above 127 falls to the decoder's ASCII-only catch-all. Both raise an uncaught `Failure` before `main`
starts. An argument is data, not source text: C17 5.1.2.2.1#2 gives the `argv` strings "implementation-defined values
by the host environment", with no escape processing.

## Reproducers

```c
int main(int argc, char **argv) { return argv[1][1]; }
```

```
$ cerberus --nolibc --exec --batch --args='a\b' argv_second.c
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, invalid constant: '\\'")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Decode.decode_character_constant in file "ocaml_frontend/decode.ml", line 218, characters 8-43
          Called from Cerb_frontend__Driver.prepare_main_args.(fun) in file "ocaml_frontend/generated/driver.ml", line 2063, characters 38-94
```

(exit 125; verbatim, 2026-11-10, un-forked upstream binary + runtime @ `c3ff8c53f`.)

```c
int main(int argc, char **argv) { return (unsigned char)argv[1][0]; }
```

```
$ cerberus --nolibc --exec --batch --args='é' argv_byte.c
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant: invalid char constant ==> \169")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Decode.decode_character_constant in file "ocaml_frontend/decode.ml", line 218, characters 8-43
          Called from Cerb_frontend__Driver.prepare_main_args.(fun) in file "ocaml_frontend/generated/driver.ml", line 2063, characters 38-94
```

(exit 125; the argument is the two UTF-8 bytes 0xC3 0xA9.) gcc 13.3.0 (`gcc -std=c11 -w -O0 f.c && ./a.out ARG; echo
$?`, 2026-11-10): 92 for the first program with the argument `a\b`, 195 for the second with `é`. Control: a plain ASCII
argument works —

```c
int main(int argc, char **argv) { return argc * 100 + argv[1][0]; }
```

```
$ cerberus --nolibc --exec --batch --args='ab' argv_plain.c
Defined {value: "Specified(297)", stdout: "", stderr: "", blocked: "false"}
```

(297 = 2 × 100 + 97; gcc's exit status is 41, the low byte of 297.)

## Observed vs expected

- Observed: an internal error (exit 125) for an argument containing `\` or any byte ≥ 0x80.
- Expected: the byte's value stored in the `argv` string (92; 195).

## Impact

Programs cannot be given Windows-style paths, regular expressions, or any non-ASCII text as arguments. The failure is
a crash, with a message about character constants that the user never wrote.

## Proposed remedy (prose; no patch is attached)

Store the byte's numeric value directly (converted to `char`'s range) instead of passing it through the source-level
decoder.

## Fork status (2026-11-10)

Unchanged in both engines (the same `Failure` texts from the fork's oracle today). Reported, not refused in code.

## Classification

**TRUE BUG** (a crash on valid input to a documented option).

## Provenance

Found on 2026-11-07 by the pre-merge review of the fork's half-mirrors slice (the neighbour of reports 10, 11 and 63:
the same decoder, reached from the driver). Re-run on pristine upstream at `c3ff8c53f`, the fork's oracle and gcc on
2026-11-10. This draft by Claude (Fable 5.2) under operator direction; the filed issue carries an AI-provenance note
per the tray's policy.
