# `UB088_reached_end_of_function` is reported whether or not the caller uses the value (stricter than ISO §6.9.1#12)

**Affected:** `frontend/model/translation.lem` (upstream `b9aeedcb4`), the end-of-body expression of a
non-void function: `Caux.mk_std_undef_pe loc "§6.9.1#12" Undefined.UB088_reached_end_of_function` is emitted
unconditionally. A use-dependent form (`mk_if_pe (mk_sym_pe is_used_sym) (undef UB088) (unspecified return_ty)`)
sits commented out immediately above it (fork `:4468-4471`). `frontend/model/core_eval.lem` relocates the
undef to the call site when a parent call location is known (fork `:596-603`).

## Reproducers

```c
int f(void) { }                         /* falls off the end of a non-void function */
int main(void) { f(); return 0; }       /* the call's value is DISCARDED */
```

```c
int f(void) { }
int main(void) { return f(); }          /* the call's value is USED */
```

Fork oracle `git-cerberus-lean-v0.1.0-alpha.1-156-gf5303eda5` (merge-base `b9aeedcb4`), `--exec --batch
--mode=exhaustive`, 2026-10-17, verbatim:

```
discarded:  Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<2:18--2:21>"}
used:       Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<2:25--2:28>"}
```

(`<2:18--2:21>` is the call `f()` in `main`, the relocation above.) The Lean engine agrees on both
(exec lane: `UB_MATCH` ×2). A suite instance: `tests/gcc-torture/execute/compare-1.c` reports
`UB088_reached_end_of_function` at `<93:3--93:16>`.

## Observed vs expected

Observed: UB088 whenever control reaches the closing brace of a non-void function, independent of the
caller. C11 §6.9.1#12: "If the `}` that terminates a function is reached, and the value of the function
call is used by the caller, the behavior is undefined." The first reproducer is therefore a defined
program under ISO (the value is never used), and the report is an over-approximation.

## Impact

Any program with a non-void function whose end is reachable and whose result is sometimes discarded is
classified UB by Cerberus where ISO calls it defined. gcc's torture suite contains several (compare-1.c,
and the fork's `tests/bmc/basic/func_call/sat/call_fnend_*`). Consumers comparing against another
semantics (here RefinedC's Caesium, which follows §6.9.1#12) see a spurious disagreement.

## Proposed remedy (a suggestion, not a demand)

Either (a) the commented-out use-dependent form, with `is_used_sym` bound at the call site (the Core
`Ecall`/`Eproc` elaboration knows whether the value flows anywhere), or (b) a documented statement that
Cerberus deliberately reports the stricter condition (reaching the brace at all), so that the reading is
a declared design choice rather than an open TODO. The fork mirrors upstream here and will keep doing so
until upstream decides; it does not change the verdict on its own (no fork-ahead fix: this is a reading,
not an unambiguous implementation bug).

## Origin

Raised by the consumer cerberus-caesium (its note of 2026-10-17, item E, asking which reading the driver
implements) and confirmed in the fork on 2026-10-17 by the two reproducers above; the fork's response note
is `lean_frontend/docs/2026-10-17_consumer-note-cerberus-caesium-response-note-2.md`. Decision not to fix
ahead of upstream: [USER 2026-10-17] (the case is a deliberate stricter reading, not an obviously wrong
implementation).

## Provenance

[AGENT] report; both engines run on the fork at `f5303eda5`; the upstream source read at merge-base
`b9aeedcb4`. No upstream build was run for this report.
