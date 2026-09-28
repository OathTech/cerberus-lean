// 039: strerror: the runtime libc's strerror is an assert-failing stub, so
// both engines stop with Error "assert() failure" (recorded as the observed
// behaviour; the texts for 0/ERANGE/EDOM are therefore not served).
#include <errno.h>
#include <stdio.h>
#include <string.h>
int main(void) { return printf("%s|%s|%s\n", strerror(0), strerror(ERANGE), strerror(EDOM)); }
