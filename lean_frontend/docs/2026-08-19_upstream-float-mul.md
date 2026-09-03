# Upstream cerberus bug: `Cerb_floating.mul` is addition

**NOT a lem bug** — this is a bug in upstream CERBERUS (the OCaml
runtime support library), recorded here for want of a better register
(this directory is the project's dated bug-report convention; see
lean_frontend/CLAUDE.md).

Found by the arc-4 S5 adversarial audit of `CerbFloat.lean` against its
cited OCaml counterpart (fix item C4, 2026-08-19).

## The bug

`util/cerb_floating.ml` (the OCaml targets of lem's `Float` module,
frontend/model/float.lem):

```ocaml
(* Floating point operations indirection, since Lem does not support '+.', '*.'.... *)

let add = (+.)
let sub = (-.)
let mul = (+.)     (* <-- line 5: multiplication defined as ADDITION *)
let div = (/.)
```

`mul` is literally `(+.)`. Neighboring `add`/`sub`/`div` are correct, so
this reads as a copy-paste slip, present in the pinned upstream tree
(cerberus-lean @ mdd/cerberus-lean, memory-model-independent util/).

## Blast radius

* Every OCaml-side use of lem `Float.floatMul` (`declare ocaml
  target_rep function floatMul = `Cerb_floating.mul``,
  frontend/model/float.lem) computes x + y instead of x * y. That
  includes the generated defacto memory's `op_fval` FloatMul arm.
* The CONCRETE memory model is NOT affected on the execution path:
  `impl_mem.ml:2529-2537 op_fval` uses `*.` directly — which is why the
  current differential corpora (which run the concrete model) do not
  surface the bug.

## Lean-side disposition (documented-deliberate divergence)

`CerbFloat.floatMul` (the lean target of the same lem val) implements
real multiplication. Mirroring the upstream bug was rejected: it is an
evident defect, and the mirror-with-citation doctrine (arc-4 D8) covers
divergence-from-defect via this record. Consequence, stated up front:
**the first differential test whose verdict flows through lem-level
float multiplication will show the OCAML side wrong** — a Lean-vs-OCaml
mismatch on such a test is expected to be an oracle failure, and should
be triaged against this note before anything is "fixed" on the Lean
side.

Upstream-reportable (needs a networked window).
