// KEPT (upstream's behaviour; pinned to pristine c3ff8c53f's line): upstream reports UB036 (wchar_t is not
// promoted, the addition is done at wchar_t against its unsigned maximum); with int's rank the fork answered
// Specified(0). In gcc's types (wchar_t is int) the addition overflows int. Record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md.
#include <stdint.h>
int main(void) { return WCHAR_MAX + 1 > 0; }
