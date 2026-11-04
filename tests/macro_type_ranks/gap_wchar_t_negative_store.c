// GAP control (unchanged by the 2026-11-04 rank fix; upstream-tray report 62, the queued refusal): a negative
// value stored into a wchar_t object crashes both engines at the store — the implementation gives wchar_t an
// unsigned range and a signed representation (bytes_of_int(signed), i= 4294967295, nbits= 32). Not this mechanism:
// the usual arithmetic conversions on wchar_t (dense_wchar_t_*) are right since the fix.
#include <stddef.h>
int main(void) { wchar_t w = -1; return w > -1; }
