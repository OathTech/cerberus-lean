// exhaustive/002: errno read/write in libc mode, compared EXHAUSTIVELY (the
// oracle's execution set has five executions, all Specified(50)): the errno
// object's initial value is 0 in every execution.
#include <errno.h>
int main(void) { int e0 = errno; errno = 5; int e1 = errno; errno = 0; return e0 * 100 + e1 * 10 + errno; }
