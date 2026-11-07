#include <stdio.h>
/* nolibc control: the same program under --nolibc on both engines (std.core's printf proxy, the other path to the shared formatter) */
#include <stdint.h>

int main(void) { printf("[%jd]\n", (intmax_t)-7); return 0; }
