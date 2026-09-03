# impl/ — CerberusImpl.lean vs ocaml_implementation.ml DefaultImpl probes (Z2, 2026-09-03)

Engines/binaries as in `../mem/README.md`. Classes [AGENT].

| Probe | Mode | What it tests | fork oracle | upstream | Lean | Class | Proposed lane |
|---|---|---|---|---|---|---|---|
| `int32_uac.c` | nolibc | `int32_t + unsigned int` — reader claim: `CerberusImpl.normalise_integerType:245-252` lacks the `Signed/Unsigned (IntN_t n)` aliasing of `ocaml_implementation.ml:37-54` | `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}` | same | same | AGREE — REFUTES the claim for the `<stdint.h>` route: `runtime/libc/include/stdint.h:11` is `typedef signed int int32_t;`, so `IntN_t` never arises from the headers | exec nolibc MATCH |
| `int32_compat.c` | nolibc | `int32_t x; int *p = &x` (`are_compatible`) | `Specified(5)` | same | same | AGREE (same reason) | exec nolibc MATCH |
| `int32_printf.c` | libc | `printf("%d", int32_t)` (`formatted.lem:417`) | `Defined {value: "Specified(0)", stdout: "7\n", stderr: "", blocked: "false"}` | same | same | AGREE (same reason) | libc_exec MATCH |
| `cerbty_int32_uac.c` | nolibc | the DIRECT spelling `__cerbty_int32_t` (= `Signed (IntN_t 32)`, `builtins.lem:14`) mixed with `unsigned int` | `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}` | same | exit 134 `PANIC at _private.LemLib.0.failwithIImpl LemLib:158:2: AilTypesAux.le_integer_range: internal error` | **BUG-FIX, CONFIRMED** on the direct spelling: `ailTypesAux.lem:302-303`'s `(Signed (IntN_t _), _) -> fail ()` arms are "inaccessible because of the normalisation" only if `normalise_integerType` aliases `IntN_t 32` → `Signed Int_` (`ocaml_implementation.ml:39-40,155-160`); Lean's does not. Reachability: any program spelling `__cerbty_intN_t`/`__cerbty_int_leastN_t`/`__cerbty_int_fastN_t`/`__cerbty_intmax_t`/`__cerbty_intptr_t` directly (the shared headers alias them to plain types, so ordinary C is unaffected — hence the green corpora) | immaculate DIFF pair (Lean pin `CRASH`) → MATCH after the fix |

Derived: 4 runs; 1 LEAN≠ORACLE (crash vs value), 3 AGREE (one reader claim refuted on its stated route, confirmed on the direct-spelling route).
