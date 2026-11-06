/* NOLIBC CONTROL: the tray 24 reproducer under --nolibc on both engines: no FILE objects without the library (unresolved __stdout), the termination path is upstream's. */
#include <stdio.h>
int main(void) { fputs("out", stdout); return 0; }
