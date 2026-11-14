// KEPT (upstream's behaviour; pinned to pristine c3ff8c53f's line): a FALSE undefined-behaviour verdict of
// upstream's (upstream-tray report 62: the difference is -100000 under either signedness; gcc exits 1). With
// int's rank the fork answered gcc's 1; the verdict is upstream's to repair, with wchar_t's signedness.
// Record lean_frontend/docs/2026-11-14_wchar-rank-record.md.
#include <stddef.h>
int main(void) { wchar_t w = 100000; return (w - 200000) < 0; }
