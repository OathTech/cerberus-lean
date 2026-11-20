# Every `#pragma` line is skipped by the lexer; a `#pragma` on the last line is a parse error

**Affected:** `parsers/c/c_lexer.mll:497-498` @ `c3ff8c53f`: `| ("pragma" [^ '\n']* '\n') { new_line lexbuf }`; :499-500 raises `Cparser_unexpected_eof` when the line has no newline (the preprocessed text is joined without a final one, `backend/common/pipeline.ml:171`).

## Description

C17 6.10.6#1 lets an implementation ignore a pragma it does not recognise, so the skip is permitted. It is silent for the pragmas a program's layout depends on (`#pragma pack`, also through `_Pragma`), where a diagnostic would tell the user that the answer is not the ABI's.

## Reproducers

Pack:

```c
#pragma pack(1)
struct S { char c; int i; }; int main(void) { return sizeof(struct S); }
```

Upstream: `Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}`. gcc: 5.

Last line:

```c
int main(void) { return 0; }
#pragma foo
```

Upstream: `error: unexpected end of file`. gcc: 0.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W1; §2.3 C8; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged: upstream's judgement stands (the standard's rule covers it). Reported so that the choice is recorded; a warning for `pack` would cost one lexer rule.
