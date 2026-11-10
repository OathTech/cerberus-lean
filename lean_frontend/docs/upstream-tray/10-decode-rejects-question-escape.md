# `decode_character_constant` rejects the standard `\?` escape (tool crash)

**Status (cerberus-lean fork):** fixed in the fork on 2026-11-07 as a fork-ahead delta (the oracle's `decode.ml`
gains the `\?` arm; the Lean engine carried it since 2026-09-03 under the fork's ISO-fix register row R1, now retired;
record `lean_frontend/docs/2026-11-07_half-mirrors-oracle-record.md`; witness `scripts/check_half_mirrors.sh`, ladder
row 1); Sent upstream (communicated privately, 2026-09-26), no public issue URL. The patch at the end is against
`rems-project/cerberus` at `c3ff8c53f` (`git apply --check` in the pristine checkout: OK, 2026-11-07); upstream's tip
carries the same text in the cited region (the true-bug audit of 2026-11-04 re-observed the crash at `ae70925fc`).

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
codes 48..56 = `'0'..'8'` — `'8'` is not an octal digit. Correction
2026-11-07: `'\8'` is NOT reachable from source — the lexer's
`octal_escape_sequence` (`parsers/c/c_lexer.mll:411-414`) takes octal digits
only, so `'\8'` is rejected as an invalid symbol before the decoder runs.
The off-by-one was reachable only through `escaped_char`'s decimal
rendering of a stored byte (report 11: `Char.escaped 18 = "\\018"` decoded
as 16), which report 11's fix removes; it is then a dead quirk, and the
one-character fix `48 <= n && n <= 55` is tidy-up only.)

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

## Fork status and patch (2026-11-07)

Fixed in the fork on 2026-11-07 ([USER 2026-11-04] agreed the fix pass under the standing bar — a fork fix only
where the standard is very clear, no invented semantics; the standard's text here is the simple-escape-sequence
grammar itself). Before and after, verbatim (the fork's oracle at `1e5f2cbca` = pristine `c3ff8c53f`, then the fixed
tree; `--exec --batch --nolibc`; gcc 13.3.0 `-std=c11 -w -O0`):

```text
$ cerberus --nolibc --exec --batch t10_char.c          # int main(void) { char c = '\?'; return c; }
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: ?")     (rc 125, before)
Defined {value: "Specified(63)", stdout: "", stderr: "", blocked: "false"}                       (rc 0, after; = the Lean engine byte for byte; gcc exit 63)
$ cerberus --nolibc --exec --batch t10_str.c           # int main(void) { const char *s = "a\?b"; return s[1]; }
          Failure("decode_character_constant, started like an octal constant, but failed: ?")     (rc 125, before)
Defined {value: "Specified(63)", stdout: "", stderr: "", blocked: "false"}                       (rc 0, after; gcc exit 63)
```

The patch (the one arm; the comment is the fork's registration note and may be dropped):

```diff
--- a/ocaml_frontend/decode.ml
+++ b/ocaml_frontend/decode.ml
@@ -152,6 +152,15 @@
   | "\\r"   -> Z.of_int 13
   | "\\t"   -> Z.of_int 9
   | "\\v"   -> Z.of_int 11
+  (* FORK FIX (2026-11-07, upstream-tray report 10; a fork-ahead delta, registered in
+     scripts/fork_drift_manifest.txt): C17 6.4.4.4#1 lists \? among the simple-escape-sequences
+     (beside the two quote escapes and the backslash escape above) and #4 gives it the value of
+     the character it names, the question mark, 63; gcc 13 agrees. Upstream has no arm, so the catch-all below routes it into the octal
+     validator and the tool dies on an uncaught Failure on strictly conforming C -- through
+     both entry points, the character constant (translation.lem translate_constant) and the
+     string literal (translation.lem's AilEstr arm), which share this decoder. The Lean
+     engine's CerbDecode.decode_character_constant_aux carries the same arm. *)
+  | "\\?"   -> Z.of_int 63
 
   (* NOTE: here are the (graphical) extended characters from ASCII *)
   | "$"     -> Z.of_int 36
```

## Re-run at `c3ff8c53f` (2026-11-10): still reproduces on pristine; two neighbours in the same decoder

(Un-forked upstream binary + runtime @ `c3ff8c53f`, both fork engines and gcc 13.3.0 `-std=c11 -w -O0`, all run on 2026-11-10; outputs verbatim. [AGENT 2026-11-10], the reporting slice.)

`'\?'` and `"\?"` still die on pristine upstream with `Failure("decode_character_constant, started like an octal
constant, but failed: ?")` (exit 125; gcc exits 63 for both; the fork's engines answer 63 since 2026-11-07). Two
neighbours reach the same catch-all (`ocaml_frontend/decode.ml:197` at `c3ff8c53f`) and are not fixed in the fork:

- Universal character names (C17 6.4.3) — filed under report 63, which owns the non-ASCII decoding:
  `int main(void) { return (unsigned char)'\u00e9'; }` dies with `… but failed: u00e9`.
- An octal escape followed by a digit: `'\0123'` is read as ONE four-digit octal escape.

```c
int main(void) { return (unsigned char)'\0123'; }
```

```
$ cerberus --nolibc --exec --batch esc_char_oct0123.c
Defined {value: "Specified(83)", stdout: "", stderr: "", blocked: "false"}
```

  (gcc exits 51.) C17 6.4.4.4#1: an octal escape sequence has at most three octal digits, so the constant is the
  two-character constant `'\012' '3'`, whose value is implementation-defined (#10; gcc's is the last character, 51);
  83 is octal 0123. Silent, on a rare spelling; both fork engines print the same line.
