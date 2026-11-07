#include <stdio.h>
/* nolibc control: the same program under --nolibc on both engines (std.core's printf proxy, the other path to the shared formatter) */

int main(void) { printf("[%e]\n", 3.5); return 0; }
