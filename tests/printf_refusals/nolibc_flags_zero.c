#include <stdio.h>
/* nolibc control: the same program under --nolibc on both engines (std.core's printf proxy, the other path to the shared formatter) */

int main(void) { printf("[%05d][%05d][%+05d][% 05d][%05u][%05x]\n", 5, -5, 5, 5, 5u, 255u); return 0; }
