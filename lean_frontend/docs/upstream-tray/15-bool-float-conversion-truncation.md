# Floating→`_Bool` conversion truncates before the compare-to-zero test (`_Bool b = 0.5` yields 0; non-finite crashes the tool)

**Affected:** `runtime/libcore/std.core:79-92` (`loaded_ivfromfloat`;
checked against `master` @ `b9aeedcb4`; our checkout's
`runtime/libcore/std.core` is byte-identical to it — diff-verified
2026-08-30), together with `memory/concrete/impl_mem.ml:2553-2554`
(`Concrete.ivfromfloat`) and `frontend/model/defacto_memory.lem:1147-1152`
(`impl_ivfromfloat`) — both truncate and both ignore the target integer
type.

## Description

C11 §6.3.1.2#1: "When any scalar value is converted to `_Bool`, the
result is 0 if the value compares equal to 0; otherwise, the result
is 1." The fractional-discard rule for floating→integer conversion
explicitly does NOT apply here — §6.3.1.4#1 opens "When a finite value
of real floating type is converted to an integer type *other than
`_Bool`*, the fractional part is discarded".

`loaded_ivfromfloat` (std.core:79-92) clearly intends §6.3.1.2 — it has
a `_Bool` arm citing it — but it tests the WRONG operand: it truncates
first (`let n: integer = Ivfromfloat(ty, f)`, std.core:82; the concrete
model's `ivfromfloat` is `IV (Prov_none, Z.of_float fval)`,
impl_mem.ml:2553-2554 — round toward zero, target type ignored) and
then guards `if ty = '_Bool' /\ not (n = 0)` (std.core:83) on the
*truncated* value. Every nonzero `f` in (-1, 1) truncates to `n = 0`,
slips past the guard, is representable in `_Bool`, and converts to 0
where ISO requires 1. The existing arm only rescues *large* values
(e.g. 256.0 → 256, unrepresentable in `_Bool`, which would otherwise
hit the UB017 arm below).

Secondary crash in the same expression: for non-finite `f` the
truncation itself is reached before any `_Bool` logic, and zarith's
`Z.of_float` raises `Overflow` on non-finite input — an uncaught
exception that kills the tool on defined-behavior C (§6.3.1.2 gives
inf → 1; only §6.3.1.4's finite rule is inapplicable to non-finite,
and it doesn't govern `_Bool` anyway).

## Reproducer 1 — fractional value

`tests/parity-probes/probes/bool_conv.c` in our tree:

```c
int main(void) {
  _Bool b1 = 0.5;   /* true */
  _Bool b2 = 256;   /* true (not truncation to 0) */
  _Bool b3 = 0;
  return b1 + b2 + b3 + 40;  /* 42 */
}
```

```
$ cerberus --nolibc --exec --batch bool_conv.c
Defined {value: "Specified(41)", stdout: "", stderr: "", blocked: "false"}
```

(verbatim, 2026-08-30, upstream binary + upstream runtime at
`b9aeedcb4` via `CERB_INSTALL_PREFIX`.)

```
$ gcc -std=c11 bool_conv.c && ./a.out; echo $?
42
```

(gcc 13.3.0; verbatim 2026-08-30.) Note `b2 = 256` IS converted
correctly to 1 — the *integer*→`_Bool` path (`conv_int`,
std.core:33-34) tests the untruncated value. The defect is
floating-source only.

## Reproducer 2 — non-finite value (tool crash)

```c
int main(void) { _Bool b = 1e300 * 1e300; return b ? 42 : 7; }
```

```
$ cerberus --nolibc --exec --batch bool_inf.c   # exit 125
cerberus: internal error, uncaught exception:
          Z.Overflow
          Raised by primitive operation at Cerb_frontend__Impl_mem.Concrete.ivfromfloat in file "memory/concrete/impl_mem.ml", line 2554, characters 19-34
```

(verbatim head, 2026-08-30, same upstream build; gcc: exit 42.)

## Observed vs expected

- Observed: `_Bool` from 0.5 is 0 (run yields `Specified(41)`);
  `_Bool` from +inf is an uncaught `Z.Overflow` crash, exit 125.
- Expected: both convert to 1 (`Specified(42)` twice).

## Impact

Any float→`_Bool` conversion of a nonzero value of magnitude < 1
silently yields false — `if ((_Bool)eps)`-shaped guards on small
quantities invert. Non-finite operands (or NaN) crash the tool
outright on a conversion whose C11 result is defined. All memory
models are affected: the defect sits in the shared Core stdlib and in
each model's truncating `ivfromfloat`.

## Proposed remedy

Decide `_Bool` from the *floating* value, before any truncation, in
`loaded_ivfromfloat` (covers every memory model at once):

```
| Specified(f:floating) =>
    if ty = '_Bool' then
      -- STD §6.3.1.2#1: compare the VALUE to zero
      Specified(if f = Fvfromint(0) then 0 else 1)
    else
      let n: integer = Ivfromfloat(ty, f) in
      ...
```

This also fixes reproducer 2 for `_Bool` (the truncation is never
evaluated; a nonzero non-finite compares unequal to 0 → 1).
Non-finite→wider-integer conversions would still reach `Z.of_float`;
guarding `Concrete.ivfromfloat` against non-finite input (UB017 arm
rather than an uncaught `Z.Overflow`, cf. the `Z.to_int64` crash class
of our bswap64 report) is a natural companion fix but a separable one.

## Classification

**TRUE BUG.** The `_Bool` arm at std.core:83 cites §6.3.1.2#1 itself —
the rule is intended, and merely applied to the truncated integer
instead of the floating value. The crash on non-finite input is a
secondary robustness bug on the same path.

## Provenance

Found by the 2026-08-30 parity-detective beyond-testset probe campaign
of our Lean port (`lean_frontend/docs/2026-08-30_parity-detective-report.md`
§4, oracle-wrong suspect 1): our Lean pipeline deliberately mirrors
the shared std.core/`ivfromfloat` behavior, so both engines agree on
the wrong value (`AGREE`) — an upstream defect, not a port divergence.
Repros re-verified 2026-08-30 against the un-forked
`deps/cerberus-upstream` binary and runtime @ `b9aeedcb4`
(`std.core` byte-identical between fork and upstream).
