/* zero-discrepancy Z2 pin (2026-09-03; audit row Z2-FL-03 / charter Z-58 (F2), tests/z2-probes/float/
   nan_to_int_nopanicflag.c; record docs/2026-09-04_zero-discrepancy-Z2-record.md). `(int)NaN`: the oracle's
   `Z.of_float` raises Z.Overflow (impl_mem.ml:2554, uncaught, exit 125); Lean's CerbFloat.truncToInt panics
   (exit 134 under LEAN_ABORT_ON_PANIC, which the driver now REQUIRES — Z1's Z2-FL-03 refusal). A both-crash
   pair, pinned MATCH | L=CRASH; the oracle-side crash is tray 15's non-finite class (register (ii')-eligible,
   charter §1.4 — not admitted). nolibc. */
/* Z2 probe (reader C Z2-10, INSTRUMENT): (int)NaN — oracle uncaught Z.Overflow
   (impl_mem.ml:2554 Z.of_float); Lean CerbFloat.truncToInt:301-302 panics.
   Under LEAN_ABORT_ON_PANIC=1 (every lane) the failure classes match; WITHOUT
   the flag a Lean panic prints to stderr and CONTINUES with `default`.
   NaN built as inf - inf (0.0/0.0 is UB045a on Cerberus). nolibc. */
int main(void) { double inf = 1e308 * 10.0; double d = inf - inf; return (int)d; }
