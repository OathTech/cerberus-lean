/* tray 10 through the library: a "\?" literal stored by snprintf %s. gcc 13: Specified(63). Pristine c3ff8c53f: rc 125. Moved. */
#include <stdio.h>
int main(void) { char buf[8]; snprintf(buf, 8, "%s", "\?"); return buf[0]; }
