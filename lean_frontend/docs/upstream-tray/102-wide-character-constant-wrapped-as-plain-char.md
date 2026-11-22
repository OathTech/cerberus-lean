# A prefixed character constant is evaluated as a plain `char` constant: `L'\xff'` is -1

**Affected:** `frontend/model/translation.lem` @ `c3ff8c53f`, :207-209 (`A.ConstantCharacter (_, str)` evaluates
`Decode.decode_character_constant str`, the prefix ignored); `frontend/model/cabs_to_ail.lem` :1523 (the same
decoder for the constant evaluator); `ocaml_frontend/decode.ml` :204-218 (the decoder wraps its result into the range
of plain `char`).

## Description

C17 6.4.4.4#11 gives a wide character constant the type `wchar_t` and, for a single character, the value of that
character in the extended execution character set; the wrap into plain `char`'s range (6.4.4.4#10, the conversion of
a `char` object's value to `int`) belongs to unprefixed constants only. The decoder applies it to every character
constant, so with signed plain `char` a wide constant above `\x7f` is negative.

## Reproducer

```c
int main(void) { return (L'\xff' == 255 ? 1 : 0) + (L'\xff' > 0 ? 2 : 0) + (L'a' == 97 ? 4 : 0); }
```

Upstream: `Defined {value: "Specified(6)", stdout: "", stderr: "", blocked: "false"}`: `L'\xff' == 255` is false.
gcc 13: 7.

(Measured 2026-11-22 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @
`c3ff8c53f`.)

## Fork status

Unchanged in the fork: the oracle answers 6 under the default implementation profile, and the fork's pre-merge
review of 2026-11-22 measured the comparison false on both of its engines. Related: report 62
(`wchar_t`'s range and representation), report 63 (multi-character and UTF-8 constants).
