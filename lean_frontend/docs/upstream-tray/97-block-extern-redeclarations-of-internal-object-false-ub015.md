# Two block-scope `extern` redeclarations of one internal-linkage object are reported as UB015

**Affected:** `frontend/model/cabs_to_ail_effect.lem` @ `c3ff8c53f`: a block-scope `extern` declaration of an identifier
that has internal linkage at file scope is registered through `register_internal_object_declaration` under the file-scope
object's own symbol; a second such declaration in another function meets the first and takes the
`undef loc Undefined.UB015_incompatible_redeclaration` arm (`if decl <> decl'`, whose own comment calls the code
unreachable because redeclaration of internal objects is caught earlier).

## Description

C17 6.2.2#4: an `extern` declaration in a scope where a prior declaration with internal linkage is visible has that
linkage; any number of them is permitted, and both name the one object. The program below is defined; Cerberus reports
undefined behaviour.

## Reproducers

```c
static int e; int f(void) { extern int e; return e; } int main(void) { extern int e; return e + f(); }
```

Upstream: `Undefined {ub: "UB015_incompatible_redeclaration", stderr: "", loc: "<1:83--1:84>"}`. gcc: compiles clean, exits 0.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=c2x -Wall -Wextra -pedantic`. Found by the second look at the fork's attribute slice, `../2026-11-20_attribute-preservation-second-look.md` F9.)

## Fork status

Unchanged in the fork: both engines give upstream's verdict (a false undefined-behaviour verdict on a defined
program; nothing is refused or repaired).
