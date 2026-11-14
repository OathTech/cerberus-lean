// KEPT (upstream's behaviour; pinned to pristine c3ff8c53f's line): the reproducer of the 2026-11-04..14 defect.
// Pristine and gcc: 1. With int's rank for wchar_t the fork answered 0 (WCHAR_MAX is the unsigned maximum
// 4294967295 in the model and was converted to int). Record lean_frontend/docs/2026-11-14_wchar-rank-record.md.
#include <stdint.h>
int main(void) { return WCHAR_MAX > 0; }
