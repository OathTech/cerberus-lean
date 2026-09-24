#include <stdio.h>
int main(void) { int a=fopen("sc-first.tmp","w")!=0; int b=fopen("sc-second.tmp","w")!=0; return a+2*b; }
