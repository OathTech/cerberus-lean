#include <stdio.h>
/* nolibc control: the same program under --nolibc on both engines (std.core's printf proxy, the other path to the shared formatter) */

int main(void) { printf("[%*d]\n", 4, 9); return 0; }
