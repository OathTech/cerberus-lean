# `decode_character_constant` rejects the standard `\?` escape (tool crash)

**Affected:** `ocaml_frontend/decode.ml:44-200`
(`decode_character_constant_aux`; checked against `master` @ `b9aeedcb4`;
our checkout's `ocaml_frontend/decode.ml` is byte-identical to it —
diff-verified 2026-08-22).

## Description

C11 §6.4.4.4#4 lists `\?` among the *simple-escape-sequences*
(`\' \" \? \\ \a \b \f \n \r \t \v`); its value is `'?'` = 63. It exists
so trigraph-era code can write `"??" "?"`-safe strings, and every
conforming compiler accepts it.

`decode_character_constant_aux` has no arm for `"\\?"`: the simple-escape
table (decode.ml:146-153) covers `\a \b \f \n \r \t \v`, the quoting arms
cover `\\ \' \"`, and everything else starting with a backslash falls to
the hex/octal catch-all (decode.ml:165-197). `?` fails the octal
validator, so the function `failwith`s — and since nothing catches it,
the whole tool dies with an internal error on a strictly-conforming
program.

## Reproducer

```c
int main(void) { char c = '\?'; return c; }
```

```
$ cerberus --exec --batch --nolibc q.c
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: ?")
```

(verbatim, 2026-08-22, our build — decode.ml byte-identical to master.)

```
$ gcc -std=c11 q.c && ./a.out; echo $?
63
```

## Observed vs expected

- Observed: uncaught `Failure`, tool crash.
- Expected: the constant decodes to 63 (a `Defined {value: "Specified(63)"}` run).

## Impact

Any translation unit containing `'\?'` (or `"\?"` inside a string
literal reaching this decoder) crashes Cerberus outright. The input is
legal C11; the crash is also an *uncaught exception* rather than a
diagnostic.

## Proposed remedy

One arm in the simple-escape section of `decode_character_constant_aux`:

```ocaml
  | "\\?"   -> Z.of_int 63
```

(While there: the octal validator at decode.ml:188-191 accepts character
codes 48..56 = `'0'..'8'` — `'8'` is not an octal digit, so `'\8'` (a
constraint violation gcc rejects) silently decodes as the value 8.
A separate one-character fix, `48 <= n && n <= 55`.)

## Classification

**TRUE BUG.** `\?` is in the C11 simple-escape grammar; the surrounding
table clearly intends to enumerate exactly that grammar (it carries the
§5.2.2#2 citation) and simply misses one entry. The failure mode
(uncaught exception) is a secondary robustness bug of the same function.

## Provenance

Found by the arc-14 "immaculate pass" differential campaign of our
Lean port (targeted decode-edge tests, S0 baseline 2026-08-22); the
Lean side now decodes `\?` to 63 as a documented deliberate divergence
from the oracle (tests/immaculate/nolibc/g5-decode-question.c pins the
three-way verdict).

[2026-08-30 update: the `\?` = 63 pin is now also confirmed by an
oracle-independent instrument — the gcc second-oracle differential
lane runs g5-decode-question as `AGREE gcc=63 lean={63}`: gcc-compiled
native execution sides with the Lean semantics against the OCaml
oracle, by instrument rather than by hand. Record:
`lean_frontend/docs/2026-08-30_gcc-oracle-lane-record.md` (headline
run, "mechanical referee" bullet).]

## Addendum (2026-09-05): the string-literal form `"\?"` reaches the same decoder and crashes the same way

The character-constant form above is one of two entry points into
`decode_character_constant`; string literals are decoded by the same
function from the elaboration (`ocaml_frontend/generated/translation.ml:3029`
on master @ `b9aeedcb4`, `translate_expression`'s string-literal arm), so
`"\?"` inside a string literal crashes the tool identically. Reproducer
`tests/noodle-probes/ptr/ptr_string_literals.c` in our tree (string-literal
concatenation and escapes, incl. `const char *e = "\n\t\\\"\'\?";`):

```
$ cerberus --nolibc --exec --batch --mode=exhaustive ptr_string_literals.c   # exit 125
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: ?")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Decode.decode_character_constant in file "ocaml_frontend/decode.ml", line 218, characters 8-43
          Called from Cerb_frontend__Translation.translate_expression.(fun) in file "ocaml_frontend/generated/translation.ml", line 3029, characters 37-77
```

(verbatim head, 2026-09-05, un-forked upstream binary + runtime @
`b9aeedcb4`; the fork's oracle at `928aa1e76` fails identically, at
`translation.ml:3032` in its own generated file.)

```
$ gcc -std=c11 -O0 ptr_string_literals.c && ./a.out
98 65 66 4 83 52 3 10 9 92 34 39 63 0 4
```

(gcc 13.3.0; verbatim 2026-09-05. Our Lean port, which decodes `\?` as
63, prints the same line byte for byte.) The one-arm remedy above fixes
both entry points, since they share the decoder.
