# A block-scope typedef accepts an alignment specifier and an initializer

**Affected:** `frontend/model/cabs_to_ail.lem:3972-3975` @ `c3ff8c53f` (the typedef arm of `desugar_declaration_base`); the file-scope arm checks both (:3048-3049, :3064-3065).

## Description

C17 6.7.5#2 (no alignment specifier in a typedef) and 6.7.9 (an initializer initializes an object): constraint violations, diagnosed at file scope and accepted in a block.

## Reproducers

```c
int main(void) { typedef int T = 3; typedef _Alignas(8) char U; T x = 0; return x; }
```

Upstream: `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`. gcc: rejects.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W9; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork (an invalid program is accepted; nothing is refused or repaired).
