// 016: strstr with a needle of length >= 5 takes musl's two-way path
// (twoway_strstr), which reads the haystack ahead of the match position; the
// concrete model reports an out-of-bounds load in both engines. Recorded as
// the observed behaviour (shared libc C over the shared memory model).
#include <string.h>
int main(void) { const char *h = "abcabcabcdabcde-xyzzy"; return (int)(strstr(h, "abcde") - h); }
