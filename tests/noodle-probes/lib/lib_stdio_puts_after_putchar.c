/* Corner: puts after putchar on the same stream: both must appear in order
   (ISO C11 7.21.3). gcc "\nxy\n"; both Cerberus engines print only "\n". */
#include <stdio.h>
int main(void) { putchar('\n'); puts("xy"); return 0; }
