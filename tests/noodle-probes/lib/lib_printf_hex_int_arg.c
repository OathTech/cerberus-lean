/* Corner: %x/%X/%o (and %u) with an INT argument whose value is
   representable in unsigned int. ISO C11 7.21.6.1p9 + 6.5.2.2p6 (same
   representation, value representable in both -> interchangeable): every
   real-world program does this; gcc prints "[ff][FF][10]". Cerberus reports
   UB153b_illtyped_argument_for_format. */
#include <stdio.h>
int main(void) { printf("[%x][%X][%o]\n", 255, 255, 8); return 0; }
