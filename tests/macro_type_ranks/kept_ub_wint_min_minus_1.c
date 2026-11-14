// KEPT (upstream's behaviour; pinned to pristine c3ff8c53f's line): upstream reports UB036 (0 - 1 at wint_t,
// whose model range is [0, 2^31-1]); with int's rank the fork answered Specified(0); gcc (wint_t is unsigned
// int) exits 1. Record lean_frontend/docs/2026-11-14_wchar-rank-record.md.
#include <stdint.h>
int main(void) { return WINT_MIN - 1 > 0; }
