# Under the default (PVI) model, every integer arithmetic operator drops pointer provenance: `(int*)((unsigned long)p + 4)` is UB043 — is this intended?

**Affected:** `frontend/model/core_eval.lem:29-46` (`mk_wrapI`) and
`:61-80` (`mk_conv_int`) — both rebuild their result with
`Mem.integer_ival n`, i.e. a fresh provenance-less integer value, even
when the value is in range; `memory/concrete/impl_mem.ml:2464-2490`
(`Concrete.op_ival`, which DOES propagate provenance through
`combine_prov`), `:627` (`is_PNVI`: false unless `--switches=PNVI`).
Checked against `master` @ `b9aeedcb4`: `core_eval.lem` differs from
master only by Lean-target `declare` lines outside the cited region
(region diff empty); `impl_mem.ml` is byte-identical through :2998.

## Description

The concrete memory model is provenance-via-integers (PVI) by default:
`intfromptr` yields an integer value carrying the pointer's allocation
id, `op_ival` combines provenances (`IntAdd`/`IntMul` via
`combine_prov`, `IntSub` keeps the left operand's), and `ptrfromint`
turns an integer WITH provenance back into a usable pointer. That is the
model's point: `(T*)(((uintptr_t)p + 15) & ~15)` is meant to be defined.

But the elaboration never lets `op_ival`'s result reach the cast. Every
C arithmetic operator on an unsigned type is elaborated as
`wrapI_<op>(ty, __conv_int__(ty, a), __conv_int__(ty, b))` (verbatim
`--pp=core` of the reproducer, upstream binary, 2026-09-05):

```
Specified(wrapI_add('unsigned long', __conv_int__('unsigned long', a_530), __conv_int__('unsigned long', a_531)))
```

and the evaluators of both wrappers discard provenance: `mk_conv_int`
(:61-80) returns `Mem.integer_ival n` for an in-range `n` (a new
`IV (Prov_none, n)`), and `mk_wrapI` (:29-46) likewise wraps through
`Mem.integer_ival`. So after ANY arithmetic — `+ 4`, `+ 0`, `^ 0`, `* 1`,
through an intermediate variable, with matched `unsigned long` operands —
the integer is provenance-free, `ptrfromint` produces a pointer with
`Prov_none`, and the dereference is `UB043_indirection_invalid_value`.
Only the arithmetic-free round trip `(int*)(unsigned long)p` works.

## Reproducer

`tests/noodle-probes/ptr/ptr_intptr_arith_roundtrip.c` in our tree:

```c
int main(void) {
  int a[2] = {10, 20};
  unsigned long u = (unsigned long)&a[0];
  int *q = (int*)(u + 4ul);
  return *q;
}
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive ptr_intptr_arith_roundtrip.c
Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<10:10--10:12>"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`;
the fork's oracle at `928aa1e76` and our Lean port print the identical
line.)

```
$ gcc -std=c11 -O0 ptr_intptr_arith_roundtrip.c && ./a.out; echo $?
20
```

(gcc 13.3.0; verbatim 2026-09-05.) The same verdict with `+ 0`, `^ 0`,
`* 1` and via an intermediate variable (probe
`ptr/ptr_int_roundtrip_ops.c`: gcc `20 30 40 10 8`, Cerberus UB043).

## Observed vs expected

- Observed: UB043 for a pointer reconstructed from an in-bounds integer
  that went through one arithmetic operation.
- Expected under PVI: a pointer to `a[1]`, value 20 — this is exactly the
  class of idiom (alignment rounding, tagged pointers, `offsetof`
  arithmetic) that PVI exists to make defined. ISO C11 §6.3.2.3#5 leaves
  integer→pointer conversion implementation-defined; the Cerberus
  implementation documents the identity mapping.

## Impact

Under the default model, essentially every pointer→integer→pointer idiom
in systems code (alignment rounding, pointer tagging, hashing of
addresses back into pointers) is reported as UB043 at the first
dereference. The C-level provenance paper's PVI examples with
arithmetic cannot be reproduced with the exec mode as shipped.

## Proposed remedy (or documentation)

If exec-mode PVI is meant to carry provenance through integer arithmetic:

- `mk_conv_int`: when `min <= n && n <= max`, return the ORIGINAL `ival`
  (not `Mem.integer_ival n`) so its provenance survives; only the
  wrapping path constructs a new value.
- `mk_wrapI`: compute the wrapped result through `Mem.op_ival` (so
  `combine_prov` applies), or re-attach the operand provenance to the
  rebuilt value (`Mem.op_ival IntAdd ival (Mem.integer_ival 0)` is one
  cheap way to say "same provenance, this value").

If instead exec-mode PVI is deliberately this lossy (provenance survives
only casts, never arithmetic), that is worth stating in the
documentation next to the `--switches` list, because today the
behaviour reads as an accident of the `wrapI`/`__conv_int__` encoding
rather than a model decision — `op_ival` goes to the trouble of
combining provenances that no C program can ever observe.

## Classification

**TRUE BUG relative to the PVI model's evident intent** (`op_ival`
propagates provenance; the wrappers around it throw it away) — but
**UNCLEAR whether the exec mode intends provenance-through-arithmetic**,
so this is filed as a question with the code path traced. Our port
mirrors the current behaviour and will follow whichever way upstream
rules.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding P2); both engines agree (shared `.lem`), gcc differs. Re-verified
2026-09-05 on the un-forked upstream binary + runtime @ `b9aeedcb4`, the
fork's oracle and the Lean port (lines above verbatim). Localisation and
this draft by Claude (Fable 5.1) under operator direction; the filed
issue carries an AI-provenance note per the tray's policy.
