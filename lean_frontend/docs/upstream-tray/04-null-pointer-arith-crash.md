# Uncaught `Failure` (TODO) instead of a UB verdict for arithmetic on a null pointer

**Affected:** `memory/concrete/impl_mem.ml:2217`
(`array_shift_ptrval`, the pure variant)
(checked against `master` @ `b9aeedcb4`; file unchanged there).

## Description

The concrete memory model's pure `array_shift_ptrval` crashes on a null
pointer operand:

```ocaml
| PVnull _ ->
    (* TODO: this seems to be undefined in ISO C *)
    (* NOTE: in C++, if offset = 0, this is defined and returns a PVnull *)
    failwith ("TODO(pure shift a null pointer should be undefined behaviour), offset:" ^ Z.to_string offset)
```

The effectful sibling already handles the identical case gracefully:
`eff_array_shift_ptrval` (`impl_mem.ml:2244-2252`) has the analogous
`failwith` commented out and does `fail ~loc MerrArrayShift`, which
surfaces as a proper memory-error/UB verdict.

## Reproducer

```c
int main(void) {
  int *p = (int *)0;
  int *q = p + 1;     /* UB: arithmetic on a null pointer */
  return 0;
}
```

`cerberus --exec` on this file terminates with the uncaught
`Failure("TODO(pure shift a null pointer should be undefined behaviour), offset:4")`
rather than reporting undefined behaviour.

## Observed vs expected

- Observed: tool crash (uncaught OCaml exception) during evaluation of
  the pure `PEarray_shift`.
- Expected: an undefined-behaviour verdict (ISO C 6.5.6: `p + 1` where
  `p` does not point into an array object is UB), as the effectful path
  already produces for the same operation.

## Impact

Diagnosing UB is Cerberus's core use case; on this input class the tool
crashes instead of diagnosing. Six lines of ordinary (if erroneous) C
suffice. It also breaks batch/differential workflows: a harness cannot
distinguish "tool defect" from "program UB" without special-casing the
exception text.

## Proposed remedy

Make the pure null case produce the same verdict as the effectful
precedent (`fail ~loc MerrArrayShift`, impl_mem.ml:2252). The pure
interface returns `pointer_value` directly and has no error channel, so
concretely either:

- elaborate/evaluate `PEarray_shift` through the effectful memop when
  the base operand may be null (the eff variant exists and already
  implements the desired behaviour), or
- extend the pure interface to a fallible return (`either mem_error
  pointer_value`), threading the existing `MerrArrayShift` out to the
  driver.

The existing comment's C++ note (offset 0 on null is defined) can be
kept as a special case if desired; the current behaviour crashes for
offset 0 too.

## Classification

**INTENDED GAP / KNOWN LIMITATION** — the `failwith` text is a literal
author TODO, so the missing behaviour is acknowledged. We report it
because the failure mode (crash on a 6-line reproducer, on the tool's
target input class) is disproportionate to the gap, and because the
fixed behaviour already exists in-tree on the effectful path.

<!-- internal provenance:
  Reproducer is tests/minimal/097-null-ptr-arith.undef.c in our tree.
  Evidence: cerberus-lean/lean_frontend/docs/2026-08-19_arc4-s0-frontier.md
  (097 rows; post-S3c: "3 CERB_SKIPs ... 097 OCaml-side skip");
  2026-08-19_arc4-decision-log.md D5 ("097's oracle-side crash recorded as
  CERB_SKIP (the OCaml TODO-failure is upstream-reportable)") and D10
  ("097 upstream TODO-crash"). Our Lean port initially panicked here too
  (CerbMem.arrayShiftPtrval), for the same reason of a missing error
  channel — the shared shape of the failure supports the interface-level
  remedy.
-->
