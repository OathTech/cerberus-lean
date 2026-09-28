// fmt-027: %.Ns on a char array with NO terminating NUL: exactly N bytes are
// read (served-surface probe p2_printf_s_nonul, verbatim).
#include <stdio.h>
int main(void) { char buf[3] = {'a','b','c'}; return printf("[%.3s|%.2s]\n", buf, buf); }
