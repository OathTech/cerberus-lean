/* FORK-PINNED: the model reports the returned int, Specified(300); gcc's $? is 44 (the host truncates, 7.22.4.4#5 implementation-defined). stdout flushed: "r". */
#include <stdio.h>
int main(void) { fputs("r", stdout); return 300; }
