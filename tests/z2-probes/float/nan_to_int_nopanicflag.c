/* Z2 probe (reader C Z2-10, INSTRUMENT): (int)NaN — oracle uncaught Z.Overflow
   (impl_mem.ml:2554 Z.of_float); Lean CerbFloat.truncToInt:301-302 panics.
   Under LEAN_ABORT_ON_PANIC=1 (every lane) the failure classes match; WITHOUT
   the flag a Lean panic prints to stderr and CONTINUES with `default`.
   NaN built as inf - inf (0.0/0.0 is UB045a on Cerberus). nolibc. */
int main(void) { double inf = 1e308 * 10.0; double d = inf - inf; return (int)d; }
