/* every FILE writer before a printf. gcc: "abcd\n". */
#include <stdio.h>
int main(void) { fputc(97, stdout); putc(98, stdout); fwrite("c", 1, 1, stdout); printf("d\n"); return 0; }
