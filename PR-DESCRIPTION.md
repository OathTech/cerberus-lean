# Fix character-escape decoding/encoding in `ocaml_frontend/decode.ml`

This PR fixes three related defects in the character-escape handling of
`decode_character_constant` / `escaped_char`, each with a self-checking CI
test. Two are user-visible (a crash on conforming input, and silent data
corruption on the `*printf` path); the third is an internal off-by-one in
the octal validator.

## 1. Missing `\?` simple escape (tool crash on conforming input)

The C11 grammar lists `\?` among the simple-escape-sequences
(§6.4.4.4#1), and §6.4.4.4#3–4 give it the value of `?` — 63 under the
ASCII mapping this file implements (it exists so trigraph-era code can
write `?`-safe strings).
The C lexer (`parsers/c/c_lexer.mll`) accepts it, but
`decode_character_constant_aux` had no arm for it: the constant fell
through to the octal reader and the whole tool died with an uncaught
exception.

Before:

```
$ cerberus --exec --batch --nolibc q.c     # int main(void){ return '\?'; }
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: ?")
```

After: `Defined {value: "Specified(63)", ...}` — matching gcc/clang
(`gcc -std=c11 q.c && ./a.out; echo $?` prints 63).

## 2. `escaped_char`/decoder round-trip corrupts stored chars (127 → 87)

`store_chars_in_array()` in `frontend/model/formatted.lem` — the path by
which every char produced by the `*printf` builtins is written to memory —
round-trips each char through
`Decode.decode_character_constant (Decode.escaped_char c)`.

`escaped_char` was OCaml's `Char.escaped`, which renders chars without a
symbolic escape in OCaml's **decimal** `\DDD` notation (e.g. `'\127'` →
`"\\127"`). The decoder only speaks C escape syntax, where `\DDD` is
**octal** (§6.4.4.4#1), so such chars were silently corrupted
(`"\127"` → 0o127 = 87, 153 → 107, …), and chars whose decimal rendering
contains a `9` crashed the tool outright (`"\129"` fails the octal
validator → uncaught `Failure`). Chars with symbolic escapes (`\n`, `\t`,
…) and printable chars round-trip fine, which is why common tests never
noticed.

Before:

```
$ cerberus --exec --batch r.c   # snprintf(buf, 8, "%c", 127); return buf[0];
Defined {value: "Specified(87)", stdout: "", stderr: "", blocked: "false"}
```

(gcc returns 127.) With 129 instead of 127, the tool crashed with an
uncaught `Failure`.

After: 127 stays 127, 129 stays 129 (both matching gcc).

Fix: make `escaped_char` emit C octal escapes (`\%03o`) for chars outside
the printable/symbolic set, so the pair is actually an encode/decode
inverse. Fixing the emission side keeps the decoder exactly the C escape
grammar (the honest alternative — storing `Char.code c` directly and
skipping the string detour — would touch the Lem model and generated
code; this one-function change in the same file as the decoder is
minimal and equivalent).

## 3. Octal validator accepts `'8'` (off-by-one)

The decoder's octal-escape validator accepted digit characters `'0'..'8'`;
octal-digit is one of `0..7` (§6.4.4.1#1, referenced by the escape
grammar in §6.4.4.4#1). This is not observable from C
source — the lexer already enforces the escape grammar, so `'\8'` is
rejected with a proper diagnostic before reaching the decoder — but until
item 2 it was reachable via `escaped_char`'s decimal output (e.g. char 138
→ `"\138"` "validated" as octal and misdecoded), and independently the
validator should implement the grammar it cites. One-character fix:
`n <= 56` → `n <= 55`, plus a comment marking the branch as the
§6.4.4.4#1 octal case (mirroring the hex branch above it).

## Tests

Three new self-checking tests in the CI suite (each `return`s 0 on
success, with a distinct non-zero code identifying the failing check;
all three also compile and exit 0 under `gcc -std=c11 -Wall`):

- `tests/ci/0342-escape_question.c` — `'\?'` and `"\?"` decode to 63.
- `tests/ci/0343-snprintf_nonprintable_char.c` — `%c` stores 127, 129,
  11, 255, `\n`, `'a'` unchanged (calls `__builtin_vsnprintf` directly
  since the CI lane runs `--nolibc`).
- `tests/ci/0344-octal_escape_boundary.c` — valid octal escapes still
  decode correctly at the boundaries (`\0`, `\7`, `\10`, `\377`,
  maximal-munch `"\1770"`).

Run with:

```
cd tests
./run-ci.sh                                   # full lane
./run-ci.sh 0343-snprintf_nonprintable_char.c # single test
```

Without the fixes: 0342 crashes (uncaught `Failure`), 0343 returns 1
(127 read back as 87), 0344 passes (regression guard for the validator
tightening). With the fixes all three pass, and the rest of the CI lane
is unchanged relative to the base commit (verified by running
`./run-ci.sh` on both and diffing the results).

The rest of `decode.ml` was checked for adjacent defects: every other
C11 simple escape has an arm, the hexadecimal path validates correctly,
and `encode_character_constant`'s `Z.to_int` only ever receives
char-range values from its callers. Possibly related: #154 reports
`'\xFF'` decoding to 255 instead of -1 under signed char, but the
current `wrapI` in `decode_character_constant` appears to have fixed
that already (`'\xFF' == -1` evaluates true at the base commit) — that
issue may be closable independently of this PR.

## Provenance

These defects were found, and this patch (code, tests, and this
description) was written, by an AI assistant (Anthropic's Claude) under
human direction, as part of a project that differentially tests
Cerberus against a Lean port of its semantics. It is submitted after
review and validation by the human author.
