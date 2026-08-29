# `va_arg` performs no type-compatibility check (acknowledged TODO) — confirmation the gap is observable

**Affected:** `memory/concrete/impl_mem.ml:2731` (`va_arg`)
(checked against `master` @ `b9aeedcb4`; file unchanged there).

## Description

The concrete memory model's `va_arg` returns the stored argument pointer
without consulting the requested type:

```ocaml
let va_arg va ty =
  ...
  begin match List.nth_opt args i with
    | Some (_, ptr) -> (* TODO: check type is compatible *)
        ...
        return ptr
```

The recorded per-argument ctype (the `fst` of the stored pair) is
discarded; `ty` is unused for checking. C11 7.16.1.1p2 makes `va_arg`
with an incompatible type undefined behaviour (with the enumerated
compatibility exceptions: signed/unsigned with representable value,
character/void pointer types), so the model currently under-reports UB
for varargs misuse.

This report is a confirmation-of-known-TODO with one datapoint upstream
may find useful: **the absence of the check is observable behaviour, not
dead code.** In our port of this model we mirrored the no-check
behaviour exactly and match the OCaml oracle across our varargs
differential corpora; a review during that work established that
introducing a strict type check at this site would have produced
divergent verdicts on existing passing tests — i.e. programs currently
execute to completion that would (correctly, per C11) receive UB
verdicts with the check in place.

## Observed vs expected

- Observed: `va_arg(ap, T)` succeeds for any `T`, reinterpreting the
  stored argument.
- Expected (C11 7.16.1.1p2): UB verdict when `T` is not compatible with
  the promoted type of the actual argument (modulo the enumerated
  exceptions).

## Impact

Missed UB diagnosis on varargs misuse — a class of real-world bugs
(printf-style format mismatches reduce to exactly this). Low urgency:
no crash, and well-typed programs are unaffected.

## Proposed remedy

Implement the check the TODO contemplates: compare `ty` against the
stored ctype (`Some (arg_ty, ptr)` instead of `Some (_, ptr)`) under
C11 compatibility-modulo-promotions (the exceptions of 7.16.1.1p2), and
on failure `fail` with a UB-classed `mem_error` so the driver reports UB
rather than a generic error.

Caveat worth deciding deliberately: enabling the check changes
observable behaviour for programs that rely on the current leniency
(mixed signed/unsigned and pointer-flavour varargs use that today runs
to completion). We would suggest either guarding it behind a switch
(consistent with the existing `Switches` mechanism) or landing it with a
changelog note, so downstream differential users can account for the
verdict changes.

## Classification

**INTENDED GAP / KNOWN LIMITATION** — the TODO comment shows the author
knows the check is missing. Not a bug report; a confirmation that the
gap has behavioural consequences, plus a compatibility note for whenever
it is closed.

<!-- internal provenance:
  worktrees/cerberus-lean-arc/libc-load/lean_frontend/docs/
  2026-08-19_arc6-decision-log.md D11: the S2 worker's brief specified a
  va_arg ctype check; the worker verified impl_mem.ml:2731 is a TODO with
  no check and refused to add one under the mirror doctrine ("adding it
  would change behavior"). S2 port: CerbMem vaStart/vaCopy/vaArg/vaEnd/
  vaList mirror impl_mem.ml:2698-2764; varargs corpora (5 coverage DIFFs,
  debug varargs-01, libc_exec 006/007) all MATCH the oracle with the
  check absent (worktree lean_frontend/CLAUDE.md, pipeline status).
-->
