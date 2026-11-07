/* tray 11, the crash variant: a byte whose decimal escape contains a 9 ("\019") made pristine's octal reader
   FAILWITH (rc 125) instead of storing. gcc 13: Specified(19). Fixed in the fork 2026-11-07. */
#include <stdio.h>
int main(void) { char b[4]; snprintf(b, 4, "%c", 19); return b[0]; }
