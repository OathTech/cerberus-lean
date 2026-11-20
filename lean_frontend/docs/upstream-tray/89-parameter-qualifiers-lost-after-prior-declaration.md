# A parameter's qualifiers and `register` are lost when the function was declared earlier

**Affected:** `frontend/model/ail/ailTypesAux.lem:949-952` @ `c3ff8c53f`: the composite parameter is `(no_qualifiers, ty, false)`; reached from `make_composite_fdecl` (`cabs_to_ail_aux.lem:208`), and the body's bindings are built from the composite (`ail/genTyping.lem:2347-2350`).

## Description

C17 6.5.16#2 (assignment to a const-qualified object) and 6.5.3.2#1 (address of a register object) are constraint violations; they are diagnosed without the earlier declaration.

## Reproducers

```c
void f(const int x); void f(const int x) { x = 1; } int main(void) { f(1); return 0; }
```

Upstream: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} (without the first declaration: `error: constraint violation: expression is not assignable`). gcc: rejects.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W13; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
