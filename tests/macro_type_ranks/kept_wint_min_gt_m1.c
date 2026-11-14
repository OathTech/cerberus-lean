// KEPT (upstream's behaviour; pinned to pristine c3ff8c53f's line): the wint_t sibling of the reproducer.
// Pristine and gcc: 0 (both compare as unsigned). With int's rank for wint_t the fork answered 1.
// Record lean_frontend/docs/2026-11-14_wchar-rank-record.md.
#include <stdint.h>
int main(void) { return WINT_MIN > -1; }
