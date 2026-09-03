/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-CP-01; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/coreparser/strtod_inf.c. The pinned --pp=core dump tests/libc/libc.core
   (lines 53897/53906/64081/64090) prints `pure(Specified(inf))` — pp_core.ml:279-282 `string_of_float`
   of +infinity — inside proc decfloat's overflow path; the oracle runs its in-memory libc.co AST with
   OVfloating +inf there, while CoreParser.lean lexed `inf` as an IDENTIFIER (PEsym, unbound) so every
   strtod/strtof overflow in libc mode gave `Error {msg: "Unresolved_symbol: …"}`. Pinned DIFF at
   the current Lean token; the Z2-CP-01 fix (inf/-inf/nan → OVfloating, mirroring what the pp
   printed) re-records MATCH. libc mode. */
#include <stdlib.h>
int main(void) { double d = strtod("1e5000", 0); return d > 1e308; }
