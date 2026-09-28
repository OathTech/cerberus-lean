// 029: errno is 0 at program start, writable and readable (served-surface
// probe p2_errno_basic, verbatim).
#include <errno.h>
int main(void) { int e0 = errno; errno = 5; int e1 = errno; errno = 0; return e0 * 100 + e1 * 10 + errno; }
