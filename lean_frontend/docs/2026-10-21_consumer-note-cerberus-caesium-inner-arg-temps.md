# inner_arg_temps consumer note — updated 2026-10-22

Delivery is **parked**, not ready for adoption. The driver accepts
`--switches=inner_arg_temps` as the whole switch set, selects
`std_inner_arg_temps.core`, and uses callee-allocated argument temporaries,
including for `main`. Switched `--libc` execution and quotation are again
contained with `R-IAT-LIBC-SYMBOL-LOSS`, exit 2. `--call` under the switch,
mixed sets and `--iso` remain refused.

The repaired production sweep finds exact engine agreement within each
mode on all 42 libc inputs. But exhaustive libc row 001 produces four
observations under the switch versus eighty in Normal mode. Its distinct
outcomes coincide; its complete sequences do not. The required cross-mode
criterion fails, so no new baseline or release row is adopted. Row 039's
accepted assert Error passes four ways and is not this park's cause. See
the [completion/park record](2026-10-22_inner-arg-temps-completion-record.md).
This note does not claim downstream testing.

The fork printer now distinguishes loaded parameter values from local
object addresses and rejects spelling collisions. The loader independently
checks parameter rebinding in every dump, including Normal. This can refuse
legal block-local shadowing; the checks guard known failures and do not
prove arbitrary text transport soundness. Normal output is unchanged.
See [VALIDATION](../VALIDATION.md#core-text-parameter-identity-speedbumps-inner_arg_temps-repair).
I2's earlier green was a faithful quotation of a corrupted parse, not
transport evidence. The repaired variant dump SHA-256 is
`56986871ff4cf05959213c5c20936b0914d14bd925b5bf7223cce25be72536ac`.
The updated quotation pin and its validation are pending in the completion record.

Correction to the earlier recursive-main guidance: upstream's guard is
dead on the active driver path. The Eccall reduction directly invokes
`Core_run.call_proc`, so recursion into main executes under this switch.
Bounded witnesses with and without argc/argv pass on both engines in both
modes: 42 and 7 respectively, also their GCC results. The argument witness
checks nested calls through the callee-allocated convention and preservation
of the outer frame. No recursive-main refusal has been introduced.

The [park disposition](2026-10-21_inner-arg-temps-record.md#park-resolution)
attributes the earlier opposite claim to the orchestrator's reading of
the guard without tracing the reduction path. Tray
[64](upstream-tray/64-recursive-main-guard-bypassed.md) reports the dead guard;
tray [65](upstream-tray/65-inner-arg-temps-core-symbol-loss.md) reports the
separate libc transport issue, and
[66](upstream-tray/66-main-inner-arg-temps-comment.md) reports the inaccurate
main-exclusion comment. None has been submitted externally.

Completed runs report `cerberus-lean switches: [inner_arg_temps]` on
stderr; quotations carry `-- cerberus-lean switches: [inner_arg_temps]`.
Normal reports `[]`. Compared verdict tokens are unchanged. The proposed
Tier A row 15 is not registered; its whole selftest remains unvalidated. All 42 libc rows require equal complete observations across
both modes on both engines. Row 039 remains the existing assert Error,
registered as `BOTH_FAIL`, never execution agreement. The Normal lane calls
that row MATCH because its complete Error tokens agree. The Csmith campaign,
quotation replay and full battery remain outstanding. Quotation hygiene
(I1b) remains approved and deferred to its follow-up slice.
