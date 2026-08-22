// G4: __builtin_ffs(-1). -1 is all-ones two's complement, lowest set bit
// is bit 0 -> ffs = 1 (well-defined, signed int arg). Oracle -> 1;
// Lean gcc_builtin_generic_ffs clamps via Int.toNat -> 0. WRONG VALUE.
int main(void) { return __builtin_ffs(-1); }
