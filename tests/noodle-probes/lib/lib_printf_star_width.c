/* Corner: the `*` field width taken from an int argument (ISO C11
   7.21.6.1p5). gcc prints "[   9]". Both Cerberus engines die with
   "TODO: formatted.lem 6" (oracle uncaught Failure exit 125 / Lean PANIC). */
#include <stdio.h>
int main(void) { printf("[%*d]\n", 4, 9); return 0; }
