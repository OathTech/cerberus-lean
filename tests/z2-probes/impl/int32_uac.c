/* Z2 probe (CerberusImpl.normalise_integerType:245-252 lacks the
   Signed/Unsigned IntN_t/least/fast/Intmax/Intptr aliasing arm of
   ocaml_implementation.ml:37-54): int32_t (= Signed (IntN_t 32)) mixed with
   unsigned int reaches ailTypesAux.lem le_integer_range's `fail ()` arms on
   Lean if not normalised to Signed Int_. */
#include <stdint.h>
int main(void) { int32_t s = -1; unsigned int u = 1; return (s + u) == 0; }
