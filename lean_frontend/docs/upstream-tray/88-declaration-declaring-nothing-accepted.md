# A declaration that declares nothing is accepted

**Affected:** `frontend/model/cabs_to_ail.lem` @ `c3ff8c53f`: :5245-5255 (file scope, an empty declarator list) and :4156-4162 (block scope).

## Description

C17 6.7#2: a declaration other than a static assertion shall declare at least a declarator, a tag, or the members of an enumeration.

## Reproducers

```c
static int; int main(void) { const long; return 0; }
```

Upstream: `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0 (warns).

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W11; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
