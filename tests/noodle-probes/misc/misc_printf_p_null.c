/* Corner: %p with a null pointer: impl-defined rendering (ISO C11
   7.21.6.1p8). Oracle-vs-Lean agreement only (gcc "(nil)"). */
#include <stdio.h>
int main(void) { printf("[%p]\n", (void*)0); return 0; }
