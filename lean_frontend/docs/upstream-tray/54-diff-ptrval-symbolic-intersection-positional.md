# PNVI-ae-udi: diff_ptrval symbolic/symbolic intersection is positional, misses a shared allocation

**Switch:** `--switches=PNVI_ae_udi`.

**Site:** `memory/concrete/impl_mem.ml:2063-2105` (`diff_ptrval`, `(Prov_symbolic, Prov_symbolic)` arm), the `Double`/`Double` case at :2081-2090.

(Line numbers are the cerberus-lean fork's tree; in pristine upstream `b9aeedcb4` the arm's comment is at
`:2020` and `find_overlaping` starts at `:761`.)

## Reproducer

`tests/pnvi_arms/a12-diff-symbolic-double-double-positional.c` (the fork's lane row `arm/a12-…`). Globals `y, x, z` are adjacent with descending addresses; `r = (int*)(uintptr_t)(&x+1)` has A(r)={y,x}; `s = (int*)(uintptr_t)(&z+1)` has A(s)={x,z}; `return (int)(r - s);`.

```c
// PNVI arms witness a12 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: diff_ptrval's
// (Prov_symbolic, Prov_symbolic) arm (impl_mem.ml:2063-2105), the `Double`/`Double` case with
// no positional match (:2081-2090): three adjacent exposed globals y > x > z give
// A(r) = {y, x} and A(s) = {x, z}; the intersection is computed POSITIONALLY (x1 = y1, x2 = y2),
// so the shared x is not found and the subtraction is error_postcond. MIRRORED, not judged
// ([USER 2026-10-03] no innovation vs upstream). Expected under the switch: Undefined UB048.
#include <stdint.h>
int y = 2, x = 1, z = 3;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  uintptr_t k = (uintptr_t)(&z + 1);
  uintptr_t l = (uintptr_t)&x;
  if (i != j || k != l) return 1;
  int *r = (int *)i;
  int *s = (int *)k;
  return (int)(r - s);
}
```

## Observed

`Undefined {ub: "UB048_disjoint_array_pointers_subtraction", …}` at `r - s`.

Verbatim (`--exec --batch --mode=exhaustive --switches=PNVI_ae_udi`; the same line from pristine upstream
`b9aeedcb4` and from the fork's oracle, MEASURED 2026-10-08):

```
Undefined {ub: "UB048_disjoint_array_pointers_subtraction", stderr: "", loc: "<18:15--18:22>"}
```

## Expected

A(r) ∩ A(s) = {x}. Per the arm's own comment (:2064, "IF A(iota1) INTER A(iota2) = { i } AND precond valid THEN collapse iota1 and iota2 to i"), both iotas collapse to x, so the result is `Defined 1`. Cross-check: collapsing each pointer to x first via a mixed subtraction makes `r - s` evaluate to 1.

(Cross-check measured 2026-10-08 [AGENT]: the same program with `int d1 = (int)(r - &x); int d2 = (int)(s - &x);`
before `return (int)(r - s) + 10 * d1 + 20 * d2;` gives `Defined {value: "Specified(11)", …}` on pristine
`b9aeedcb4` and on the fork's oracle, i.e. `r - s` = 1.)

## Cause

`find_overlaping` (:796-875) orders a `DoubleAlloc` by ascending allocation id. The shared allocation is therefore the SECOND candidate of r's iota and the FIRST of s's. The intersection at :2081-2090 compares only `x1 = y1` and `x2 = y2`, never the crossed pairs, so it returns `None` and takes `error_postcond`.

## Fork status

Lean mirrors this behaviour, per the no-innovation rule ([USER 2026-10-03]); the fork's lane row `arm/a12-…` is
`AGREE`. Reports only; no patch.

## Classification

TRUE BUG (the arm disagrees with its own stated specification), C-reachable under `--switches=PNVI_ae_udi`.

## Provenance

Found while writing the fork's PNVI arm-witness rows (record
`lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md` §5); drafted 2026-10-08 by Claude (Opus 5.5)
under operator direction; AI-provenance note per the tray's policy. Duplicate search: none done (no network at
drafting); repeat before filing.
