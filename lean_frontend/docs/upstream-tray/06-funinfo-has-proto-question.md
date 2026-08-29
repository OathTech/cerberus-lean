# Question: `funinfo` `has_proto` diverges between declaration and definition entries, and its runtime uses appear dead

**Affected (for orientation):** `funinfo` construction in the elaborator
(`frontend/model/translation.lem`, ~4505-4540); consumers
`frontend/model/core_eval.lem:907-912` and
`frontend/model/core_rewrite2.lem:696-702` (`PEcfunction` result tuple)
(checked against `master` @ `b9aeedcb4`).

This is a question / minor observation, not a defect claim.

## Observation

While reloading the Core elaboration of the shipped C library
(`runtime/libc`), we found:

1. **Per-TU divergence.** For functions that are declared in one
   translation unit and defined in another, the two `funinfo` entries
   (kept under distinct symbols) agree on return/parameter ctypes and
   variadicity but disagree on `has_proto` (concretely the
   `__strtox`/`__strtoxd` family in the shipped libc).
2. **The runtime value appears unread.** `has_proto` does flow into the
   `cfunction(...)` 4-tuple (`core_eval.lem:907-912`,
   `core_rewrite2.lem:696-702`, fourth component `Vtrue/Vfalse`), but in
   the entire libc Core dump every one of the 221 `cfunction` 4-tuple
   pattern bindings binds that component to a dead variable — we checked
   this mechanically. So at least for the code the elaborator itself
   generates, the value is produced but never consumed.

## Question for upstream

Is `has_proto` intended to be consumed at Core run time? If yes:

- which entry should win when declaration and definition disagree, and
- should the elaborator normalise it (e.g. OR over all declarations of
  the same C function) so linked programs see one value?

If it is vestigial at this level (e.g. only meaningful earlier, in the
Ail typing phase), dropping it from the `cfunction` tuple would remove a
per-TU-nondeterministic value from the Core representation, which is a
small win for anyone doing differential or serialisation work over Core.

## Impact

None observed on execution (consistent with the dead bindings). The cost
is to consumers of Core as a data format: a semantically irrelevant
field that varies with TU structure shows up in dumps and diffs, and a
reimplementation cannot tell from the code whether it must reproduce the
divergence faithfully.

## Proposed remedy

Either (a) document/normalise: merge declaration+definition `has_proto`
at elaboration or link time, or (b) remove the component from the
`PEcfunction` result tuple if it is confirmed dead. We have no basis to
choose between them — that is the question.

## Classification

**UNCLEAR / minor.** We cannot determine author intent from the code;
framed as a question accordingly. (Plausibly a vestigial field.)

<!-- internal provenance:
  worktrees/cerberus-lean-arc/libc-load/lean_frontend/docs/
  2026-08-19_arc6-s1-libc-load.md (task 3: has_proto excluded from the
  funinfo name-join because decl-TU vs def-TU entries disagree
  (__strtox/__strtoxd); "verified UNREAD by the pinned bodies (all 221
  cfunction 4-tuple binders bind it to a dead variable — checked
  mechanically)"); register item 3, and arc-6 decision log D10
  ("has_proto verified-dead finding (upstream-reportable oddity)").
-->
