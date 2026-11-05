// 016: strstr with a needle of length >= 5 takes musl's two-way path (twoway_strstr).
// Until 2026-11-04 both engines reported an out-of-bounds load here: the library's own
// `ip+1` (size_t ip = -1) was narrowed to unsigned int by the macro-type rank defect
// (upstream-tray report 20), so SIZE_MAX + 1 was 2^32, `ip+1 > ms+1` held and the memcmp
// read past the needle. Since the fix both engines answer Specified(10) = gcc (MATCH);
// the N4 location-only witness moved to 042-strlen-unterminated-loc.c.
#include <string.h>
int main(void) { const char *h = "abcabcabcdabcde-xyzzy"; return (int)(strstr(h, "abcde") - h); }
