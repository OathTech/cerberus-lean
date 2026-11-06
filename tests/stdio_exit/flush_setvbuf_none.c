/* unbuffered stdout: every write through, ordered with printf. gcc: "n1pn2\n". */
#include <stdio.h>
int main(void) { setvbuf(stdout, NULL, _IONBF, 0); fputs("n1", stdout); printf("p"); fputs("n2\n", stdout); return 0; }
