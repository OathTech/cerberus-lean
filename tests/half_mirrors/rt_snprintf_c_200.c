/* tray 11, the widened row (bug hunt K-1, 2026-09-29): 0xC8 = 200 rendered "\200" was read back as octal 128.
   gcc 13: Specified(200). Fixed in the fork 2026-11-07. */
#include <stdio.h>
int main(void) { char b[4]; snprintf(b, 4, "%c", 200); return (unsigned char)b[0]; }
