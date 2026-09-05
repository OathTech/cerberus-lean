# `atexit` handlers do not run when `main` returns (they do run on `exit()`)

**Affected:** `frontend/model/driver.lem:1303-1311` (`prepare_exit`) and
`:1328-1333` (`Step_done2 cval`: the value returned by `main` ends the
program directly); `runtime/libc/src/stdlib.c:146-227` (the `atexit`
machinery: `__funcs_on_exit` :158-166, `__cxa_atexit` :168-192, `atexit`
:197-200, and `exit` :223-227 which is the ONLY caller of
`__funcs_on_exit`). Checked against `master` @ `b9aeedcb4`: `stdlib.c`
byte-identical; `driver.lem` differs from master only by Lean-target
`declare` lines outside the cited region (master's line numbers).

## Description

ISO C11 §5.1.2.2.3: "If the return type of the `main` function is a type
compatible with `int`, a return from the initial call to the `main`
function is equivalent to calling the `exit` function with the value
returned by the `main` function as its argument". §7.22.4.4#3: `exit`
calls the functions registered with `atexit`, in reverse order of
registration. The shipped libc implements the second part (stdlib.c:223-227
`exit` → `__funcs_on_exit`), but the driver implements return-from-`main`
as "stop here and report the value" (`Step_done2` → `prepare_exit`), so
the library's `exit` is never reached and the registered handlers never
run. (The same path is why buffered stdout is not flushed — companion
report.)

## Reproducer

`tests/noodle-probes/lib/lib_atexit_order.c`:

```c
#include <stdlib.h>
#include <stdio.h>
void h1(void) { printf("1"); }
void h2(void) { printf("2"); }
int main(void) { atexit(h1); atexit(h2); printf("m"); return 4; }   /* "m21", exit 4 */
```

```
$ cerberus --exec --batch --mode=exhaustive lib_atexit_order.c
Defined {value: "Specified(4)", stdout: "m", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`,
shipped libc; the fork's oracle at `928aa1e76` and our Lean port print
the identical line.)

```
$ gcc -std=c11 -O0 lib_atexit_order.c && ./a.out; echo " $?"
m21 4
```

(gcc 13.3.0; verbatim stdout `m21`, exit 4; 2026-09-05.) Control
`lib/lib_atexit_exit_control.c` (same handlers, `exit(4)` instead of
`return 4`, one handler registered): all three Cerberus engines and gcc
print `m1` — on the `exit()` path the handlers DO run.

## Observed vs expected

- Observed: `stdout: "m"`, handlers skipped on return from `main`.
- Expected: `m21` (reverse registration order), value 4.

## Impact

Any program relying on `atexit` for its final output, cleanup, or result
reporting (a common test-harness pattern: register a summary printer,
return from `main`) behaves differently from every hosted implementation;
the difference is silent (no diagnostic, the value is right, the side
effects are missing).

## Proposed remedy

When the C library is linked, have the driver's return-from-`main` call
the library's `exit(ret)` (either from the `Step_done2` path or by
emitting the call in the elaborated `main` wrapper, `translation.lem`'s
`main`-wrapping code) so that §5.1.2.2.3 holds by construction:
`atexit` handlers run, streams are flushed, and `exit`'s own `_Exit` →
`__builtin_exit` reaches `prepare_exit` with the status. In `--nolibc`
mode there is no `atexit`, so the current path is right there.

## Classification

**TRUE BUG.** The library implements `atexit`/`exit` correctly; the
driver's termination path bypasses it, contradicting §5.1.2.2.3 on
conforming input.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding L4); both engines agree, gcc differs. Re-verified 2026-09-05 on
the un-forked upstream binary + runtime @ `b9aeedcb4`, the fork's oracle
and the Lean port (lines above verbatim). Localisation and this draft by
Claude (Fable 5.1) under operator direction; the filed issue carries an
AI-provenance note per the tray's policy.
