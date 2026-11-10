# Converting an infinity or a NaN to an integer type crashes the tool (uncaught `Z.Overflow` in `ivfromfloat`); an out-of-range finite value is a UB017 verdict

**Affected:** `memory/concrete/impl_mem.ml:2372-2373` @ `c3ff8c53f`:

```ocaml
  let ivfromfloat _ fval =
    IV (Prov_none, Z.of_float fval)
```

`Z.of_float` raises `Z.Overflow` on a non-finite argument. Reached from `runtime/libcore/std.core`'s floating-to-integer
conversion, whose range test answers `undef(<<UB017_out_of_range_floating_integer_conversion>>)` (`std.core:96`) for a
finite value outside the target type. The Lean port mirrors the raise as a stop with the same attribution.

## Description

C17 6.3.1.4#1 defines the conversion of a *finite* real floating value to an integer type and makes it undefined when
the integral part is not representable. An infinity or a NaN is not covered by that sentence and has no representable
integral part: the conversion is undefined behaviour as well (Annex F.4, for implementations that define
`__STDC_IEC_559__`, makes it an "invalid" exception with an unspecified result). Cerberus reports the finite
out-of-range case as UB017 and dies on the non-finite one.

## Reproducers

```c
int main(void) { double h = 1e300 * 1e300; int i = h; return i == 0; }
```

```
$ cerberus --nolibc --exec --batch inf_int.c
cerberus: internal error, uncaught exception:
          Z.Overflow
          Raised by primitive operation at Cerb_frontend__Impl_mem.Concrete.ivfromfloat in file "memory/concrete/impl_mem.ml", line 2373, characters 19-34
          Called from Cerb_frontend__Core_eval.step_eval_pexpr.(fun) in file "ocaml_frontend/generated/core_eval.ml", line 698, characters 195-226
```

(exit 125; verbatim, 2026-11-10, un-forked upstream binary + runtime @ `c3ff8c53f`.) The same exception and exit code
for a NaN and for the other integer types tried:

```c
int main(void) { double h = 1e300 * 1e300; double n = h - h; int i = n; return i == 0; }
int main(void) { double h = 1e300 * 1e300; unsigned long u = h; return u == 0; }
int main(void) { double h = -1e300 * 1e300; long l = h; return l == 0; }
```

Control, the finite out-of-range value:

```c
int main(void) { double h = 1e300; int i = h; return i == 0; }
```

```
Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<1:36--1:46>"}
```

gcc 13.3.0 (`gcc -std=c11 -w -O0`, 2026-11-10; the programs have undefined behaviour, so these are one compiler's
results and not a reference): exit 0, 0, 1, 0 for the four non-finite programs and 0 for the control. `_Bool b = h;`
with `h` infinite is defined (6.3.1.2#1) and answers 1 on pristine today, as on gcc.

## Observed vs expected

- Observed: an uncaught OCaml exception (exit 125) on a program whose behaviour is undefined.
- Expected: the undefined-behaviour verdict the finite case already gets (UB017), or a distinct one.

## Impact

A crash where the tool's purpose is to name the undefined behaviour. Reached by any computation that overflows to
infinity (or produces a NaN) before an integer conversion.

## Proposed remedy (prose; no patch is attached)

Test for a non-finite value before `Z.of_float` — in `std.core`'s conversion beside the existing range test, or in
`ivfromfloat` returning a value the range test rejects.

## Fork status (2026-11-10)

Unchanged in both engines. Reported, not fixed. Report 15 (the `_Bool` conversion, fixed upstream by `3230aa494`, in
the base) named this as its residual.

## Classification

**TRUE BUG** as a crash (the input has undefined behaviour; the defect is that the verdict is an exception).

## Provenance

Report 15's residual (2026-08-30), re-found by the fork's true-bug audit of 2026-11-04 (sibling finding 19). Re-run on
pristine upstream at `c3ff8c53f`, the fork's oracle and gcc on 2026-11-10. This draft by Claude (Fable 5.2) under
operator direction; the filed issue carries an AI-provenance note per the tray's policy.
