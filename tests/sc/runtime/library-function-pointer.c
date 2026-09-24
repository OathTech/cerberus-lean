#include <stdio.h>
int main(void) { int (*f)(FILE*)=ferror; int a=0,b=0; {-{ {a=f(stdout);} ||| {b=f(stderr);} }-}; return a+b; }
