# Upstream backport: pointer arguments to _Bool parameters

Recorded 2026-10-21. This is a backport record, not a new issue filing.

Upstream commit `f10329b44287ab79ed5017ff68431d5c5953ebd7` (PR 1020)
repairs a second conversion of pointer arguments to `_Bool` parameters under
`inner_arg_temps`. The fork at `e32c16709` still has the defect: upstream's
`tests/ci/0344-ptr-to-_Bool-param.c` produces an ill-typed `Civfromfloat`
Core error under the switch and its expected result in Normal mode.

The `feature/inner-arg-temps` slice adopts the unmodified shared-model hunk
and upstream witness. Both OCaml and Lean are regenerated from the shared
model; the independent upstream baseline remains at `b9aeedcb4`.

Reproduction commands, measurements and checkpoint status:
[slice record](../2026-10-21_inner-arg-temps-record.md).
