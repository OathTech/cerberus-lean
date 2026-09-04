/* zero-discrepancy Z2 fixture (2026-09-03; audit row Z2-C-02, tests/z2-probes/call/errno_order.c; record
   docs/2026-09-04_zero-discrepancy-Z2-record.md). The parameter object's address (low 16 bits) observes the
   allocation ORDER: `drive` allocates errno before main's body (driver.lem:1860-1868) and the call site creates
   the argument temporaries inside it, so the oracle's wrapper answers 65524; the pre-Z2 CerbCall allocated
   errno after the arguments (65528). */
int f(int x) { return (int)((long)&x & 0xffff); }
int main(void) { return f(1); }
