#include <stdlib.h>
void a(void){} void b(void){} int main(void){atexit(a);atexit(b);return 0;}
