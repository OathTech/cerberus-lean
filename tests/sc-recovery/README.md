# Proposed inputs for SC concurrency

These were collected as proposed acceptance inputs on 2026-09-24, before the
new branch had an SC implementation; they are not a passing concurrency suite.
The directory name records the initial investigation; it remains unchanged
so historical provenance and diagnostic records continue to identify the inputs.

`provenance.json` records 21 byte-identical inputs from the failed prototype at
`631382a9d23a709112f38add53357d4cbe6fc108`. Reuse of an input does not adopt its
comments, expected outcomes, old harness, or the donor's semantic claims. The
`intent_to_validate` entries are qualitative requirements; a slice must
derive exact expected observations independently before using them as a gate.
`prefix/member-before-race-loop.c` is a new distinguishing input derived from
the donor's global suppression of race findings after an interpretation gap.

Use the existing observation codec when these become executable gates. Preserve
process exit status, value, output, error payload, blocking, and incompleteness.
Choose execution mode per case: bounded complete exploration for tiny cases,
recorded schedule/prefix checks for the others. In particular, the two looping
cases require a finite race witness, not exhaustive termination. A stop-at-first-
UB executor and an optional diagnostic continuation have different contracts;
the initial executor stops at the first justified UB or unsupported operation.
Post-UB diagnostic continuation is deferred and must label everything after the
first UB as diagnostic only. Expectations mentioning later faults apply only
to that separate diagnostic contract.

The callable fence/library cases need the proper linked runtime. Do not apply
`--nolibc` to the entire set. `domain/fence+sc_sc.c` is a weak-order refusal
control, not a positive SC fence test; a positive callable SC fence input is
still needed. A replayed selected schedule establishes only that observation.

The two ordered object examples have fresh donor reproductions in
[`donor-reproductions.json`](../../lean_frontend/docs/sc-recovery-evidence/donor-reproductions.json).
Those runs diagnose the donor; they do not validate a new implementation.

The governing work order is the
[SC concurrency master plan](../../SC-CONCURRENCY.md).
Its V1 milestone adds a persistent real-C lane for publication/fork/join,
ordinary objects and explicit step-budget behavior. Derive exact expectations
and schedule/completeness classifications before turning these seeds into it.
