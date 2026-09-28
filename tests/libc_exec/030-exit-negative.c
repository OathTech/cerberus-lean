// 030: exit(-1) after unflushed output: the value is -1, stdout is flushed
// (served-surface probe p2_exit_codes, verbatim).
#include <stdio.h>
#include <stdlib.h>
int main(void) { printf("before"); exit(-1); }
