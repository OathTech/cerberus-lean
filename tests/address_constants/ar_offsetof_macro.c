#include <stddef.h>
struct S { char c; int x; }; static int off = (int)offsetof(struct S, x) - 1; int main(void) { return off; }
