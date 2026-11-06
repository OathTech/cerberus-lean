/* FORK-PINNED: Specified(-1); gcc's $? is 255. stdout "r". */
#include <stdio.h>
int main(void) { fputs("r", stdout); return -1; }
