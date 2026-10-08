// PNVI arms witness a13 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: eff_array_shift_ptrval's
// (Prov_none, PVconcrete) arm (impl_mem.ml:2392-2397), its PNVI bounds branch (:2393-2395):
// under PNVI ptrfromint gives an address in no exposed allocation Prov_none (:2196-2198), and
// any shift of it fails "out-of-bound pointer arithmetic (Prov_none)".
// Expected under the switch: Error MerrOther (default mode: Defined 1).
#include <stdint.h>
int main(void) {
  int *p = (int *)(uintptr_t)16;
  int *q = p + 1;
  return q != 0;
}
