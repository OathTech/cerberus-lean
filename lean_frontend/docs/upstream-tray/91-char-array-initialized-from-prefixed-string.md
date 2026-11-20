# A character array is initialized from a wide string literal

**Affected:** `frontend/model/cabs_to_ail.lem:3828` @ `c3ff8c53f`: the prefix is bound to `_` and the characters rebuilt as narrow ones (:3840-3847).

## Description

C17 6.7.9#14: an array of character type may be initialized by a character string literal or UTF-8 string literal; a wide literal is a constraint violation.

## Reproducers

```c
char s[] = L"ab"; int main(void) { return sizeof s; }
```

Upstream: `Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}`. gcc: rejects.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W15; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
