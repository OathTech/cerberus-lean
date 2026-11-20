# A block-scope typedef that shadows a file-scope typedef is treated as a redefinition of it

**Affected:** `frontend/model/cabs_to_ail_effect.lem` @ `c3ff8c53f`, `register_typedef` (:919-963): "if the identifier is
already declared we reuse that existing declaration" (`internal_register_identifier` with a callback that returns the
existing symbol), with no test of the scope the existing declaration is in.

## Description

C17 6.2.1#4: a declaration in an inner scope hides the outer one; the inner `T` is another entity. Cerberus applies the
redefinition rule of 6.7#3 across the scopes: a shadowing typedef of a different type is rejected, and one of the same
type is merged with the outer typedef, its attributes included, so an attribute written on the inner typedef (for
instance upstream's own `cerb::byte`) lands on the outer one.

## Reproducers

A different type:

```c
[[m::a("s")]] typedef int T; int main(void) { [[m::b("t")]] typedef long T; T x = 0; return (int)x; }
```

Upstream: `error: constraint violation: typedef redefinition with different types`. gcc: compiles (one warning, for the unknown attribute) and the program exits 0.

The same type:

```c
[[m::a("s")]] typedef int T; int main(void) { [[m::b("t")]] typedef int T; T x = 0; return x; }
```

Upstream: runs, and `--pp=ail --ast=ail` shows ONE entry for `T` under `AilTypedefAttributes`, carrying both
`m::b("t")` and `m::a("s")`.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=c2x -Wall -Wextra -pedantic`. Found by the second look at the fork's attribute slice, `../2026-11-20_attribute-preservation-second-look.md` F9.)

## Fork status

Unchanged in the fork. The fork's attribute carriage (contract D19) reports what `register_typedef` stores, so a reader
of `typedef_attributes` sees the inner typedef's attributes on the outer entry; the fork's consumer notes say so.
