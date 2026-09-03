/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-02, folded into Z1 with Z-06).
   Origin: tests/z2-probes/mem/device_funptr_call.c (branch audit/z2-seams @ 9e86fe67c).
   Oracle: uncaught Failure("case_ptrval") exit 125 (impl_mem.ml:1814); Lean before: Error
   {msg: "Illformed_program: ... does not point to a function"} (fail-open fallback);
   Lean after: PANIC "case_ptrval" — a both-crash pair, MATCH | L=CRASH. */
int main(void) { ((void (*)(void))0xABC)(); return 0; }
