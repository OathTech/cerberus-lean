/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/impl/int32_uac.c — int32_t + unsigned via the shared <stdint.h> typedef (Z2-I-01 header route: the claim was refuted here, confirmed on the __cerbty spelling).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc MATCH row. */
/* Z2 probe (CerberusImpl.normalise_integerType:245-252 lacks the
   Signed/Unsigned IntN_t/least/fast/Intmax/Intptr aliasing arm of
   ocaml_implementation.ml:37-54): int32_t (= Signed (IntN_t 32)) mixed with
   unsigned int reaches ailTypesAux.lem le_integer_range's `fail ()` arms on
   Lean if not normalised to Signed Int_. */
#include <stdint.h>
int main(void) { int32_t s = -1; unsigned int u = 1; return (s + u) == 0; }
