# `return e;` in a `_Noreturn` function reports UB071 without evaluating `e`

**Affected:** `frontend/model/translation.lem` @ `c3ff8c53f`, the `A.AilSreturn e` arm (:4102-4103): `if env.is_Noreturn then E.return (Caux.mk_pure_e (Caux.mk_std_undef_pe loc "§6.7.4#8" Undefined.UB071_noreturn))`, before `translate_expression`.

## Description

C17 6.7.4#8: a function declared `_Noreturn` has undefined behaviour if it returns to its caller. A `return` whose operand never completes (a call to a function that exits or does not return) does not return to the caller; the tail-call idiom is conforming.

## Reproducers

The operand exits (libc mode):

```c
#include <stdlib.h>
int g(void) { exit(3); return 0; } _Noreturn int f(void) { return g(); } int main(void) { f(); return 0; }
```

Upstream: `Undefined {ub: "UB071_noreturn", stderr: "", loc: "<2:60--2:71>"}`. gcc: 3.

The operand is itself undefined:

```c
int zero = 0; _Noreturn int f(void) { return 1 / zero; } int main(void) { f(); return 0; }
```

Upstream: `Undefined {ub: "UB071_noreturn", stderr: "", loc: "<1:39--1:55>"}` (the division is never reached). gcc: signal.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W17; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

FIXED: the operand is elaborated and bound first, and the UB071 follows it, so it fires exactly when control would come back (`tests/libc_exec/044-noreturn-return-operand-exits.c`: `Specified(3)` on both engines; a function that really returns is still UB071).

## Patch

Commit `4b260827c`, in the `env.is_Noreturn` branch: `translate_expression true e >>= fun core_e -> E.wrapped_fresh_symbol bTy >>= fun e_wrp -> E.return (Caux.mk_sseq_e e_wrp.E.sym_pat core_e (Caux.mk_pure_e (Caux.mk_std_undef_pe loc "§6.7.4#8" Undefined.UB071_noreturn)))`, with `bTy` computed as the arm below computes it.
