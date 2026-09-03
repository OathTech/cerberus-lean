# `Cerb_floating.mul` is defined as addition

**FILED:** https://github.com/rems-project/cerberus/issues/1009
(operator, 2026-08-19; open. Re-checked 2026-08-23: `mul` is still
`(+.)` on current upstream master.)

**Affected:** `util/cerb_floating.ml:5` (checked against `master` @ `b9aeedcb4`;
file unchanged there).

## Description

The OCaml floating-point indirection module defines multiplication as
addition:

```ocaml
(* util/cerb_floating.ml *)
let add = (+.)
let sub = (-.)
let mul = (+.)     (* line 5: should be ( *. ) *)
let div = (/.)
```

`frontend/model/float.lem:41-42` maps the Lem-level `floatMul` to
`Cerb_floating.mul` (and `float.lem:56` binds `( * )` to it), so every
OCaml-side consumer of Lem-level float multiplication computes `x + y`.
The reachable consumer in-tree is the defacto memory model's float
arithmetic (`frontend/model/defacto_memory.lem:1107`, `FloatMul ->
FVconcrete (fval1 * fval2)`).

The concrete memory model is **not** affected: its `op_fval`
(`memory/concrete/impl_mem.ml:2529-2538`) uses `*.` directly. That is
presumably why default (concrete-model) test runs have not surfaced this.

## Reproducer

Any float multiplication evaluated through the defacto/symbolic memory
model's `op_fval`, e.g. `3.0 * 2.0`, yields `5.0` instead of `6.0`.
(Found by code audit while porting; we have not run an upstream
defacto-model build to demonstrate it end-to-end, but the data flow from
`floatMul` to `Cerb_floating.mul` is direct and unconditional.)

## Observed vs expected

- Observed: `Float.floatMul x y = x +. y` in all OCaml backends.
- Expected: `x *. y`.

## Impact

Silent wrong results for any execution or analysis path that reaches
Lem-level float multiplication with the OCaml backend (defacto memory
model; any future caller of `Float.floatMul`). Neighbouring `add`, `sub`,
`div` are correct, so this reads as a copy-paste slip.

## Proposed remedy

One-line fix:

```ocaml
let mul = ( *. )
```

## Classification

**TRUE BUG.** The surrounding definitions and the function's name make
the intent unambiguous; the behaviour contradicts it.

<!-- internal provenance:
  cerberus-lean/lean_frontend/docs/2026-08-19_upstream-float-mul.md
  (arc-4 S5 adversarial audit, fix item C4);
  arc-4 results doc, audit disposition C4
  (cerberus-lean/lean_frontend/docs/2026-08-19_arc4-results.md).
  Our Lean port implements real multiplication (documented-deliberate
  divergence): the first lem-level float-mul differential will show the
  OCaml side wrong.
-->
