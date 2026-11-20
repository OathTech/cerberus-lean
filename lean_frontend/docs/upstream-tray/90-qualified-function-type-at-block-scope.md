# A qualified function type declared at block scope is accepted (UB066 missed)

**Affected:** `frontend/model/cabs_to_ail.lem:3978-3997` @ `c3ff8c53f` (`do_function` never reads `qs`); the file-scope arm reports it (:5271-5272).

## Description

C17 6.7.3#9: a function type specified with qualifiers is undefined behaviour; Cerberus reports `UB066_qualified_function_specification` at file scope only.

## Reproducers

```c
typedef int F(void); int main(void) { const F g; return 0; }
```

Upstream: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} (the file-scope form: `UB066_qualified_function_specification`). gcc: 0.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W14; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
