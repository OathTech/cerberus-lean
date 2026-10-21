# inner_arg_temps consumer status — parked, 2026-10-21

The slice is not ready for adoption. The driver accepts the whole switch
set `--switches=inner_arg_temps` and selects the matching runtime and
calling convention, but imported libc execution and quotation are now
refused with `R-IAT-LIBC-SYMBOL-LOSS` (exit 2). The variant Core text loses
parameter/address symbol identity and produced both crashes and wrong
answers. I2's successful literal quotation checks did not establish that
the text preserves the original binary library. See the
[park record](2026-10-21_inner-arg-temps-libc-park.md).

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
separate libc transport issue. Neither has been submitted externally.

`--call` remains refused under the switch. Run reports use stderr and
quotations carry a switch-set header; compared verdict tokens are unchanged.
The new matched-mode lane is provisional, without an adopted baseline or
release row. Its selftest, Csmith campaign and the close-out full battery
remain outstanding. Quotation hygiene (I1b) remains approved and deferred
to its follow-up slice. This note records status and the correction; it
does not claim downstream testing or a completed delivery.
