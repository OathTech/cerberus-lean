# Excess initializers and out-of-range array designators are accepted and discarded

**Affected:** `frontend/model/desugaring_init.lem` @ `c3ff8c53f`: :353-355 (`TODO: ... array designator is larger than array`), :501-505 (the element is not inserted when the cursor overflows).

## Description

C17 6.7.9#2: no initializer shall attempt to provide a value for an object not contained within the entity being initialized. The excess expression is not evaluated either.

## Reproducers

```c
int main(void) { int a[2] = {1, 2, 3}; int b[2] = {[5] = 1}; return a[1] + b[0]; }
```

Upstream: `Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}`. gcc: rejects (the designator).

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W16; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
