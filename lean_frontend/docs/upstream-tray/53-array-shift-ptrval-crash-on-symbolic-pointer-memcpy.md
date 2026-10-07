# PNVI-ae-udi: `memcpy` from a symbolic pointer crashes (`array_shift_ptrval found a Prov_symbolic`)

**Affected:** `memory/concrete/impl_mem.ml` `array_shift_ptrval` (upstream `b9aeedcb4`
`:2203-2240`; its arm `:2210-2211` `| Prov_symbolic iota -> failwith "Concrete.array_shift_ptrval
found a Prov_symbolic"`), reached from `memcpy` (`:2635-2646`), which shifts both pointer arguments
with the PURE `array_shift_ptrval` (`:2640-2641`). `memcmp` (`:2649-…`) does the same.

## Reproducer

```c
#include <string.h>
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  int *p = &x + 1;
  int *q = &y;
  uintptr_t i = (uintptr_t)p;
  uintptr_t j = (uintptr_t)q;
  if (i != j) return 1;
  int *r = (int *)i;
  int d = 0;
  memcpy(&d, r, sizeof d);
  return d;
}
```

Fork oracle at merge-base `b9aeedcb4`, `--runtime=… --exec --batch --mode=exhaustive`, 2026-10-07
(the trace's first frames; rc 125):

```
== without --switches
Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<12:3--12:26>"}
== --switches=PNVI_ae_udi
cerberus: internal error, uncaught exception:
          Failure("Concrete.array_shift_ptrval found a Prov_symbolic")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Impl_mem.Concrete.memcpy.aux in file "memory/concrete/impl_mem.ml", line 2684, characters 37-105
```

(`line 2684` is the fork's numbering of upstream `:2640`.) Under the switch the cast `(int *)i`
mints a `Prov_symbolic` (the address is one past `x` and the start of `y`, both exposed).

## Observed vs expected

Observed: a crash. Expected: what an `int` load through `r` gives — the effectful
`eff_array_shift_ptrval` already handles `Prov_symbolic` (resolving or collapsing the iota), so
`memcpy` would behave like the equivalent loop of `char` loads.

## Impact

Any `memcpy`/`memcmp` whose argument is a pointer obtained from an ambiguous integer cast crashes
under PNVI-ae-udi. The pure `array_shift` is also what the default-elaborated libc (`libc.co`) uses
for every pointer `+`, so a symbolic pointer passed into libc C code that indexes it would hit the
same arm.

## Proposed remedy

Use `eff_array_shift_ptrval` (the effectful shift, with its iota handling) in `memcpy`/`memcmp`,
or give `array_shift_ptrval` a symbolic arm that shifts the address and keeps the iota (leaving its
resolution to the access).

## Classification

INTENDED GAP (unimplemented arm), crash-severity; reachable from ordinary C under the switch.

## Provenance

Found by the cerberus-lean PNVI arc's S3 review (finding F2) and reproduced for this draft on
2026-10-07 (PNVI arc S4; the reproducer is the fork's lane witness
`tests/pnvi_refusals/r06-memcpy-symbolic-source.c`). Fork status: cerberus-lean REFUSES at this
arm (refusal R-PNVI-06, [USER 2026-10-05]). Duplicate search: none done (no network at drafting);
repeat before filing.
