#include <stdio.h>
int main(void) { int a=0,b=0; {-{ { a=fopen("sc-first.tmp","w")!=0; } ||| { b=fopen("sc-second.tmp","w")!=0; } }-}; return a+2*b; }
