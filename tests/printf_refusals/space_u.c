/* FORK-PINNED (not gcc's line): the space flag applied to an unsigned conversion; 7.21.6.1#6 describes the flag for
   signed conversions and, unlike `#`/`0`, does not declare the other conversions undefined; upstream prefixes the space,
   gcc prints `5` and warns. Upstream's reading, kept; filed with upstream-tray report 70. */
#include <stdio.h>

int main(void) { printf("[% u][% x]\n", 5u, 5u); return 0; }
