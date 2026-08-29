# `memcmp` with a huge size crashes the tool (uncaught `Z.Overflow`)

**Affected:** `memory/concrete/impl_mem.ml:2660` (`Concrete.memcmp`;
checked against `master` @ `b9aeedcb4` — the fork-drift manifest pins our
memory/concrete tree byte-identical to it on this file's surface, and the
cited line is upstream's own `Z.to_int size_n`).

## Description

`memcmp`'s concrete implementation converts the size argument with
`Z.to_int`:

```ocaml
     get_bytes ptrval1 [] (Z.to_int size_n) >>= fun bytes1 ->   (* :2660 *)
```

`Z.to_int` RAISES `Z.Overflow` for values outside the OCaml `int` range.
A C program can pass any `size_t` value — e.g. `(size_t)-1` = 2^64−1.
Reading past the object is UB, so a UB verdict would be fine; instead the
tool dies with an internal error before any semantic judgment.

## Reproducer

```c
#include <string.h>
int main(void) {
  char a[4] = {1,2,3,4};
  char b[4] = {1,2,3,4};
  return memcmp(a, b, (size_t)-1);
}
```

```
$ cerberus --exec --batch m.c
cerberus: internal error, uncaught exception:
          Z.Overflow
          Raised by primitive operation at Z.to_int in file "z.ml", line 221, characters 46-56
          Called from Cerb_frontend__Impl_mem.Concrete.memcmp in file "memory/concrete/impl_mem.ml", line 2660, characters 26-43
```

(verbatim, 2026-08-22, our build; the memcmp path and cited line are
upstream's.)

## Observed vs expected

- Observed: uncaught `Z.Overflow`, tool crash.
- Expected: a UB verdict — the per-byte read leaves the 4-byte object at
  offset 4, e.g. `Undefined {ub: "UB_CERB002a_out_of_bound_load", ...}`
  (that is precisely what our Lean port's checked per-byte loop reports
  for this program: the recursion kills at the first out-of-bounds load
  long before any count-dependent conversion matters).

## Impact

Any evaluated `memcmp` (and by the same `Z.to_int`-on-size shape,
sibling paths worth auditing — see remedy) whose size argument exceeds
`max_int` crashes Cerberus with an internal error on a program whose
misbehavior the tool exists to diagnose. Values like `(size_t)-1` arise
readily from underflowed size computations — exactly the buggy programs
one feeds a UB checker.

## Proposed remedy

Iterate on `Z` (or clamp the loop by the failing load): `get_bytes`
already loads byte-at-a-time through the checked `load`, which reports
the out-of-bounds UB on its own; counting down a `Z.t` instead of an
`int` removes the conversion entirely. More generally, the
`Z.to_int`/`Z.to_int64` family on C-controlled quantities is a crash
class worth a one-pass audit (cf. our report 12, `bswap64`'s
`Z.to_int64`).

## Classification

**TRUE BUG.** The conversion is an implementation detail leaking as a
crash on reachable input; the checked per-byte load machinery
immediately below it already implements the correct (UB-verdict)
behavior for the same program.

## Provenance

Found by professor B′ in the arc-14 S4b re-grade of our Lean port
(hunting residual crash paths after the port's memcmp was re-mirrored
through checked loads); pinned three-way in
tests/immaculate/libc/s4b-memcmp-hugesize.c (lane row ORACLE_CRASH with
the Lean UB token pinned).
