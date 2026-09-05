# Pointer subtraction over pointers to arrays divides by the INNER element size: `&a[2] - &a[0]` on `int a[3][4]` is 8, not 2

**Affected:** `memory/concrete/impl_mem.ml:1961-1967` (`Concrete.diff_ptrval`,
`valid_postcond`: strips one `Array` layer off `diff_ty` before dividing
the address difference by `sizeof`); `frontend/model/translation.lem:2183-2189`
(`AilEbinary … Arithmetic Sub` on pointers: `diff_ty_pe` is the operands'
REFERENCED type, i.e. already the pointed-to type). Checked against
`master` @ `b9aeedcb4`: `impl_mem.ml` byte-identical through :2998;
`translation.lem` differs from master only by Lean-target `declare`
lines outside the cited region (line numbers are master's).

## Description

The elaboration passes the pointed-to type to the memory operation
(translation.lem:2183-2189, "by Ail typing we can just use the
referenced type of either operand": for `int (*)[4]` operands that is
`int[4]`). `diff_ptrval` then does

```ocaml
let valid_postcond addr1 addr2 =
  let diff_ty' = match diff_ty with
    | Ctype (_, Array (elem_ty, _)) ->
        elem_ty
    | _ ->
        diff_ty in
  return (IV (Prov_none, Z.div (Z.sub addr1 addr2) (sizeof diff_ty'))) in
```

(impl_mem.ml:1961-1967, verbatim) — i.e. when the pointed-to type is
itself an array it divides by the size of that array's ELEMENT. For
pointers to scalars or structs the `match` is a no-op and the result is
right; for pointers to arrays the quotient is too large by the array
length.

## Reproducer

`tests/noodle-probes/ptr/ptr_array_ptrdiff_scaling.c` in our tree:

```c
#include <stdio.h>
struct S { int x, y, z; };
int main(void) {
  int a[3][4]; char c[2][3]; struct S s[3]; long long l[3];
  int (*p)[4] = a;
  int d1 = (int)(&a[2] - &a[0]);          /* 2 */
  int d2 = (int)(&c[1] - &c[0]);          /* 1 */
  int d3 = (int)(&s[2] - &s[0]);          /* 2 (struct control) */
  int d4 = (int)(&l[2] - &l[0]);          /* 2 (scalar control) */
  int d5 = (int)((p + 1) - p);            /* 1 */
  int d6 = (int)(&a[2][0] - &a[0][0]);    /* 8 (int-element control) */
  printf("%d %d %d %d %d %d\n", d1, d2, d3, d4, d5, d6);
  return 0;
}
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive ptr_array_ptrdiff_scaling.c
Defined {value: "Specified(0)", stdout: "8 3 2 2 4 8\n", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`;
the fork's oracle at `928aa1e76` and our Lean port print the identical
line — our Lean memory model mirrors the strip deliberately, with a
comment citing these lines, and will drop it in the same change.)

```
$ gcc -std=c11 -O0 ptr_array_ptrdiff_scaling.c && ./a.out
2 1 2 2 1 8
```

(gcc 13.3.0; verbatim 2026-09-05.)

## Observed vs expected

- Observed: `d1 = 8` (32 bytes / `sizeof(int)`), `d2 = 3`, `d5 = 4`; the
  struct/scalar/int-element controls are right.
- Expected (ISO C11 §6.5.6#9: the result is the difference of the
  subscripts of the two array elements, i.e. bytes / `sizeof` of the
  pointed-to type): `2 1 2 2 1 8`.

## Impact

Any code that iterates over rows of a 2-D array by pointer difference
(`row - table`, `end - begin` over `T (*)[N]`) gets a value `N` times too
large; row-index computations then index out of bounds or the program
takes a different branch. Silent wrong value on UB-free input.

## Proposed remedy

Delete the strip in `valid_postcond` (divide by `sizeof diff_ty`), since
the elaboration already provides the pointed-to type:

```ocaml
let valid_postcond addr1 addr2 =
  return (IV (Prov_none, Z.div (Z.sub addr1 addr2) (sizeof diff_ty))) in
```

If some other caller of `diff_ptrval` passes the ARRAY type of the
pointed-to elements (which would be the only reason for the strip), that
caller should pass the element type instead — the memory interface
documents `diff_ptrval : ctype (the pointee) -> …`. The same shape should
be checked in the other memory models' `diff_ptrval` (the CHERI and
defacto models have their own).

## Classification

**TRUE BUG.** §6.5.6#9 is unambiguous, the controls show the intended
formula (bytes / pointee size) is implemented, and the strip has no
comment explaining a purpose; the elaboration's comment ("we can just use
the referenced type") confirms the pointee type is what arrives.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding P1); both engines agree, gcc differs. Re-verified 2026-09-05 on
the un-forked upstream binary + runtime @ `b9aeedcb4`, the fork's oracle
and the Lean port (lines above verbatim). Localisation and this draft by
Claude (Fable 5.1) under operator direction; the filed issue carries an
AI-provenance note per the tray's policy.
