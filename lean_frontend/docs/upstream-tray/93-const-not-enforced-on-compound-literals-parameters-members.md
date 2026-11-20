# Modifying a const compound literal, parameter or struct member is not detected

**Affected:** `frontend/model/translation.lem` @ `c3ff8c53f`: :2973-2977 (the compound literal's store is always `Caux.pstore`), :934-975 (arguments), :4303/:4508 (only the outermost object's qualifiers decide the lock).

## Description

C17 6.7.3#6: modifying an object defined with a const-qualified type through a non-const lvalue is undefined. Cerberus reports `UB064_modifying_const` for a plain local or global and not for these three.

## Reproducers

```c
int main(void) { const int *p = &(const int){1}; *(int *)p = 2; return *p; }
```

Upstream: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"} (for `const int c = 1; *(int *)&c = 2;`: `UB064_modifying_const`). gcc: 2.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W18; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
