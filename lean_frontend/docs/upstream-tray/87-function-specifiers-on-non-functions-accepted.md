# `inline` and `_Noreturn` are accepted on objects, parameters and typedefs

**Affected:** `frontend/model/cabs_to_ail.lem` @ `c3ff8c53f`: `function_specifiers` is read only on the function paths (:3989-3990, :5167-5168, :5280-5281).

## Description

C17 6.7.4#2: function specifiers shall be used only in the declaration of an identifier for a function. Also unchecked: `inline int main(void)` (6.7.4#4) and a modifiable static object in an inline definition (6.7.4#3).

## Reproducers

```c
_Noreturn int x; inline int y; int main(void) { return x + y; }
```

Upstream: `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0 (warns).

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W10; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
