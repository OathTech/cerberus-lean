// G4: __builtin_ffs(INT_MIN) = ffs(0x80000000) -> bit 31 set -> 32.
int main(void) { return __builtin_ffs((int)(-2147483647 - 1)); }
