# A redeclaration with an incomplete array type replaces the complete one

**Affected:** `frontend/model/cabs_to_ail_effect.lem:2381-2384` @ `c3ff8c53f` (`TODO: what about ty' ??`): the composite type is computed and the later declaration's type is stored.

## Description

C17 6.2.7#4: an identifier redeclared in a scope where a prior declaration is visible has the composite type.

## Reproducers

```c
int a[3]; extern int a[]; int main(void) { return sizeof a; }
```

Upstream: `error: constraint violation: invalid application of 'sizeof' to an incomplete type 'array  of signed int'`. gcc: 12.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.3 C6; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork: the program is valid C and the fork stops on it exactly as upstream does (nothing is refused or repaired).
